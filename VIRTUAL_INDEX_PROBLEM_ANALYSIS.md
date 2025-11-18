# 虚拟索引方案问题分析

## 📊 问题现象

从日志分析：
- `completedCount = 38`（已完成 38 张卡片）
- `queueCount = 322`（队列还有 322 张）
- `virtualTotal = 360`（虚拟总数）
- `currentKolodaIndex = 35`（Koloda 当前索引）

**问题**：卡片消失了，Koloda 卡在索引 35，无法继续。

---

## 🔍 问题拆解

### 问题 1：索引滞后（Index Lag）

**现象**：
- Koloda 的 `currentCardIndex = 35`
- `completedCount = 38`
- 35 < 38，说明 Koloda 的索引**落后于已完成数**

**原因分析**：
1. **提前掌握导致 completedCount 跳跃增长**：
   ```
   用户滑动第 35 张卡片
   → 检测到提前掌握
   → 一次性移除该单词的 5 张卡片
   → completedCount += 6 (当前 1 + 提前 5)
   → completedCount 从 33 跳到 39
   → 但 Koloda 的 currentCardIndex 只从 34 跳到 35
   → 差距：39 - 35 = 4
   ```

2. **Koloda 索引递增是线性的**：
   - 每次滑动：`currentCardIndex += 1`
   - 不管队列减少了多少张

3. **结果**：
   - Koloda 认为：我在显示第 35 张卡片
   - 实际状态：第 35 张卡片已经在"已完成"范围内（0-37）
   - 我们的逻辑：跳过已完成的卡片
   - **Koloda 卡住了**：无法继续，因为 `didShowCardAt` 被跳过

---

### 问题 2：didShowCardAt 被跳过导致卡片不显示

**流程**：
```
Koloda 显示索引 35 的卡片
→ 调用 didShowCardAt(35)
→ 检查：35 < 38（completedCount）
→ 返回（跳过）
→ 没有调用 viewModel.dwellTimeTracker.startTracking
→ 没有更新卡片视图
→ 用户看到空白/紫色背景
```

**关键问题**：
- `didShowCardAt` 被跳过，导致：
  1. 没有开始计时
  2. 没有更新卡片视图
  3. Koloda 认为卡片已显示，但实际没有内容

---

### 问题 3：索引不同步的累积效应

**时间线**：
```
T0: completedCount=30, currentKolodaIndex=30 ✅ 同步
T1: 滑动，提前掌握移除 5 张
    → completedCount=36, currentKolodaIndex=31 ❌ 差距 5
T2: 滑动，提前掌握移除 3 张
    → completedCount=40, currentKolodaIndex=32 ❌ 差距 8
T3: 滑动，提前掌握移除 4 张
    → completedCount=45, currentKolodaIndex=33 ❌ 差距 12
...
Tn: completedCount=38, currentKolodaIndex=35 ❌ 差距 3
```

**累积效应**：
- 每次提前掌握都会拉大差距
- 差距会越来越大
- 最终 Koloda 索引远远落后于 completedCount

---

### 问题 4：虚拟索引映射的边界条件

**当前逻辑**：
```swift
if index < completedCount {
    // 返回占位视图，跳过处理
    return placeholderView
}
```

**问题场景**：
- `completedCount = 38`
- `currentKolodaIndex = 35`
- `35 < 38` → 返回占位视图
- Koloda 认为卡片已显示，但实际是占位视图（透明）
- Koloda 不会自动递增索引，因为认为已经显示了

**根本矛盾**：
- Koloda 的索引是**累积的**（每次滑动 +1）
- 我们的 completedCount 是**跳跃的**（提前掌握时 +N）
- 两者不同步，导致 Koloda 索引落在"已完成"范围内

---

### 问题 5：updateUIView 的检测逻辑不完整

**当前检测**：
```swift
if currentKolodaIndex >= virtualTotalCount {
    // 重新加载
}
```

**缺失的检测**：
```swift
if currentKolodaIndex < completedCount {
    // 索引落后，需要调整
    // 但如何调整？Koloda 的 currentCardIndex 是只读的
}
```

**问题**：
- 只检测了"索引超出"的情况
- 没有检测"索引落后"的情况
- 即使检测到，也无法直接修改 Koloda 的 `currentCardIndex`（只读）

---

## 🎯 核心问题总结

### 问题 A：索引滞后无法自动恢复

**原因**：
- Koloda 的 `currentCardIndex` 是只读的，无法直接修改
- 提前掌握导致 `completedCount` 跳跃增长
- Koloda 索引线性增长，跟不上

**影响**：
- Koloda 卡在"已完成"范围内
- `didShowCardAt` 被跳过
- 卡片不显示

---

### 问题 B：虚拟索引映射的语义冲突

**虚拟索引的假设**：
- 索引 0 到 completedCount-1：已滑过的卡片
- 索引 completedCount 到 completedCount+queueCount-1：队列中的卡片

**实际情况**：
- Koloda 的索引是累积的，不会"跳过"已完成范围
- 如果 Koloda 索引 < completedCount，说明它还在显示"已滑过"的卡片
- 但我们的逻辑认为这是无效的，所以跳过

**冲突**：
- Koloda 认为：索引 35 是有效的
- 我们的逻辑：索引 35 是已完成的，应该跳过
- 结果：Koloda 卡住，无法继续

---

### 问题 C：提前掌握导致的索引跳跃

**提前掌握流程**：
```
滑动第 N 张卡片
→ 检测到提前掌握
→ 移除该单词的其他 M 张卡片
→ completedCount += (1 + M)
→ 但 Koloda 索引只 += 1
→ 差距 = M
```

**累积效应**：
- 每次提前掌握都会产生差距
- 差距会累积
- 最终 Koloda 索引远远落后

---

## 💡 问题本质

**虚拟索引映射的前提假设是错误的**：

**假设**：Koloda 索引会从 0 开始，逐步递增到 completedCount，然后继续到 completedCount+queueCount-1

**现实**：
1. Koloda 索引是累积的，不会"重置"
2. 提前掌握导致 completedCount 跳跃增长
3. Koloda 索引线性增长，跟不上 completedCount
4. 当 Koloda 索引 < completedCount 时，我们的逻辑认为这是"已滑过"的，所以跳过
5. 但 Koloda 认为这是有效的，所以卡住了

---

## 🔧 解决方案思路

### 方案 1：强制同步 Koloda 索引（推荐 ⭐⭐⭐⭐⭐）

**核心思想**：当检测到索引滞后时，强制让 Koloda 跳到正确的索引。

**实现**：
```swift
if currentKolodaIndex < completedCount {
    // 强制 Koloda 跳到队列的第一张卡片（索引 = completedCount）
    // 方法：重置并重新加载，但需要确保 Koloda 从 completedCount 开始
}
```

**挑战**：
- Koloda 的 `currentCardIndex` 是只读的
- `resetCurrentCardIndex()` 会重置到 0，不是我们想要的
- 需要让 Koloda 从 completedCount 开始

---

### 方案 2：调整虚拟索引映射逻辑（推荐 ⭐⭐⭐⭐）

**核心思想**：当 Koloda 索引 < completedCount 时，不跳过，而是返回队列的第一张卡片。

**实现**：
```swift
if index < completedCount {
    // 不返回占位视图，而是返回队列的第一张卡片
    // 这样 Koloda 可以继续显示，同时我们记录这是"追赶"状态
    let queueIndex = 0  // 总是返回队列的第一张
    return realCardView
}
```

**优点**：
- 不需要修改 Koloda 源码
- Koloda 可以继续显示卡片
- 用户体验好

**缺点**：
- 可能会重复显示某些卡片
- 逻辑稍微复杂

---

### 方案 3：禁用提前掌握逻辑（不推荐 ⭐⭐）

**核心思想**：暂时禁用提前掌握，让所有卡片都正常滑动。

**缺点**：
- 失去提前掌握功能
- 用户体验下降

---

### 方案 4：动态调整 completedCount（不推荐 ⭐）

**核心思想**：不让 completedCount 跳跃增长，而是线性增长。

**缺点**：
- 失去提前掌握的意义
- 进度显示不准确

---

## 🎯 推荐方案

**方案 2：调整虚拟索引映射逻辑**

**核心改进**：
- 当 `index < completedCount` 时，不返回占位视图，而是返回队列的第一张卡片（索引 0）
- 这样 Koloda 可以继续显示，同时我们记录这是"追赶"状态
- 当 Koloda 索引 >= completedCount 时，恢复正常映射

**优点**：
- ✅ 不需要修改 Koloda 源码
- ✅ Koloda 可以继续显示卡片
- ✅ 用户体验好，无卡顿
- ✅ 逻辑清晰，易于维护

**实现要点**：
1. `viewForCardAt`：当 `index < completedCount` 时，返回 `queue[0]`
2. `didSwipeCardAt`：当 `index < completedCount` 时，不触发滑动回调（因为这是"追赶"状态）
3. `didShowCardAt`：当 `index < completedCount` 时，不开始计时（因为这是"追赶"状态）

---

## 📝 总结

**问题根源**：
1. 虚拟索引映射的前提假设错误（假设 Koloda 索引会跳过已完成范围）
2. 提前掌握导致 completedCount 跳跃增长
3. Koloda 索引线性增长，跟不上 completedCount
4. 当 Koloda 索引 < completedCount 时，我们的逻辑跳过，导致 Koloda 卡住

**最佳解决方案**：
- 调整虚拟索引映射逻辑，当索引落后时，返回队列的第一张卡片，让 Koloda 可以继续显示
- 这样 Koloda 可以"追赶"到正确的索引，恢复正常映射

