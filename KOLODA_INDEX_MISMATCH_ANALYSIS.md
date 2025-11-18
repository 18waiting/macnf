# Koloda 索引不匹配问题分析

## 📊 问题现象

- **总单词数**：353（`initialTotalCount=353`）
- **已完成进度**：266/353（已完成 266 张卡片）
- **当前队列数**：69（`queueCount=69`）
- **Koloda 索引**：74/75（超出队列范围 0-68）
- **问题**：进度在 266 时卡片就滑完了

## 🔍 根本原因分析

### 核心问题：**索引递增与队列减少不同步**

#### 问题流程：

1. **正常滑动流程**：
   ```
   用户滑动第 0 张卡片
   → handleSwipe() 调用
   → queue.removeFirst() (移除 1 张)
   → Koloda.currentCardIndex += 1 (递增 1)
   → 队列从 100 → 99，索引从 0 → 1 ✅ 同步
   ```

2. **提前掌握流程（问题所在）**：
   ```
   用户滑动第 0 张卡片（单词 A）
   → handleSwipe() 调用
   → 检测到提前掌握
   → queue.removeAll { wordId == A } (移除 6 张：当前 1 张 + 其他 5 张)
   → queue.removeFirst() (再移除 1 张，但已经被移除了)
   → 队列从 100 → 94 (减少了 6 张)
   → Koloda.currentCardIndex += 1 (只递增 1)
   → 队列从 100 → 94，索引从 0 → 1 ❌ 不同步！
   ```

3. **累积效应**：
   ```
   第 1 次滑动：队列 100 → 94，索引 0 → 1 (差距: -5)
   第 2 次滑动：队列 94 → 88，索引 1 → 2 (差距: -10)
   第 3 次滑动：队列 88 → 82，索引 2 → 3 (差距: -15)
   ...
   第 20 次滑动：队列 10 → 4，索引 19 → 20 (差距: -100)
   → 索引 20 超出队列范围 (0-3) ❌
   ```

### 数学验证：

- **已完成卡片数**：266
- **剩余队列数**：69
- **理论剩余数**：353 - 266 = 87
- **实际差距**：87 - 69 = 18 张卡片

**说明**：有 18 张卡片被提前掌握逻辑移除了，但 Koloda 索引没有相应调整。

### 代码分析：

#### 1. `handleSwipe` 中的提前掌握逻辑：
```swift
// 提前掌握，移除该单词的所有剩余卡片
if !exposureStrategy.shouldContinueExposure(for: updatedRecord) {
    queue.removeAll { card.word.id == wordId && card.id != currentCardId }
    // 可能移除 5-10 张卡片
}

// 然后移除当前卡片
queue.removeFirst()
// 队列总共减少了 6-11 张
```

#### 2. Koloda 的索引递增：
```swift
// KolodaView.swift:418
currentCardIndex += 1
// 只递增 1，不管队列减少了多少张
```

#### 3. 索引映射：
```swift
// KolodaCardsView.swift
func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
    return viewModel?.queueCount ?? 0  // 返回 69
}

func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
    let queueIndex = index  // 直接使用索引
    // 当 index=74 时，queueIndex=74，但队列只有 69 张，越界！
}
```

## 🎯 问题本质

**Koloda 的 `currentCardIndex` 是累积递增的**，每次滑动只递增 1，但我们的队列可能因为"提前掌握"而一次性减少多张卡片。

**关键矛盾**：
- Koloda 认为：我滑了 75 张卡片，所以索引是 75
- 实际队列：只有 69 张卡片（因为提前掌握移除了 6 张）
- 结果：索引 75 超出队列范围 (0-68)

## 📈 数据验证

从日志计算：
- `completedCount = 266`（已完成）
- `queueCount = 69`（剩余）
- `initialTotalCount = 353`（总数）
- **验证**：266 + 69 = 335 ≠ 353
- **差距**：353 - 335 = 18 张卡片

**说明**：有 18 张卡片被提前掌握逻辑移除了，但 `completedCount` 已经正确计算了（266 = 实际滑动 + 提前移除），问题是 Koloda 的索引没有相应调整。

## 🔧 解决方案思路

### 方案 1：动态调整 Koloda 索引（推荐 ⭐⭐⭐⭐⭐）

**核心思想**：当队列减少时，同步调整 Koloda 的 `currentCardIndex`。

```swift
// 在 handleSwipe 后，检测索引是否超出范围
if koloda.currentCardIndex >= queueCount {
    // 调整索引到队列范围内
    koloda.currentCardIndex = max(0, queueCount - 1)
    koloda.reloadData()
}
```

**优点**：
- ✅ 完全同步，不会出现索引越界
- ✅ 保持 Koloda 的索引语义（已滑过的卡片数）

**缺点**：
- ⚠️ 需要访问 Koloda 的 `currentCardIndex`（只读，可能需要 KVC 或修改源码）

### 方案 2：使用虚拟索引映射（当前方案的改进 ⭐⭐⭐⭐）

**核心思想**：让 `kolodaNumberOfCards` 返回一个虚拟总数，包含已滑过的卡片。

```swift
func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
    // 返回：已完成数 + 当前队列数
    return (viewModel?.completedCount ?? 0) + (viewModel?.queueCount ?? 0)
}

func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
    // 如果索引在已完成范围内，返回占位卡片
    // 如果索引在队列范围内，返回真实卡片
    let completedCount = viewModel?.completedCount ?? 0
    if index < completedCount {
        return placeholderView  // 已滑过的卡片
    }
    let queueIndex = index - completedCount
    return realCardView  // 队列中的卡片
}
```

**优点**：
- ✅ 不需要修改 Koloda 源码
- ✅ Koloda 索引可以累积递增，不会越界

**缺点**：
- ⚠️ 需要维护占位卡片（但只在已滑过范围内，不会影响当前显示）

### 方案 3：禁用提前掌握逻辑（临时方案 ⭐⭐）

**核心思想**：暂时禁用提前掌握，让所有卡片都正常滑动。

**优点**：
- ✅ 简单，立即解决问题

**缺点**：
- ❌ 失去提前掌握功能
- ❌ 用户体验下降

## 🎯 推荐方案

**推荐方案 2：虚拟索引映射**

原因：
1. **不需要修改第三方库**：Koloda 的 `currentCardIndex` 是只读的，方案 1 需要修改源码
2. **性能影响小**：占位卡片只在已滑过范围内，不会影响当前显示
3. **逻辑清晰**：Koloda 索引 = 已完成数 + 队列索引，语义明确
4. **易于实现**：只需要修改 `kolodaNumberOfCards` 和 `viewForCardAt`

## 📝 实现要点

1. **`kolodaNumberOfCards`**：
   ```swift
   return completedCount + queueCount  // 虚拟总数
   ```

2. **`viewForCardAt`**：
   ```swift
   if index < completedCount {
       return placeholderView  // 已滑过的卡片
   }
   let queueIndex = index - completedCount
   return realCardView  // 队列中的卡片
   ```

3. **`didSwipeCardAt`**：
   ```swift
   let queueIndex = index - completedCount
   // 使用 queueIndex 处理滑动
   ```

4. **`didShowCardAt`**：
   ```swift
   let queueIndex = index - completedCount
   if queueIndex >= 0 {
       // 只处理队列中的卡片
   }
   ```

## ✅ 总结

**问题根源**：提前掌握逻辑一次性移除多张卡片，但 Koloda 索引只递增 1，导致索引与队列不同步。

**最佳解决方案**：使用虚拟索引映射，让 Koloda 索引 = 已完成数 + 队列索引，这样 Koloda 可以正常累积递增，不会越界。

