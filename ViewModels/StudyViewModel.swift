//
//  StudyViewModel.swift
//  NFwordsDemo
//
//  Created by 甘名杨 on 2025/11/1.
//  Updated by 甘名杨 on 2025/11/3.
//

//
//  StudyViewModel.swift
//  NFwords Demo
//
//  学习逻辑ViewModel - 整合停留时间追踪
//
import SwiftUI
import Foundation
import Combine

class StudyViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var visibleCards: [StudyCard] = []
    @Published var completedCount: Int = 0
    @Published var rightSwipeCount: Int = 0
    @Published var leftSwipeCount: Int = 0
    @Published var studyTime: TimeInterval = 0
    @Published var isCompleted: Bool = false
    @Published var currentGoal: LearningGoal?
    @Published var currentTask: DailyTask?
    @Published var currentReport: DailyReport?
    @Published var queueCount: Int = 0  // ⭐ 新增：用于触发 totalCount 的 UI 更新
    
    // MARK: - Private Properties
    private var queue: [StudyCard] = [] {
        didSet {
            // ⭐ 修复：当队列变化时，更新 queueCount 以触发 UI 更新
            queueCount = queue.count
        }
    }
    private var learningRecords: [Int: WordLearningRecord] = [:]  // wid -> record
    private var startTime = Date()
    private var timer: Timer?
    private let sessionId = UUID().uuidString  // 会话ID
    private var currentPackId: Int = 2001  // 当前词书ID（默认CET-4）
    private var hasInitialized = false  // 标记是否已初始化队列
    
    // MARK: - Dependencies
    let dwellTimeTracker = DwellTimeTracker()
    let taskScheduler = TaskScheduler()
    let reportViewModel = ReportViewModel()
    private let wordRepository = WordRepository.shared
    private let exposureStorage = WordExposureStorage()
    private let eventStorage = ExposureEventStorage()
    private let taskStorage = DailyTaskStorage()
    private let goalStorage = LearningGoalStorage()
    private let reportStorage = DailyReportStorage()
    
    // 核心组件 ⭐
    private var exposureStrategy: ExposureStrategy = ExposureStrategyFactory.defaultStrategy()
    
    // MARK: - Computed Properties
    // ⭐ 修复：使用 @Published 属性确保 UI 更新
    var totalCount: Int {
        // ⭐ 修复：始终使用 queueCount + completedCount 来计算总数
        // 这样进度会随着队列变化而更新
        let total = queueCount + completedCount
        
        #if DEBUG
        if let task = currentTask, task.totalExposures > 0 {
            print("[ViewModel] totalCount: queueCount(\(queueCount)) + completedCount(\(completedCount)) = \(total), task.totalExposures=\(task.totalExposures)")
        } else {
            print("[ViewModel] totalCount: queueCount(\(queueCount)) + completedCount(\(completedCount)) = \(total)")
        }
        #endif
        
        return total
    }
    
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    var studyTimeFormatted: String {
        let minutes = Int(studyTime) / 60
        let seconds = Int(studyTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var remainingExposures: Int {
        totalCount - completedCount
    }
    
    // MARK: - Initialization
    init() {
        loadCurrentGoalAndTask()
        setupDemoData()
        startTimer()
    }
    
    // MARK: - 从数据库加载当前目标和任务
    private func loadCurrentGoalAndTask() {
        do {
            currentGoal = try goalStorage.fetchCurrent()
            currentTask = try taskStorage.fetchToday()
            
            if let goal = currentGoal {
                currentPackId = goal.packId
                
                // 根据目标选择曝光策略 ⭐ 新增
                exposureStrategy = ExposureStrategyFactory.strategyForGoal(goal)
                
                #if DEBUG
                print("[ViewModel] Loaded goal: \(goal.packName), Day \(goal.currentDay)/\(goal.durationDays)")
                print("[ViewModel] Using strategy: \(exposureStrategy.strategyName)")
                #endif
            }
            
            if let task = currentTask {
                #if DEBUG
                print("[ViewModel] Loaded task: \(task.newWordsCount) new + \(task.reviewWordsCount) review")
                #endif
            }
        } catch {
            #if DEBUG
            print("[ViewModel] ERROR loading goal/task: \(error)")
            #endif
        }
    }
    
    // MARK: - Setup
    private func setupDemoData() {
        // 避免重复初始化
        guard !hasInitialized else {
            #if DEBUG
            print("[ViewModel] setupDemoData: already initialized, skipping")
            #endif
            return
        }
        
        #if DEBUG
        print("[ViewModel] setupDemoData: loading study cards (first time)...")
        #endif
        
        do {
            // ⭐ 修复：根据任务中的单词ID列表来加载卡片，而不是使用固定的 limit
            let (cards, records): ([StudyCard], [Int: WordLearningRecord])
            
            if let task = currentTask, !task.newWords.isEmpty || !task.reviewWords.isEmpty {
                // 使用任务中的单词ID列表
                #if DEBUG
                print("[ViewModel] Loading cards from task: \(task.newWords.count) new + \(task.reviewWords.count) review")
                #endif
                
                // 根据曝光策略计算曝光次数
                // ⭐ 修复：使用任务的 totalExposures 来估算每个单词的曝光次数
                // 如果任务有 totalExposures，使用它来计算；否则使用策略默认值
                let newWordExposures: Int
                let reviewWordExposures: Int
                
                if task.totalExposures > 0 {
                    // 根据任务的总曝光次数来估算
                    // 假设：新词占大部分曝光，复习词占小部分
                    let estimatedNewExposures = task.newWordsCount > 0 ? 
                        (task.totalExposures * 8 / 10) / max(task.newWordsCount, 1) : 10
                    let estimatedReviewExposures = task.reviewWordsCount > 0 ?
                        (task.totalExposures * 2 / 10) / max(task.reviewWordsCount, 1) : 5
                    
                    newWordExposures = max(estimatedNewExposures, 5)  // 最少5次
                    reviewWordExposures = max(estimatedReviewExposures, 3)  // 最少3次
                } else {
                    // 使用策略默认值
                    let defaultRecord = WordLearningRecord.initial(wid: 0, targetExposures: 10)
                    newWordExposures = exposureStrategy.calculateExposures(for: defaultRecord)
                    reviewWordExposures = max(newWordExposures / 2, 5)  // 复习词通常是新词的一半，最少5次
                }
                
                #if DEBUG
                print("[ViewModel] Exposure settings: new=\(newWordExposures), review=\(reviewWordExposures)")
                #endif
                
                (cards, records) = try wordRepository.fetchStudyCardsForTask(
                    newWordIds: task.newWords,
                    reviewWordIds: task.reviewWords,
                    newWordExposures: newWordExposures,
                    reviewWordExposures: reviewWordExposures
                )
                
                #if DEBUG
                print("[ViewModel] Task-based loading: \(cards.count) cards from \(task.newWords.count + task.reviewWords.count) words")
                #endif
            } else {
                // 如果没有任务，使用默认方式（向后兼容）
                #if DEBUG
                print("[ViewModel] No task found, using default loading (limit: 40)")
                #endif
                (cards, records) = try wordRepository.fetchStudyCards(limit: 40)
            }
            
            #if DEBUG
            print("[ViewModel] Repository returned: \(cards.count) cards, \(records.count) records")
            #endif
            
            if cards.isEmpty {
                #if DEBUG
                print("[ViewModel] No cards from repository, using fallback")
                #endif
                throw NSError(domain: "StudyViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No cards"])
            }
            
            learningRecords = records
            queue = optimizeQueue(cards)
            
            #if DEBUG
            print("[ViewModel] Card queue prepared: \(queue.count) cards")
            #endif
            
        } catch {
            #if DEBUG
            print("[ViewModel] ERROR: \(error.localizedDescription), using fallback data")
            #endif
            
            // 回退到示例数据
            learningRecords.removeAll()
            var fallbackCards: [StudyCard] = []
            
            for word in Word.examples {
                var record = WordLearningRecord.initial(wid: word.id, targetExposures: 10)
                
                // 使用曝光策略计算目标次数 ⭐ 新增
                let targetExposures = exposureStrategy.calculateExposures(for: record)
                record.targetExposures = targetExposures
                record.remainingExposures = targetExposures
                
                learningRecords[word.id] = record
                
                // ⭐ P0 修复：移除 record 参数
                for _ in 0..<targetExposures {
                    fallbackCards.append(StudyCard(word: word))
                }
            }
            
            queue = optimizeQueue(fallbackCards)
            
            #if DEBUG
            print("[ViewModel] Fallback queue: \(queue.count) cards from \(Word.examples.count) example words")
            #endif
        }
        
        loadNextCards()
        
        // 标记已初始化
        hasInitialized = true
        
        #if DEBUG
        print("[ViewModel] Visible cards: \(visibleCards.count)")
        if visibleCards.isEmpty {
            print("[ViewModel] ERROR: visibleCards is empty!")
        } else {
            for (index, card) in visibleCards.enumerated() {
                print("[ViewModel]   Card \(index + 1): \(card.word.word) (wid: \(card.word.id))")
            }
        }
        print("[ViewModel] Initialization complete, hasInitialized=true")
        #endif
    }
    
    /// 优化队列（避免相同单词连续出现）
    /// ⭐ P2 修复：改进队列优化逻辑，确保所有卡片都被正确处理，不会丢失或过度延迟
    private func optimizeQueue(_ queue: [StudyCard]) -> [StudyCard] {
        var optimized: [StudyCard] = []
        var lastWordId: Int? = nil
        var buffer: [StudyCard] = []
        let maxBufferSize = 3  // 缓冲区最大大小
        
        for card in queue {
            if card.word.id == lastWordId {
                buffer.append(card)
                
                // ⭐ P2 修复：当缓冲区达到最大大小时，分批插入，避免过度积累
                if buffer.count >= maxBufferSize {
                    // 插入前 maxBufferSize-1 张卡片，保留最后一张
                    optimized.append(contentsOf: buffer.prefix(maxBufferSize - 1))
                    buffer = Array(buffer.suffix(1))  // 保留最后一张
                }
            } else {
                // 遇到新单词，先处理缓冲区
                if !buffer.isEmpty {
                    optimized.append(contentsOf: buffer)
                    buffer = []
                }
                
                optimized.append(card)
                lastWordId = card.word.id
            }
        }
        
        // ⭐ P2 修复：确保所有剩余的缓冲区卡片都被添加
        if !buffer.isEmpty {
            optimized.append(contentsOf: buffer)
        }
        
        #if DEBUG
        // 验证：确保没有丢失卡片
        if optimized.count != queue.count {
            print("[ViewModel] ⚠️ 警告：队列优化后卡片数量不匹配！原始: \(queue.count), 优化后: \(optimized.count)")
        }
        #endif
        
        return optimized
    }
    
    // MARK: - 加载卡片
    private func loadNextCards() {
        visibleCards = Array(queue.prefix(3))
    }
    
    // MARK: - 处理滑动 ⭐ 核心（整合停留时间追踪 + 数据库写入）
    func handleSwipe(wordId: Int, direction: SwipeDirection, dwellTime: TimeInterval) {
        #if DEBUG
        print("[ViewModel] handleSwipe: wid=\(wordId), direction=\(direction.rawValue), dwell=\(String(format: "%.2f", dwellTime))s")
        print("[ViewModel] Before swipe: queue=\(queue.count), visible=\(visibleCards.count), completed=\(completedCount)")
        #endif
        
        // ⭐ P0 修复：在开始时保存当前卡片的 UUID，用于后续判断
        let currentCardId = visibleCards.first?.id
        
        // 1. 更新学习记录
        if var record = learningRecords[wordId] {
            record.recordSwipe(direction: direction, dwellTime: dwellTime)
            learningRecords[wordId] = record
            
            #if DEBUG
            print("[Swipe] wid=\(wordId), dir=\(direction.rawValue), right=\(record.swipeRightCount), left=\(record.swipeLeftCount), remain=\(record.remainingExposures)")
            #endif
            
            // 1a. 记录曝光事件到数据库
            Task {
                do {
                    try eventStorage.recordSwipe(
                        packId: currentPackId,
                        wid: wordId,
                        direction: direction,
                        dwellTime: dwellTime,
                        sessionId: sessionId
                    )
                } catch {
                    #if DEBUG
                    print("[ViewModel] ERROR: Failed to record swipe event: \(error)")
                    #endif
                }
            }
        }
        
        // 2. 检查是否提前掌握（使用曝光策略）⭐ 新增（提前到步骤2，以便在步骤3中使用结果）
        let updatedRecord = learningRecords[wordId]!
        var earlyMasteredRemovedCount = 0  // ⭐ P1 修复：记录提前掌握移除的卡片数
        
        if !exposureStrategy.shouldContinueExposure(for: updatedRecord) {
            // 提前掌握，从队列移除该单词的所有剩余卡片
            // ⚠️ 注意：这里移除的是除了当前卡片之外的其他卡片
            // 当前卡片会在步骤5中正常移除
            let remainingCards = queue.filter { $0.word.id == wordId }
            earlyMasteredRemovedCount = remainingCards.count - 1  // 减去当前卡片（会在步骤5移除）
            
            // ⭐ P0 修复：使用保存的 currentCardId 而不是 queue.first?.id
            var removed = 0
            queue.removeAll { card in
                if card.word.id == wordId && card.id != currentCardId {
                    removed += 1
                    return true
                }
                return false
            }
            
            #if DEBUG
            print("[Strategy] Word \(wordId) mastered early, removed \(removed) additional cards from queue")
            print("[Strategy] Reason: right=\(updatedRecord.swipeRightCount), dwell=\(String(format: "%.1f", updatedRecord.avgDwellTime))s")
            #endif
        }
        
        // 3. 更新统计
        // ⭐ P1 修复：计算实际完成的卡片数（当前卡片 + 提前掌握移除的卡片）
        let totalCardsCompleted = 1 + max(0, earlyMasteredRemovedCount)
        completedCount += totalCardsCompleted
        
        #if DEBUG
        print("[ViewModel] ⭐ 进度更新: completedCount=\(completedCount), queueCount=\(queueCount), totalCount=\(totalCount)")
        #endif
        
        switch direction {
        case .right:
            rightSwipeCount += 1
        case .left:
            leftSwipeCount += 1
        }
        
        #if DEBUG
        if earlyMasteredRemovedCount > 0 {
            print("[ViewModel] ⭐ 提前掌握：当前卡片(1) + 提前移除(\(earlyMasteredRemovedCount)) = 总计完成(\(totalCardsCompleted))")
        }
        #endif
        
        // 4. 更新当前任务进度
        if var task = currentTask {
            task.completedExposures = completedCount
            currentTask = task
        }
        
        // 5. 从队列移除当前卡片（关键修复：先移除 queue，再更新 visibleCards）⭐
        if !queue.isEmpty {
            queue.removeFirst()
            
            #if DEBUG
            print("[ViewModel] Removed from queue, queue now: \(queue.count)")
            #endif
        }
        
        // 6. 重新计算可见卡片（始终是 queue 的前 3 张，避免重复）⭐
        visibleCards = Array(queue.prefix(3))
        
        #if DEBUG
        print("[ViewModel] Updated visibleCards from queue, visible now: \(visibleCards.count)")
        if let first = visibleCards.first {
            print("[ViewModel] New top card: \(first.word.word) (wid: \(first.word.id))")
        }
        #endif
        
        // 7. 下一张卡片的计时由 KolodaCardsCoordinator 负责（在 didSwipeCardAt 中）
        // 这里不再重复启动计时，避免冲突
        
        // 8. 检查是否完成
        if queue.isEmpty && visibleCards.isEmpty {
            #if DEBUG
            print("[ViewModel] Study completed, generating report...")
            #endif
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.completeStudy()
            }
        }
        
        #if DEBUG
        print("[ViewModel] After swipe: queue=\(queue.count), visible=\(visibleCards.count), completed=\(completedCount)")
        #endif
    }
    
    // MARK: - 开始当前卡片计时
    func startCurrentCardTracking() {
        if let currentCard = visibleCards.first {
            dwellTimeTracker.startTracking(wordId: currentCard.word.id)
        }
    }
    
    // MARK: - 获取学习记录（用于UI显示）
    /// 获取指定单词的学习记录
    func getLearningRecord(for wordId: Int) -> WordLearningRecord? {
        return learningRecords[wordId]
    }
    
    // MARK: - 获取队列信息（用于 Koloda 数据源）
    /// ⭐ 修复：根据索引获取队列中的卡片（Koloda 需要根据索引获取卡片）
    func getCard(at index: Int) -> StudyCard? {
        guard index >= 0 && index < queue.count else { return nil }
        return queue[index]
    }
    
    /// ⭐ 修复：获取队列中的卡片数量（Koloda 需要知道总卡片数）
    /// 注意：使用 @Published 的 queueCount 属性，而不是计算属性
    var currentQueueCount: Int {
        return queueCount  // 使用 @Published 属性
    }
    
    // MARK: - 完成学习（保存到数据库）⭐
    private func completeStudy() {
        isCompleted = true
        timer?.invalidate()
        dwellTimeTracker.stopTracking()
        
        // 生成学习报告（使用ReportViewModel）⭐
        guard let goal = currentGoal else { return }
        
        let report = reportViewModel.generateDailyReport(
            goal: goal,
            day: goal.currentDay,
            records: learningRecords,
            duration: studyTime,
            totalExposures: completedCount,
            words: Word.examples
        )
        
        currentReport = report
        
        // 保存学习数据到数据库 ⭐
        Task {
            await saveStudyDataToDatabase(report: report)
        }
        
        // 延迟后显示报告
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("📊 学习完成，已生成报告")
            print("💡 停留最长的10个词可用于生成AI短文")
        }
    }
    
    // MARK: - 保存学习数据到数据库
    private func saveStudyDataToDatabase(report: DailyReport) async {
        do {
            #if DEBUG
            print("💾 开始保存学习数据到数据库...")
            #endif
            
            // 1. 保存单词曝光数据（word_exposure）
            try exposureStorage.batchSaveFromLearningRecords(
                packId: currentPackId,
                records: learningRecords
            )
            #if DEBUG
            print("  ✅ 已保存 \(learningRecords.count) 个单词的曝光数据")
            #endif
            
            // 2. 保存每日报告（daily_reports_local）
            let reportId = try reportStorage.insert(report)
            #if DEBUG
            print("  ✅ 已保存每日报告: ID=\(reportId)")
            #endif
            
            // 3. 更新任务状态（daily_tasks_local）
            if var task = currentTask {
                task.completedExposures = completedCount
                task.status = .completed
                task.endTime = Date()
                try taskStorage.update(task)
                #if DEBUG
                print("  ✅ 已更新任务状态: ID=\(task.id)")
                #endif
            }
            
            // 4. 更新学习目标进度（learning_goals_local）
            if var goal = currentGoal {
                goal.completedWords += report.totalWordsStudied
                goal.completedExposures += report.totalExposures
                // 如果不是最后一天，currentDay + 1
                if goal.currentDay < goal.durationDays {
                    goal.currentDay += 1
                } else {
                    goal.status = .completed
                }
                try goalStorage.update(goal)
                
                // 更新内存中的 currentGoal
                currentGoal = goal
                
                #if DEBUG
                print("  ✅ 已更新学习目标: 第\(goal.currentDay)天, 完成\(goal.completedWords)词")
                #endif
            }
            
            #if DEBUG
            print("💾 学习数据已全部保存到数据库！")
            #endif
            
        } catch {
            #if DEBUG
            print("❌ 保存数据库失败: \(error)")
            #endif
        }
    }
    
    // MARK: - Timer
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.studyTime = Date().timeIntervalSince(self.startTime)
        }
    }
    
    // MARK: - Public Methods
    
    /// 重置 ViewModel 状态（用于重置学习进度或重新开始）
    func reset() {
        #if DEBUG
        print("[ViewModel] Resetting ViewModel state...")
        #endif
        
        timer?.invalidate()
        dwellTimeTracker.reset()
        
        queue.removeAll()
        learningRecords.removeAll()
        visibleCards.removeAll()
        completedCount = 0
        rightSwipeCount = 0
        leftSwipeCount = 0
        studyTime = 0
        isCompleted = false
        currentReport = nil
        hasInitialized = false
        startTime = Date()
        
        // 重新加载目标和任务
        loadCurrentGoalAndTask()
        
        // 重新初始化数据
        setupDemoData()
        
        // 重新启动计时器
        startTimer()
        
        #if DEBUG
        print("[ViewModel] Reset complete, ready for new session")
        #endif
    }
    
    deinit {
        timer?.invalidate()
    }
}
