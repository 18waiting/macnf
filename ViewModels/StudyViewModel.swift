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
    
    // MARK: - Dependencies
    let dwellTimeTracker = DwellTimeTracker()
    let taskScheduler = TaskScheduler()
    let reportViewModel = ReportViewModel()
    
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
        setupDemoData()
        startTimer()
    }
    
    // MARK: - Setup
    private func setupDemoData() {
        // 生成学习队列（每个单词重复10次）
        var tempQueue: [StudyCard] = []
        var cardIdCounter = 0  // 用于生成唯一的卡片ID
        
        for word in Word.examples {
            // 初始化学习记录
            let record = WordLearningRecord.initial(wid: word.id, targetExposures: 10)
            learningRecords[word.id] = record
            
            // 每个单词添加10次到队列
            for _ in 1...10 {
                cardIdCounter += 1
                tempQueue.append(StudyCard(
                    id: cardIdCounter,
                    word: word,
                    record: record
                ))
            }
        }
        
        // 随机打乱
        tempQueue.shuffle()
        
        // 优化队列（避免连续相同）
        queue = optimizeQueue(tempQueue)
        
        // 加载前3张卡片
        loadNextCards()
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
    
    // MARK: - 处理滑动 ⭐ 核心（整合停留时间追踪）
    func handleSwipe(wordId: Int, direction: SwipeDirection, dwellTime: TimeInterval) {
        // 1. 更新学习记录
        if var record = learningRecords[wordId] {
            record.recordSwipe(direction: direction, dwellTime: dwellTime)
            learningRecords[wordId] = record
            
            print("""
                📊 单词学习记录：
                wid: \(wordId)
                方向: \(direction.rawValue)
                停留: \(String(format: "%.2f", dwellTime))秒 ⭐
                右滑: \(record.swipeRightCount)次
                左滑: \(record.swipeLeftCount)次
                平均停留: \(String(format: "%.2f", record.avgDwellTime))秒 ⭐
                剩余: \(record.remainingExposures)次 ⭐
                熟悉度: \(record.familiarityScore)%
                """)
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
        
        // 4. 移除当前卡片，加载下一张
        if !queue.isEmpty {
            queue.removeFirst()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.loadNextCards()
                
                // 启动下一张卡片的计时
                if let nextCard = self.visibleCards.first {
                    self.dwellTimeTracker.startTracking(wordId: nextCard.word.id)
                }
            }
        }
        
        // 5. 检查是否完成
        if queue.isEmpty && visibleCards.count == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.completeStudy()
            }
        }
    }
    
    // MARK: - 开始当前卡片计时
    func startCurrentCardTracking() {
        if let currentCard = visibleCards.first {
            dwellTimeTracker.startTracking(wordId: currentCard.word.id)
        }
    }
    
    // MARK: - 完成学习
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
        
        // 延迟后显示报告
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("📊 学习完成，已生成报告")
            print("💡 停留最长的10个词可用于生成AI短文")
        }
    }
    
    // MARK: - Timer
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.studyTime = Date().timeIntervalSince(self.startTime)
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
