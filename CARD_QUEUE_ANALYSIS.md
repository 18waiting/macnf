# 卡片队列问题分析

## 🔴 问题描述

**现象**：滑动几张卡片就没了，但任务里有好几百个词

**根本原因**：
1. `StudyViewModel.setupDemoData()` 只调用了 `wordRepository.fetchStudyCards(limit: 40)`
2. 这意味着只获取了前40个单词的卡片，而不是任务中的所有单词
3. `DailyTask` 中有 `newWords: [Int]` 和 `reviewWords: [Int]`，包含任务中所有单词的ID
4. 但代码没有根据这些ID列表来加载卡片

---

## 📊 数据流分析

### 当前流程（错误）

```
StudyViewModel.setupDemoData()
  └─> wordRepository.fetchStudyCards(limit: 40)  // ❌ 只获取40个单词
      └─> fetchWords(limit: 40)  // ❌ 只返回前40个单词
          └─> allWordIds.prefix(40)  // ❌ 不是任务中的单词
```

### 应该的流程（正确）

```
StudyViewModel.setupDemoData()
  └─> 从 currentTask 获取 newWords 和 reviewWords
      └─> wordRepository.fetchWordsByIds(newWords + reviewWords)  // ✅ 根据ID获取
          └─> 为每个单词创建卡片（新词10次，复习词5次）
```

---

## 🔍 问题详细分析

### 问题1：WordRepository 缺少按ID获取单词的方法

**位置**：`Services/WordRepository.swift`

**当前方法**：
- `fetchWords(limit: Int)` - 只返回前 `limit` 个单词
- `fetchStudyCards(limit: Int)` - 只返回前 `limit` 个单词的卡片

**缺少**：
- `fetchWordsByIds(_ wordIds: [Int])` - 根据ID列表获取单词
- `fetchStudyCardsForTask(_ task: DailyTask)` - 根据任务获取卡片

### 问题2：StudyViewModel 没有使用任务中的单词ID

**位置**：`ViewModels/StudyViewModel.swift:126`

**当前代码**：
```swift
let (cards, records) = try wordRepository.fetchStudyCards(limit: 40)  // ❌ 固定40个
```

**应该**：
```swift
// 根据任务中的单词ID列表来加载
if let task = currentTask {
    let allWordIds = task.newWords + task.reviewWords
    let (cards, records) = try wordRepository.fetchStudyCardsForWordIds(
        wordIds: allWordIds,
        newWordIds: task.newWords,
        reviewWordIds: task.reviewWords
    )
}
```

### 问题3：新词和复习词的曝光次数不同

**问题**：
- 新词可能需要10次曝光
- 复习词可能需要5次曝光
- 但当前代码对所有单词使用相同的 `exposuresPerWord`

---

## ✅ 修复方案（已实施）

### 修复1：在 WordRepository 中添加按ID获取的方法 ✅

**位置**：`Services/WordRepository.swift:43-72`

**新增方法**：
- `fetchWordsByIds(_ wordIds: [Int])` - 根据单词ID列表获取单词
- `fetchStudyCardsForTask(newWordIds:reviewWordIds:newWordExposures:reviewWordExposures:)` - 根据任务获取卡片

**功能**：
- 支持根据任务中的单词ID列表加载单词
- 区分新词和复习词，使用不同的曝光次数
- 处理单词ID不存在的情况（记录警告但不崩溃）

---

### 修复2：修改 StudyViewModel 使用任务中的单词ID ✅

**位置**：`ViewModels/StudyViewModel.swift:126-175`

**修复前**：
```swift
let (cards, records) = try wordRepository.fetchStudyCards(limit: 40)  // ❌ 只获取40个单词
```

**修复后**：
```swift
if let task = currentTask, !task.newWords.isEmpty || !task.reviewWords.isEmpty {
    // ✅ 使用任务中的单词ID列表
    (cards, records) = try wordRepository.fetchStudyCardsForTask(
        newWordIds: task.newWords,
        reviewWordIds: task.reviewWords,
        newWordExposures: newWordExposures,
        reviewWordExposures: reviewWordExposures
    )
} else {
    // 向后兼容：如果没有任务，使用默认方式
    (cards, records) = try wordRepository.fetchStudyCards(limit: 40)
}
```

---

### 修复3：区分新词和复习词的曝光次数 ✅

**位置**：`ViewModels/StudyViewModel.swift:135-160`

**修复内容**：
- 根据任务的 `totalExposures` 来估算每个单词的曝光次数
- 新词和复习词使用不同的曝光次数
- 如果任务有 `totalExposures`，使用它来计算；否则使用策略默认值

---

## 🎯 修复效果

### 修复前
- ❌ 只加载了40个单词的卡片
- ❌ 任务中有几百个词，但只显示几张卡片
- ❌ 没有根据任务中的单词ID列表来加载

### 修复后
- ✅ 根据任务中的单词ID列表加载所有卡片
- ✅ 支持几百个单词的任务
- ✅ 区分新词和复习词，使用不同的曝光次数
- ✅ 向后兼容：如果没有任务，使用默认方式

---

## 📋 验证方法

1. **检查日志**：
   ```
   [ViewModel] Loading cards from task: X new + Y review
   [Repository] fetchStudyCardsForTask: newWords=X, reviewWords=Y
   [Repository] Generated Z cards from task
   [ViewModel] Card queue prepared: Z cards
   ```

2. **测试场景**：
   - 创建一个包含几百个单词的任务
   - 开始学习，检查卡片数量是否正确
   - 滑动多张卡片，确认队列不会过早结束

3. **检查数据**：
   - 确认 `queue.count` 应该等于任务的总曝光次数
   - 确认 `visibleCards.count` 应该始终有卡片（直到队列用完）

