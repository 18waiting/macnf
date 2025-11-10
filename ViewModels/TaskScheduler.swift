//
//  TaskScheduler.swift
//  NFwordsDemo
//
//  任务调度器 - 生成每日任务和学习队列（集成核心组件）
//  Created by 甘名杨 on 2025/11/3.
//  Updated by AI Assistant on 2025/11/5 - 集成核心组件
//

import Foundation

// MARK: - 任务调度器
class TaskScheduler {
    
    // 核心组件 ⭐
    private let taskStrategy: TaskGenerationStrategy
    private let dwellAnalyzer: DwellTimeAnalyzer
    
    init() {
        self.dwellAnalyzer = DwellTimeAnalyzerFactory.defaultAnalyzer()
        self.taskStrategy = TaskGenerationStrategyFactory.defaultStrategy(dwellAnalyzer: dwellAnalyzer)
        
        #if DEBUG
        print("[TaskScheduler] Initialized with:")
        print("  - \(taskStrategy.strategyName)")
        print("  - DwellTimeAnalyzer")
        #endif
    }
    
    // MARK: - 公共方法（使用核心组件）⭐
    
    /// 生成完整的学习计划（所有天的任务）
    func generateCompletePlan(for goal: LearningGoal, packEntries: [Int]) -> [DailyTask] {
        #if DEBUG
        print("[TaskScheduler] Generating complete plan for: \(goal.packName)")
        #endif
        
        return taskStrategy.generateCompletePlan(for: goal, packEntries: packEntries)
    }
    
    /// 生成单日任务（基于昨日停留时间分析）⭐
    func generateDailyTask(
        for goal: LearningGoal,
        day: Int,
        packEntries: [Int],
        yesterdayRecords: [Int: WordLearningRecord]?
    ) -> DailyTask {
        
        #if DEBUG
        print("[TaskScheduler] Generating task for day \(day)")
        #endif
        
        // 分析昨日停留时间
        var analysis: DwellTimeAnalysis?
        if let records = yesterdayRecords, !records.isEmpty {
            analysis = dwellAnalyzer.analyze(records)
            
            #if DEBUG
            print("[TaskScheduler] Yesterday analysis: \(analysis!.briefSummary)")
            #endif
        }
        
        // 使用策略生成任务
        return taskStrategy.generateDailyTask(
            for: goal,
            day: day,
            packEntries: packEntries,
            previousAnalysis: analysis
        )
    }
    
    // MARK: - 原有方法（保持兼容）
    
    /// 根据学习目标生成某一天的任务
    /// - Parameters:
    ///   - goal: 学习目标
    ///   - day: 第几天（1-based）
    ///   - previousRecords: 之前的学习记录
    /// - Returns: 每日任务
    func generateDailyTask(
        for goal: LearningGoal,
        day: Int,
        previousRecords: [Int: WordLearningRecord]
    ) -> DailyTask {
        // 1. 计算新词
        let newWords = calculateNewWords(goal: goal, day: day)
        
        // 2. 计算复习词（基于停留时间）⭐
        let reviewWords = calculateReviewWords(
            day: day,
            previousRecords: previousRecords
        )
        
        // 3. 计算总曝光次数
        let newWordsExposures = newWords.count * 10  // 新词10次
        let reviewExposures = reviewWords.count * 5  // 复习5次
        let totalExposures = newWordsExposures + reviewExposures
        
        return DailyTask(
            id: day,
            goalId: goal.id,
            day: day,
            date: Calendar.current.date(byAdding: .day, value: day - 1, to: goal.startDate)!,
            newWords: newWords,
            reviewWords: reviewWords,
            totalExposures: totalExposures,
            completedExposures: 0,
            status: .pending,
            startTime: nil,
            endTime: nil
        )
    }
    
    // MARK: - 计算新词
    private func calculateNewWords(goal: LearningGoal, day: Int) -> [Int] {
        let totalWords = goal.totalWords
        let totalDays = goal.durationDays
        
        // 前70%的天数学习90%的词汇（前期多，后期少）
        let frontLoadRatio = 0.7
        let frontDays = Int(Double(totalDays) * frontLoadRatio)
        
        let wordsPerDay: Int
        if day <= frontDays {
            // 前期：每天多学新词
            wordsPerDay = Int(Double(totalWords) * 0.9 / Double(frontDays))
        } else {
            // 后期：主要复习，少量新词
            let remainingWords = Int(Double(totalWords) * 0.1)
            let remainingDays = totalDays - frontDays
            wordsPerDay = max(remainingWords / remainingDays, 50)
        }
        
        // 生成词ID（简化版，实际应该从数据库获取）
        let startId = (day - 1) * wordsPerDay + 1
        return Array(startId..<(startId + wordsPerDay))
    }
    
    // MARK: - 计算复习词（基于停留时间）⭐ 核心算法
    private func calculateReviewWords(
        day: Int,
        previousRecords: [Int: WordLearningRecord]
    ) -> [Int] {
        guard day > 1 else { return [] }
        
        // 从之前学过的词中选择停留时间最长的
        let difficultWords = previousRecords.values
            .sorted { $0.avgDwellTime > $1.avgDwellTime }  // ⭐ 按停留时间降序
            .prefix(20)  // 选择最困难的20个
            .map { $0.id }
        
        return Array(difficultWords)
    }
    
    // MARK: - 生成学习队列（带重复）
    /// 将任务转换为学习队列（每个词重复多次）
    /// - Parameter task: 每日任务
    /// - Returns: 学习卡片数组
    func generateStudyQueue(task: DailyTask, words: [Word]) -> [StudyCard] {
        var queue: [StudyCard] = []
        
        // 1. 新词（每个10次）
        for wid in task.newWords {
            guard let word = words.first(where: { $0.id == wid }) else { continue }
            let record = WordLearningRecord.initial(wid: wid, targetExposures: 10)
            
            // ⭐ P0 修复：移除 record 参数
            for _ in 0..<10 {
                queue.append(StudyCard(word: word))
            }
        }
        
        // 2. 复习词（每个5次）
        for wid in task.reviewWords {
            guard let word = words.first(where: { $0.id == wid }) else { continue }
            let record = WordLearningRecord.initial(wid: wid, targetExposures: 5)
            
            // ⭐ P0 修复：移除 record 参数
            for _ in 0..<5 {
                queue.append(StudyCard(word: word))
            }
        }
        
        // 3. 随机打乱（避免连续相同）
        queue = shuffleWithSpacing(queue)
        
        return queue
    }
    
    // MARK: - 间距洗牌（避免同词连续出现）
    private func shuffleWithSpacing(_ queue: [StudyCard]) -> [StudyCard] {
        var shuffled = queue.shuffled()
        let minGap = 3  // 同词之间至少间隔3张卡片
        
        // 简单的间距优化（可以进一步改进）
        for i in 0..<shuffled.count {
            for j in (i + 1)..<min(i + minGap + 1, shuffled.count) {
                if shuffled[i].word.id == shuffled[j].word.id {
                    // 找到后面一个不同的词交换
                    if let swapIndex = shuffled.indices.dropFirst(i + minGap + 1).first(where: { 
                        shuffled[$0].word.id != shuffled[i].word.id 
                    }) {
                        shuffled.swapAt(j, swapIndex)
                    }
                }
            }
        }
        
        return shuffled
    }
}

