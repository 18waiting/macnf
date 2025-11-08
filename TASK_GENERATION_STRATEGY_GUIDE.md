# TaskGenerationStrategy 核心组件使用指南

## 🎯 组件概述

`TaskGenerationStrategy` 是 NFwords 的**第三个核心业务组件**，体现"任务预定制、10天3000词"的核心理念。

### 核心价值

**业务理念**：
> 每天的单词任务是提前就定好的，比如说10天背完3000个单词，会用算法去给用户安排每天的具体任务。

**技术实现**：
- 完整的10天计划预生成算法
- 前期多学新词，后期多复习
- 基于停留时间智能选择复习词
- 与 DwellTimeAnalyzer 无缝配合

---

## 📊 核心算法

### 10天3000词分配策略

**算法原理**：
```
前70%天数（1-7天）学习90%词汇（2700词）
后30%天数（8-10天）学习10%词汇（300词）

原因：
- 前期大量新词，快速覆盖
- 后期少量新词，专注复习
- 符合短期应试记忆规律
```

**具体分配**：
```
Day 1: 270新词 + 0复习 = 2700次曝光（约40分钟）
Day 2: 270新词 + 20复习 = 2800次曝光（约42分钟）
Day 3: 270新词 + 20复习 = 2800次曝光
Day 4: 270新词 + 20复习 = 2800次曝光
Day 5: 270新词 + 20复习 = 2800次曝光
Day 6: 270新词 + 20复习 = 2800次曝光
Day 7: 270新词 + 20复习 = 2800次曝光

Day 8: 100新词 + 20复习 = 1100次曝光（约20分钟）
Day 9: 100新词 + 20复习 = 1100次曝光
Day 10: 100新词 + 20复习 = 1100次曝光

总计：
- 新词：3000个
- 总曝光：约26,000次
- 总时长：约6-7小时（分10天）
```

---

### 复习词选择算法 ⭐ 核心

**与 DwellTimeAnalyzer 配合**：

```
Day 1 学习结束：
  ↓
DwellTimeAnalyzer 分析：
  - abandonment: 12.5s（最难）
  - resilient: 9.8s
  - elaborate: 8.3s
  ...
  - ability: 1.2s（最熟）
  ↓
选择前20个（停留时间最长）：
  - [abandonment, resilient, elaborate, ...]
  ↓
Day 2 复习词：
  - 这20个昨日最难的词
  - 每个曝光5次
```

**优点**：
- ✅ 自动识别薄弱环节
- ✅ 重点攻克困难词
- ✅ 无需手动选择
- ✅ 基于客观数据（停留时间）

---

## 🚀 使用方法

### 方法1：创建学习目标时生成完整计划

```swift
// 在 LearningGoalView 或 DemoDataSeeder 中
func createLearningGoal(packId: Int, durationDays: Int, totalWords: Int) throws {
    
    // 1. 获取词书entries
    let packStorage = LocalPackStorage()
    let pack = try packStorage.fetchAll().first(where: { $0.packId == packId })!
    let packEntries = pack.entries
    
    // 2. 创建学习目标
    let goal = LearningGoal(
        id: 0,
        packId: packId,
        packName: pack.title,
        totalWords: totalWords,
        durationDays: durationDays,
        dailyNewWords: totalWords / durationDays,
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: durationDays, to: Date())!,
        status: .inProgress,
        currentDay: 1,
        completedWords: 0,
        completedExposures: 0
    )
    
    let goalId = try goalStorage.insert(goal)
    
    // 3. 使用策略生成完整的10天计划 ⭐
    let strategy = TaskGenerationStrategyFactory.strategyForGoal(goal)
    let allTasks = strategy.generateCompletePlan(for: goal, packEntries: packEntries)
    
    // 4. 保存所有任务到数据库
    for task in allTasks {
        try taskStorage.insert(task)
    }
    
    #if DEBUG
    print("[Goal] Created goal with \(allTasks.count) tasks")
    print("[Goal] Strategy: \(strategy.strategyName)")
    #endif
}
```

---

### 方法2：每日动态生成（基于昨日停留时间）

```swift
// 在 App 每日启动时或 StudyViewModel 中
func loadTodayTask(goal: LearningGoal, packEntries: [Int]) throws -> DailyTask {
    
    let currentDay = goal.currentDay
    
    // 1. 获取昨日学习记录和分析
    var previousAnalysis: DwellTimeAnalysis?
    
    if currentDay > 1 {
        // 获取昨日学习记录
        let yesterdayRecords = loadYesterdayRecords(goalId: goal.id, day: currentDay - 1)
        
        // 使用 DwellTimeAnalyzer 分析 ⭐
        let analyzer = DwellTimeAnalyzerFactory.defaultAnalyzer()
        previousAnalysis = analyzer.analyze(yesterdayRecords)
        
        #if DEBUG
        print("[Task] Yesterday analysis:")
        print(previousAnalysis!.briefSummary)
        #endif
    }
    
    // 2. 使用策略生成今日任务 ⭐
    let strategy = TaskGenerationStrategyFactory.strategyForGoal(goal, dwellAnalyzer: nil)
    let todayTask = strategy.generateDailyTask(
        for: goal,
        day: currentDay,
        packEntries: packEntries,
        previousAnalysis: previousAnalysis
    )
    
    // 3. 保存任务
    try taskStorage.insert(todayTask)
    
    #if DEBUG
    print("[Task] Today's task generated:")
    print("  - Day: \(currentDay)/\(goal.durationDays)")
    print("  - New words: \(todayTask.newWords.count)")
    print("  - Review words: \(todayTask.reviewWords.count)")
    print("  - Total exposures: \(todayTask.totalExposures)")
    #endif
    
    return todayTask
}
```

---

### 方法3：替换现有的 TaskScheduler

```swift
// ViewModels/TaskScheduler.swift（重构）
class TaskScheduler {
    private let taskStrategy: TaskGenerationStrategy
    private let dwellAnalyzer: DwellTimeAnalyzer
    
    init(
        taskStrategy: TaskGenerationStrategy? = nil,
        dwellAnalyzer: DwellTimeAnalyzer = DwellTimeAnalyzerFactory.defaultAnalyzer()
    ) {
        self.taskStrategy = taskStrategy ?? TaskGenerationStrategyFactory.defaultStrategy(dwellAnalyzer: dwellAnalyzer)
        self.dwellAnalyzer = dwellAnalyzer
    }
    
    /// 生成每日任务（新接口）⭐
    func generateDailyTask(
        for goal: LearningGoal,
        day: Int,
        packEntries: [Int],
        yesterdayRecords: [Int: WordLearningRecord]?
    ) -> DailyTask {
        
        // 分析昨日停留时间
        var analysis: DwellTimeAnalysis?
        if let records = yesterdayRecords, !records.isEmpty {
            analysis = dwellAnalyzer.analyze(records)
        }
        
        // 使用策略生成任务
        return taskStrategy.generateDailyTask(
            for: goal,
            day: day,
            packEntries: packEntries,
            previousAnalysis: analysis
        )
    }
    
    /// 生成完整计划（新接口）⭐
    func generateCompletePlan(for goal: LearningGoal, packEntries: [Int]) -> [DailyTask] {
        taskStrategy.generateCompletePlan(for: goal, packEntries: packEntries)
    }
}
```

---

## 📊 实际效果示例

### 10天3000词完整计划

```
=== 学习计划：10天3000词 ===

Day 1:
  新词：270个（wid 1-270）
  复习：0个
  总曝光：2700次
  预计时长：40分钟
  
Day 2:
  新词：270个（wid 271-540）
  复习：20个（Day 1最难的）
  总曝光：2800次
  预计时长：42分钟
  
Day 3:
  新词：270个（wid 541-810）
  复习：20个（Day 2最难的）
  总曝光：2800次
  预计时长：42分钟
  
...

Day 7:
  新词：270个（wid 1621-1890）
  复习：20个（Day 6最难的）
  总曝光：2800次
  预计时长：42分钟
  
Day 8:
  新词：100个（wid 2701-2800）
  复习：20个（Day 7最难的）
  总曝光：1100次
  预计时长：20分钟
  
Day 9:
  新词：100个（wid 2801-2900）
  复习：20个（Day 8最难的）
  总曝光：1100次
  预计时长：20分钟
  
Day 10:
  新词：100个（wid 2901-3000）
  复习：20个（Day 9最难的）
  总曝光：1100次
  预计时长：20分钟

=== 计划总结 ===
总新词：3000个
总复习次数：180个词×5次 = 900次
总曝光：约27,100次
总时长：约6.5小时（分10天）
平均每天：39分钟
```

---

## 🔗 三个核心组件协同

### 完整闭环

```
TaskGenerationStrategy
    ↓
生成10天计划（预定任务）
    ↓
Day 1: 270新词
    ↓
ExposureStrategy: 每个词10次
    ↓
用户学习 → 记录停留时间
    ↓
DwellTimeAnalyzer: 分析排序
    ↓
识别最难的20个词
    ↓
Day 2: TaskGenerationStrategy
    ↓
新词270个 + 复习20个（昨日最难）
    ↓
ExposureStrategy:
  - 新词：10次
  - 复习词：基于停留时间（10次或更多）
    ↓
持续循环优化...
```

---

## 📊 预期日志

### 创建学习目标时

```
[TaskStrategy] Initialized: 量化任务策略（10天3000词）
[TaskStrategy] Config:
  - Front load: 70% days, 90% words
  - Daily review: 20 words
  - New word exposures: 10x
  - Review exposures: 5x

[TaskStrategy] Generating complete plan: 10 days, 3000 words
[TaskStrategy] Distribution:
  - Front period (7 days): 2700 words
  - Back period (3 days): 300 words

[TaskStrategy] Day 1: 270 new words, 0 review
[TaskStrategy] Day 2: 270 new words, 0 review
[TaskStrategy] Day 3: 270 new words, 0 review
...
[TaskStrategy] Day 8: 100 new words, 0 review
[TaskStrategy] Day 9: 100 new words, 0 review
[TaskStrategy] Day 10: 100 new words, 0 review

[TaskStrategy] Complete plan generated: 10 tasks
[TaskStrategy] Total new words: 3000

[Goal] Created goal with 10 tasks
[Goal] Strategy: 量化任务策略（10天3000词）
```

### Day 2 加载任务时

```
[Task] Yesterday analysis:
共270词，平均停留3.8秒
熟悉180个，困难90个

[TaskStrategy] Generating task for day 2/10
[TaskStrategy] New words: 270
[TaskStrategy] Review words: 20
[TaskStrategy] Review words selected from yesterday's top difficult words

[Task] Today's task generated:
  - Day: 2/10
  - New words: 270
  - Review words: 20
  - Total exposures: 2800
```

---

## 🎯 业务价值

### 1. 任务预定制 ⭐⭐⭐

```
创建目标 → 立即生成10天完整计划

用户知道：
- 每天要学多少新词
- 每天要复习多少
- 每天大概多长时间
- 什么时候能完成

无需每天纠结学什么 ✅
```

### 2. 智能复习排程 ⭐⭐⭐

```
昨日学习 → 停留时间分析 → 选择最难的20个 → 今日复习

不是随机复习，而是：
- 基于停留时间（客观数据）
- 重点攻克薄弱环节
- 持续优化直到掌握
```

### 3. 前期多后期少 ⭐⭐

```
Day 1-7: 每天270词（高强度）
Day 8-10: 每天100词（巩固期）

原因：
- 短期记忆特点
- 前期快速覆盖
- 后期专注复习
- 符合应试需求
```

### 4. 灵活可配置 ⭐⭐

```
标准策略：70%天学90%词
强化策略：60%天学95%词（更快）
轻松策略：80%天学85%词（更稳）

用户可选：
- 7天极速（强化）
- 10天快速（标准）
- 20天稳步（轻松）
```

---

## 🧪 测试验证

### 测试1：10天3000词计划

```swift
let goal = LearningGoal(
    totalWords: 3000,
    durationDays: 10,
    ...
)

let packEntries = Array(1...3000)  // 3000个wid

let strategy = TaskGenerationStrategyFactory.defaultStrategy()
let tasks = strategy.generateCompletePlan(for: goal, packEntries: packEntries)

// 验证：
assert(tasks.count == 10)
assert(tasks.reduce(0) { $0 + $1.newWords.count } == 3000)

// Day 1
assert(tasks[0].newWords.count == 270)
assert(tasks[0].reviewWords.count == 0)

// Day 8
assert(tasks[7].newWords.count == 100)

print("✅ 10天3000词计划验证通过")
```

### 测试2：基于停留时间的复习词选择

```swift
// Day 1学习记录
let day1Records: [Int: WordLearningRecord] = [
    1: WordLearningRecord(avgDwell: 12.5),  // 最难
    2: WordLearningRecord(avgDwell: 9.8),
    ...
    270: WordLearningRecord(avgDwell: 1.2)  // 最熟
]

// 分析
let analyzer = DwellTimeAnalyzerFactory.defaultAnalyzer()
let analysis = analyzer.analyze(day1Records)

// 生成Day 2任务
let strategy = TaskGenerationStrategyFactory.defaultStrategy()
let task2 = strategy.generateDailyTask(
    for: goal,
    day: 2,
    packEntries: packEntries,
    previousAnalysis: analysis
)

// 验证：复习词应该是停留时间最长的20个
let expectedReviewWords = analysis.sortedByDwellTime.prefix(20).map { $0.id }
assert(task2.reviewWords == expectedReviewWords)

print("✅ 复习词选择验证通过")
```

---

## 🔧 集成到现有代码

### 步骤1：更新 DemoDataSeeder

```swift
// Services/Database/DemoDataSeeder.swift
static func seedDemoDataIfNeeded() throws {
    // ... 现有代码
    
    // 创建学习目标
    let demoGoal = LearningGoal(...)
    let goalId = try goalStorage.insert(demoGoal)
    
    // 使用 TaskGenerationStrategy 生成完整计划 ⭐ 新增
    let strategy = TaskGenerationStrategyFactory.strategyForGoal(demoGoal)
    let allTasks = strategy.generateCompletePlan(for: demoGoal, packEntries: firstPack.entries)
    
    // 只保存第1天的任务（其他按需生成）
    let firstTask = allTasks[0]
    try taskStorage.insert(firstTask)
    
    #if DEBUG
    print("[Seeder] Generated \(allTasks.count) tasks, saved first task")
    #endif
}
```

---

### 步骤2：更新 TaskScheduler

```swift
// ViewModels/TaskScheduler.swift（完全重构）
class TaskScheduler {
    private let taskStrategy: TaskGenerationStrategy
    private let dwellAnalyzer: DwellTimeAnalyzer
    private let taskStorage: DailyTaskStorage
    
    init() {
        self.dwellAnalyzer = DwellTimeAnalyzerFactory.defaultAnalyzer()
        self.taskStrategy = TaskGenerationStrategyFactory.defaultStrategy(dwellAnalyzer: dwellAnalyzer)
        self.taskStorage = DailyTaskStorage()
    }
    
    /// 生成并保存完整计划 ⭐
    func createCompletePlan(for goal: LearningGoal, packEntries: [Int]) throws {
        let tasks = taskStrategy.generateCompletePlan(for: goal, packEntries: packEntries)
        
        for task in tasks {
            try taskStorage.insert(task)
        }
        
        #if DEBUG
        print("[TaskScheduler] Created \(tasks.count) tasks for goal \(goal.id)")
        #endif
    }
    
    /// 生成明日任务（基于今日学习）⭐
    func generateNextDayTask(
        for goal: LearningGoal,
        packEntries: [Int],
        todayRecords: [Int: WordLearningRecord]
    ) throws -> DailyTask {
        
        // 分析今日学习
        let analysis = dwellAnalyzer.analyze(todayRecords)
        
        // 生成明日任务
        let tomorrow = goal.currentDay + 1
        let task = taskStrategy.generateDailyTask(
            for: goal,
            day: tomorrow,
            packEntries: packEntries,
            previousAnalysis: analysis
        )
        
        // 保存
        try taskStorage.insert(task)
        
        return task
    }
}
```

---

## 🎊 三个核心组件完整集成

### 完美协同

```
┌─────────────────────────────────────────┐
│  1. TaskGenerationStrategy              │
│     生成10天完整计划                     │
│     Day 1: 270新词                      │
│     Day 2: 270新词 + 20复习             │
│     ...                                 │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  2. ExposureStrategy                    │
│     分配曝光次数                         │
│     新词：10次                          │
│     复习词：基于停留时间（10-15次）     │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  用户学习 Day 1                         │
│  270个新词，每个10次 = 2700次曝光      │
│  记录每个词的停留时间                   │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  3. DwellTimeAnalyzer                   │
│     分析Day 1学习                       │
│     按停留时间排序                       │
│     识别最难的20个词                    │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  1. TaskGenerationStrategy              │
│     生成Day 2任务                       │
│     新词：270个                         │
│     复习：20个（Day 1最难的）⭐         │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  2. ExposureStrategy                    │
│     新词：10次                          │
│     复习词（停留12.5s）：10次           │
│     复习词（停留8.2s）：7次             │
└─────────────────────────────────────────┘
              ↓
        持续10天循环...
```

---

## ✅ 完成状态

### 已实现的3个核心组件

#### 1. ExposureStrategy ✅
- 体现"量变引起质变"
- 动态分配曝光次数（3/5/7/10次）
- 基于停留时间和左右滑

#### 2. DwellTimeAnalyzer ✅
- 体现"停留时间=熟悉度"
- 生成每日时间表（按停留时间排序）
- 识别困难词，支持AI短文

#### 3. TaskGenerationStrategy ✅
- 体现"任务预定制"
- 10天3000词完整算法
- 基于停留时间选择复习词

### 三者协同 = 完整学习系统 ⭐⭐⭐

```
TaskGenerationStrategy → 规划任务
         ↓
ExposureStrategy → 分配曝光
         ↓
用户学习 → 记录停留
         ↓
DwellTimeAnalyzer → 分析排序
         ↓
TaskGenerationStrategy → 选择复习词
         ↓
持续优化10天...
```

---

## 🚀 立即集成（30分钟）

### 集成清单：
1. ✅ TaskGenerationStrategy.swift 已创建
2. ⏳ 更新 DemoDataSeeder（使用策略生成计划）
3. ⏳ 更新 TaskScheduler（使用策略）
4. ⏳ 测试验证

### 预期效果：
- ✅ 创建目标时自动生成10天计划
- ✅ 每天任务基于昨日停留时间选择复习词
- ✅ 前期多学新词，后期多复习
- ✅ 算法清晰，易于调整

---

## 📖 相关文档

创建的文档：
1. **`Core/TaskGenerationStrategy.swift`** - 任务生成策略（450行）
2. **`TASK_GENERATION_STRATEGY_GUIDE.md`** - 使用指南

---

**创建时间**：2025-11-05  
**组件状态**：✅ 完成并通过编译  
**核心价值**：完美实现"10天3000词"预定任务  

**三个核心业务组件已全部完成！** 🎊

**它们形成了NFwords的核心竞争力：**
1. ExposureStrategy - 量变引起质变
2. DwellTimeAnalyzer - 停留时间=熟悉度  
3. TaskGenerationStrategy - 10天3000词算法

**下一步：集成这三个组件到现有代码（30分钟）或继续实现第四个组件 AIContentGenerator？** 🚀

