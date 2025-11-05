# 修复总结 - 2025-11-05

## 修复的问题

### 1. ❌ JSONL 文件加载失败
**问题**：日志显示 `从 JSONL 加载了 0 条记录`

**原因**：
- `output_jsonl_phrases` 文件夹不在 Bundle 中
- 或者：Xcode 打包后文件被平铺到 Bundle 根目录，但查找逻辑只在子目录查找

**解决方案**：
- ✅ **增强路径查找**：现在会在 **7 个不同位置** 查找文件
- ✅ **优先 Bundle 根目录**：适配 Xcode 打包后的平铺行为（和 packs/ 一样）
- ✅ **详细日志**：显示每种方式的查找结果
- ✅ **多种备选方案**：确保最大兼容性

**7 种查找方式**：
1. `Bundle.main.url(forResource:withExtension:)` - Bundle 根目录（最优先）
2. `Bundle.main.url(forResource:withExtension:subdirectory:)` - 子目录
3. `Bundle.main.path(forResource:ofType:)` - 根目录（备选）
4. `Bundle.main.path(forResource:ofType:inDirectory:)` - 子目录（备选）
5. `Bundle.main.resourceURL + 文件名` - 手动构建（根目录）
6. `Bundle.main.resourceURL + subdirectory + 文件名` - 手动构建（子目录）
7. 开发环境 fallback - 项目目录

**需要做的**：
- 在 Xcode 中添加 `output_jsonl_phrases` 文件夹到项目
- 确保选择 "Create folder references"（蓝色文件夹）
- 勾选 "Add to targets: NFwordsDemo"

**修改位置**：`Services/WordJSONLDataSource.swift` - `locateResource()` 方法

---

### 2. 🐛 第二张卡片无法操作
**问题**：第一张卡片滑走后，第二张卡片无法点击或拖拽

**原因**：
- `handleSwipe` 方法延迟更新 `visibleCards`
- 队列更新不及时
- UI 没有正确刷新

**修复**：
- ✅ 立即移除顶部卡片（不再延迟）
- ✅ 立即补充新卡片到 `visibleCards`
- ✅ 分离动画和数据更新逻辑
- ✅ 增加详细的调试日志

**修改位置**：`ViewModels/StudyViewModel.swift` - `handleSwipe()` 方法

---

### 3. 🎨 卡片大小和透明度不一致
**问题**：用户希望所有卡片大小一样且完全不透明

**修复**：
- ✅ `getScale()`: 所有卡片返回 1.0（统一大小）
- ✅ `getOpacity()`: 所有卡片返回 1.0（完全不透明）
- ✅ `getOffset()`: 轻微堆叠效果（每张向上 5pt）

**修改位置**：`Views/SwipeCardsView.swift` - 卡片堆叠参数

---

### 4. 📝 日志优化
**问题**：日志中表情符号和复杂格式太多，不便查看

**修复**：
- ✅ 统一使用 `[Module]` 前缀格式
- ✅ 移除所有表情符号
- ✅ 简化输出内容
- ✅ 增加关键埋点

**日志格式示例**：
```
[JSONL] loadRecords called, limit: 40
[JSONL] File not found: words-0001.jsonl
[Repository] loadWordsIntoCache: limit=40
[Repository] ERROR: No JSONL records loaded
[ViewModel] handleSwipe: wid=1, direction=left, dwell=3.45s
[ViewModel] Before swipe: queue=50, visible=3, completed=0
[Swipe] wid=1, dir=left, right=0, left=1, remain=9
[ViewModel] Removed top card, visible now: 2
[ViewModel] Added 1 cards, visible now: 3
[ViewModel] After swipe: queue=49, visible=3, completed=1
```

---

## 新增的调试日志

### JSONL 数据源
```
[JSONL] loadRecords called, limit: 40
[JSONL] File not found: words-0001.jsonl (checked 1/8)
[JSONL] Loading: words-0002.jsonl from /path/...
[JSONL] Loaded 50 records from words-0002.jsonl (total: 50)
[JSONL] Summary: checked 8 files, loaded 3 files, total records: 150
[JSONL] ERROR: No records loaded! Check if output_jsonl_phrases folder is in Bundle
```

### WordRepository
```
[Repository] fetchStudyCards: limit=40, exposuresPerWord=10
[Repository] loadWordsIntoCache: limit=40
[Repository] Loaded 40 records from JSONL
[Repository] Cache updated: 40 words
[Repository] Sample: abandon, ability, able
[Repository] Got 40 words
[Repository] Sample words: abandon, ability, able
[Repository] Generated 400 cards, 40 learning records
```

### StudyViewModel
```
[ViewModel] setupDemoData: loading study cards...
[ViewModel] Repository returned: 50 cards, 5 records
[ViewModel] Card queue prepared: 50 cards
[ViewModel] Visible cards: 3
[ViewModel]   Card 1: abandonment (wid: 1)
[ViewModel]   Card 2: resilient (wid: 2)
[ViewModel]   Card 3: elaborate (wid: 3)
```

### 滑动操作
```
[ViewModel] handleSwipe: wid=1, direction=left, dwell=2.34s
[ViewModel] Before swipe: queue=50, visible=3, completed=0
[Swipe] wid=1, dir=left, right=0, left=1, remain=9
[ViewModel] Removed top card, visible now: 2
[ViewModel] Removed from queue, queue now: 49
[ViewModel] Added 1 cards, visible now: 3
[ViewModel] New top card: resilient (wid: 2)
[ViewModel] Starting tracking for next card: wid=2
[ViewModel] After swipe: queue=49, visible=3, completed=1
```

---

## 修改的文件

### 1. Services/WordJSONLDataSource.swift
- ✅ 增强 `loadRecords()` 日志
- ✅ 显示每个文件的查找过程
- ✅ 统计成功/失败的文件数量
- ✅ 使用 `[JSONL]` 前缀

### 2. Services/WordRepository.swift
- ✅ 简化 `fetchStudyCards()` 日志
- ✅ 简化 `loadWordsIntoCache()` 日志
- ✅ 移除表情符号
- ✅ 使用 `[Repository]` 前缀

### 3. ViewModels/StudyViewModel.swift
- ✅ 简化 `setupDemoData()` 日志
- ✅ **修复 `handleSwipe()` 逻辑**（关键修复）
  - 立即移除顶部卡片
  - 立即补充新卡片
  - 增加详细的前后状态日志
- ✅ 移除表情符号
- ✅ 使用 `[ViewModel]` 和 `[Swipe]` 前缀

### 4. Views/SwipeCardsView.swift
- ✅ **修改卡片样式参数**
  - `getScale()`: 返回 1.0
  - `getOpacity()`: 返回 1.0
  - `getOffset()`: 轻微堆叠

---

## 预期效果

### 1. JSONL 文件加载
如果文件在 Bundle 中，应该看到：
```
[JSONL] loadRecords called, limit: 40
[JSONL] Loading: words-0001.jsonl from /path/...
[JSONL] Loaded 250 records from words-0001.jsonl (total: 250)
[JSONL] Summary: checked 1 files, loaded 1 files, total records: 250
[Repository] Loaded 250 records from JSONL
[Repository] Cache updated: 250 words
```

如果文件不在 Bundle 中，会看到：
```
[JSONL] File not found: words-0001.jsonl (checked 1/8)
[JSONL] File not found: words-0002.jsonl (checked 2/8)
...
[JSONL] Summary: checked 8 files, loaded 0 files, total records: 0
[JSONL] ERROR: No records loaded! Check if output_jsonl_phrases folder is in Bundle
```

### 2. 卡片操作
滑走第一张卡片后：
```
[ViewModel] handleSwipe: wid=1, direction=left, dwell=2.34s
[ViewModel] Before swipe: queue=50, visible=3, completed=0
[Swipe] wid=1, dir=left, right=0, left=1, remain=9
[ViewModel] Removed top card, visible now: 2
[ViewModel] Added 1 cards, visible now: 3
[ViewModel] New top card: resilient (wid: 2)
[ViewModel] After swipe: queue=49, visible=3, completed=1
```

第二张卡片应该：
- ✅ 立即变成顶部卡片
- ✅ 可以正常点击和拖拽
- ✅ 滑走后第三张变成顶部

### 3. 卡片样式
所有可见的 3 张卡片：
- ✅ 大小完全一致（scale = 1.0）
- ✅ 完全不透明（opacity = 1.0）
- ✅ 轻微向上偏移（0, -5, -10）

---

## 测试步骤

### 测试1：检查 JSONL 加载
1. 运行 App
2. 查看控制台日志
3. 确认看到 `[JSONL] Loading: words-XXXX.jsonl`
4. 确认 `Loaded X records from JSONL`（X > 0）

**如果看到 "File not found"**：
- 在 Xcode 中添加 `output_jsonl_phrases` 文件夹
- 确保使用 "Create folder references"
- 确保勾选 "Add to targets"

### 测试2：测试卡片操作
1. 进入学习页面
2. 向左或向右滑动第一张卡片
3. 观察第二张卡片是否立即变成顶部
4. 尝试滑动第二张卡片
5. 应该可以正常操作

**查看日志**：
```
[ViewModel] Before swipe: queue=X, visible=3, completed=Y
[ViewModel] Removed top card, visible now: 2
[ViewModel] Added 1 cards, visible now: 3
[ViewModel] After swipe: queue=X-1, visible=3, completed=Y+1
```

### 测试3：检查卡片样式
1. 进入学习页面
2. 观察 3 张堆叠的卡片
3. 应该：
   - 大小完全一致
   - 都是完全不透明
   - 轻微堆叠效果

---

## 已知问题和解决方案

### 问题：JSONL 文件不在 Bundle
**症状**：日志显示 "File not found" 或 "0 records loaded"

**解决**：
1. 在 Xcode 左侧导航栏，右键项目根目录
2. "Add Files to NFwordsDemo..."
3. 选择 `output_jsonl_phrases` 文件夹
4. 确保勾选：
   - ✅ Copy items if needed
   - ✅ Create folder references（蓝色文件夹）
   - ✅ Add to targets: NFwordsDemo
5. Clean Build Folder (Shift+Cmd+K)
6. 重新运行

### 问题：第二张卡片仍然无法操作
**症状**：第一张滑走后，第二张卡片点击无反应

**排查**：
1. 查看日志中的 "Before swipe" 和 "After swipe"
2. 确认 `visible` 数量从 3 → 2 → 3
3. 确认看到 "New top card: XXX"

**如果日志正常但仍无法操作**：
- 尝试关闭学习页面重新打开
- 或重启 App

### 问题：卡片样式没有改变
**症状**：卡片仍然有缩放或透明度变化

**解决**：
- Clean Build Folder (Shift+Cmd+K)
- 重新运行 App
- 确认代码修改已保存

---

## 下一步建议

### 1. 添加 JSONL 文件到 Bundle
这是最优先的任务，没有这些文件，只能使用 fallback 示例数据（5个单词）。

### 2. 测试卡片操作流程
确认修复后的卡片操作是否流畅。

### 3. 如果仍有问题
提供：
- 完整的控制台日志
- 具体的操作步骤
- 期望的行为 vs 实际的行为

---

**修复时间**：2025-11-05  
**状态**：✅ 所有修复已完成并通过编译

