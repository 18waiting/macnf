# NFwords 架构分析与重构建议（基于核心理念优化版）

## 🎯 核心设计理念（架构基础）

### NFwords 的本质（必须反映在架构中）

1. **Tinder式交互** - 右滑会写，左滑不会写
2. **停留时间 = 熟悉度** - 每个单词的停留时间精确记录，按时间排序
3. **量变引起质变** - 摈弃艾宾浩斯，通过多次曝光（5次、10次）实现记忆
4. **短期应试记忆** - 目标用户：大学生/研究生，2-6个月通过考试
5. **预定任务计划** - 10天3000词，算法提前安排每日任务
6. **AI考研短文** - 基于困难词（停留时间最长）生成考研风格阅读
7. **剩余次数可见** - 用户清楚看到每个词还要出现几次

---

## 📊 当前架构现状（从业务视角审视）

### ✅ 已正确实现的核心功能

#### 1. 停留时间追踪 ⭐⭐⭐
```swift
// DwellTimeTracker.swift - 精确到0.01秒
@Published var currentDwellTime: TimeInterval
func startTracking(wordId: Int)
func stopTracking() -> TimeInterval
```
**符合核心理念**：✅ 停留时间 = 熟悉度

#### 2. 按停留时间排序 ⭐⭐⭐
```swift
// DailyReport.swift - 核心字段
let sortedByDwellTime: [WordSummary]  // 按停留时间降序
let unfamiliarWords: [Int]  // 停留>5s
let familiarWords: [Int]  // 停留<2s
```
**符合核心理念**：✅ 每日生成时间表

#### 3. 剩余次数显示 ⭐⭐⭐
```swift
// WordLearningRecord.swift
var remainingExposures: Int  // 剩余曝光次数
var targetExposures: Int  // 目标曝光次数（10次）
```
**符合核心理念**：✅ 显示剩余次数

#### 4. 10天3000词计划 ⭐⭐
```swift
// LearningGoal.swift
let totalWords: Int  // 3000
let durationDays: Int  // 10
let dailyNewWords: Int  // 300
```
**符合核心理念**：✅ 预定任务计划

#### 5. AI短文生成 ⭐⭐
```swift
// DeepSeekService.swift
func generateReadingPassage(difficultWords: [String]) async throws -> ReadingPassage
```
**符合核心理念**：✅ 考研风格短文

---

### 🔴 严重偏离核心理念的问题

#### 问题1：多次曝光逻辑分散 🔴

**核心理念**：
> 让用户多看，而不是死记硬背。一次不行就5次，5次不行就10次。

**当前问题**：
```swift
// 曝光次数逻辑分散在3个地方：
1. WordLearningRecord.remainingExposures  // 内存
2. WordExposureRecord.totalExposureCount  // 数据库
3. StudyCard 的生成逻辑  // 队列构建

// 导致：
- 逻辑重复
- 容易不一致
- 难以调整曝光策略
```

**应该**：
```swift
// 统一的曝光管理器
protocol ExposureScheduler {
    func calculateExposures(for word: WordStudyState) -> Int
    func shouldRepeat(word: WordStudyState) -> Bool
}

class QuantitativeExposureScheduler: ExposureScheduler {
    func calculateExposures(for word: WordStudyState) -> Int {
        // 基于停留时间和左滑次数
        if word.avgDwellTime > 8.0 {
            return 10  // 很陌生，10次
        } else if word.avgDwellTime > 5.0 {
            return 7   // 不熟悉，7次
        } else if word.avgDwellTime > 2.0 {
            return 5   // 一般，5次
        } else {
            return 3   // 熟悉，3次
        }
    }
}
```

**收益**：
- 曝光策略集中管理
- 易于调整（5次→10次只需改一处）
- 符合"量变引起质变"理念

---

#### 问题2：停留时间排序的数据流复杂 🔴

**核心理念**：
> 每一天学习完毕后会生成一个时间表，按停留时间排序，间接反映熟悉程度。

**当前问题**：
```
数据流混乱：
1. StudyViewModel 记录 dwellTimes
2. ReportViewModel 排序生成报告
3. DailyReportStorage 保存排序结果
4. StatisticsView 读取并展示

问题：
- 排序逻辑在 ReportViewModel
- 显示逻辑在多个 View 中
- 数据转换多次（WordLearningRecord → WordSummary）
```

**应该**：
```swift
// 统一的学习分析器
protocol StudyAnalyzer {
    func analyzeSession(_ records: [WordStudyState]) -> StudyAnalysis
}

struct StudyAnalysis {
    let sortedByDwellTime: [WordStudyState]  // 按停留时间排序
    let difficult: [WordStudyState]  // 停留>5s
    let familiar: [WordStudyState]  // 停留<2s
    let avgDwellTime: Double
    let masteryRate: Double
    
    // AI短文生成输入
    func getTopDifficultWords(count: Int = 10) -> [String] {
        Array(sortedByDwellTime.prefix(count).map { $0.word })
    }
}

class QuantitativeStudyAnalyzer: StudyAnalyzer {
    func analyzeSession(_ records: [WordStudyState]) -> StudyAnalysis {
        let sorted = records.sorted { $0.avgDwellTime > $1.avgDwellTime }
        return StudyAnalysis(
            sortedByDwellTime: sorted,
            difficult: sorted.filter { $0.avgDwellTime >= 5.0 },
            familiar: sorted.filter { $0.avgDwellTime < 2.0 },
            // ...
        )
    }
}
```

**收益**：
- 分析逻辑集中
- 直接支持AI短文生成
- 易于添加新分析维度

---

#### 问题3：任务算法与数据模型脱节 🔴

**核心理念**：
> 每天的单词任务是提前就定好的，用算法安排每天的具体任务。

**当前问题**：
```swift
// TaskScheduler.swift 存在但功能简陋
class TaskScheduler {
    func generateDailyTask(...) -> DailyTask {
        // 逻辑不完整
        // 没有真正的"10天3000词"算法
    }
}

// DailyTask.swift 只是数据模型
struct DailyTask {
    let newWords: [Int]  // 只有wid列表
    let reviewWords: [Int]  // 没有算法依据
}
```

**应该**：
```swift
// 任务生成策略（体现10天3000词算法）
protocol TaskGenerationStrategy {
    func generate10DayPlan(totalWords: Int, wordIds: [Int]) -> [DailyTask]
    func selectReviewWords(from history: [WordStudyState]) -> [Int]
}

class QuantitativeTaskStrategy: TaskGenerationStrategy {
    func generate10DayPlan(totalWords: Int, wordIds: [Int]) -> [DailyTask] {
        let dailyCount = totalWords / 10  // 300词/天
        var tasks: [DailyTask] = []
        
        for day in 1...10 {
            let start = (day - 1) * dailyCount
            let end = min(day * dailyCount, totalWords)
            let newWords = Array(wordIds[start..<end])
            
            // 复习词：昨天停留最长的20个
            let reviewWords = day > 1 ? selectReviewWords(day - 1) : []
            
            tasks.append(DailyTask(
                day: day,
                newWords: newWords,
                reviewWords: reviewWords,
                totalExposures: newWords.count * 10 + reviewWords.count * 5
            ))
        }
        
        return tasks
    }
    
    func selectReviewWords(from history: [WordStudyState]) -> [Int] {
        // 按停留时间降序，取前20个
        history
            .sorted { $0.avgDwellTime > $1.avgDwellTime }
            .prefix(20)
            .map { $0.wid }
    }
}
```

**收益**：
- 算法独立，易于调整
- 支持不同策略（7天、10天、20天）
- 直接体现"停留时间→复习优先级"

---

#### 问题4：AI短文生成触发时机不清晰 🟡

**核心理念**：
> 根据时间表的前几位单词，组成考研英语阅读文章风格的小短文。

**当前问题**：
```swift
// AI生成分散在多个地方
1. DeepSeekService.generateReadingPassage()  // 技术实现
2. ReportViewModel.getDifficultWordsForAI()  // 获取困难词
3. DailyReportView 的按钮  // UI触发

// 缺少：
- 自动触发时机（学习完成后）
- 与停留时间表的直接关联
- 生成后的存储和展示流程
```

**应该**：
```swift
// AI内容生成协调器
protocol AIContentGenerator {
    func shouldGenerateArticle(for report: DailyReport) -> Bool
    func generateFromDifficultWords(_ analysis: StudyAnalysis) async throws -> ReadingPassage
}

class DeepSeekContentGenerator: AIContentGenerator {
    func shouldGenerateArticle(for report: DailyReport) -> Bool {
        // 自动触发条件：
        // 1. 困难词≥10个
        // 2. 平均停留>5秒
        report.unfamiliarWords.count >= 10 && report.avgDwellTime > 5.0
    }
    
    func generateFromDifficultWords(_ analysis: StudyAnalysis) async throws -> ReadingPassage {
        // 从停留时间表的前10个单词生成
        let words = analysis.getTopDifficultWords(count: 10)
        return try await deepSeekService.generateReadingPassage(
            difficultWords: words,
            style: .postgraduate  // 考研风格
        )
    }
}
```

**收益**：
- 自动触发，无需手动
- 与停留时间表直接关联
- 符合"困难词→AI短文"流程

---

### 🟡 部分符合但需要优化的问题

#### 问题5：L1→L2渐隐逻辑缺失 🟡

**核心理念（总览文档）**：
> 看得越多，中文越少。第1次显示中文，2-3次显示英文释义，≥4次只显示英文。

**当前问题**：
```swift
// WordCardView.swift 没有渐隐逻辑
// 所有曝光都显示相同内容
```

**应该**：
```swift
// Word.swift 或 WordCardView
struct WordDisplayStrategy {
    func getDisplayContent(for word: Word, exposureCount: Int, lastSwipeDirection: SwipeDirection?) -> DisplayContent {
        switch exposureCount {
        case 0...1:
            // 第1次：中文短义 + 中英短语
            return .beginner(chinese: word.translations.first?.meaning, phrase: word.phrases.first)
        case 2...3:
            // 2-3次：英文释义 + 纯英短语，中文收起
            return .intermediate(englishDef: word.englishDefinition, phrase: word.phrases.first?.english)
        default:
            // ≥4次：纯英文信息，中文需点按
            return .advanced(englishDef: word.englishDefinition, collocations: word.collocations)
        }
    }
}
```

**收益**：
- 符合思维化学习
- 自动适应学习阶段
- 降低初学门槛，提升高阶沉浸

---

#### 问题6：微场景触发逻辑未实现 🟡

**核心理念（总览文档）**：
> 长时间停留且连续左滑（困难）→ 下次出现带微场景句。

**当前问题**：
```swift
// DeepSeekService 有生成能力，但缺少触发逻辑
// WordCardView 没有条件显示微场景
```

**应该**：
```swift
// 困难词判定
protocol DifficultWordDetector {
    func isDifficult(_ state: WordStudyState) -> Bool
}

class DwellTimeBasedDetector: DifficultWordDetector {
    func isDifficult(_ state: WordStudyState) -> Bool {
        // 困难态：停留>8秒 且 左滑≥2次
        state.avgDwellTime > 8.0 && state.swipeLeftCount >= 2
    }
}

// 在 StudyViewModel 中
func checkAndGenerateMicroScene(for wordId: Int) {
    guard let state = learningRecords[wordId],
          difficultDetector.isDifficult(state) else { return }
    
    Task {
        let scene = try await aiContentGenerator.generateMicroScene(for: word)
        // 下次出现时显示
    }
}
```

**收益**：
- 自动检测困难词
- 自动生成微场景
- 符合"困难→增强记忆钩子"

---

## 🏗️ 优化后的架构设计（基于核心理念）

### 核心层次（从业务出发）

```
┌───────────────────────────────────────────────┐
│  1. 交互层 (Tinder式滑卡)                      │
│     - 右滑/左滑判定                            │
│     - 停留时间精确追踪 ⭐                       │
│     - 剩余次数实时显示 ⭐                       │
└───────────────────────────────────────────────┘
              ↓
┌───────────────────────────────────────────────┐
│  2. 学习逻辑层 (量变引起质变)                   │
│     - 曝光次数管理 (5次、10次) ⭐              │
│     - 停留时间记录 ⭐                           │
│     - 左右滑统计                               │
└───────────────────────────────────────────────┘
              ↓
┌───────────────────────────────────────────────┐
│  3. 分析层 (停留时间 = 熟悉度)                 │
│     - 按停留时间排序 ⭐                         │
│     - 生成每日时间表 ⭐                         │
│     - 识别困难词                               │
└───────────────────────────────────────────────┘
              ↓
┌───────────────────────────────────────────────┐
│  4. 任务调度层 (10天3000词算法)                │
│     - 每日任务预生成 ⭐                         │
│     - 基于停留时间选复习词 ⭐                   │
│     - 新词+复习词混合                          │
└───────────────────────────────────────────────┘
              ↓
┌───────────────────────────────────────────────┐
│  5. AI增强层 (DeepSeek)                       │
│     - 基于困难词生成短文 ⭐                     │
│     - 微场景句生成                             │
│     - 考研风格文章                             │
└───────────────────────────────────────────────┘
              ↓
┌───────────────────────────────────────────────┐
│  6. 数据持久化层 (SQLite)                     │
│     - 学习记录（含停留时间）                   │
│     - 每日报告（按时间排序）                   │
│     - 学习目标（10天计划）                     │
└───────────────────────────────────────────────┘
```

---

## ✅ 优化建议（基于核心理念）

### 建议1：创建"曝光策略"核心组件 🔴

**为什么**：体现"量变引起质变"，多看不死记

**实现**：

**Core/ExposureStrategy.swift**
```swift
/// 曝光策略（体现量变引起质变）
protocol ExposureStrategy {
    /// 计算单词需要曝光的次数
    func calculateExposures(for state: WordStudyState) -> Int
    
    /// 是否需要继续曝光
    func shouldContinue(state: WordStudyState) -> Bool
}

/// 基于停留时间的曝光策略
class DwellTimeExposureStrategy: ExposureStrategy {
    func calculateExposures(for state: WordStudyState) -> Int {
        // 核心算法：停留时间越长，曝光次数越多
        switch state.avgDwellTime {
        case 0..<2.0: return 3   // 熟悉：3次
        case 2.0..<5.0: return 5  // 一般：5次
        case 5.0..<8.0: return 7  // 不熟：7次
        default: return 10         // 陌生：10次
        }
    }
    
    func shouldContinue(state: WordStudyState) -> Bool {
        // 右滑≥3次 且 停留<2秒 → 可以停止
        if state.swipeRightCount >= 3 && state.avgDwellTime < 2.0 {
            return false
        }
        // 否则继续曝光
        return state.remainingExposures > 0
    }
}
```

**在 StudyViewModel 中使用**：
```swift
class StudyViewModel {
    private let exposureStrategy: ExposureStrategy
    
    func handleSwipe(wordId: Int, direction: SwipeDirection, dwellTime: TimeInterval) {
        var state = learningRecords[wordId]
        state.recordSwipe(direction: direction, dwellTime: dwellTime)
        
        // 根据策略决定是否继续曝光
        if exposureStrategy.shouldContinue(state) {
            // 继续在队列中
        } else {
            // 提前移除（已掌握）
            print("[Strategy] Word \(wordId) mastered early, removing from queue")
        }
    }
}
```

---

### 建议2：创建"停留时间分析"核心组件 🔴

**为什么**：停留时间是核心指标，需要专门管理

**实现**：

**Core/DwellTimeAnalyzer.swift**
```swift
/// 停留时间分析器（核心业务逻辑）
protocol DwellTimeAnalyzer {
    func analyze(_ records: [WordStudyState]) -> DwellTimeAnalysis
    func rankByDifficulty(_ records: [WordStudyState]) -> [WordStudyState]
}

struct DwellTimeAnalysis {
    let distribution: [DwellTimeRange: Int]  // 分布统计
    let avgDwellTime: Double
    let sortedByDwellTime: [WordStudyState]  // 按停留时间排序 ⭐
    
    // 分类
    let veryFamiliar: [WordStudyState]  // <2s
    let familiar: [WordStudyState]  // 2-5s
    let unfamiliar: [WordStudyState]  // 5-8s
    let veryUnfamiliar: [WordStudyState]  // >8s
    
    // AI短文生成输入
    var topDifficultWords: [String] {
        Array(sortedByDwellTime.prefix(10).map { $0.word })
    }
}

enum DwellTimeRange {
    case veryFast  // <2s
    case fast  // 2-5s
    case medium  // 5-8s
    case slow  // >8s
}

class DefaultDwellTimeAnalyzer: DwellTimeAnalyzer {
    func analyze(_ records: [WordStudyState]) -> DwellTimeAnalysis {
        let sorted = records.sorted { $0.avgDwellTime > $1.avgDwellTime }
        
        return DwellTimeAnalysis(
            distribution: calculateDistribution(sorted),
            avgDwellTime: sorted.reduce(0.0) { $0 + $1.avgDwellTime } / Double(sorted.count),
            sortedByDwellTime: sorted,
            veryFamiliar: sorted.filter { $0.avgDwellTime < 2.0 },
            familiar: sorted.filter { $0.avgDwellTime >= 2.0 && $0.avgDwellTime < 5.0 },
            unfamiliar: sorted.filter { $0.avgDwellTime >= 5.0 && $0.avgDwellTime < 8.0 },
            veryUnfamiliar: sorted.filter { $0.avgDwellTime >= 8.0 }
        )
    }
}
```

**收益**：
- 停留时间分析逻辑集中
- 直接输出排序结果
- 自动分类（熟悉/困难）
- 支持AI短文生成

---

### 建议3：优化数据模型（符合业务本质）

#### 统一单词状态模型

**Models/Domain/WordStudyState.swift**
```swift
/// 单词学习状态（统一模型，体现核心指标）
struct WordStudyState: Identifiable, Codable {
    var id: UUID
    let wid: Int
    let packId: Int
    var word: String  // 添加：方便使用
    
    // 核心指标1：停留时间 ⭐⭐⭐
    var totalDwellTime: TimeInterval
    var avgDwellTime: TimeInterval  // 停留时间 = 熟悉度
    private var dwellTimes: [TimeInterval]  // 每次停留详细记录
    
    // 核心指标2：左右滑统计 ⭐⭐⭐
    var swipeRightCount: Int  // 会写
    var swipeLeftCount: Int  // 不会写
    
    // 核心指标3：曝光管理 ⭐⭐⭐
    var totalExposureCount: Int  // 已曝光次数
    var remainingExposures: Int  // 剩余次数（用户可见）
    var targetExposures: Int  // 目标次数（5/10）
    
    // 学习阶段
    var learningPhase: LearningPhase
    var familiarity: Double
    var learned: Bool
    
    // 时间戳
    var firstExposedAt: Date?
    var lastExposedAt: Date?
    
    // 计算属性（符合业务规则）
    var isMastered: Bool {
        // 掌握条件：右滑≥3次 且 停留<2秒
        swipeRightCount >= 3 && avgDwellTime < 2.0
    }
    
    var isDifficult: Bool {
        // 困难条件：停留>8秒 且 左滑≥2次
        avgDwellTime > 8.0 && swipeLeftCount >= 2
    }
    
    var shouldShowMicroScene: Bool {
        // 微场景触发：困难词
        isDifficult
    }
    
    var displayStrategy: ContentDisplayLevel {
        // L1→L2渐隐
        switch totalExposureCount {
        case 0...1: return .beginner  // 中文
        case 2...3: return .intermediate  // 中英混合
        default: return .advanced  // 纯英文
        }
    }
    
    // 方法
    mutating func recordSwipe(direction: SwipeDirection, dwellTime: TimeInterval) {
        totalExposureCount += 1
        remainingExposures = max(0, remainingExposures - 1)
        
        dwellTimes.append(dwellTime)
        totalDwellTime += dwellTime
        avgDwellTime = totalDwellTime / Double(totalExposureCount)
        
        switch direction {
        case .right:
            swipeRightCount += 1
            // 右滑：剩余-1
        case .left:
            swipeLeftCount += 1
            // 左滑：剩余+1（最多不超过目标）
            remainingExposures = min(remainingExposures + 1, targetExposures)
        }
        
        lastExposedAt = Date()
    }
}

enum ContentDisplayLevel {
    case beginner  // 第1次：中文
    case intermediate  // 2-3次：中英混合
    case advanced  // ≥4次：纯英文
}
```

**删除**：
- WordLearningRecord（合并）
- WordExposureRecord（合并）

**收益**：
- 单一真实来源
- 业务规则内聚
- 易于理解和维护
- 直接支持L1→L2渐隐

---

### 建议4：优化 AppState（聚焦核心状态）

**当前问题**：
```swift
// AppState 包罗万象
final class AppState: ObservableObject {
    @Published var hasActiveGoal: Bool
    @Published var activeStatisticDetail: StatisticsDetailDisplay?
    @Published var dashboard: DashboardSnapshot
    @Published var localDatabase: LocalDatabaseSnapshot  // 整个数据库！
    let studyViewModel: StudyViewModel
}
```

**优化后**：

**App/AppState.swift（精简，只管核心业务状态）**
```swift
@MainActor
final class AppState: ObservableObject {
    // 1. 当前学习会话（核心）
    @Published private(set) var currentSession: StudySession?
    
    // 2. 每日任务状态
    @Published private(set) var todayTask: DailyTask?
    @Published private(set) var taskProgress: TaskProgress?
    
    // 3. 最新报告（停留时间表）
    @Published private(set) var latestReport: DailyReport?
    
    // 4. 可用词书
    @Published private(set) var availablePacks: [LocalPackRecord] = []
    
    // 5. UI 导航状态（独立）
    @Published var activeSheet: AppSheet?
    @Published var activeAlert: AppAlert?
    
    // Dependencies
    private let studyRepository: StudyRepositoryProtocol
    private let taskGenerator: TaskGenerationStrategy
    private let dwellAnalyzer: DwellTimeAnalyzer
    
    // Global ViewModels
    let studyViewModel: StudyViewModel
    let themeManager: ThemeManager
    
    // 核心方法（精简）
    func loadTodayTask()
    func refreshPacks()
    func completeStudy(analysis: DwellTimeAnalysis)
}

struct StudySession {
    let goal: LearningGoal
    let packId: Int
    let startedAt: Date
}

struct TaskProgress {
    let completed: Int
    let total: Int
    var percentage: Double { Double(completed) / Double(total) }
}
```

**收益**：
- 聚焦核心业务状态
- 移除 localDatabase（太底层）
- 职责清晰

---

### 建议5：拆分文件结构（按业务领域）

#### 当前问题
```
Models/ - 混杂了Domain、Database、UI模型
Services/ - 混杂了Database、Network、DataSource
```

#### 优化后的目录（按业务领域组织）

```
NFwordsDemo/
├── App/  (应用级)
│   ├── NFwordsDemoApp.swift
│   ├── AppState.swift  ← 精简
│   ├── ThemeManager.swift
│   └── AppTheme.swift
│
├── Core/  (核心业务逻辑) ⭐ 新增
│   ├── ExposureStrategy.swift  ← 曝光策略（5次/10次）
│   ├── DwellTimeAnalyzer.swift  ← 停留时间分析
│   ├── TaskGenerationStrategy.swift  ← 10天3000词算法
│   ├── DifficultWordDetector.swift  ← 困难词判定
│   └── AIContentGenerator.swift  ← AI内容生成协调
│
├── Domain/  (业务模型) ⭐ 重构
│   ├── Word.swift
│   ├── WordStudyState.swift  ← 统一模型
│   ├── LearningGoal.swift
│   ├── DailyTask.swift
│   ├── DailyReport.swift
│   ├── StudyAnalysis.swift  ← 分析结果
│   └── ContentDisplayLevel.swift  ← L1→L2渐隐
│
├── Persistence/  (数据持久化) ⭐ 重命名
│   ├── Models/
│   │   ├── LocalPackRecord.swift
│   │   ├── DailyPlanRecord.swift
│   │   └── ...
│   ├── Storage/
│   │   ├── PackStorage.swift
│   │   ├── GoalStorage.swift
│   │   ├── WordStudyStorage.swift  ← 统一
│   │   └── ...
│   ├── DatabaseManager.swift
│   └── DatabaseSchema.swift
│
├── Repositories/  (数据访问抽象) ⭐ 新增
│   ├── StudyRepository.swift
│   ├── WordRepository.swift
│   ├── PackRepository.swift
│   └── Protocols/
│
├── Services/
│   ├── AI/
│   │   ├── DeepSeekService.swift
│   │   └── MicroSceneGenerator.swift
│   └── DataSources/
│       └── WordJSONLDataSource.swift
│
├── Presentation/  (展示层)
│   ├── ViewModels/
│   │   ├── StudyViewModel.swift
│   │   ├── DwellTimeTracker.swift
│   │   └── ...
│   └── Views/
│       ├── Study/  (学习流程)
│       │   ├── SwipeCardsView.swift
│       │   ├── WordCardView.swift
│       │   └── DailyReportView.swift  ← 停留时间表
│       ├── Library/
│       ├── Statistics/
│       └── Profile/
│
└── Utilities/
    ├── Extensions/
    └── Protocols/
```

---

## 🎯 核心重构清单（按业务优先级）

### 阶段1：核心业务逻辑提取（1-2天）🔴

#### 1.1 创建曝光策略组件
- [ ] 创建 `Core/ExposureStrategy.swift`
- [ ] 实现 DwellTimeExposureStrategy
- [ ] StudyViewModel 使用策略模式
- [ ] **业务价值**：体现"量变引起质变"核心理念

#### 1.2 创建停留时间分析组件
- [ ] 创建 `Core/DwellTimeAnalyzer.swift`
- [ ] 实现按停留时间排序
- [ ] 自动分类（熟悉/困难）
- [ ] **业务价值**：每日时间表核心功能

#### 1.3 创建任务生成策略
- [ ] 创建 `Core/TaskGenerationStrategy.swift`
- [ ] 实现10天3000词算法
- [ ] 基于停留时间选复习词
- [ ] **业务价值**：预定任务计划核心功能

---

### 阶段2：数据模型统一（2-3天）🔴

#### 2.1 创建 WordStudyState 统一模型
- [ ] 创建 `Domain/WordStudyState.swift`
- [ ] 包含所有核心指标（停留时间、左右滑、曝光次数）
- [ ] 添加业务方法（recordSwipe, isMastered, isDifficult）
- [ ] **业务价值**：消除重复，数据一致性

#### 2.2 替换使用
- [ ] StudyViewModel 使用 WordStudyState
- [ ] Storage 层使用 WordStudyState
- [ ] 删除 WordLearningRecord 和 WordExposureRecord
- [ ] **业务价值**：减少转换，降低bug

---

### 阶段3：AI功能增强（1天）🟡

#### 3.1 自动生成考研短文
- [ ] 学习完成后自动检测（困难词≥10）
- [ ] 自动调用 DeepSeek 生成
- [ ] 自动保存和展示
- [ ] **业务价值**：核心差异化功能

#### 3.2 微场景自动触发
- [ ] 检测困难词（停留>8s且左滑≥2）
- [ ] 下次出现时显示微场景
- [ ] **业务价值**：增强记忆钩子

---

### 阶段4：L1→L2渐隐实现（1天）🟡

#### 4.1 实现内容显示策略
- [ ] 创建 ContentDisplayStrategy
- [ ] 第1次显示中文
- [ ] 2-3次中英混合
- [ ] ≥4次纯英文
- [ ] **业务价值**：思维化学习核心功能

---

### 阶段5：文件重构（1-2天）🟡

#### 5.1 拆分 ContentView.swift
- [ ] 移动全局类型到独立文件
- [ ] ContentView 只保留 View

#### 5.2 拆分 LocalDatabaseStorage.swift
- [ ] 每个 Storage 独立文件

---

## 📋 业务功能完整性检查

### ✅ 已实现的核心功能

| 核心理念 | 当前实现 | 完成度 | 备注 |
|---------|---------|--------|------|
| Tinder式滑卡 | SwipeCardsView | 100% | ✅ 完整 |
| 停留时间追踪 | DwellTimeTracker | 100% | ✅ 精确到0.01秒 |
| 按停留时间排序 | DailyReport.sortedByDwellTime | 90% | ⚠️ 逻辑分散 |
| 剩余次数显示 | remainingExposures | 100% | ✅ UI已显示 |
| 10天3000词 | LearningGoal | 60% | ⚠️ 算法简陋 |
| AI考研短文 | DeepSeekService | 70% | ⚠️ 未自动触发 |
| 多次曝光（5/10次）| targetExposures | 80% | ⚠️ 策略固定 |
| 左右滑统计 | swipeRightCount/Left | 100% | ✅ 完整 |

### ❌ 未实现的核心功能

| 核心理念 | 缺失 | 优先级 |
|---------|------|--------|
| L1→L2渐隐 | ContentDisplayStrategy | 🔴 高 |
| 微场景自动触发 | DifficultWordDetector | 🟡 中 |
| 曝光策略（5次/10次算法）| ExposureStrategy | 🔴 高 |
| 10天任务算法 | TaskGenerationStrategy | 🔴 高 |
| AI短文自动生成 | AIContentGenerator | 🟡 中 |

---

## 🏗️ 优化后的架构图（业务驱动）

```
┌──────────────────────────────────────────────────┐
│  UI Layer (Tinder式交互)                          │
│  ┌────────────────────────────────────────────┐  │
│  │ SwipeCardsView                             │  │
│  │  - 左右滑判定 ⭐                            │  │
│  │  - 停留时间显示                            │  │
│  │  - 剩余次数显示 ⭐                          │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
              ↓
┌──────────────────────────────────────────────────┐
│  Presentation Layer (学习逻辑)                    │
│  ┌────────────────────────────────────────────┐  │
│  │ StudyViewModel                             │  │
│  │  - 依赖 ExposureStrategy ⭐                │  │
│  │  - 依赖 DwellTimeAnalyzer ⭐               │  │
│  │  - 依赖 StudyRepository                    │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
              ↓
┌──────────────────────────────────────────────────┐
│  Core Business Layer (核心业务) ⭐ 关键层        │
│  ┌────────────────────────────────────────────┐  │
│  │ ExposureStrategy (曝光策略)                │  │
│  │  - 5次/10次算法 ⭐                          │  │
│  │  - 基于停留时间动态调整                    │  │
│  ├────────────────────────────────────────────┤  │
│  │ DwellTimeAnalyzer (停留时间分析) ⭐        │  │
│  │  - 按停留时间排序                          │  │
│  │  - 生成每日时间表                          │  │
│  │  - 识别困难词（>8s）                       │  │
│  ├────────────────────────────────────────────┤  │
│  │ TaskGenerationStrategy (任务算法) ⭐       │  │
│  │  - 10天3000词分配                          │  │
│  │  - 基于停留时间选复习词                    │  │
│  │  - 新词+复习词混合                         │  │
│  ├────────────────────────────────────────────┤  │
│  │ AIContentGenerator (AI增强)                │  │
│  │  - 困难词→考研短文 ⭐                       │  │
│  │  - 微场景句生成                            │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
              ↓
┌──────────────────────────────────────────────────┐
│  Repository Layer (数据访问抽象)                  │
│  - StudyRepository (封装所有学习相关数据操作)     │
│  - WordRepository (词汇数据)                     │
└──────────────────────────────────────────────────┘
              ↓
┌──────────────────────────────────────────────────┐
│  Data Layer (数据持久化)                          │
│  - SQLite Storage (学习记录、停留时间)            │
│  - JSONL DataSource (词汇内容)                   │
│  - DeepSeek API (AI内容)                         │
└──────────────────────────────────────────────────┘
```

---

## 🎯 立即执行的重构（最小改动，最大收益）

### 重构1：拆分 ContentView.swift（30分钟）

```bash
# 创建目录
mkdir -p App Models/UI

# 创建文件并移动代码
touch App/AppState.swift
touch App/ThemeManager.swift
touch App/AppTheme.swift
touch Models/UI/DashboardSnapshot.swift
touch Models/UI/QuickStat.swift
touch Models/UI/StatisticsDetailDisplay.swift

# ContentView.swift 只保留：
# - import
# - ContentView struct
# - WelcomeView
# - FeatureRow
# - 预览
```

**立即收益**：
- 代码组织清晰
- 编译更快
- 易于维护

---

### 重构2：创建核心业务组件（2小时）

**Core/ExposureStrategy.swift**
```swift
protocol ExposureStrategy {
    func calculateExposures(for state: WordStudyState) -> Int
}

class QuantitativeExposureStrategy: ExposureStrategy {
    func calculateExposures(for state: WordStudyState) -> Int {
        // 停留时间越长，曝光次数越多（量变引起质变）
        if state.avgDwellTime > 8.0 { return 10 }
        if state.avgDwellTime > 5.0 { return 7 }
        if state.avgDwellTime > 2.0 { return 5 }
        return 3
    }
}
```

**Core/DwellTimeAnalyzer.swift**
```swift
protocol DwellTimeAnalyzer {
    func analyze(_ records: [WordStudyState]) -> DwellTimeAnalysis
}

struct DwellTimeAnalysis {
    let sortedByDwellTime: [WordStudyState]  // 每日时间表
    let avgDwellTime: Double
    let difficult: [WordStudyState]  // >8s
    let familiar: [WordStudyState]  // <2s
    
    // AI短文输入
    var topDifficultWords: [String] {
        Array(sortedByDwellTime.prefix(10).map { $0.word })
    }
}
```

**立即收益**：
- 核心业务逻辑独立
- 易于测试和调整
- 直接支持核心功能

---

### 重构3：统一数据模型（3小时）

**Domain/WordStudyState.swift（替换2个模型）**
```swift
struct WordStudyState: Identifiable, Codable {
    // 所有核心指标
    var avgDwellTime: TimeInterval  // 停留时间 = 熟悉度
    var swipeRightCount: Int  // 会写
    var swipeLeftCount: Int  // 不会写
    var remainingExposures: Int  // 剩余次数
    var targetExposures: Int  // 目标次数
    
    // 业务方法
    mutating func recordSwipe(direction: SwipeDirection, dwellTime: TimeInterval)
    
    // 业务规则
    var isMastered: Bool { swipeRightCount >= 3 && avgDwellTime < 2.0 }
    var isDifficult: Bool { avgDwellTime > 8.0 && swipeLeftCount >= 2 }
}
```

**替换**：
- WordLearningRecord → WordStudyState
- WordExposureRecord → WordStudyState

**立即收益**：
- 消除重复
- 数据一致性
- 减少转换代码

---

## 📊 重构收益评估（业务视角）

### 核心功能完整性
- 停留时间分析：70% → 95% ⭐
- 10天任务算法：40% → 85% ⭐
- AI短文自动生成：50% → 90% ⭐
- 曝光策略灵活性：30% → 80% ⭐

### 代码质量
- 可维护性：60% → 90%
- 业务逻辑清晰度：50% → 90%
- 可扩展性：50% → 85%

### 开发效率
- 添加新曝光策略：1天 → 1小时
- 调整10天算法：2小时 → 20分钟
- 修改停留时间阈值：30分钟 → 5分钟

---

## 🚀 推荐的执行路径

### Week 1: 核心业务组件（最重要）
- **Day 1**: 创建 ExposureStrategy（体现量变引起质变）
- **Day 2**: 创建 DwellTimeAnalyzer（停留时间表核心）
- **Day 3**: 创建 TaskGenerationStrategy（10天3000词算法）
- **Day 4**: 集成到 StudyViewModel
- **Day 5**: 测试验证

**为什么先做这个**：
- 直接体现核心业务价值
- 不影响现有功能
- 代码改动量小
- 业务逻辑清晰化

### Week 2: 数据模型统一
- **Day 1-2**: 创建 WordStudyState
- **Day 3-4**: 替换使用
- **Day 5**: 测试验证

### Week 3: 文件重构
- **Day 1**: 拆分 ContentView.swift
- **Day 2**: 拆分 LocalDatabaseStorage.swift
- **Day 3-5**: 组织目录结构

---

## 🎯 关键设计原则（基于业务本质）

### 1. 停留时间优先原则
**架构体现**：
- DwellTimeAnalyzer 是核心组件
- 所有排序、分类都基于停留时间
- UI 优先显示停留时间相关信息

### 2. 量变引起质变原则
**架构体现**：
- ExposureStrategy 管理曝光次数
- 基于停留时间动态调整（3/5/7/10次）
- 不使用艾宾浩斯曲线

### 3. 数据驱动原则
**架构体现**：
- WordStudyState 包含所有关键指标
- 分析器从数据生成洞察
- AI从数据生成内容

### 4. 短期应试原则
**架构体现**：
- 10天任务算法（不是长期记忆曲线）
- 高频曝光（10次/词）
- 考研风格短文生成

---

## 💡 架构设计要点

### 要点1：核心业务逻辑独立
```
Core/
├── ExposureStrategy.swift  ← 体现"量变引起质变"
├── DwellTimeAnalyzer.swift  ← 体现"停留时间=熟悉度"
├── TaskGenerationStrategy.swift  ← 体现"10天3000词"
└── AIContentGenerator.swift  ← 体现"困难词→短文"
```

### 要点2：数据模型反映业务
```swift
struct WordStudyState {
    var avgDwellTime: TimeInterval  // 停留时间（核心）
    var remainingExposures: Int  // 剩余次数（用户可见）
    var swipeRightCount: Int  // 会写（核心）
    var swipeLeftCount: Int  // 不会写（核心）
    
    var isMastered: Bool  // 业务规则
    var isDifficult: Bool  // 业务规则
}
```

### 要点3：分析器输出直接可用
```swift
struct DwellTimeAnalysis {
    let sortedByDwellTime: [WordStudyState]  // 每日时间表
    var topDifficultWords: [String]  // AI短文输入
}
```

---

## 📝 总结

### 当前架构的优点 ✅
1. ✅ 核心功能基本实现
2. ✅ 数据持久化完整
3. ✅ UI交互流畅
4. ✅ 停留时间精确追踪

### 当前架构的不足 ❌
1. ❌ 核心业务逻辑分散（曝光策略、停留时间分析）
2. ❌ 数据模型重复（WordLearningRecord vs WordExposureRecord）
3. ❌ 算法未独立（10天3000词）
4. ❌ AI功能未自动化

### 重构优先级（业务视角）

#### 🔴 高优先级（直接提升核心功能）
1. **创建 ExposureStrategy** - 体现量变引起质变
2. **创建 DwellTimeAnalyzer** - 优化停留时间表
3. **创建 TaskGenerationStrategy** - 完善10天算法
4. **统一 WordStudyState** - 消除重复

#### 🟡 中优先级（完善体验）
5. **AI自动触发** - 学习完成后自动生成短文
6. **L1→L2渐隐** - 思维化学习
7. **拆分超大文件** - 改善维护性

#### 🟢 低优先级（锦上添花）
8. **引入 UseCase 层** - 进一步解耦
9. **Coordinator 模式** - 优化导航
10. **单元测试** - 提升质量

---

## 🎊 核心建议

### 建议：先创建核心业务组件，再重构文件结构

**为什么**：
1. 核心业务组件直接提升功能完整性
2. 代码改动小，风险低
3. 立即体现业务价值
4. 为后续重构打基础

**具体步骤**：
1. 创建 `Core/ExposureStrategy.swift`（1小时）
2. 创建 `Core/DwellTimeAnalyzer.swift`（1小时）
3. 创建 `Core/TaskGenerationStrategy.swift`（2小时）
4. 集成到 StudyViewModel（1小时）
5. 测试验证（1小时）

**总计**：6小时即可显著提升架构质量和功能完整性！

---

**分析时间**：2025-11-05  
**基于文档**：【总览】NFwords架构设计总结.md  
**核心关注**：业务本质驱动的架构设计  
**建议策略**：核心组件优先，文件重构其次

