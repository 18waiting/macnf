//
//  TaskGenerationStrategy.swift
//  NFwordsDemo
//
//  任务生成策略核心组件 - 体现"10天3000词"预定任务理念
//  Created by AI Assistant on 2025/11/5.
//

import Foundation

// MARK: - 任务生成策略协议

/// 任务生成策略协议
///
/// 定义如何生成学习计划和每日任务
protocol TaskGenerationStrategy {
    /// 生成完整的学习计划（所有天的任务）
    /// - Parameters:
    ///   - goal: 学习目标（如10天3000词）
    ///   - packEntries: 词书的所有单词ID
    /// - Returns: 所有天的任务列表
    func generateCompletePlan(for goal: LearningGoal, packEntries: [Int]) -> [DailyTask]
    
    /// 生成单日任务
    /// - Parameters:
    ///   - goal: 学习目标
    ///   - day: 第几天
    ///   - packEntries: 词书的所有单词ID
    ///   - previousAnalysis: 前一天的停留时间分析（用于选择复习词）
    /// - Returns: 当日任务
    func generateDailyTask(
        for goal: LearningGoal,
        day: Int,
        packEntries: [Int],
        previousAnalysis: DwellTimeAnalysis?
    ) -> DailyTask
    
    var strategyName: String { get }
    var strategyDescription: String { get }
}

// MARK: - 量化任务生成策略（核心实现）⭐

/// 量化任务生成策略（10天3000词完整算法）
///
/// 核心理念：
/// 1. 任务预定制 - 10天的任务提前全部生成
/// 2. 前期多学新词，后期多复习
/// 3. 基于停留时间选择复习词（与DwellTimeAnalyzer配合）
///
/// 算法：
/// - 前70%天数学习90%词汇（1-7天学2700词）
/// - 后30%天数学习10%词汇（8-10天学300词）
/// - 每天复习：昨日停留时间最长的20个词
final class QuantitativeTaskStrategy: TaskGenerationStrategy {
    
    // MARK: - Configuration
    
    /// 任务分配配置
    struct Config {
        /// 新词前置比例（前X%的天数学习Y%的词）
        let frontLoadRatio: Double  // 默认0.7（前70%天）
        let frontLoadWords: Double  // 默认0.9（90%词汇）
        
        /// 每日复习词数量
        let dailyReviewCount: Int  // 默认20个
        
        /// 新词曝光次数
        let newWordExposures: Int  // 默认10次
        
        /// 复习词曝光次数
        let reviewWordExposures: Int  // 默认5次
        
        static let standard = Config(
            frontLoadRatio: 0.7,
            frontLoadWords: 0.9,
            dailyReviewCount: 20,
            newWordExposures: 10,
            reviewWordExposures: 5
        )
        
        static let intensive = Config(
            frontLoadRatio: 0.6,  // 前60%天学完
            frontLoadWords: 0.95,  // 95%词汇
            dailyReviewCount: 30,  // 复习更多
            newWordExposures: 12,  // 曝光更多
            reviewWordExposures: 6
        )
        
        static let relaxed = Config(
            frontLoadRatio: 0.8,  // 前80%天
            frontLoadWords: 0.85,  // 85%词汇
            dailyReviewCount: 15,
            newWordExposures: 8,
            reviewWordExposures: 4
        )
    }
    
    // MARK: - Properties
    
    private let config: Config
    private let dwellAnalyzer: DwellTimeAnalyzer?
    
    var strategyName: String {
        "量化任务策略（10天3000词）"
    }
    
    var strategyDescription: String {
        """
        任务预定制算法：
        
        新词分配：
        • 前\(Int(config.frontLoadRatio * 100))%天学习\(Int(config.frontLoadWords * 100))%词汇
        • 后\(Int((1 - config.frontLoadRatio) * 100))%天学习\(Int((1 - config.frontLoadWords) * 100))%词汇
        
        复习策略：
        • 每天复习\(config.dailyReviewCount)个词
        • 基于昨日停留时间选择（最难的）
        
        曝光次数：
        • 新词：\(config.newWordExposures)次
        • 复习：\(config.reviewWordExposures)次
        """
    }
    
    // MARK: - Initialization
    
    init(config: Config = .standard, dwellAnalyzer: DwellTimeAnalyzer? = nil) {
        self.config = config
        self.dwellAnalyzer = dwellAnalyzer
        
        #if DEBUG
        print("[TaskStrategy] Initialized: \(strategyName)")
        print("[TaskStrategy] Config:")
        print("  - Front load: \(Int(config.frontLoadRatio * 100))% days, \(Int(config.frontLoadWords * 100))% words")
        print("  - Daily review: \(config.dailyReviewCount) words")
        print("  - New word exposures: \(config.newWordExposures)x")
        print("  - Review exposures: \(config.reviewWordExposures)x")
        #endif
    }
    
    // MARK: - TaskGenerationStrategy Protocol
    
    func generateCompletePlan(for goal: LearningGoal, packEntries: [Int]) -> [DailyTask] {
        #if DEBUG
        print("[TaskStrategy] Generating complete plan: \(goal.durationDays) days, \(goal.totalWords) words")
        #endif
        
        var tasks: [DailyTask] = []
        let totalDays = goal.durationDays
        let totalWords = min(goal.totalWords, packEntries.count)
        
        // 计算分配方案
        let distribution = calculateWordDistribution(totalDays: totalDays, totalWords: totalWords)
        
        #if DEBUG
        print("[TaskStrategy] Distribution:")
        print("  - Front period (\(distribution.frontDays) days): \(distribution.frontWords) words")
        print("  - Back period (\(totalDays - distribution.frontDays) days): \(distribution.backWords) words")
        #endif
        
        var currentIndex = 0
        
        for day in 1...totalDays {
            let dailyNewCount = distribution.dailyNewWords[day - 1]
            let newWords = Array(packEntries[currentIndex..<min(currentIndex + dailyNewCount, packEntries.count)])
            currentIndex += newWords.count
            
            // 完整计划生成时，复习词为空（实际复习词需要基于前一天的学习数据动态生成）
            let reviewWords: [Int] = []
            
            let task = createTask(
                goalId: goal.id,
                day: day,
                date: Calendar.current.date(byAdding: .day, value: day - 1, to: goal.startDate)!,
                newWords: newWords,
                reviewWords: reviewWords
            )
            
            tasks.append(task)
            
            #if DEBUG
            if day <= 3 || day >= totalDays - 2 {
                print("[TaskStrategy] Day \(day): \(newWords.count) new words, \(reviewWords.count) review")
            }
            #endif
        }
        
        #if DEBUG
        print("[TaskStrategy] Complete plan generated: \(tasks.count) tasks")
        let totalNewWords = tasks.reduce(0) { $0 + $1.newWords.count }
        print("[TaskStrategy] Total new words: \(totalNewWords)")
        #endif
        
        return tasks
    }
    
    func generateDailyTask(
        for goal: LearningGoal,
        day: Int,
        packEntries: [Int],
        previousAnalysis: DwellTimeAnalysis?
    ) -> DailyTask {
        
        #if DEBUG
        print("[TaskStrategy] Generating task for day \(day)/\(goal.durationDays)")
        #endif
        
        // 1. 计算新词
        let newWords = calculateNewWords(goal: goal, day: day, packEntries: packEntries)
        
        #if DEBUG
        print("[TaskStrategy] New words: \(newWords.count)")
        #endif
        
        // 2. 选择复习词（基于停留时间）⭐
        let reviewWords = selectReviewWords(day: day, previousAnalysis: previousAnalysis)
        
        #if DEBUG
        print("[TaskStrategy] Review words: \(reviewWords.count)")
        if !reviewWords.isEmpty && previousAnalysis != nil {
            print("[TaskStrategy] Review words selected from yesterday's top difficult words")
        }
        #endif
        
        // 3. 创建任务
        return createTask(
            goalId: goal.id,
            day: day,
            date: Calendar.current.date(byAdding: .day, value: day - 1, to: goal.startDate)!,
            newWords: newWords,
            reviewWords: reviewWords
        )
    }
    
    // MARK: - Private Methods
    
    /// 计算单词分配方案
    private func calculateWordDistribution(totalDays: Int, totalWords: Int) -> WordDistribution {
        let frontDays = Int(Double(totalDays) * config.frontLoadRatio)
        let frontWords = Int(Double(totalWords) * config.frontLoadWords)
        let backWords = totalWords - frontWords
        
        var dailyNewWords: [Int] = []
        
        // 前期：平均分配frontWords到frontDays
        let frontDailyAvg = frontWords / max(frontDays, 1)
        for _ in 0..<frontDays {
            dailyNewWords.append(frontDailyAvg)
        }
        
        // 后期：平均分配backWords到剩余天数
        let backDays = totalDays - frontDays
        let backDailyAvg = backWords / max(backDays, 1)
        for _ in 0..<backDays {
            dailyNewWords.append(backDailyAvg)
        }
        
        // 调整最后一天，确保总数正确
        let sum = dailyNewWords.reduce(0, +)
        if sum < totalWords {
            dailyNewWords[dailyNewWords.count - 1] += (totalWords - sum)
        }
        
        return WordDistribution(
            frontDays: frontDays,
            frontWords: frontWords,
            backWords: backWords,
            dailyNewWords: dailyNewWords
        )
    }
    
    /// 计算新词列表
    private func calculateNewWords(goal: LearningGoal, day: Int, packEntries: [Int]) -> [Int] {
        let distribution = calculateWordDistribution(totalDays: goal.durationDays, totalWords: goal.totalWords)
        
        // 计算起始索引
        var startIndex = 0
        for d in 1..<day {
            startIndex += distribution.dailyNewWords[d - 1]
        }
        
        let dailyCount = distribution.dailyNewWords[day - 1]
        let endIndex = min(startIndex + dailyCount, packEntries.count)
        
        return Array(packEntries[startIndex..<endIndex])
    }
    
    /// 选择复习词（基于停留时间）⭐ 核心
    private func selectReviewWords(day: Int, previousAnalysis: DwellTimeAnalysis?) -> [Int] {
        guard day > 1, let analysis = previousAnalysis else {
            return []
        }
        
        // 从停留时间分析中选择最困难的N个词 ⭐
        return analysis.getWordsNeedingReview(count: config.dailyReviewCount)
    }
    
    /// 创建任务
    private func createTask(goalId: Int, day: Int, date: Date, newWords: [Int], reviewWords: [Int]) -> DailyTask {
        let newWordExposures = newWords.count * config.newWordExposures
        let reviewExposures = reviewWords.count * config.reviewWordExposures
        
        return DailyTask(
            id: day,
            goalId: goalId,
            day: day,
            date: date,
            newWords: newWords,
            reviewWords: reviewWords,
            totalExposures: newWordExposures + reviewExposures,
            completedExposures: 0,
            status: .pending,
            startTime: nil,
            endTime: nil
        )
    }
    
    /// 单词分配方案
    private struct WordDistribution {
        let frontDays: Int
        let frontWords: Int
        let backWords: Int
        let dailyNewWords: [Int]
    }
}

// MARK: - 均衡任务策略

/// 均衡任务策略（每天新词数量相同）
///
/// 适用场景：
/// - 简单计划
/// - 稳定节奏
final class BalancedTaskStrategy: TaskGenerationStrategy {
    private let dailyReviewCount: Int
    private let newWordExposures: Int
    private let reviewWordExposures: Int
    
    var strategyName: String {
        "均衡任务策略"
    }
    
    var strategyDescription: String {
        "每天新词数量相同，节奏稳定"
    }
    
    init(dailyReviewCount: Int = 20, newWordExposures: Int = 10, reviewWordExposures: Int = 5) {
        self.dailyReviewCount = dailyReviewCount
        self.newWordExposures = newWordExposures
        self.reviewWordExposures = reviewWordExposures
    }
    
    func generateCompletePlan(for goal: LearningGoal, packEntries: [Int]) -> [DailyTask] {
        let dailyNewWords = goal.totalWords / goal.durationDays
        var tasks: [DailyTask] = []
        
        for day in 1...goal.durationDays {
            let start = (day - 1) * dailyNewWords
            let end = min(day * dailyNewWords, packEntries.count)
            let newWords = Array(packEntries[start..<end])
            
            let task = DailyTask(
                id: day,
                goalId: goal.id,
                day: day,
                date: Calendar.current.date(byAdding: .day, value: day - 1, to: goal.startDate)!,
                newWords: newWords,
                reviewWords: [],
                totalExposures: newWords.count * newWordExposures,
                completedExposures: 0,
                status: .pending,
                startTime: nil,
                endTime: nil
            )
            
            tasks.append(task)
        }
        
        return tasks
    }
    
    func generateDailyTask(
        for goal: LearningGoal,
        day: Int,
        packEntries: [Int],
        previousAnalysis: DwellTimeAnalysis?
    ) -> DailyTask {
        let dailyNewWords = goal.totalWords / goal.durationDays
        let start = (day - 1) * dailyNewWords
        let end = min(day * dailyNewWords, packEntries.count)
        let newWords = Array(packEntries[start..<end])
        
        let reviewWords = previousAnalysis?.getWordsNeedingReview(count: dailyReviewCount) ?? []
        
        return DailyTask(
            id: day,
            goalId: goal.id,
            day: day,
            date: Calendar.current.date(byAdding: .day, value: day - 1, to: goal.startDate)!,
            newWords: newWords,
            reviewWords: reviewWords,
            totalExposures: newWords.count * newWordExposures + reviewWords.count * reviewWordExposures,
            completedExposures: 0,
            status: .pending,
            startTime: nil,
            endTime: nil
        )
    }
}

// MARK: - 渐进任务策略

/// 渐进任务策略（逐步增加难度）
///
/// 特点：
/// - 前期少量新词，让用户适应
/// - 中期加大力度
/// - 后期减少新词，专注复习
final class ProgressiveTaskStrategy: TaskGenerationStrategy {
    
    var strategyName: String {
        "渐进任务策略"
    }
    
    var strategyDescription: String {
        "前期适应，中期发力，后期巩固"
    }
    
    func generateCompletePlan(for goal: LearningGoal, packEntries: [Int]) -> [DailyTask] {
        var tasks: [DailyTask] = []
        let totalDays = goal.durationDays
        let totalWords = goal.totalWords
        
        // 计算每天的新词数量（渐进式）
        var dailyCounts = calculateProgressiveCounts(totalDays: totalDays, totalWords: totalWords)
        
        var currentIndex = 0
        
        for day in 1...totalDays {
            let dailyCount = dailyCounts[day - 1]
            let newWords = Array(packEntries[currentIndex..<min(currentIndex + dailyCount, packEntries.count)])
            currentIndex += newWords.count
            
            let task = DailyTask(
                id: day,
                goalId: goal.id,
                day: day,
                date: Calendar.current.date(byAdding: .day, value: day - 1, to: goal.startDate)!,
                newWords: newWords,
                reviewWords: [],
                totalExposures: newWords.count * 10,
                completedExposures: 0,
                status: .pending,
                startTime: nil,
                endTime: nil
            )
            
            tasks.append(task)
        }
        
        return tasks
    }
    
    func generateDailyTask(
        for goal: LearningGoal,
        day: Int,
        packEntries: [Int],
        previousAnalysis: DwellTimeAnalysis?
    ) -> DailyTask {
        // 简化实现：使用均衡策略
        let balanced = BalancedTaskStrategy()
        return balanced.generateDailyTask(for: goal, day: day, packEntries: packEntries, previousAnalysis: previousAnalysis)
    }
    
    private func calculateProgressiveCounts(totalDays: Int, totalWords: Int) -> [Int] {
        var counts: [Int] = []
        let phases = [0.7, 1.2, 0.8]  // 前期70%，中期120%，后期80%
        let avgPerDay = totalWords / totalDays
        
        let frontDays = totalDays / 3
        let midDays = totalDays / 3
        let backDays = totalDays - frontDays - midDays
        
        // 前期
        for _ in 0..<frontDays {
            counts.append(Int(Double(avgPerDay) * phases[0]))
        }
        
        // 中期
        for _ in 0..<midDays {
            counts.append(Int(Double(avgPerDay) * phases[1]))
        }
        
        // 后期
        for _ in 0..<backDays {
            counts.append(Int(Double(avgPerDay) * phases[2]))
        }
        
        // 调整总数
        let sum = counts.reduce(0, +)
        if sum != totalWords {
            counts[counts.count - 1] += (totalWords - sum)
        }
        
        return counts
    }
}

// MARK: - 任务生成策略工厂

/// 任务生成策略工厂
enum TaskGenerationStrategyFactory {
    
    /// 获取默认策略（量化任务策略）⭐
    static func defaultStrategy(dwellAnalyzer: DwellTimeAnalyzer? = nil) -> TaskGenerationStrategy {
        QuantitativeTaskStrategy(config: .standard, dwellAnalyzer: dwellAnalyzer)
    }
    
    /// 获取强化策略（快速冲刺）
    static func intensiveStrategy(dwellAnalyzer: DwellTimeAnalyzer? = nil) -> TaskGenerationStrategy {
        QuantitativeTaskStrategy(config: .intensive, dwellAnalyzer: dwellAnalyzer)
    }
    
    /// 获取轻松策略（稳步学习）
    static func relaxedStrategy(dwellAnalyzer: DwellTimeAnalyzer? = nil) -> TaskGenerationStrategy {
        QuantitativeTaskStrategy(config: .relaxed, dwellAnalyzer: dwellAnalyzer)
    }
    
    /// 获取均衡策略（简单计划）
    static func balancedStrategy() -> TaskGenerationStrategy {
        BalancedTaskStrategy()
    }
    
    /// 获取渐进策略（逐步加强）
    static func progressiveStrategy() -> TaskGenerationStrategy {
        ProgressiveTaskStrategy()
    }
    
    /// 根据学习目标自动选择策略
    static func strategyForGoal(_ goal: LearningGoal, dwellAnalyzer: DwellTimeAnalyzer? = nil) -> TaskGenerationStrategy {
        switch goal.durationDays {
        case 1...7:
            // 7天极速冲刺 → 强化策略
            return intensiveStrategy(dwellAnalyzer: dwellAnalyzer)
        case 8...15:
            // 10-15天快速学习 → 标准量化策略
            return defaultStrategy(dwellAnalyzer: dwellAnalyzer)
        case 16...30:
            // 20-30天稳步学习 → 轻松策略
            return relaxedStrategy(dwellAnalyzer: dwellAnalyzer)
        default:
            // 长期学习 → 均衡策略
            return balancedStrategy()
        }
    }
}

// MARK: - 使用示例和文档

/*
 
 ## 使用示例
 
 ### 创建学习目标时生成完整计划
 
 ```swift
 // 用户创建10天3000词计划
 let goal = LearningGoal(
     id: 1,
     packId: 2001,
     packName: "CET-4",
     totalWords: 3000,
     durationDays: 10,
     ...
 )
 
 // 获取词书entries
 let packEntries = [...] // 3000个wid
 
 // 生成完整的10天计划 ⭐
 let strategy = TaskGenerationStrategyFactory.strategyForGoal(goal)
 let allTasks = strategy.generateCompletePlan(for: goal, packEntries: packEntries)
 
 // 结果：
 // Day 1: 270新词 + 0复习 = 2700次曝光
 // Day 2: 270新词 + 20复习 = 2800次曝光
 // ...
 // Day 10: 30新词 + 20复习 = 400次曝光
 
 // 保存所有任务到数据库
 for task in allTasks {
     try taskStorage.insert(task)
 }
 ```
 
 ### 每日动态生成（基于昨日停留时间）
 
 ```swift
 // Day 2开始时
 let yesterdayRecords = [...] // Day 1的学习记录
 
 // 分析昨日停留时间 ⭐
 let analyzer = DwellTimeAnalyzerFactory.defaultAnalyzer()
 let analysis = analyzer.analyze(yesterdayRecords)
 
 // 生成Day 2任务
 let strategy = TaskGenerationStrategyFactory.defaultStrategy(dwellAnalyzer: analyzer)
 let todayTask = strategy.generateDailyTask(
     for: goal,
     day: 2,
     packEntries: packEntries,
     previousAnalysis: analysis  // ⭐ 基于昨日分析
 )
 
 // todayTask.reviewWords = 昨日停留时间最长的20个词
 ```
 
 ### 三种策略对比（10天3000词）
 
 ```swift
 // 标准策略
 let standard = QuantitativeTaskStrategy(config: .standard)
 // Day 1-7: 每天270词（前7天2700词）
 // Day 8-10: 每天100词（后3天300词）
 // 每天复习20个昨日最难的词
 
 // 强化策略（快速冲刺）
 let intensive = QuantitativeTaskStrategy(config: .intensive)
 // Day 1-6: 每天475词（前6天2850词）
 // Day 7-10: 每天38词（后4天150词）
 // 每天复习30个昨日最难的词
 
 // 轻松策略（稳步学习）
 let relaxed = QuantitativeTaskStrategy(config: .relaxed)
 // Day 1-8: 每天319词（前8天2550词）
 // Day 9-10: 每天225词（后2天450词）
 // 每天复习15个昨日最难的词
 ```
 
 ## 核心算法详解
 
 ### 10天3000词分配算法
 
 ```
 前70%天数（7天）学习90%词汇（2700词）：
   - Day 1: 270词 (2700/10)
   - Day 2: 270词 + 20复习
   - ...
   - Day 7: 270词 + 20复习
   
 后30%天数（3天）学习10%词汇（300词）：
   - Day 8: 100词 + 20复习
   - Day 9: 100词 + 20复习
   - Day 10: 100词 + 20复习
   
 总计：
   - 新词：3000个
   - 每天曝光：2700-3000次（新词×10 + 复习×5）
   - 每天时长：约40-50分钟
 ```
 
 ### 复习词选择算法
 
 ```
 基于昨日停留时间分析：
 
 1. DwellTimeAnalyzer 分析昨日学习
    → sortedByDwellTime（按停留时间降序）
    
 2. 选择前20个（停留时间最长）
    → [wid1(12.5s), wid2(9.8s), ..., wid20(5.2s)]
    
 3. 作为今日复习词
    → 重点攻克昨日最难的词 ⭐
 ```
 
 ## 设计模式
 
 ### 策略模式
 - TaskGenerationStrategy 协议
 - QuantitativeTaskStrategy（核心）
 - BalancedTaskStrategy（简单）
 - ProgressiveTaskStrategy（渐进）
 
 ### 工厂模式
 - TaskGenerationStrategyFactory
 - 自动选择合适策略
 
 ### 配置模式
 - Config 结构体
 - 支持多种预设（standard/intensive/relaxed）
 
 ## 扩展性
 
 ### 添加新策略
 
 ```swift
 // 自定义策略
 class CustomTaskStrategy: TaskGenerationStrategy {
     func generateCompletePlan(...) -> [DailyTask] {
         // 实现自定义算法
     }
 }
 ```
 
 ### 自定义配置
 
 ```swift
 let customConfig = QuantitativeTaskStrategy.Config(
     frontLoadRatio: 0.8,  // 前80%天
     frontLoadWords: 0.95,  // 95%词汇
     dailyReviewCount: 25,
     newWordExposures: 12,
     reviewWordExposures: 6
 )
 
 let strategy = QuantitativeTaskStrategy(config: customConfig)
 ```
 
 */

