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
    /// - Note: 会自动验证数据完整性，使用实际可用的单词数
    func createGoal(
        packId: Int,
        packName: String,
        totalWords: Int,
        plan: LearningPlan
    ) throws -> (goal: LearningGoal, todayTask: DailyTask) {
        #if DEBUG
        print("[GoalService] 创建学习目标: pack=\(packName), plan=\(plan.displayName)")
        #endif
        
        // 1. 获取词库的单词ID列表（优先使用数据库中的 entries）
        let packEntries = try getPackEntries(packId: packId, expectedCount: totalWords)
        
        // 2. 获取单词并验证数据完整性
        let allWords = try wordRepository.fetchWordsByIds(packEntries, allowPartial: true)
        let shuffledWords = allWords.shuffled()
        
        // 3. 数据验证：确保获取到的单词数量足够
        let actualWordCount = shuffledWords.count
        let expectedWordCount = totalWords
        
        if actualWordCount < expectedWordCount {
            #if DEBUG
            print("[GoalService] ⚠️ 数据不一致：实际获取 \(actualWordCount) 个单词，但词库声明 \(expectedWordCount) 个")
            #endif
            
            // 如果缺失过多（超过 20%），抛出错误
            let missingRatio = Double(expectedWordCount - actualWordCount) / Double(expectedWordCount)
            if missingRatio > 0.2 {
                throw NSError(
                    domain: "GoalService",
                    code: 2001,
                    userInfo: [
                        NSLocalizedDescriptionKey: "词库数据不完整：实际可用 \(actualWordCount) 个单词，但词库声明 \(expectedWordCount) 个（缺失 \(String(format: "%.1f", missingRatio * 100))%）"
                    ]
                )
            }
            
            // 如果缺失在可接受范围内，调整目标的总词数
            #if DEBUG
            print("[GoalService] 调整目标总词数：\(expectedWordCount) → \(actualWordCount)")
            #endif
        }
        
        // 4. 使用实际单词数计算计划参数
        let actualTotalWords = shuffledWords.count
        let calculation = calculatePlan(
            totalWords: actualTotalWords,
            plan: plan
        )
        
        // 5. 创建学习目标（使用实际单词数）
        let goal = LearningGoal(
            id: generateGoalId(),
            packId: packId,
            packName: packName,
            totalWords: actualTotalWords,  // ⭐ 使用实际单词数
            durationDays: plan.durationDays,
            dailyNewWords: calculation.dailyNewWords,
            startDate: calculation.startDate,
            endDate: calculation.endDate,
            status: .inProgress,
            currentDay: 1,
            completedWords: 0,
            completedExposures: 0
        )
        
        // 6. 保存目标
        _ = try goalStorage.insert(goal)
        
        #if DEBUG
        print("[GoalService] ✅ 目标已保存: id=\(goal.id), totalWords=\(actualTotalWords)")
        #endif
        
        // 7. 生成所有任务（异步，不阻塞UI）
        Task {
            do {
                try await generateAllTasks(for: goal, shuffledWords: shuffledWords)
                #if DEBUG
                print("[GoalService] ✅ 所有任务已生成")
                #endif
            } catch {
                #if DEBUG
                print("[GoalService] ⚠️ 任务生成失败: \(error)")
                #endif
            }
        }
        
        // 8. 立即生成今日任务（同步，确保可以立即学习）
        let todayTask = try generateTodayTask(
            for: goal,
            day: 1,
            shuffledWords: shuffledWords
        )
        _ = try taskStorage.insert(todayTask)
        
        #if DEBUG
        print("[GoalService] ✅ 今日任务已生成: newWords=\(todayTask.newWordsCount), reviewWords=\(todayTask.reviewWordsCount)")
        #endif
        
        return (goal, todayTask)
    }
    
    // MARK: - 放弃目标
    
    /// 放弃当前学习目标
    /// - Note: 由于 LearningGoal 的 endDate 是 let 常量，需要创建新实例
    func abandonGoal(_ goal: LearningGoal) throws {
        #if DEBUG
        print("[GoalService] 放弃学习目标: id=\(goal.id), pack=\(goal.packName)")
        #endif
        
        // 1. 创建更新后的目标（endDate 是 let，需要创建新实例）
        let updatedGoal = LearningGoal(
            id: goal.id,
            packId: goal.packId,
            packName: goal.packName,
            totalWords: goal.totalWords,
            durationDays: goal.durationDays,
            dailyNewWords: goal.dailyNewWords,
            startDate: goal.startDate,
            endDate: Date(),  // 更新为当前日期
            status: .abandoned,  // 更新状态
            currentDay: goal.currentDay,
            completedWords: goal.completedWords,
            completedExposures: goal.completedExposures
        )
        
        // 2. 保存到数据库
        try goalStorage.update(updatedGoal)
        
        // 3. 清理当前任务（如果有未完成的）
        if let task = try? taskStorage.fetchToday(),
           task.goalId == goal.id,
           task.status == .inProgress {
            // 创建更新后的任务
            let updatedTask = DailyTask(
                id: task.id,
                goalId: task.goalId,
                day: task.day,
                date: task.date,
                newWords: task.newWords,
                reviewWords: task.reviewWords,
                totalExposures: task.totalExposures,
                completedExposures: task.completedExposures,
                status: .pending,  // 标记为待开始，而不是删除
                startTime: task.startTime,
                endTime: task.endTime
            )
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
    /// - Note: 处理整数除法余数，确保所有单词都被分配
    private func generateAllTasks(
        for goal: LearningGoal,
        shuffledWords: [Word]
    ) async throws {
        #if DEBUG
        print("[GoalService] 开始生成所有任务: \(goal.durationDays) 天，共 \(shuffledWords.count) 个单词")
        #endif
        
        // ⭐ 修复：计算整数除法的余数，分配到前几天的任务中
        let baseDailyNewWords = goal.dailyNewWords
        let remainder = goal.totalWords % goal.durationDays
        
        // 按天分配新词
        for day in 1...goal.durationDays {
            // ⭐ 修复：计算每日新词数（前 remainder 天会多分配1个词）
            let dailyNewWordsForDay = baseDailyNewWords + (day <= remainder ? 1 : 0)
            
            // ⭐ 修复：计算累计索引（考虑余数分配）
            var startIndex = 0
            for d in 1..<day {
                let wordsForDay = baseDailyNewWords + (d <= remainder ? 1 : 0)
                startIndex += wordsForDay
            }
            
            // ⭐ 修复：索引越界保护
            guard startIndex < shuffledWords.count else {
                #if DEBUG
                print("[GoalService] ⚠️ 第 \(day) 天：startIndex(\(startIndex)) >= shuffledWords.count(\(shuffledWords.count))，跳过任务生成")
                #endif
                break  // 如果已经超出范围，停止生成后续任务
            }
            
            let endIndex = min(startIndex + dailyNewWordsForDay, shuffledWords.count)
            
            // ⭐ 修复：确保 startIndex < endIndex
            guard startIndex < endIndex else {
                #if DEBUG
                print("[GoalService] ⚠️ 第 \(day) 天：startIndex(\(startIndex)) >= endIndex(\(endIndex))，跳过任务生成")
                #endif
                break
            }
            
            let newWords = Array(shuffledWords[startIndex..<endIndex])
            
            // 计算复习词（基于遗忘曲线）
            let reviewWords = try calculateReviewWords(
                currentDay: day,
                goal: goal,
                previousNewWords: getPreviousNewWords(
                    days: Array(1..<day),
                    shuffledWords: shuffledWords,
                    baseDailyNewWords: baseDailyNewWords,
                    remainder: remainder
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
    /// - Note: 第1天只生成新词，无复习词
    private func generateTodayTask(
        for goal: LearningGoal,
        day: Int,
        shuffledWords: [Word]
    ) throws -> DailyTask {
        // 计算新词（第1天）
        let startIndex = 0
        let endIndex = min(goal.dailyNewWords, shuffledWords.count)
        let newWords = Array(shuffledWords[startIndex..<endIndex])
        
        // 第1天无复习词
        let reviewWords: [Word] = []
        
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
    /// - Note: 考虑整数除法余数分配
    private func getPreviousNewWords(
        days: [Int],
        shuffledWords: [Word],
        baseDailyNewWords: Int,
        remainder: Int
    ) -> [Int: [Word]] {
        var result: [Int: [Word]] = [:]
        
        for day in days {
            // 计算每日新词数（前 remainder 天会多分配1个词）
            let dailyNewWordsForDay = baseDailyNewWords + (day <= remainder ? 1 : 0)
            
            // 计算累计索引
            var startIndex = 0
            for d in 1..<day {
                let wordsForDay = baseDailyNewWords + (d <= remainder ? 1 : 0)
                startIndex += wordsForDay
            }
            
            guard startIndex < shuffledWords.count else { continue }
            
            let endIndex = min(startIndex + dailyNewWordsForDay, shuffledWords.count)
            guard startIndex < endIndex else { continue }
            
            result[day] = Array(shuffledWords[startIndex..<endIndex])
        }
        
        return result
    }
    
    // MARK: - 辅助方法
    
    /// 获取词库的单词ID列表
    /// - Parameter packId: 词库ID
    /// - Parameter expectedCount: 期望的单词数量（用于验证）
    /// - Returns: 单词ID列表
    private func getPackEntries(packId: Int, expectedCount: Int) throws -> [Int] {
        // 从数据库获取词库的单词ID列表
        let packs = try packStorage.fetchAll()
        
        if let pack = packs.first(where: { $0.packId == packId }) {
            // 如果词库有 entries 字段，直接返回
            if !pack.entries.isEmpty {
                #if DEBUG
                print("[GoalService] 使用数据库中的 entries: \(pack.entries.count) 个ID")
                #endif
                return pack.entries
            }
            
            // 否则，从 WordRepository 获取实际可用的单词ID
            #if DEBUG
            print("[GoalService] 词库 \(packId) 没有 entries，从 WordRepository 获取实际可用的单词ID")
            #endif
            
            let allAvailableIds = try wordRepository.getAllWordIds()
            
            if allAvailableIds.count >= expectedCount {
                // 如果可用单词数足够，使用前 expectedCount 个
                let entries = Array(allAvailableIds.prefix(expectedCount))
                #if DEBUG
                print("[GoalService] 从 WordRepository 获取前 \(expectedCount) 个ID（共 \(allAvailableIds.count) 个可用）")
                #endif
                return entries
            } else {
                // 如果可用单词数不足，使用所有可用的
                #if DEBUG
                print("[GoalService] ⚠️ 警告：可用单词数（\(allAvailableIds.count)）少于词库声明的数量（\(expectedCount)），使用所有可用单词")
                #endif
                return allAvailableIds
            }
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

