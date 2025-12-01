# NFwords 开发规则文档

## 📋 目录

1. [项目概述](#项目概述)
2. [架构规范](#架构规范)
3. [代码规范](#代码规范)
4. [数据流规范](#数据流规范)
5. [UI/UX规范](#uiux规范)
6. [性能规范](#性能规范)
7. [测试规范](#测试规范)
8. [文档规范](#文档规范)
9. [Git工作流](#git工作流)
10. [错误处理规范](#错误处理规范)
11. [安全规范](#安全规范)
12. [依赖管理](#依赖管理)

---

## 🎯 项目概述

### 核心定位
**NFwords** 是一款为应试考试而生的单词学习应用，核心特点：
- 🎯 **Tinder式交互**：左右滑动判断会/不会，流畅有趣
- 🎯 **目标导向**：10天3000词，清晰明确的学习目标
- 📊 **停留排序**：智能发现薄弱环节，优先复习
- 📖 **AI考研短文**：用最陌生的10个词生成考研风格阅读

### 技术栈
- **框架**：SwiftUI + UIKit (Koloda)
- **架构**：MVVM + Combine
- **存储**：SQLite (本地优先)
- **算法**：间隔重复（SM-2）+ 停留时间排序
- **AI**：DeepSeek API

### 目标用户
大学生、研究生等需要在**短期内（2-6个月）**通过应试考试（CET-4/6、考研、TOEFL等）的学习者。

---

## 🏗️ 架构规范

### 1. MVVM 架构模式

#### 职责划分

**View（视图层）**
- ✅ **只负责展示**：不包含业务逻辑
- ✅ **响应式更新**：通过 `@ObservedObject` 或 `@StateObject` 绑定 ViewModel
- ✅ **用户交互**：将用户操作传递给 ViewModel
- ❌ **禁止**：直接访问数据库、Service 层
- ❌ **禁止**：在 View 中实现复杂业务逻辑

```swift
// ✅ 正确示例
struct LearningHomeView: View {
    @StateObject private var viewModel = StudyViewModel()
    
    var body: some View {
        VStack {
            Text("进度: \(viewModel.completedCount)/\(viewModel.totalCount)")
            Button("开始学习") {
                viewModel.startStudy()
            }
        }
    }
}

// ❌ 错误示例
struct LearningHomeView: View {
    var body: some View {
        VStack {
            // ❌ 直接在 View 中访问数据库
            let goal = try? LearningGoalStorage().getActiveGoal()
            Text("目标: \(goal?.totalWords ?? 0)")
        }
    }
}
```

**ViewModel（视图模型层）**
- ✅ **业务逻辑**：处理用户交互、数据转换
- ✅ **状态管理**：使用 `@Published` 暴露状态
- ✅ **依赖注入**：通过构造函数接收 Service 依赖
- ✅ **异步操作**：使用 `async/await` 处理异步任务
- ❌ **禁止**：直接操作数据库（通过 Service 层）
- ❌ **禁止**：包含 UI 相关代码

```swift
// ✅ 正确示例
@MainActor
class StudyViewModel: ObservableObject {
    @Published var completedCount: Int = 0
    @Published var queueCount: Int = 0
    
    private let goalService: GoalService
    private let wordRepository: WordRepository
    
    init(goalService: GoalService = .shared, 
         wordRepository: WordRepository = .shared) {
        self.goalService = goalService
        self.wordRepository = wordRepository
    }
    
    func startStudy() async {
        // 业务逻辑
        let goal = try? await goalService.getActiveGoal()
        // ...
    }
}
```

**Service（服务层）**
- ✅ **业务逻辑**：封装复杂的业务规则
- ✅ **数据访问**：通过 Storage 层访问数据库
- ✅ **可测试性**：易于单元测试
- ✅ **单一职责**：每个 Service 负责一个业务领域
- ❌ **禁止**：直接操作数据库（通过 Storage 层）

```swift
// ✅ 正确示例
class GoalService {
    private let goalStorage: LearningGoalStorage
    private let taskStorage: DailyTaskStorage
    
    init(goalStorage: LearningGoalStorage = LearningGoalStorage(),
         taskStorage: DailyTaskStorage = DailyTaskStorage()) {
        self.goalStorage = goalStorage
        self.taskStorage = taskStorage
    }
    
    func createGoal(packId: Int, plan: LearningPlan) throws -> LearningGoal {
        // 业务逻辑
        let goal = LearningGoal(...)
        try goalStorage.save(goal)
        return goal
    }
}
```

**Storage（存储层）**
- ✅ **数据访问**：封装数据库操作
- ✅ **CRUD操作**：提供增删改查接口
- ✅ **错误处理**：统一处理数据库错误
- ❌ **禁止**：包含业务逻辑

```swift
// ✅ 正确示例
class LearningGoalStorage {
    private let db: DatabaseManager
    
    func save(_ goal: LearningGoal) throws {
        try db.insert(goal)
    }
    
    func getActiveGoal() throws -> LearningGoal? {
        return try db.query("SELECT * FROM learning_goals WHERE status = 'in_progress'")
    }
}
```

### 2. 目录结构规范

```
NFwordsDemo/
├── Models/                    # 数据模型（只包含数据结构）
│   ├── Word.swift
│   ├── LearningGoal.swift
│   └── ...
├── Views/                     # SwiftUI 视图（只负责展示）
│   ├── KolodaCardsView.swift
│   ├── BookLibraryView.swift
│   └── ...
├── ViewModels/                # 视图模型（业务逻辑）
│   ├── StudyViewModel.swift
│   └── ...
├── Services/                  # 业务服务层
│   ├── GoalService.swift
│   ├── SpacedRepetitionService.swift
│   └── Database/              # 数据库相关
│       ├── DatabaseManager.swift
│       └── ...
├── Core/                      # 核心算法组件
│   ├── ExposureStrategy.swift
│   └── ...
└── Koloda/                    # 第三方库（Koloda）
```

### 3. 依赖注入规范

**原则**：使用依赖注入，避免单例滥用

```swift
// ✅ 正确：通过构造函数注入
class StudyViewModel: ObservableObject {
    private let goalService: GoalService
    private let wordRepository: WordRepository
    
    init(goalService: GoalService = .shared,
         wordRepository: WordRepository = .shared) {
        self.goalService = goalService
        self.wordRepository = wordRepository
    }
}

// ⚠️ 谨慎使用：单例模式（仅用于共享资源）
class GoalService {
    static let shared = GoalService()
    private init() {}
}

// ❌ 错误：在 ViewModel 中直接创建依赖
class StudyViewModel: ObservableObject {
    private let goalService = GoalService()  // ❌ 硬编码依赖
}
```

---

## 💻 代码规范

### 1. Swift 编码规范

#### 命名规范

**类型命名**：使用 PascalCase
```swift
// ✅ 正确
struct LearningGoal { }
class StudyViewModel { }
enum GoalStatus { }

// ❌ 错误
struct learningGoal { }
class studyViewModel { }
```

**变量和函数命名**：使用 camelCase
```swift
// ✅ 正确
var completedCount: Int
func handleSwipe() { }

// ❌ 错误
var CompletedCount: Int
func HandleSwipe() { }
```

**常量命名**：使用 camelCase，或全大写（全局常量）
```swift
// ✅ 正确
let maxQueueSize = 100
let MAX_RETRY_COUNT = 3
```

**布尔值命名**：使用 `is`、`has`、`should` 前缀
```swift
// ✅ 正确
var isCompleted: Bool
var hasActiveGoal: Bool
var shouldReview: Bool

// ❌ 错误
var completed: Bool
var activeGoal: Bool
```

#### 访问控制

**原则**：最小权限原则，默认使用 `internal`，需要时再提升

```swift
// ✅ 正确
class StudyViewModel: ObservableObject {
    @Published var completedCount: Int = 0  // internal（默认）
    private var queue: [StudyCard] = []     // private（内部使用）
    
    func startStudy() { }                   // internal（可被 View 调用）
    private func loadQueue() { }            // private（内部方法）
}

// ❌ 错误：过度使用 public
public class StudyViewModel { }  // ❌ 不需要 public
```

#### 可选值处理

**原则**：安全处理可选值，避免强制解包

```swift
// ✅ 正确：使用可选绑定
if let goal = currentGoal {
    // 使用 goal
}

// ✅ 正确：使用 guard
guard let goal = currentGoal else {
    return
}
// 使用 goal

// ✅ 正确：使用 nil 合并
let count = goal?.totalWords ?? 0

// ❌ 错误：强制解包（除非确定不为 nil）
let count = goal!.totalWords  // ❌ 危险
```

#### 错误处理

**原则**：使用 `throws` 和 `Result` 类型，避免返回可选值表示错误

```swift
// ✅ 正确：使用 throws
func createGoal() throws -> LearningGoal {
    guard packId > 0 else {
        throw GoalServiceError.invalidPackId
    }
    // ...
}

// ✅ 正确：使用 Result
func fetchWords() async -> Result<[Word], Error> {
    // ...
}

// ❌ 错误：使用可选值表示错误
func createGoal() -> LearningGoal? {  // ❌ 无法区分错误类型
    // ...
}
```

### 2. SwiftUI 规范

#### 视图组件化

**原则**：将复杂视图拆分为小组件

```swift
// ✅ 正确：组件化
struct LearningHomeView: View {
    var body: some View {
        VStack {
            progressSection
            taskSection
            actionButtons
        }
    }
    
    private var progressSection: some View {
        VStack {
            Text("进度")
            ProgressView()
        }
    }
}

// ❌ 错误：所有代码都在 body 中
struct LearningHomeView: View {
    var body: some View {
        VStack {
            // 100+ 行代码...
        }
    }
}
```

#### 状态管理

**原则**：正确使用 `@State`、`@StateObject`、`@ObservedObject`

```swift
// ✅ 正确：使用 @StateObject（拥有所有权）
struct LearningHomeView: View {
    @StateObject private var viewModel = StudyViewModel()
}

// ✅ 正确：使用 @ObservedObject（观察外部对象）
struct ChildView: View {
    @ObservedObject var viewModel: StudyViewModel
}

// ✅ 正确：使用 @State（本地状态）
struct CardView: View {
    @State private var isExpanded = false
}

// ❌ 错误：在 View 中创建 @ObservedObject
struct LearningHomeView: View {
    @ObservedObject private var viewModel = StudyViewModel()  // ❌ 每次重建都会创建新实例
}
```

#### 性能优化

**原则**：避免不必要的视图重建

```swift
// ✅ 正确：使用 @Published 触发更新
class StudyViewModel: ObservableObject {
    @Published var completedCount: Int = 0  // 只有这个变化时才更新
}

// ✅ 正确：使用 Equatable 优化
struct WordCard: View, Equatable {
    let word: Word
    
    static func == (lhs: WordCard, rhs: WordCard) -> Bool {
        lhs.word.id == rhs.word.id
    }
}

// ❌ 错误：在 body 中创建新对象
struct LearningHomeView: View {
    var body: some View {
        VStack {
            Text("\(Date())")  // ❌ 每次重建都创建新 Date
        }
    }
}
```

### 3. 异步编程规范

**原则**：使用 `async/await`，避免回调地狱

```swift
// ✅ 正确：使用 async/await
func loadData() async throws -> [Word] {
    let words = try await wordRepository.fetchWords()
    return words
}

// ✅ 正确：在 ViewModel 中使用 Task
func startStudy() {
    Task {
        do {
            let words = try await loadData()
            await MainActor.run {
                self.words = words
            }
        } catch {
            // 错误处理
        }
    }
}

// ❌ 错误：使用回调
func loadData(completion: @escaping (Result<[Word], Error>) -> Void) {
    // ❌ 回调地狱
}
```

---

## 🔄 数据流规范

### 1. 数据流向

**单向数据流**：View → ViewModel → Service → Storage → Database

```
用户操作
    ↓
View（触发）
    ↓
ViewModel（处理）
    ↓
Service（业务逻辑）
    ↓
Storage（数据访问）
    ↓
Database（持久化）
```

### 2. 状态更新规范

**原则**：状态更新必须在主线程，使用 `@MainActor`

```swift
// ✅ 正确：使用 @MainActor
@MainActor
class StudyViewModel: ObservableObject {
    @Published var completedCount: Int = 0
    
    func updateCount() {
        completedCount += 1  // ✅ 自动在主线程
    }
    
    func asyncUpdate() async {
        let count = await fetchCount()
        await MainActor.run {
            self.completedCount = count  // ✅ 显式切换到主线程
        }
    }
}

// ❌ 错误：在后台线程更新 UI 状态
class StudyViewModel: ObservableObject {
    @Published var completedCount: Int = 0
    
    func updateCount() {
        DispatchQueue.global().async {
            self.completedCount += 1  // ❌ 可能崩溃
        }
    }
}
```

### 3. 队列索引映射规范

**核心原则**：Koloda 索引直接对应队列索引，使用智能同步机制

```swift
// ✅ 正确：队列索引映射
func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
    return viewModel?.queueCount ?? 0  // 直接返回队列数量
}

func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
    let queueIndex = index  // 直接使用 index 作为队列索引
    guard queueIndex >= 0 && queueIndex < queueCount else {
        return UIView()
    }
    return getCardView(at: queueIndex)
}

// ✅ 正确：智能同步
func updateUIView(_ uiView: KolodaView, context: Context) {
    let currentQueueCount = viewModel.queueCount
    let currentKolodaIndex = uiView.currentCardIndex
    
    // 检测索引超出范围
    if currentQueueCount > 0 && currentKolodaIndex >= currentQueueCount {
        uiView.resetCurrentCardIndex()
    }
    
    // 检测索引滞后（提前掌握）
    if coordinator.lastQueueCount > currentQueueCount && currentKolodaIndex > 0 {
        uiView.resetCurrentCardIndex()
    }
    
    coordinator.lastQueueCount = currentQueueCount
}
```

### 4. 提前掌握处理规范

**原则**：提前掌握时，队列减少，需要智能同步索引

```swift
// ✅ 正确：在 handleSwipe 中处理提前掌握
func handleSwipe(wordId: Int, direction: SwipeDirection, dwellTime: TimeInterval) {
    // 1. 更新学习记录
    learningRecords[wordId].recordSwipe(direction, dwellTime)
    
    // 2. 检查提前掌握
    if !exposureStrategy.shouldContinueExposure(for: record) {
        // 移除该单词的其他卡片
        let removed = queue.removeAll { $0.word.id == wordId && $0.id != currentCardId }
        earlyMasteredRemovedCount = removed
    }
    
    // 3. 更新统计
    completedCount += (1 + earlyMasteredRemovedCount)
    
    // 4. 移除当前卡片
    queue.removeFirst()
    
    // 5. 更新可见卡片
    visibleCards = Array(queue.prefix(3))
    
    // ⚠️ 注意：不在这里调用 reloadData()，让 updateUIView 检测并处理
}
```

---

## 🎨 UI/UX规范

### 1. 设计风格

**Tinder式（学习页）**
- 卡片堆叠：3层，scale 分别为 1.0、0.95、0.90
- 滑动阈值：25%（`kolodaSwipeThresholdRatioMargin`）
- 旋转角度：±15°（`rotationAngle = π/20`）
- 方向提示：绿色 ✓（右滑）、橙色 ✗（左滑）

**墨墨式（管理页）**
- 卡片布局：圆角 12pt，阴影轻微
- 进度条：蓝色已完成，灰色未完成
- 分组标题：`.headline` 字体，`.secondary` 颜色

### 2. 动画规范

**原则**：流畅 60fps，使用 Spring 动画

```swift
// ✅ 正确：Spring 动画
.animation(.spring(response: 0.35, dampingFraction: 0.75), value: offset)

// ✅ 正确：交互式动画
.animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: offset)

// ❌ 错误：线性动画（不够自然）
.animation(.linear(duration: 0.3), value: offset)
```

### 3. 颜色规范

```swift
// 主色调
Color.blue.opacity(0.6)      // 背景渐变
Color.purple.opacity(0.8)    // 背景渐变

// 反馈色
Color.green                  // 右滑（认识）
Color.orange                 // 左滑（不认识）

// 文字色
Color.primary                // 主要文字
Color.secondary              // 次要文字
```

### 4. 字体规范

```swift
.largeTitle   // 单词主体 (48pt, bold)
.title2       // 音标 (22pt, regular)
.body         // 释义/短语 (17pt)
.caption      // 次要信息 (12pt)
```

---

## ⚡ 性能规范

### 1. 滑动性能（对标 Tinder 60fps）

**原则**：预加载、视图重用、避免主线程阻塞

```swift
// ✅ 正确：预加载下一张卡片
private func preloadNextCardIfNeeded(queueIndex: Int) {
    guard queueIndex + 1 < queueCount else { return }
    if preloadedCards[queueIndex + 1] == nil {
        preloadedCards[queueIndex + 1] = viewModel.getCard(at: queueIndex + 1)
    }
}

// ✅ 正确：视图重用池
private var cardViewPool: [WordCardUIView] = []
private func dequeueCardView() -> WordCardUIView {
    if let reused = cardViewPool.popLast() {
        return reused
    }
    return WordCardUIView()
}

// ❌ 错误：每次创建新视图
func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
    return WordCardUIView()  // ❌ 性能差
}
```

### 2. 内存管理

**原则**：及时释放不需要的对象，限制队列大小

```swift
// ✅ 正确：限制队列大小
private var queue: [StudyCard] = [] {
    didSet {
        // 限制最多保留 100 张卡片
        if queue.count > 100 {
            queue = Array(queue.suffix(100))
        }
    }
}

// ✅ 正确：及时清理缓存
func clearCache() {
    preloadedCards.removeAll()
    cardViewPool.removeAll()
}
```

### 3. 数据库查询优化

**原则**：使用索引、批量查询、避免 N+1 查询

```swift
// ✅ 正确：批量查询
func fetchWords(ids: [Int]) throws -> [Word] {
    let placeholders = ids.map { _ in "?" }.joined(separator: ",")
    let query = "SELECT * FROM words WHERE id IN (\(placeholders))"
    return try db.query(query, parameters: ids)
}

// ❌ 错误：N+1 查询
func fetchWords(ids: [Int]) throws -> [Word] {
    return ids.map { id in
        try db.query("SELECT * FROM words WHERE id = ?", parameters: [id])
    }.flatMap { $0 }
}
```

---

## 🧪 测试规范

### 1. 单元测试

**原则**：测试业务逻辑，Mock 依赖

```swift
// ✅ 正确：测试 ViewModel
class StudyViewModelTests: XCTestCase {
    var viewModel: StudyViewModel!
    var mockGoalService: MockGoalService!
    
    override func setUp() {
        mockGoalService = MockGoalService()
        viewModel = StudyViewModel(goalService: mockGoalService)
    }
    
    func testStartStudy() async {
        // Given
        mockGoalService.mockGoal = LearningGoal(...)
        
        // When
        await viewModel.startStudy()
        
        // Then
        XCTAssertEqual(viewModel.completedCount, 0)
    }
}
```

### 2. UI 测试

**原则**：测试关键用户流程

```swift
// ✅ 正确：测试学习流程
func testLearningFlow() {
    let app = XCUIApplication()
    app.launch()
    
    // 1. 创建学习目标
    app.buttons["创建学习目标"].tap()
    app.buttons["确认创建"].tap()
    
    // 2. 开始学习
    app.buttons["开始学习"].tap()
    
    // 3. 滑动卡片
    let card = app.otherElements["wordCard"]
    card.swipeRight()
    
    // 4. 验证进度更新
    XCTAssertTrue(app.staticTexts["进度: 1/100"].exists)
}
```

---

## 📝 文档规范

### 1. 代码注释

**原则**：关键逻辑必须注释，使用 Markdown 格式

```swift
// ✅ 正确：关键逻辑注释
/// 处理卡片滑动
/// - Parameters:
///   - wordId: 单词ID
///   - direction: 滑动方向（.left 或 .right）
///   - dwellTime: 停留时间（秒）
/// - Note: 提前掌握时会移除该单词的其他卡片
func handleSwipe(wordId: Int, direction: SwipeDirection, dwellTime: TimeInterval) {
    // ⭐ 核心逻辑：检查提前掌握
    if !exposureStrategy.shouldContinueExposure(for: record) {
        // 移除该单词的其他卡片
    }
}

// ❌ 错误：无意义的注释
func handleSwipe() {
    // 处理滑动  // ❌ 注释没有提供额外信息
}
```

### 2. 文档文件

**原则**：重要功能必须有文档说明

- `QUEUE_INDEX_FLOW_DETAILED.md` - 队列索引映射流程
- `COMMERCIAL_GRADE_SOLUTION.md` - 商业级解决方案
- `SWIPE_LOGIC_ANALYSIS.md` - 滑动逻辑分析

---

## 🔀 Git工作流

### 1. 分支规范

```
main          # 主分支（生产环境）
develop       # 开发分支
feature/*     # 功能分支
bugfix/*      # Bug修复分支
hotfix/*      # 紧急修复分支
```

### 2. 提交信息规范

**格式**：`<type>(<scope>): <subject>`

**类型**：
- `feat`: 新功能
- `fix`: Bug修复
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建/工具相关

**示例**：
```
feat(study): 实现队列索引映射 + 智能同步
fix(koloda): 修复提前掌握导致索引不同步问题
docs(architecture): 更新架构设计文档
refactor(goal): 重构 GoalService，移除重复代码
```

### 3. 代码审查

**原则**：所有代码必须经过 Code Review

**检查清单**：
- [ ] 符合架构规范
- [ ] 符合代码规范
- [ ] 有单元测试
- [ ] 有文档说明
- [ ] 性能考虑
- [ ] 错误处理

---

## ⚠️ 错误处理规范

### 1. 错误类型定义

**原则**：使用枚举定义错误类型

```swift
// ✅ 正确：定义错误类型
enum GoalServiceError: LocalizedError {
    case invalidPackId
    case insufficientQuota
    case dataIncomplete(actual: Int, expected: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidPackId:
            return "无效的词库ID"
        case .insufficientQuota:
            return "额度不足"
        case .dataIncomplete(let actual, let expected):
            return "词库数据不完整：实际可用 \(actual) 个单词，但词库声明 \(expected) 个（缺失 \(String(format: "%.1f", (1.0 - Double(actual)/Double(expected)) * 100))%）"
        }
    }
}
```

### 2. 错误处理策略

**原则**：在 ViewModel 中处理错误，向用户展示友好提示

```swift
// ✅ 正确：在 ViewModel 中处理错误
func createGoal() async {
    do {
        let goal = try await goalService.createGoal(...)
        // 成功处理
    } catch GoalServiceError.dataIncomplete(let actual, let expected) {
        // 显示友好错误提示
        errorMessage = "词库数据不完整，请联系客服"
    } catch {
        // 通用错误处理
        errorMessage = "创建目标失败：\(error.localizedDescription)"
    }
}
```

---

## 🔒 安全规范

### 1. API Key 管理

**原则**：不在代码中硬编码 API Key

```swift
// ✅ 正确：使用环境变量或 Keychain
struct DeepSeekConfig {
    static let apiKey: String = {
        if let key = ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"] {
            return key
        }
        // 开发环境回退
        return "sk-ca514461699d4d39bd03936acfaa6616"
    }()
}

// ❌ 错误：硬编码 API Key
struct DeepSeekConfig {
    static let apiKey = "sk-ca514461699d4d39bd03936acfaa6616"  // ❌ 不安全
}
```

### 2. 数据加密

**原则**：敏感数据使用 Keychain 存储

```swift
// ✅ 正确：使用 Keychain
func storeAuthToken(_ token: String) {
    KeychainHelper.save(token, forKey: "auth_token")
}
```

---

## 📦 依赖管理

### 1. 第三方库使用

**原则**：谨慎引入第三方库，优先使用系统框架

**已使用的第三方库**：
- **Koloda**：卡片滑动库（已手动集成）

**禁止使用的库**：
- ❌ 网络库（使用系统 `URLSession`）
- ❌ JSON 解析库（使用系统 `Codable`）
- ❌ 图片加载库（使用系统 `AsyncImage`）

### 2. 依赖版本管理

**原则**：固定版本号，避免自动更新

```swift
// ✅ 正确：固定版本
dependencies: [
    .package(url: "https://github.com/...", .exact("1.0.0"))
]

// ❌ 错误：自动更新
dependencies: [
    .package(url: "https://github.com/...", from: "1.0.0")  // ❌ 可能自动更新
]
```

---

## 🎯 核心需求实现规范

### 1. 队列索引映射

**必须遵循**：`QUEUE_INDEX_FLOW_DETAILED.md` 中的流程

- ✅ Koloda 索引直接对应队列索引
- ✅ 智能同步机制（检测索引超出和滞后）
- ✅ 提前掌握时正确处理索引同步

### 2. 提前掌握逻辑

**必须遵循**：在 `handleSwipe` 中实现

- ✅ 检测提前掌握条件
- ✅ 移除该单词的其他卡片
- ✅ 更新 `completedCount`（当前卡片 + 提前移除的卡片）
- ✅ 不立即调用 `reloadData()`，让 `updateUIView` 检测并处理

### 3. 停留时间追踪

**必须遵循**：精确记录每个单词的停留时间

- ✅ 卡片显示时开始计时（`didShowCardAt`）
- ✅ 卡片滑动时停止计时（`didSwipeCardAt`）
- ✅ 记录到 `WordLearningRecord.avgDwellTime`
- ✅ 用于每日报告排序

### 4. 学习目标管理

**必须遵循**：通过 `GoalService` 统一管理

- ✅ 创建目标：`GoalService.createGoal()`
- ✅ 放弃目标：`GoalService.abandonGoal()`
- ✅ 查询目标：`GoalService.getActiveGoal()`
- ❌ 禁止：在 View 中直接操作数据库

---

## 📊 性能指标

### 目标指标（对标 Tinder）

- **滑卡帧率**：稳定 60 FPS
- **手势响应**：<16ms 延迟
- **动画流畅度**：120fps ProMotion 支持
- **崩溃率**：<0.1%
- **启动时间**：<2秒
- **内存占用**：<150MB

---

## 🔄 持续改进

### 代码审查检查清单

每次提交代码前，检查：
- [ ] 符合架构规范（MVVM）
- [ ] 符合代码规范（命名、注释）
- [ ] 有错误处理
- [ ] 有性能考虑
- [ ] 有单元测试（关键逻辑）
- [ ] 有文档说明（新功能）

### 定期重构

- **每月**：代码审查，识别重复代码
- **每季度**：架构审查，优化性能瓶颈
- **每半年**：技术债务清理

---

## 📚 参考文档

- `README.md` - 项目总览
- `QUEUE_INDEX_FLOW_DETAILED.md` - 队列索引映射流程
- `COMMERCIAL_GRADE_SOLUTION.md` - 商业级解决方案
- `ARCHITECTURE_REVIEW_REPORT.md` - 架构审查报告
- `DATA_STRUCTURE_ANALYSIS_REPORT.md` - 数据结构分析

---

## ✅ 总结

本规则文档涵盖了 NFwords 项目的所有开发规范，包括：
- ✅ 架构规范（MVVM）
- ✅ 代码规范（Swift/SwiftUI）
- ✅ 数据流规范（队列索引映射）
- ✅ UI/UX规范（Tinder式/墨墨式）
- ✅ 性能规范（60fps）
- ✅ 测试规范
- ✅ 文档规范
- ✅ Git工作流
- ✅ 错误处理
- ✅ 安全规范
- ✅ 依赖管理

**所有开发人员必须遵循本规则文档，确保代码质量和项目一致性。**

---

**最后更新**：2025-01-XX  
**版本**：v1.0.0  
**维护者**：开发团队

