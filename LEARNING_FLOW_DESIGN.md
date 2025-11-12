# 学习流程设计文档

## 📋 目录

1. [流程概览](#流程概览)
2. [状态管理](#状态管理)
3. [详细流程设计](#详细流程设计)
4. [界面设计](#界面设计)
5. [数据流设计](#数据流设计)
6. [异常处理](#异常处理)
7. [业界最佳实践参考](#业界最佳实践参考)

---

## 1. 流程概览

### 1.1 完整流程链路

```
词库选择 → 计划选择 → 算法分配 → 开始学习
   ↓         ↓          ↓          ↓
推荐词书  学习周期   单词顺序   卡片滑动
   ↓         ↓          ↓          ↓
当前状态  每日任务   曝光次数   学习记录
```

### 1.2 核心场景

#### 场景 A：首次选择词库
```
用户打开应用 → 词库页面（无当前词库） → 选择词库 → 计划选择 → 创建目标 → 生成任务 → 开始学习
```

#### 场景 B：已有词库，切换词库
```
用户打开应用 → 词库页面（显示当前词库） → 点击其他词库 → 放弃确认弹窗 → 确认放弃 → 计划选择 → 创建新目标 → 生成任务 → 开始学习
```

#### 场景 C：继续当前词库学习
```
用户打开应用 → 学习页面（显示今日任务） → 点击开始学习 → 直接进入卡片滑动
```

---

## 2. 状态管理

### 2.1 核心状态

```swift
// 应用级状态
class AppState: ObservableObject {
    @Published var currentGoal: LearningGoal?      // 当前学习目标
    @Published var currentTask: DailyTask?         // 今日任务
    @Published var selectedPack: VocabularyPack?   // 选中的词库（临时状态）
    @Published var selectedPlan: LearningPlan?    // 选中的计划（临时状态）
}

// 学习目标状态
enum GoalStatus {
    case inProgress    // 进行中
    case completed     // 已完成
    case abandoned     // 已放弃
    case paused        // 已暂停（可选）
}

// 任务状态
enum TaskStatus {
    case pending       // 待开始
    case inProgress    // 进行中
    case completed     // 已完成
}
```

### 2.2 状态流转图

```
[无目标] 
   ↓ (选择词库)
[选择词库] 
   ↓ (选择计划)
[选择计划]
   ↓ (创建目标)
[目标创建中]
   ↓ (生成任务)
[有目标 + 有任务]
   ↓ (开始学习)
[学习中]
   ↓ (完成任务)
[任务完成]
   ↓ (继续/切换)
[有目标 + 新任务] 或 [无目标]
```

---

## 3. 详细流程设计

### 3.1 词库选择流程

#### 3.1.1 词库页面布局

```
┌─────────────────────────────────┐
│  📚 我的词库                    │
├─────────────────────────────────┤
│                                 │
│  ┌───────────────────────────┐ │
│  │  当前词库卡片              │ │
│  │  ┌─────────────────────┐  │ │
│  │  │ 📖 CET-4 核心词汇   │  │ │
│  │  │ 第 3 天 / 共 10 天  │  │ │
│  │  │ 进度: 30% (900/3000)│  │ │
│  │  │ 今日任务: 300新+20复习│ │ │
│  │  └─────────────────────┘  │ │
│  └───────────────────────────┘ │
│                                 │
│  推荐词库                       │
│  ┌──────────┐  ┌──────────┐   │
│  │ CET-6    │  │ TOEFL    │   │
│  │ 5000词   │  │ 8000词   │   │
│  └──────────┘  └──────────┘   │
│                                 │
│  自定义词库                     │
│  ┌───────────────────────────┐ │
│  │  + 导入自定义词库          │ │
│  └───────────────────────────┘ │
└─────────────────────────────────┘
```

#### 3.1.2 当前词库卡片设计

**显示内容**：
- 词库名称和图标
- 学习进度（第X天/共Y天）
- 总体进度（已完成单词数/总单词数）
- 今日任务概览（新词数 + 复习词数）
- 预计学习时间
- 操作按钮：
  - "继续学习"（如果有未完成任务）
  - "查看详情"（查看完整计划）

**状态判断**：
```swift
if let goal = currentGoal, goal.status == .inProgress {
    // 显示当前词库卡片
    if let task = todayTask, task.status != .completed {
        // 显示"继续学习"按钮
    } else {
        // 显示"今日已完成"或"查看计划"
    }
} else {
    // 显示空状态占位符
    // "还没有开始学习，选择词库开始吧"
}
```

#### 3.1.3 推荐词库交互

**点击推荐词库时的逻辑**：

```swift
func onSelectPack(_ pack: VocabularyPack) {
    // 1. 检查是否有进行中的目标
    if let currentGoal = appState.currentGoal,
       currentGoal.status == .inProgress {
        
        // 2. 显示放弃确认弹窗
        showAbandonConfirmation = true
        pendingPack = pack  // 保存待选择的词库
        
    } else {
        // 3. 直接进入计划选择
        navigateToPlanSelection(pack: pack)
    }
}
```

### 3.2 放弃确认流程

#### 3.2.1 放弃确认弹窗设计

```
┌─────────────────────────────────┐
│          ⚠️ 放弃当前学习？      │
├─────────────────────────────────┤
│                                 │
│  您正在学习：                   │
│  📖 CET-4 核心词汇             │
│                                 │
│  当前进度：                     │
│  • 第 3 天 / 共 10 天          │
│  • 已完成 900 / 3000 词        │
│  • 今日任务未完成               │
│                                 │
│  放弃后将：                     │
│  • 停止当前学习计划             │
│  • 学习记录将保留               │
│  • 可以随时重新开始             │
│                                 │
│  ┌──────────┐  ┌──────────┐   │
│  │  取消    │  │  确认放弃 │   │
│  └──────────┘  └──────────┘   │
└─────────────────────────────────┘
```

#### 3.2.2 放弃逻辑

```swift
func abandonCurrentGoal() {
    guard let goal = appState.currentGoal else { return }
    
    // 1. 更新目标状态为已放弃
    goal.status = .abandoned
    goal.endDate = Date()
    
    // 2. 保存到数据库
    goalStorage.update(goal)
    
    // 3. 清理当前任务（如果有未完成的）
    if let task = appState.currentTask,
       task.status == .inProgress {
        task.status = .pending  // 或标记为暂停
        taskStorage.update(task)
    }
    
    // 4. 清除应用状态
    appState.currentGoal = nil
    appState.currentTask = nil
    
    // 5. 进入计划选择流程
    navigateToPlanSelection(pack: pendingPack)
}
```

### 3.3 计划选择流程

#### 3.3.1 计划选择页面布局

```
┌─────────────────────────────────┐
│  创建学习计划        [取消]      │
├─────────────────────────────────┤
│                                 │
│  已选择词库：                   │
│  📖 CET-4 核心词汇 (3000词)    │
│                                 │
│  ────────────────────────────  │
│                                 │
│  学习周期：                     │
│  ┌──────────┐  ┌──────────┐   │
│  │  7天     │  │  10天    │   │
│  │ 快速模式 │  │ 标准模式 │   │
│  └──────────┘  └──────────┘   │
│  ┌──────────┐  ┌──────────┐   │
│  │  14天    │  │  30天    │   │
│  │ 轻松模式 │  │ 长期模式 │   │
│  └──────────┘  └──────────┘   │
│                                 │
│  ────────────────────────────  │
│                                 │
│  系统自动计算：                 │
│  • 每日新词：300 词             │
│  • 每日复习：约 20 词           │
│  • 每日曝光：约 3100 次         │
│  • 预计时间：约 155 分钟        │
│                                 │
│  ────────────────────────────  │
│                                 │
│  开始日期：2025-01-15           │
│  结束日期：2025-01-25           │
│                                 │
│  ┌───────────────────────────┐ │
│  │     创建学习计划           │ │
│  └───────────────────────────┘ │
└─────────────────────────────────┘
```

#### 3.3.2 计划类型设计

```swift
enum LearningPlan: String, CaseIterable {
    case fast = "fast"        // 快速模式：7天
    case standard = "standard" // 标准模式：10天
    case relaxed = "relaxed"   // 轻松模式：14天
    case longTerm = "longTerm" // 长期模式：30天
    
    var durationDays: Int {
        switch self {
        case .fast: return 7
        case .standard: return 10
        case .relaxed: return 14
        case .longTerm: return 30
        }
    }
    
    var displayName: String {
        switch self {
        case .fast: return "快速模式"
        case .standard: return "标准模式"
        case .relaxed: return "轻松模式"
        case .longTerm: return "长期模式"
        }
    }
    
    var description: String {
        switch self {
        case .fast: return "每天约 430 词，适合时间充裕的用户"
        case .standard: return "每天约 300 词，推荐选择"
        case .relaxed: return "每天约 215 词，轻松完成"
        case .longTerm: return "每天约 100 词，长期坚持"
        }
    }
}
```

#### 3.3.3 计划计算逻辑

```swift
func calculatePlan(pack: VocabularyPack, plan: LearningPlan) -> PlanCalculation {
    let totalWords = pack.totalWords
    let durationDays = plan.durationDays
    
    // 计算每日新词数
    let dailyNewWords = totalWords / durationDays
    
    // 计算每日复习词数（基于遗忘曲线）
    // 复习词 = 前几天的单词需要复习的数量
    let dailyReviewWords = calculateReviewWords(
        currentDay: 1,
        previousDays: [],
        reviewStrategy: .spacedRepetition
    )
    
    // 计算每日曝光次数
    // 新词：10次曝光/词
    // 复习词：5次曝光/词（根据掌握程度调整）
    let dailyNewExposures = dailyNewWords * 10
    let dailyReviewExposures = dailyReviewWords * 5
    let totalDailyExposures = dailyNewExposures + dailyReviewExposures
    
    // 计算预计时间（假设每次曝光3秒）
    let estimatedMinutes = Int(Double(totalDailyExposures) * 3.0 / 60.0)
    
    return PlanCalculation(
        dailyNewWords: dailyNewWords,
        dailyReviewWords: dailyReviewWords,
        dailyExposures: totalDailyExposures,
        estimatedMinutes: estimatedMinutes,
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: durationDays, to: Date())!
    )
}
```

### 3.4 算法分配流程

#### 3.4.1 任务生成时机

```swift
func createGoal(pack: VocabularyPack, plan: LearningPlan) {
    // 1. 创建学习目标
    let goal = LearningGoal(
        id: generateId(),
        packId: pack.packId,
        packName: pack.name,
        totalWords: pack.totalWords,
        durationDays: plan.durationDays,
        dailyNewWords: calculation.dailyNewWords,
        startDate: calculation.startDate,
        endDate: calculation.endDate,
        status: .inProgress,
        currentDay: 1,
        completedWords: 0,
        completedExposures: 0
    )
    
    // 2. 保存目标
    goalStorage.insert(goal)
    
    // 3. 生成所有任务（异步，不阻塞UI）
    Task {
        await generateAllTasks(for: goal, plan: plan)
    }
    
    // 4. 立即生成今日任务（同步，确保可以立即学习）
    let todayTask = generateTodayTask(for: goal, day: 1)
    taskStorage.insert(todayTask)
    
    // 5. 更新应用状态
    appState.currentGoal = goal
    appState.currentTask = todayTask
    
    // 6. 导航到学习页面
    navigateToLearning()
}
```

#### 3.4.2 单词分配算法

```swift
func generateAllTasks(for goal: LearningGoal, plan: LearningPlan) async {
    let totalWords = goal.totalWords
    let durationDays = goal.durationDays
    let dailyNewWords = goal.dailyNewWords
    
    // 1. 获取词库所有单词
    let allWords = try await wordRepository.fetchWordsByIds(pack.wordIds)
    
    // 2. 算法分配单词顺序（目前是随机，后续可优化）
    let shuffledWords = allWords.shuffled()
    
    // 3. 按天分配新词
    for day in 1...durationDays {
        let startIndex = (day - 1) * dailyNewWords
        let endIndex = min(startIndex + dailyNewWords, shuffledWords.count)
        let newWords = Array(shuffledWords[startIndex..<endIndex])
        
        // 4. 计算复习词（基于遗忘曲线）
        let reviewWords = calculateReviewWords(
            currentDay: day,
            previousDays: Array(1..<day),
            previousNewWords: getPreviousNewWords(days: Array(1..<day)),
            reviewStrategy: .spacedRepetition
        )
        
        // 5. 计算曝光次数
        let newExposures = newWords.count * 10
        let reviewExposures = reviewWords.count * 5
        let totalExposures = newExposures + reviewExposures
        
        // 6. 创建任务
        let task = DailyTask(
            id: generateTaskId(goalId: goal.id, day: day),
            goalId: goal.id,
            day: day,
            date: Calendar.current.date(byAdding: .day, value: day - 1, to: goal.startDate)!,
            newWords: newWords.map { $0.id },
            reviewWords: reviewWords.map { $0.id },
            totalExposures: totalExposures,
            completedExposures: 0,
            status: day == 1 ? .pending : .pending,
            startTime: nil,
            endTime: nil
        )
        
        // 7. 保存任务
        taskStorage.insert(task)
    }
}
```

#### 3.4.3 复习词计算算法

```swift
func calculateReviewWords(
    currentDay: Int,
    previousDays: [Int],
    previousNewWords: [Int: [Word]],
    reviewStrategy: ReviewStrategy
) -> [Word] {
    var reviewWords: [Word] = []
    
    switch reviewStrategy {
    case .spacedRepetition:
        // 间隔重复算法
        // 第1天：无复习
        // 第2天：复习第1天的新词（20%）
        // 第3天：复习第1-2天的新词（30%）
        // 第4天：复习第1-3天的新词（40%）
        // ...
        
        for day in previousDays {
            let daysAgo = currentDay - day
            let reviewRatio = getReviewRatio(daysAgo: daysAgo)
            
            if let words = previousNewWords[day] {
                let reviewCount = Int(Double(words.count) * reviewRatio)
                reviewWords.append(contentsOf: words.prefix(reviewCount))
            }
        }
        
    case .adaptive:
        // 自适应算法（基于学习记录）
        // 根据用户的学习记录，优先复习掌握不好的单词
        for day in previousDays {
            if let words = previousNewWords[day] {
                let wordsToReview = words.filter { word in
                    let record = getLearningRecord(for: word.id)
                    return record?.familiarityScore ?? 0 < 70  // 掌握度低于70%需要复习
                }
                reviewWords.append(contentsOf: wordsToReview)
            }
        }
    }
    
    // 限制每日复习词数量（避免过多）
    let maxReviewWords = min(reviewWords.count, 50)
    return Array(reviewWords.shuffled().prefix(maxReviewWords))
}

func getReviewRatio(daysAgo: Int) -> Double {
    // 基于遗忘曲线的复习比例
    switch daysAgo {
    case 1: return 0.2  // 20%
    case 2: return 0.3  // 30%
    case 3: return 0.4  // 40%
    case 4...7: return 0.5  // 50%
    default: return 0.3  // 30%
    }
}
```

### 3.5 开始学习流程

#### 3.5.1 学习入口检查

```swift
func checkLearningEntry() -> LearningEntryState {
    // 1. 检查是否有进行中的目标
    guard let goal = appState.currentGoal,
          goal.status == .inProgress else {
        return .noGoal  // 需要先选择词库
    }
    
    // 2. 检查今日任务
    guard let task = appState.currentTask else {
        return .noTask  // 需要生成任务
    }
    
    // 3. 检查任务状态
    switch task.status {
    case .completed:
        return .taskCompleted  // 今日已完成
    case .inProgress:
        return .canContinue  // 可以继续学习
    case .pending:
        return .canStart  // 可以开始学习
    }
}
```

#### 3.5.2 学习页面状态

```
┌─────────────────────────────────┐
│  今日背词                        │
├─────────────────────────────────┤
│                                 │
│        🧠                        │
│                                 │
│     今日任务                     │
│                                 │
│  新词：300 词                   │
│  复习：20 词                    │
│  总计：3100 次曝光              │
│  预计：155 分钟                 │
│                                 │
│  进度：0 / 3100 (0%)           │
│                                 │
│  ┌───────────────────────────┐ │
│  │     开始学习               │ │
│  └───────────────────────────┘ │
│                                 │
│  当前词库：CET-4 核心词汇       │
│  第 3 天 / 共 10 天            │
│                                 │
└─────────────────────────────────┘
```

---

## 4. 界面设计

### 4.1 词库页面（BookLibraryView）

#### 4.1.1 当前词库卡片组件

```swift
struct CurrentPackCard: View {
    let goal: LearningGoal
    let task: DailyTask?
    let onSelectPack: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.blue)
                Text(goal.packName)
                    .font(.headline)
                Spacer()
                Button("切换") {
                    onSelectPack()
                }
            }
            
            // 进度信息
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("第 \(goal.currentDay) 天 / 共 \(goal.durationDays) 天")
                    Spacer()
                    Text("\(Int(goal.progress * 100))%")
                }
                
                ProgressView(value: goal.progress)
                
                Text("已完成 \(goal.completedWords) / \(goal.totalWords) 词")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 今日任务
            if let task = task {
                HStack {
                    Label("\(task.newWordsCount) 新词", systemImage: "sparkles")
                    Label("\(task.reviewWordsCount) 复习", systemImage: "arrow.clockwise")
                    Spacer()
                    if task.status == .completed {
                        Label("已完成", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .font(.subheadline)
            }
            
            // 操作按钮
            if let task = task, task.status != .completed {
                Button("继续学习") {
                    navigateToLearning()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
```

#### 4.1.2 推荐词库卡片组件

```swift
struct RecommendedPackCard: View {
    let pack: VocabularyPack
    let isCurrentPack: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: pack.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    Spacer()
                    if isCurrentPack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Text(pack.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(pack.totalWords) 词")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrentPack ? Color.green : Color.clear, lineWidth: 2)
            )
        }
    }
}
```

### 4.2 放弃确认弹窗（AbandonConfirmationView）

```swift
struct AbandonConfirmationView: View {
    let goal: LearningGoal
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 图标
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            // 标题
            Text("放弃当前学习？")
                .font(.title2)
                .fontWeight(.bold)
            
            // 当前学习信息
            VStack(alignment: .leading, spacing: 12) {
                Text("您正在学习：")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "book.fill")
                    Text(goal.packName)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("第 \(goal.currentDay) 天 / 共 \(goal.durationDays) 天", systemImage: "calendar")
                    Label("已完成 \(goal.completedWords) / \(goal.totalWords) 词", systemImage: "checkmark.circle")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // 提示信息
            VStack(alignment: .leading, spacing: 8) {
                Text("放弃后将：")
                    .font(.headline)
                Text("• 停止当前学习计划")
                Text("• 学习记录将保留")
                Text("• 可以随时重新开始")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 按钮
            HStack(spacing: 12) {
                Button("取消", action: onCancel)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                
                Button("确认放弃", action: onConfirm)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}
```

### 4.3 计划选择页面（PlanSelectionView）

```swift
struct PlanSelectionView: View {
    let pack: VocabularyPack
    @State private var selectedPlan: LearningPlan = .standard
    @State private var showConfirmation = false
    @Environment(\.dismiss) var dismiss
    
    var calculation: PlanCalculation {
        calculatePlan(pack: pack, plan: selectedPlan)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 已选择词库
                    selectedPackCard
                    
                    // 计划选择
                    planSelectionSection
                    
                    Divider()
                    
                    // 系统计算
                    calculationSection
                    
                    Divider()
                    
                    // 日期范围
                    dateRangeSection
                    
                    // 创建按钮
                    createButton
                }
                .padding()
            }
            .navigationTitle("创建学习计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .alert("确认创建？", isPresented: $showConfirmation) {
                Button("取消", role: .cancel) { }
                Button("确认创建") {
                    createGoal()
                }
            } message: {
                Text("将创建 \(selectedPlan.durationDays) 天学习计划，每天约 \(calculation.estimatedMinutes) 分钟")
            }
        }
    }
}
```

---

## 5. 数据流设计

### 5.1 数据流图

```
用户操作
   ↓
UI 事件
   ↓
ViewModel 处理
   ↓
Service 层（数据库/算法）
   ↓
数据更新
   ↓
@Published 属性变化
   ↓
UI 自动更新
```

### 5.2 关键数据流

#### 5.2.1 选择词库流程

```
用户点击词库
   ↓
BookLibraryView.onSelectPack()
   ↓
检查 currentGoal
   ↓
有进行中的目标？
   ├─ 是 → 显示放弃确认弹窗
   │        ↓
   │    用户确认放弃
   │        ↓
   │    GoalService.abandonGoal()
   │        ↓
   │    更新数据库
   │        ↓
   │    清除 AppState
   └─ 否 → 直接进入计划选择
            ↓
        保存 selectedPack
            ↓
        导航到 PlanSelectionView
```

#### 5.2.2 创建目标流程

```
用户选择计划
   ↓
PlanSelectionView.createGoal()
   ↓
GoalService.createGoal(pack, plan)
   ↓
1. 创建 LearningGoal
   ↓
2. 保存到数据库
   ↓
3. TaskScheduler.generateAllTasks(goal)
   ↓
4. 生成所有任务（异步）
   ↓
5. 立即生成今日任务（同步）
   ↓
6. 更新 AppState
   ├─ currentGoal = goal
   └─ currentTask = todayTask
   ↓
7. 导航到学习页面
```

#### 5.2.3 开始学习流程

```
用户点击"开始学习"
   ↓
LearningHomeView.startLearning()
   ↓
检查 currentTask
   ↓
StudyViewModel.setupStudyQueue(task)
   ↓
1. 获取任务中的单词
   ↓
2. 创建学习记录
   ↓
3. 生成卡片队列
   ↓
4. 优化队列顺序
   ↓
5. 更新 visibleCards
   ↓
6. 显示 KolodaCardsView
```

### 5.3 状态同步机制

```swift
// AppState 作为单一数据源
class AppState: ObservableObject {
    @Published var currentGoal: LearningGoal?
    @Published var currentTask: DailyTask?
    
    // 当目标变化时，自动更新任务
    func updateGoal(_ goal: LearningGoal?) {
        currentGoal = goal
        if let goal = goal {
            loadTodayTask(for: goal)
        } else {
            currentTask = nil
        }
    }
}

// ViewModel 观察 AppState
class StudyViewModel: ObservableObject {
    @ObservedObject var appState: AppState
    
    // 当 AppState 变化时，自动更新
    var currentGoal: LearningGoal? {
        appState.currentGoal
    }
    
    var currentTask: DailyTask? {
        appState.currentTask
    }
}
```

---

## 6. 异常处理

### 6.1 边界情况处理

#### 6.1.1 无词库情况

```swift
if availablePacks.isEmpty {
    // 显示空状态
    EmptyStateView(
        icon: "book.closed",
        title: "还没有词库",
        message: "请先导入词库",
        action: {
            showImportView = true
        }
    )
}
```

#### 6.1.2 任务生成失败

```swift
func generateAllTasks(for goal: LearningGoal) async throws {
    do {
        // 生成任务
        let tasks = try await taskScheduler.generateTasks(for: goal)
        
        // 保存任务
        for task in tasks {
            try taskStorage.insert(task)
        }
    } catch {
        // 记录错误
        logger.error("Failed to generate tasks: \(error)")
        
        // 显示错误提示
        await MainActor.run {
            showErrorAlert = true
            errorMessage = "任务生成失败，请重试"
        }
        
        throw error
    }
}
```

#### 6.1.3 数据不一致

```swift
func validateGoalAndTask() -> ValidationResult {
    guard let goal = currentGoal else {
        return .noGoal
    }
    
    guard let task = currentTask else {
        return .noTask
    }
    
    // 检查任务是否属于当前目标
    if task.goalId != goal.id {
        return .taskMismatch
    }
    
    // 检查任务日期是否匹配
    let today = Calendar.current.startOfDay(for: Date())
    let taskDate = Calendar.current.startOfDay(for: task.date)
    if !Calendar.current.isDate(today, inSameDayAs: taskDate) {
        return .dateMismatch
    }
    
    return .valid
}
```

### 6.2 错误恢复机制

```swift
// 自动修复数据不一致
func autoFixDataInconsistency() {
    // 1. 检查目标状态
    if let goal = currentGoal,
       goal.status == .inProgress {
        
        // 2. 检查是否有今日任务
        if currentTask == nil {
            // 尝试生成今日任务
            if let task = try? taskScheduler.generateTodayTask(for: goal) {
                currentTask = task
            }
        }
        
        // 3. 检查任务状态
        if let task = currentTask,
           task.status == .inProgress,
           task.startTime == nil {
            // 修复任务状态
            task.status = .pending
            taskStorage.update(task)
        }
    }
}
```

---

## 7. 业界最佳实践参考

### 7.1 墨墨背单词

**参考点**：
- ✅ 词库选择 → 计划选择 → 开始学习的清晰流程
- ✅ 显示当前学习进度和今日任务
- ✅ 切换词库时的放弃确认
- ✅ 系统自动计算每日任务

**改进点**：
- 更灵活的复习算法
- 更清晰的状态提示

### 7.2 Anki

**参考点**：
- ✅ 间隔重复算法
- ✅ 自适应复习策略
- ✅ 学习记录保留

**改进点**：
- 更简单的操作流程
- 更直观的进度展示

### 7.3 百词斩

**参考点**：
- ✅ 计划选择界面友好
- ✅ 预计时间计算准确
- ✅ 学习入口清晰

**改进点**：
- 更灵活的算法分配
- 更智能的复习策略

### 7.4 我们的设计亮点

1. **清晰的状态管理**：单一数据源，状态同步可靠
2. **友好的用户交互**：放弃确认、进度展示、预计时间
3. **灵活的算法设计**：支持多种复习策略，易于扩展
4. **完善的异常处理**：边界情况处理，错误恢复机制
5. **流畅的流程衔接**：每个环节都有明确的反馈

---

## 8. 实现优先级

### P0（必须实现）
1. ✅ 词库选择页面显示当前词库
2. ✅ 点击其他词库显示放弃确认
3. ✅ 计划选择页面
4. ✅ 创建目标和生成任务
5. ✅ 开始学习入口

### P1（应该实现）
1. ⭐ 复习算法优化
2. ⭐ 预计时间计算
3. ⭐ 进度展示优化
4. ⭐ 数据验证和修复

### P2（可以优化）
1. ⭐ 自定义计划选项
2. ⭐ 学习记录分析
3. ⭐ 智能推荐算法
4. ⭐ 离线支持

---

**文档版本**：v1.0  
**最后更新**：2025-01-XX  
**维护者**：开发团队

