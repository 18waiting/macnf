# 卡片滑动数据结构与逻辑架构总结

## 📋 目录

1. [核心数据结构](#核心数据结构)
2. [数据流架构](#数据流架构)
3. [滑卡逻辑流程](#滑卡逻辑流程)
4. [关键机制](#关键机制)
5. [当前问题与优化方向](#当前问题与优化方向)

---

## 1. 核心数据结构

### 1.1 StudyCard（学习卡片）

```swift
struct StudyCard: Identifiable {
    let id: UUID          // 卡片唯一ID（UUID保证全局唯一）
    let word: Word        // 关联的单词对象
    // ⭐ 注意：不包含 record，避免值类型副本导致数据不同步
}
```

**设计要点**：
- **轻量级设计**：只包含 `id` 和 `word`，不包含学习记录
- **数据源分离**：学习记录通过 `word.id` 从 `learningRecords` 字典获取
- **唯一性保证**：每个卡片都有唯一的 UUID，即使同一单词的多次曝光也有不同 ID

**数据获取**：
- 学习记录：`viewModel.getLearningRecord(for: card.word.id)`
- 曝光信息：`(current: record.targetExposures - record.remainingExposures, total: record.targetExposures)`

---

### 1.2 WordLearningRecord（学习记录）

```swift
struct WordLearningRecord: Identifiable {
    let id: Int                    // wid（单词ID）
    var swipeRightCount: Int      // 右滑次数（会写）
    var swipeLeftCount: Int        // 左滑次数（不会写）
    var totalExposureCount: Int    // 总曝光次数
    var remainingExposures: Int   // 剩余曝光次数
    var targetExposures: Int       // 目标曝光次数
    var dwellTimes: [TimeInterval] // 每次停留时间
    var totalDwellTime: TimeInterval
    
    // 计算属性
    var avgDwellTime: TimeInterval
    var isMastered: Bool
    var familiarityScore: Int
}
```

**存储位置**：
- `StudyViewModel.learningRecords: [Int: WordLearningRecord]` - 字典存储，key 为 `wordId`
- **单源真相**：所有 UI 组件都从这个字典获取最新数据，避免数据不同步

---

### 1.3 StudyViewModel（核心状态管理）

```swift
class StudyViewModel: ObservableObject {
    // MARK: - Published Properties（UI 观察）
    @Published var visibleCards: [StudyCard] = []      // 可见卡片（前3张）
    @Published var completedCount: Int = 0             // 已完成卡片数
    @Published var queueCount: Int = 0                  // 队列数量（触发 UI 更新）
    @Published var initialTotalCount: Int = 0           // 初始总数（固定值）
    
    // MARK: - Private Properties（内部状态）
    private var queue: [StudyCard] = [] {               // 卡片队列（FIFO）
        didSet {
            queueCount = queue.count  // 自动更新 @Published 属性
        }
    }
    private var learningRecords: [Int: WordLearningRecord] = [:]  // wid -> record
}
```

**关键设计**：
- **队列管理**：`queue` 是 FIFO 队列，滑动后移除第一张
- **可见卡片**：`visibleCards = Array(queue.prefix(3))`，始终是队列的前3张
- **进度计算**：`totalCount = initialTotalCount`（固定值），`progress = completedCount / totalCount`

---

## 2. 数据流架构

### 2.1 数据初始化流程

```
1. StudyViewModel.init()
   ↓
2. loadCurrentGoalAndTask()
   - 从数据库加载当前目标和任务
   ↓
3. setupDemoData()
   - 如果有任务：fetchStudyCardsForTask(newWordIds, reviewWordIds, ...)
   - 否则：fetchStudyCards(limit: 40)
   ↓
4. WordRepository.fetchStudyCardsForTask()
   - fetchWordsByIds(newWordIds) + fetchWordsByIds(reviewWordIds)
   - 为每个单词创建 targetExposures 张卡片
   - 创建 WordLearningRecord（初始状态）
   ↓
5. optimizeQueue(cards)
   - 优化队列顺序（避免连续相同单词）
   ↓
6. queue = optimizeQueue(cards)
   - initialTotalCount = queue.count  // ⭐ 保存初始总数
   - visibleCards = Array(queue.prefix(3))
```

**关键点**：
- **初始总数固定**：`initialTotalCount` 在队列创建时保存，用于进度计算
- **队列优化**：防止连续出现相同单词，提升学习体验
- **学习记录初始化**：每个单词创建初始 `WordLearningRecord`，存储在 `learningRecords` 字典

---

### 2.2 滑卡数据流

```
用户滑动卡片
   ↓
KolodaCardsCoordinator.didSwipeCardAt(index, direction)
   ↓
1. 从队列获取卡片：viewModel.getCard(at: index)
2. 获取停留时间：viewModel.dwellTimeTracker.stopTracking()
3. 触发回调：onSwipe(wordId, direction, dwellTime)
   ↓
StudyViewModel.handleSwipe(wordId, direction, dwellTime)
   ↓
【步骤1】更新学习记录
   - learningRecords[wordId].recordSwipe(direction, dwellTime)
   - 异步保存到数据库：eventStorage.recordSwipe(...)
   ↓
【步骤2】检查提前掌握
   - exposureStrategy.shouldContinueExposure(for: record)
   - 如果已掌握：从队列移除该单词的所有剩余卡片
   - earlyMasteredRemovedCount = 移除的卡片数
   ↓
【步骤3】更新统计
   - completedCount += (1 + earlyMasteredRemovedCount)
   - rightSwipeCount 或 leftSwipeCount += 1
   ↓
【步骤4】更新任务进度
   - currentTask.completedExposures = completedCount
   ↓
【步骤5】移除当前卡片
   - queue.removeFirst()  // 移除队列第一张
   ↓
【步骤6】更新可见卡片
   - visibleCards = Array(queue.prefix(3))
   ↓
【步骤7】重置 Koloda 索引（延迟 0.3 秒）
   - koloda.resetCurrentCardIndex()  // 重置为 0，对应队列第一张
   ↓
【步骤8】检查完成
   - if queue.isEmpty && visibleCards.isEmpty: completeStudy()
```

**关键机制**：
- **数据同步**：`learningRecords` 字典是单源真相，所有更新都直接修改字典
- **队列更新**：滑动后队列减少，`queueCount` 自动更新（通过 `didSet`）
- **索引重置**：滑动完成后延迟重置 Koloda 索引，确保索引与队列同步

---

## 3. 滑卡逻辑流程

### 3.1 Koloda 与队列的索引映射

**设计原则**：
- **Koloda 只看到剩余队列**：`kolodaNumberOfCards` 返回 `queueCount`（当前队列数量）
- **索引直接对应**：Koloda 的索引（0 到 queueCount-1）直接对应队列索引
- **滑动后重置**：每次滑动完成后，调用 `resetCurrentCardIndex()` 重置索引为 0

**索引同步机制**：
```
初始状态：
- 队列：360 张卡片，索引 0-359
- Koloda：看到 360 张，currentCardIndex=0

滑动第一张后（立即）：
- 队列：359 张卡片，索引 0-358（第一张被移除）
- Koloda：currentCardIndex=1（自动递增）

滑动完成后（0.3 秒后）：
- 队列：359 张卡片，索引 0-358
- Koloda：resetCurrentCardIndex() → currentCardIndex=0
- 现在 Koloda 索引 0 对应队列索引 0（新的第一张）
```

---

### 3.2 卡片视图创建与重用

**视图重用池**：
```swift
private var cardViewPool: [WordCardUIView] = []
private let maxPoolSize = 5

func dequeueCardView() -> WordCardUIView {
    // 从池中获取或创建新视图
}

func enqueueCardView(_ view: WordCardUIView) {
    // 清理视图状态，回收到池中
}
```

**数据配置**：
```swift
func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
    let card = viewModel.getCard(at: index)  // 从队列获取
    let cardView = dequeueCardView()         // 从池获取视图
    
    // 获取最新学习记录
    let record = viewModel.getLearningRecord(for: card.word.id)
    let exposureInfo = (current: record.targetExposures - record.remainingExposures,
                       total: record.targetExposures)
    
    cardView.configure(with: card, exposureInfo: exposureInfo)
    return cardView
}
```

---

### 3.3 提前掌握机制

**逻辑流程**：
```swift
if !exposureStrategy.shouldContinueExposure(for: updatedRecord) {
    // 提前掌握，移除该单词的所有剩余卡片
    let remainingCards = queue.filter { $0.word.id == wordId }
    earlyMasteredRemovedCount = remainingCards.count - 1
    
    queue.removeAll { card in
        card.word.id == wordId && card.id != currentCardId
    }
}
```

**影响**：
- **统计准确性**：`completedCount` 需要包含提前移除的卡片数
- **队列变化**：队列数量可能大幅减少（例如从 360 变成 353）
- **索引重置**：队列变化后必须重置 Koloda 索引

---

## 4. 关键机制

### 4.1 进度计算机制

**固定分母设计**：
```swift
var totalCount: Int {
    if initialTotalCount > 0 {
        return initialTotalCount  // 固定值，不会减少
    }
    // 后备方案
    return queueCount + completedCount
}

var progress: Double {
    return Double(completedCount) / Double(totalCount)
}
```

**优势**：
- **分母固定**：进度分母不会随着队列减少而减少
- **准确反映**：进度 = 已完成数 / 初始总数，准确反映学习进度

---

### 4.2 索引同步机制

**问题**：
- Koloda 的 `currentCardIndex` 在滑动后自动递增
- 我们的队列在滑动后减少（移除第一张）
- 导致索引不同步

**解决方案**：
1. **滑动后重置**：在 `didSwipeCardAt` 中延迟 0.3 秒调用 `resetCurrentCardIndex()`
2. **索引检查**：在 `updateUIView` 中检查索引是否超出范围，超出则重置
3. **后备保护**：在 `kolodaDidRunOutOfCards` 中检查队列是否还有卡片，有则重置

---

### 4.3 数据一致性保证

**单源真相原则**：
- **学习记录**：存储在 `learningRecords: [Int: WordLearningRecord]` 字典中
- **UI 获取**：所有 UI 组件通过 `getLearningRecord(for: wordId)` 获取最新数据
- **避免副本**：`StudyCard` 不包含 `record` 字段，避免值类型副本导致数据不同步

**更新流程**：
```
handleSwipe()
   ↓
learningRecords[wordId].recordSwipe(...)  // 直接修改字典
   ↓
UI 组件调用 getLearningRecord(for: wordId)  // 获取最新数据
```

---

## 5. 当前问题与优化方向

### 5.1 当前存在的问题

#### 🔴 P0 - 索引同步问题（已部分修复）

**问题描述**：
- Koloda 的 `currentCardIndex` 与队列索引不同步
- 滑动后索引可能超出队列范围，导致"卡片用完了"但队列还有卡片

**当前解决方案**：
- 滑动后延迟 0.3 秒重置索引
- `updateUIView` 中检查索引是否超出范围

**潜在问题**：
- 延迟重置可能导致短暂的不一致
- 频繁重置可能影响性能

**优化方向**：
- 考虑使用自定义的索引管理，而不是依赖 Koloda 的内部索引
- 或者，在滑动前就预测队列变化，提前重置索引

---

#### 🟡 P1 - 频繁重置导致的性能问题

**问题描述**：
- 每次滑动后都调用 `resetCurrentCardIndex()`，会清除所有卡片然后重新创建
- 可能导致卡片闪烁或性能问题

**优化方向**：
1. **增量更新**：只更新变化的卡片，而不是全部重置
2. **动画优化**：使用更平滑的过渡动画，减少视觉闪烁
3. **延迟策略**：只在必要时重置（例如索引超出范围），而不是每次滑动都重置

---

#### 🟡 P2 - 队列优化可能丢失卡片

**问题描述**：
- `optimizeQueue` 可能在某些边界情况下丢失卡片
- 缓冲区处理逻辑可能不够完善

**优化方向**：
1. **完善验证**：添加更严格的卡片数量验证
2. **优化算法**：改进队列优化算法，确保不丢失卡片
3. **调试工具**：添加更详细的调试日志，追踪卡片流转

---

### 5.2 架构优化方向

#### 🎯 方向1：索引管理重构

**当前问题**：
- Koloda 的索引管理与我们的队列管理不同步
- 需要频繁重置索引，影响性能和用户体验

**优化方案**：
```swift
// 方案A：自定义索引管理器
class QueueIndexManager {
    private var baseIndex: Int = 0  // 队列的基础索引
    private var kolodaOffset: Int = 0  // Koloda 索引的偏移量
    
    func mapKolodaIndexToQueueIndex(_ kolodaIndex: Int) -> Int {
        return kolodaIndex + baseIndex
    }
    
    func onSwipe() {
        baseIndex += 1  // 队列减少，基础索引增加
        // 不需要重置 Koloda 索引
    }
}

// 方案B：完全控制 Koloda 的索引
// 重写 Koloda 的索引管理逻辑，直接控制 currentCardIndex
```

**优势**：
- 避免频繁重置，提升性能
- 索引管理更清晰，减少同步问题

---

#### 🎯 方向2：数据流优化

**当前问题**：
- 数据更新和 UI 更新可能不同步
- 多个地方需要手动触发 UI 更新

**优化方案**：
```swift
// 使用 Combine 框架统一数据流
class StudyViewModel: ObservableObject {
    @Published var queue: [StudyCard] = [] {
        didSet {
            queueCount = queue.count
            visibleCards = Array(queue.prefix(3))
            // 自动触发 UI 更新
        }
    }
    
    // 使用 @Published 包装学习记录
    @Published var learningRecords: [Int: WordLearningRecord] = [:] {
        didSet {
            // 自动通知 UI 更新
        }
    }
}
```

**优势**：
- 数据流更清晰，减少手动同步
- 自动触发 UI 更新，减少遗漏

---

#### 🎯 方向3：性能优化

**当前问题**：
- 视图重用池可能不够高效
- 队列优化可能在大数据量时性能不佳

**优化方案**：
1. **视图重用优化**：
   - 增加重用池大小
   - 优化视图清理逻辑
   - 使用更高效的视图配置方法

2. **队列优化优化**：
   - 使用更高效的算法（例如哈希表查找）
   - 批量处理，减少遍历次数
   - 异步处理，不阻塞主线程

3. **内存优化**：
   - 及时释放不需要的卡片数据
   - 使用弱引用避免循环引用
   - 优化图片和视图的内存占用

---

#### 🎯 方向4：错误处理与鲁棒性

**当前问题**：
- 某些边界情况可能没有处理
- 错误恢复机制不够完善

**优化方案**：
1. **完善的错误处理**：
   ```swift
   func handleSwipe(...) {
       guard !queue.isEmpty else {
           // 处理队列为空的情况
           return
       }
       
       guard let record = learningRecords[wordId] else {
           // 处理记录不存在的情况
           return
       }
       
       // 正常处理...
   }
   ```

2. **状态恢复机制**：
   - 保存学习状态，支持恢复
   - 处理应用中断的情况
   - 数据校验和修复机制

3. **调试工具**：
   - 更详细的日志系统
   - 状态检查工具
   - 性能监控

---

### 5.3 用户体验优化

#### 🎯 方向1：滑动体验优化

**当前问题**：
- 滑动阈值可能不够敏感
- 重置动画可能不够流畅

**优化方案**：
1. **动态阈值**：根据设备类型和用户习惯调整滑动阈值
2. **动画优化**：使用更自然的动画曲线
3. **触觉反馈**：添加触觉反馈，提升交互体验

---

#### 🎯 方向2：数据展示优化

**当前问题**：
- 曝光次数显示可能不够直观
- 进度显示可能不够详细

**优化方案**：
1. **可视化改进**：
   - 使用进度条显示曝光进度
   - 添加动画效果
   - 更清晰的数据展示

2. **信息层次**：
   - 重要信息突出显示
   - 次要信息适当隐藏
   - 支持自定义显示选项

---

## 6. 总结

### 6.1 当前架构优势

✅ **数据一致性**：单源真相原则，避免数据不同步  
✅ **性能优化**：视图重用池，减少内存占用  
✅ **用户体验**：提前掌握机制，智能移除已掌握单词  
✅ **进度准确**：固定分母设计，准确反映学习进度  

### 6.2 需要改进的地方

⚠️ **索引同步**：需要频繁重置，可能影响性能  
⚠️ **错误处理**：某些边界情况处理不够完善  
⚠️ **性能优化**：大数据量时可能有性能瓶颈  
⚠️ **代码复杂度**：索引管理逻辑较复杂，可读性有待提升  

### 6.3 推荐优化优先级

1. **P0 - 索引同步优化**：重构索引管理机制，减少频繁重置
2. **P1 - 性能优化**：优化视图重用和队列处理
3. **P2 - 错误处理**：完善边界情况处理和错误恢复
4. **P3 - 用户体验**：优化动画和交互体验

---

## 7. 附录：关键代码位置

### 数据结构
- `Models/StudyCard.swift` - 学习卡片模型
- `Models/WordLearningRecord.swift` - 学习记录模型
- `ViewModels/StudyViewModel.swift` - 核心状态管理

### 滑卡逻辑
- `Views/KolodaCardsView.swift` - Koloda 集成和协调器
- `Views/WordCardUIView.swift` - 卡片视图实现
- `Koloda/DraggableCardView/DraggableCardView.swift` - 滑动动画和重置逻辑

### 数据服务
- `Services/WordRepository.swift` - 单词数据仓库
- `Services/ExposureEventStorage.swift` - 曝光事件存储

---

**文档版本**：v1.0  
**最后更新**：2025-01-XX  
**维护者**：开发团队

