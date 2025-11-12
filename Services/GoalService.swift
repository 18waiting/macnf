//
//  GoalService.swift
//  NFwordsDemo
//
//  学习目标服务 - 处理目标的创建、放弃、更新等操作
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 学习目标服务
class GoalService {
    static let shared = GoalService()
    
    private let goalStorage = LearningGoalStorage()
    private let taskStorage = DailyTaskStorage()
    private let taskScheduler = TaskScheduler()
    private let wordRepository = WordRepository.shared
    private let packStorage = LocalPackStorage()
    
    private init() {}
    
    // MARK: - 创建目标
    
    /// 创建学习目标并生成所有任务
    func createGoal(
        packId: Int,
        packName: String,
        totalWords: Int,
        plan: LearningPlan
    ) throws -> (goal: LearningGoal, todayTask: DailyTask) {
        #if DEBUG
        print("[GoalService] 创建学习目标: pack=\(packName), plan=\(plan.displayName)")
        #endif
        
        // 1. 计算计划参数
        let calculation = calculatePlan(
            totalWords: totalWords,
            plan: plan
        )
        
        // 2. 创建学习目标
        let goal = LearningGoal(
            id: generateGoalId(),
            packId: packId,
            packName: packName,
            totalWords: totalWords,
            durationDays: plan.durationDays,
            dailyNewWords: calculation.dailyNewWords,
            startDate: calculation.startDate,
            endDate: calculation.endDate,
            status: .inProgress,
            currentDay: 1,
            completedWords: 0,
            completedExposures: 0
        )
        
        // 3. 保存目标
        _ = try goalStorage.insert(goal)
        
        #if DEBUG
        print("[GoalService] ✅ 目标已保存: id=\(goal.id)")
        #endif
        
        // 4. 获取词库的单词ID列表
        let packEntries = try getPackEntries(packId: packId)
        
        // 5. 生成所有任务（异步，不阻塞UI）
        Task {
            do {
                try await generateAllTasks(for: goal, packEntries: packEntries, plan: plan)
                #if DEBUG
                print("[GoalService] ✅ 所有任务已生成")
                #endif
            } catch {
                #if DEBUG
                print("[GoalService] ⚠️ 任务生成失败: \(error)")
                #endif
            }
        }
        
        // 6. 立即生成今日任务（同步，确保可以立即学习）
        let todayTask = try generateTodayTask(
            for: goal,
            day: 1,
            packEntries: packEntries,
            plan: plan
        )
        _ = try taskStorage.insert(todayTask)
        
        #if DEBUG
        print("[GoalService] ✅ 今日任务已生成: newWords=\(todayTask.newWordsCount), reviewWords=\(todayTask.reviewWordsCount)")
        #endif
        
        return (goal, todayTask)
    }
    
    // MARK: - 放弃目标
    
    /// 放弃当前学习目标
    func abandonGoal(_ goal: LearningGoal) throws {
        #if DEBUG
        print("[GoalService] 放弃学习目标: id=\(goal.id), pack=\(goal.packName)")
        #endif
        
        // 1. 更新目标状态为已放弃
        var updatedGoal = goal
        updatedGoal.status = .abandoned
        updatedGoal.endDate = Date()
        
        // 2. 保存到数据库
        try goalStorage.update(updatedGoal)
        
        // 3. 清理当前任务（如果有未完成的）
        if let task = try? taskStorage.fetchToday(),
           task.goalId == goal.id,
           task.status == .inProgress {
            var updatedTask = task
            updatedTask.status = .pending  // 标记为待开始，而不是删除
            try taskStorage.update(updatedTask)
        }
        
        #if DEBUG
        print("[GoalService] ✅ 目标已放弃")
        #endif
    }
    
    // MARK: - 计划计算
    
    /// 计算计划参数（公开方法，供 UI 使用）
    func calculatePlan(
        totalWords: Int,
        plan: LearningPlan
    ) -> PlanCalculation {
        let durationDays = plan.durationDays
        
        // 计算每日新词数
        let dailyNewWords = totalWords / durationDays
        
        // 计算每日复习词数（基于遗忘曲线）
        // 第1天：无复习
        // 第2天：复习第1天的新词（20%）
        // 第3天：复习第1-2天的新词（30%）
        // 第4天：复习第1-3天的新词（40%）
        // 平均每天约 20-50 个复习词
        let dailyReviewWords = estimateDailyReviewWords(
            totalWords: totalWords,
            durationDays: durationDays,
            dailyNewWords: dailyNewWords
        )
        
        // 计算每日曝光次数
        // 新词：10次曝光/词
        // 复习词：5次曝光/词（根据掌握程度调整）
        let dailyNewExposures = dailyNewWords * 10
        let dailyReviewExposures = dailyReviewWords * 5
        let totalDailyExposures = dailyNewExposures + dailyReviewExposures
        
        // 计算预计时间（假设每次曝光3秒）
        let estimatedMinutes = Int(Double(totalDailyExposures) * 3.0 / 60.0)
        
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
        
        return PlanCalculation(
            dailyNewWords: dailyNewWords,
            dailyReviewWords: dailyReviewWords,
            dailyExposures: totalDailyExposures,
            estimatedMinutes: estimatedMinutes,
            startDate: startDate,
            endDate: endDate
        )
    }
    
    /// 估算每日复习词数
    private func estimateDailyReviewWords(
        totalWords: Int,
        durationDays: Int,
        dailyNewWords: Int
    ) -> Int {
        // 基于间隔重复算法估算
        // 假设每天需要复习前几天的 30% 的新词
        let averageReviewRatio = 0.3
        let averageDaysToReview = 3.0  // 平均复习前3天的词
        
        let estimatedReviewWords = Int(Double(dailyNewWords) * averageDaysToReview * averageReviewRatio)
        
        // 限制在合理范围内（20-50个）
        return min(max(estimatedReviewWords, 20), 50)
    }
    
    // MARK: - 任务生成
    
    /// 生成所有任务（异步）
    private func generateAllTasks(
        for goal: LearningGoal,
        packEntries: [Int],
        plan: LearningPlan
    ) async throws {
        #if DEBUG
        print("[GoalService] 开始生成所有任务: \(goal.durationDays) 天")
        #endif
        
        // 获取所有单词
        let allWords = try wordRepository.fetchWordsByIds(packEntries)
        
        // 算法分配单词顺序（目前是随机，后续可优化）
        let shuffledWords = allWords.shuffled()
        
        // 按天分配新词
        for day in 1...goal.durationDays {
            let startIndex = (day - 1) * goal.dailyNewWords
            let endIndex = min(startIndex + goal.dailyNewWords, shuffledWords.count)
            let newWords = Array(shuffledWords[startIndex..<endIndex])
            
            // 计算复习词（基于遗忘曲线）
            let reviewWords = try calculateReviewWords(
                currentDay: day,
                goal: goal,
                previousNewWords: getPreviousNewWords(
                    days: Array(1..<day),
                    shuffledWords: shuffledWords,
                    dailyNewWords: goal.dailyNewWords
                ),
                reviewStrategy: .spacedRepetition
            )
            
            // 计算曝光次数
            let newExposures = newWords.count * 10
            let reviewExposures = reviewWords.count * 5
            let totalExposures = newExposures + reviewExposures
            
            // 创建任务
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
            
            // 保存任务
            try taskStorage.insert(task)
            
            #if DEBUG
            if day % 5 == 0 || day == goal.durationDays {
                print("[GoalService] 已生成任务: \(day)/\(goal.durationDays)")
            }
            #endif
        }
        
        #if DEBUG
        print("[GoalService] ✅ 所有任务生成完成")
        #endif
    }
    
    /// 生成今日任务（同步）
    private func generateTodayTask(
        for goal: LearningGoal,
        day: Int,
        packEntries: [Int],
        plan: LearningPlan
    ) throws -> DailyTask {
        // 获取所有单词
        let allWords = try wordRepository.fetchWordsByIds(packEntries)
        let shuffledWords = allWords.shuffled()
        
        // 计算新词
        let startIndex = (day - 1) * goal.dailyNewWords
        let endIndex = min(startIndex + goal.dailyNewWords, shuffledWords.count)
        let newWords = Array(shuffledWords[startIndex..<endIndex])
        
        // 计算复习词（第1天无复习）
        let reviewWords: [Word]
        if day > 1 {
            reviewWords = try calculateReviewWords(
                currentDay: day,
                goal: goal,
                previousNewWords: getPreviousNewWords(
                    days: Array(1..<day),
                    shuffledWords: shuffledWords,
                    dailyNewWords: goal.dailyNewWords
                ),
                reviewStrategy: .spacedRepetition
            )
        } else {
            reviewWords = []
        }
        
        // 计算曝光次数
        let newExposures = newWords.count * 10
        let reviewExposures = reviewWords.count * 5
        let totalExposures = newExposures + reviewExposures
        
        return DailyTask(
            id: generateTaskId(goalId: goal.id, day: day),
            goalId: goal.id,
            day: day,
            date: Calendar.current.date(byAdding: .day, value: day - 1, to: goal.startDate)!,
            newWords: newWords.map { $0.id },
            reviewWords: reviewWords.map { $0.id },
            totalExposures: totalExposures,
            completedExposures: 0,
            status: .pending,
            startTime: nil,
            endTime: nil
        )
    }
    
    // MARK: - 复习词计算
    
    /// 计算复习词（基于间隔重复算法）
    private func calculateReviewWords(
        currentDay: Int,
        goal: LearningGoal,
        previousNewWords: [Int: [Word]],
        reviewStrategy: ReviewStrategy
    ) throws -> [Word] {
        guard currentDay > 1 else { return [] }
        
        var reviewWords: [Word] = []
        let previousDays = Array(1..<currentDay)
        
        switch reviewStrategy {
        case .spacedRepetition:
            // 间隔重复算法
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
            // TODO: 后续实现基于学习记录的自适应复习
            for day in previousDays {
                if let words = previousNewWords[day] {
                    // 暂时使用间隔重复
                    let daysAgo = currentDay - day
                    let reviewRatio = getReviewRatio(daysAgo: daysAgo)
                    let reviewCount = Int(Double(words.count) * reviewRatio)
                    reviewWords.append(contentsOf: words.prefix(reviewCount))
                }
            }
        }
        
        // 限制每日复习词数量（避免过多）
        let maxReviewWords = min(reviewWords.count, 50)
        return Array(reviewWords.shuffled().prefix(maxReviewWords))
    }
    
    /// 获取复习比例（基于遗忘曲线）
    private func getReviewRatio(daysAgo: Int) -> Double {
        switch daysAgo {
        case 1: return 0.2  // 20%
        case 2: return 0.3  // 30%
        case 3: return 0.4  // 40%
        case 4...7: return 0.5  // 50%
        default: return 0.3  // 30%
        }
    }
    
    /// 获取之前几天的新词
    private func getPreviousNewWords(
        days: [Int],
        shuffledWords: [Word],
        dailyNewWords: Int
    ) -> [Int: [Word]] {
        var result: [Int: [Word]] = [:]
        
        for day in days {
            let startIndex = (day - 1) * dailyNewWords
            let endIndex = min(startIndex + dailyNewWords, shuffledWords.count)
            result[day] = Array(shuffledWords[startIndex..<endIndex])
        }
        
        return result
    }
    
    // MARK: - 辅助方法
    
    /// 获取词库的单词ID列表
    private func getPackEntries(packId: Int) throws -> [Int] {
        // 从数据库获取词库的单词ID列表
        let packs = try packStorage.fetchAll()
        
        if let pack = packs.first(where: { $0.packId == packId }) {
            // 如果词库有 entries 字段，直接返回
            if !pack.entries.isEmpty {
                return pack.entries
            }
            
            // 否则，从 WordRepository 获取该词库的所有单词ID
            // TODO: 实现从 WordRepository 根据 packId 获取单词ID列表
            // 暂时返回示例数据
            #if DEBUG
            print("[GoalService] ⚠️ 词库 \(packId) 没有 entries，使用临时数据")
            #endif
            return Array(1...pack.totalCount)
        }
        
        // 如果找不到词库，返回空数组
        #if DEBUG
        print("[GoalService] ⚠️ 找不到词库 \(packId)")
        #endif
        return []
    }
    
    /// 生成目标ID
    private func generateGoalId() -> Int {
        return Int(Date().timeIntervalSince1970)
    }
    
    /// 生成任务ID
    private func generateTaskId(goalId: Int, day: Int) -> Int {
        return goalId * 1000 + day
    }
}

// MARK: - 复习策略
enum ReviewStrategy {
    case spacedRepetition  // 间隔重复
    case adaptive          // 自适应（基于学习记录）
}

