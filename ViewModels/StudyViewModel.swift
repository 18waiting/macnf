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
    
    // MARK: - Private Properties
    private var queue: [StudyCard] = []
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
    var totalCount: Int {
        currentTask?.totalExposures ?? (queue.count + completedCount)
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
            let (cards, records) = try wordRepository.fetchStudyCards(limit: 40)
            
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
                
                for _ in 0..<targetExposures {
                    fallbackCards.append(StudyCard(word: word, record: record))
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
    private func optimizeQueue(_ queue: [StudyCard]) -> [StudyCard] {
        var optimized: [StudyCard] = []
        var lastWordId: Int? = nil
        var buffer: [StudyCard] = []
        
        for card in queue {
            if card.word.id == lastWordId {
                buffer.append(card)
            } else {
                optimized.append(card)
                lastWordId = card.word.id
                
                // 插入缓冲区
                if !buffer.isEmpty && buffer.count < 3 {
                    optimized.append(contentsOf: buffer)
                    buffer = []
                }
            }
        }
        
        optimized.append(contentsOf: buffer)
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
        
        // 2. 更新统计
        completedCount += 1
        
        switch direction {
        case .right:
            rightSwipeCount += 1
        case .left:
            leftSwipeCount += 1
        }
        
        // 3. 更新当前任务进度
        if var task = currentTask {
            task.completedExposures = completedCount
            currentTask = task
        }
        
        // 4. 检查是否提前掌握（使用曝光策略）⭐ 新增
        let updatedRecord = learningRecords[wordId]!
        if !exposureStrategy.shouldContinueExposure(for: updatedRecord) {
            // 提前掌握，从队列移除该单词的所有剩余卡片
            let removedCount = queue.removeAll { $0.word.id == wordId }
            #if DEBUG
            print("[Strategy] Word \(wordId) mastered early, removed \(removedCount) cards from queue")
            print("[Strategy] Reason: right=\(updatedRecord.swipeRightCount), dwell=\(String(format: "%.1f", updatedRecord.avgDwellTime))s")
            #endif
        }
        
        // 5. 从队列移除卡片（关键修复：先移除 queue，再更新 visibleCards）⭐
        if !queue.isEmpty {
            queue.removeFirst()
            
            #if DEBUG
            print("[ViewModel] Removed from queue, queue now: \(queue.count)")
            #endif
            
            // 6. 重新计算可见卡片（始终是 queue 的前 3 张，避免重复）⭐
            visibleCards = Array(queue.prefix(3))
            
            #if DEBUG
            print("[ViewModel] Updated visibleCards from queue, visible now: \(visibleCards.count)")
            if let first = visibleCards.first {
                print("[ViewModel] New top card: \(first.word.word) (wid: \(first.word.id))")
            }
            #endif
            
            // 7. 延迟启动下一张卡片的计时（给UI动画时间）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let nextCard = self.visibleCards.first {
                    #if DEBUG
                    print("[ViewModel] Starting tracking for next card: wid=\(nextCard.word.id)")
                    #endif
                    self.dwellTimeTracker.startTracking(wordId: nextCard.word.id)
                }
            }
        }
        
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
