# 滑卡逻辑与数据流架构文档

> 本文档描述当前项目（NFwordsDemo）中基于 SwiftUI 原生实现的滑卡逻辑、数据结构及数据流向。
> **注意**：本项目已从 Koloda 库迁移至自定义 SwiftUI 实现 (`SwipeCardsView`)，以解决索引同步和性能问题。

## 1. 核心数据结构

### 1.1 基础模型

#### `StudyCard` (学习卡片)
UI 渲染的基本单位，轻量级设计。
```swift
struct StudyCard: Identifiable {
    let id: UUID          // 唯一标识符 (即使同一单词多次出现，ID也不同)
    let word: Word        // 关联的单词数据
    // 不包含可变状态，状态存储在 ViewModel 的字典中
}
```

#### `WordLearningRecord` (学习记录)
记录单词的学习状态，是业务逻辑的核心。
```swift
struct WordLearningRecord {
    let id: Int                    // 单词ID (wid)
    var swipeRightCount: Int       // 掌握次数
    var swipeLeftCount: Int        // 遗忘次数
    var remainingExposures: Int    // 本次任务剩余需展示次数
    var targetExposures: Int       // 本次任务目标展示次数
    var dwellTimes: [TimeInterval] // 历史停留时间记录
    
    // 计算属性
    var avgDwellTime: TimeInterval // 平均停留时间
    var isMastered: Bool           // 是否已掌握
}
```

### 1.2 视图模型 (`StudyViewModel`)

ViewModel 是单一数据源（Single Source of Truth），管理所有状态。

```swift
class StudyViewModel: ObservableObject {
    // MARK: - 状态数据
    @Published var visibleCards: [StudyCard] = []  // 当前UI渲染的卡片堆叠（最多3张）
    @Published var completedCount: Int = 0         // 已完成卡片数
    @Published var queueCount: Int = 0             // 剩余队列长度
    
    // MARK: - 核心存储
    private var queue: [StudyCard] = []            // 完整的待学习卡片队列 (FIFO)
    private var learningRecords: [Int: WordLearningRecord] = [:] // 单词ID -> 学习记录
}
```

---

## 2. 滑卡交互逻辑 (`SwipeCardsView`)

### 2.1 视觉堆叠 (Visual Stack)
采用 SwiftUI `ZStack` 实现 3 层卡片堆叠效果：
1.  **顶层卡 (`InteractiveCard`)**: 唯一可交互的卡片，支持拖拽、点击展开。
2.  **底层卡 (`CardBackdrop`)**: 仅作视觉展示，通过 `offset` 和 `scale` 营造深度感。
3.  **背景**: 渐变色背景。

### 2.2 交互流程
1.  **手势**: 用户拖拽顶层卡片。
2.  **判断**: 拖拽距离超过阈值（如 100pt）。
3.  **动画**: 卡片飞出屏幕（左/右），同时触发触感反馈。
4.  **回调**: 调用 `onSwipe(direction, dwellTime)`。
5.  **销毁**: SwiftUI 自动根据 `visibleCards` 的变化移除视图。

---

## 3. 数据流向 (Data Flow)

当发生一次有效滑动时，数据流向如下：

### 步骤 1: 交互触发
用户在 `SwipeCardsView` 完成滑动，触发 `viewModel.handleSwipe(wordId, direction, dwellTime)`。

### 步骤 2: 更新学习记录
*   在 `learningRecords` 中找到对应 `wordId` 的记录。
*   更新 `swipeRightCount`/`swipeLeftCount`。
*   记录本次 `dwellTime`。
*   **异步操作**: 立即启动 Task 将滑动事件写入数据库 (`ExposureEventStorage`)。

### 步骤 3: 策略检查 (Strategy Check)
*   调用 `ExposureStrategy` 检查单词是否**提前掌握**。
*   **如果已掌握**:
    *   从 `queue` 中移除该单词的所有**后续**卡片。
    *   计算移除数量，累加到 `completedCount`。
    *   *目的：避免用户重复学习已熟练的单词。*

### 步骤 4: 更新队列 (Queue Update)
*   **移除**: 从 `queue` 头部移除当前卡片 (`removeFirst()`)。
*   **统计**: `completedCount += 1`。
*   **任务进度**: 更新 `currentTask.completedExposures`。

### 步骤 5: 刷新视图 (View Refresh)
*   **重算可见卡片**: `visibleCards = Array(queue.prefix(3))`。
*   **UI响应**: 
    *   `@Published visibleCards` 变化触发 View 重绘。
    *   旧的顶层卡片消失。
    *   原来的第二张卡片变为新的顶层卡片（带动画）。
    *   新的第三张卡片从队列补充进来。

### 步骤 6: 完成检查
*   如果 `queue` 和 `visibleCards` 都为空：
    *   触发 `completeStudy()`。
    *   生成 `DailyReport`。
    *   保存所有数据到数据库。
    *   显示完成界面。

---

## 4. 关键算法与策略

### 4.1 队列优化 (`optimizeQueue`)
在初始化时，对原始卡片列表进行重排：
*   **目标**: 避免同一单词的卡片连续出现。
*   **逻辑**: 使用缓冲区，当遇到相同单词时暂存，直到遇到新单词或缓冲区满再插入。

### 4.2 停留时间追踪 (`DwellTimeTracker`)
*   **开始**: 卡片出现 (`onAppear`) 或成为顶层卡片时记录 `startTime`。
*   **结束**: 滑动触发时计算 `Date() - startTime`。
*   **用途**: 停留时间是判断单词难度的核心指标，用于后续的复习调度和 AI 短文生成。

### 4.3 进度计算
为了保证进度条平滑增长（分母不减）：
*   `initialTotalCount`: 初始化队列时固定保存总数。
*   `progress = completedCount / initialTotalCount`。
*   即使触发"提前掌握"移除了卡片，`completedCount` 也会相应增加移除的数量，确保进度最终能达到 100%。

---

## 5. 总结

| 组件 | 职责 | 关键点 |
| :--- | :--- | :--- |
| **SwipeCardsView** | 负责渲染和手势 | 纯 UI，不处理业务逻辑，只回调 |
| **StudyViewModel** | 负责业务逻辑 | 单一数据源，管理队列和状态 |
| **StudyCard** | 渲染数据 | 只有 ID 和 Word，无状态 |
| **WordLearningRecord** | 业务状态 | 记录掌握程度和停留时间 |

这种架构实现了 **UI 与逻辑的完全解耦**，利用 SwiftUI 的响应式特性解决了之前 Koloda 方案中索引不同步的痛点。
