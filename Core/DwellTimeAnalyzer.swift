//
//  DwellTimeAnalyzer.swift
//  NFwordsDemo
//
//  停留时间分析器核心组件 - 体现"停留时间=熟悉度"理念
//  Created by AI Assistant on 2025/11/5.
//

import Foundation

// MARK: - 停留时间范围

/// 停留时间范围分类
enum DwellTimeRange: String, CaseIterable, Comparable {
    case veryFast = "<2s"      // 非常熟悉
    case fast = "2-5s"         // 基本熟悉
    case medium = "5-8s"       // 不够熟悉
    case slow = "8-10s"        // 困难
    case verySlow = ">10s"     // 极度困难
    
    var threshold: ClosedRange<TimeInterval> {
        switch self {
        case .veryFast: return 0...2.0
        case .fast: return 2.0...5.0
        case .medium: return 5.0...8.0
        case .slow: return 8.0...10.0
        case .verySlow: return 10.0...TimeInterval.infinity
        }
    }
    
    var displayName: String {
        switch self {
        case .veryFast: return "非常熟悉"
        case .fast: return "基本熟悉"
        case .medium: return "不够熟悉"
        case .slow: return "困难"
        case .verySlow: return "极度困难"
        }
    }
    
    var emoji: String {
        switch self {
        case .veryFast: return "✅"
        case .fast: return "👍"
        case .medium: return "⚠️"
        case .slow: return "❌"
        case .verySlow: return "🔥"
        }
    }
    
    static func < (lhs: DwellTimeRange, rhs: DwellTimeRange) -> Bool {
        lhs.threshold.lowerBound < rhs.threshold.lowerBound
    }
    
    static func fromDwellTime(_ time: TimeInterval) -> DwellTimeRange {
        for range in DwellTimeRange.allCases {
            if range.threshold.contains(time) {
                return range
            }
        }
        return .verySlow
    }
}

// MARK: - 停留时间分析结果

/// 停留时间分析结果
///
/// 包含：
/// - 按停留时间排序的单词列表（每日时间表）⭐
/// - 分类结果（熟悉/困难）
/// - 统计数据
/// - AI短文生成输入
struct DwellTimeAnalysis {
    // 核心：按停留时间排序（降序）⭐
    let sortedByDwellTime: [WordLearningRecord]
    
    // 分类结果
    let veryFamiliar: [WordLearningRecord]  // <2s
    let familiar: [WordLearningRecord]  // 2-5s
    let unfamiliar: [WordLearningRecord]  // 5-8s
    let difficult: [WordLearningRecord]  // 8-10s
    let veryDifficult: [WordLearningRecord]  // >10s
    
    // 统计数据
    let totalWords: Int
    let avgDwellTime: TimeInterval
    let medianDwellTime: TimeInterval
    let distribution: [DwellTimeRange: Int]
    
    // 计算属性
    
    /// 掌握率（停留<2s的比例）
    var masteryRate: Double {
        guard totalWords > 0 else { return 0 }
        return Double(veryFamiliar.count) / Double(totalWords)
    }
    
    /// 困难率（停留>5s的比例）
    var difficultyRate: Double {
        guard totalWords > 0 else { return 0 }
        let difficultCount = unfamiliar.count + difficult.count + veryDifficult.count
        return Double(difficultCount) / Double(totalWords)
    }
    
    /// 获取最困难的N个单词（用于AI短文生成）⭐
    func getTopDifficultWords(count: Int = 10) -> [String] {
        sortedByDwellTime
            .prefix(count)
            .compactMap { getWord(for: $0.id) }
    }
    
    /// 获取需要重点复习的单词（明日任务）⭐
    func getWordsNeedingReview(count: Int = 20) -> [Int] {
        sortedByDwellTime
            .prefix(count)
            .map { $0.id }
    }
    
    // 辅助：获取单词文本（需要外部提供）
    private func getWord(for wid: Int) -> String? {
        // 实际使用时会注入 WordRepository
        nil
    }
}

// MARK: - 停留时间分析器协议

/// 停留时间分析器协议
protocol DwellTimeAnalyzer {
    /// 分析学习记录，生成停留时间报告
    /// - Parameter records: 学习记录字典
    /// - Returns: 分析结果
    func analyze(_ records: [Int: WordLearningRecord]) -> DwellTimeAnalysis
    
    /// 分析结果（支持 Word 查询）
    /// - Parameters:
    ///   - records: 学习记录字典
    ///   - wordLookup: 单词查询闭包
    /// - Returns: 增强的分析结果
    func analyze(_ records: [Int: WordLearningRecord], wordLookup: (Int) -> String?) -> EnhancedDwellTimeAnalysis
}

// MARK: - 默认停留时间分析器（核心实现）⭐

/// 默认停留时间分析器
///
/// 核心功能：
/// 1. 按停留时间降序排序（时间表生成）⭐
/// 2. 自动分类单词（5个等级）
/// 3. 统计分布和指标
/// 4. 支持AI短文输入
final class DefaultDwellTimeAnalyzer: DwellTimeAnalyzer {
    
    // MARK: - Configuration
    
    struct Config {
        let minimumExposures: Int  // 最少曝光次数（过滤噪音）
        let includeZeroDwell: Bool  // 是否包含停留为0的记录
        
        static let `default` = Config(
            minimumExposures: 1,
            includeZeroDwell: false
        )
    }
    
    private let config: Config
    
    init(config: Config = .default) {
        self.config = config
        
        #if DEBUG
        print("[DwellAnalyzer] Initialized with config: minExposures=\(config.minimumExposures), includeZero=\(config.includeZeroDwell)")
        #endif
    }
    
    // MARK: - DwellTimeAnalyzer Protocol
    
    func analyze(_ records: [Int: WordLearningRecord]) -> DwellTimeAnalysis {
        #if DEBUG
        print("[DwellAnalyzer] analyze: processing \(records.count) records")
        #endif
        
        // 1. 过滤有效记录
        let validRecords = filterValidRecords(records)
        
        #if DEBUG
        print("[DwellAnalyzer] Valid records: \(validRecords.count)")
        #endif
        
        // 2. 按停留时间降序排序 ⭐ 核心
        let sorted = sortByDwellTime(validRecords)
        
        // 3. 分类
        let classified = classifyByDwellTime(sorted)
        
        // 4. 统计
        let stats = calculateStatistics(sorted)
        
        // 5. 分布
        let distribution = calculateDistribution(sorted)
        
        #if DEBUG
        print("[DwellAnalyzer] Results:")
        print("  - Total: \(sorted.count)")
        print("  - Avg dwell: \(String(format: "%.2f", stats.average))s")
        print("  - Median: \(String(format: "%.2f", stats.median))s")
        print("  - Very familiar: \(classified.veryFamiliar.count)")
        print("  - Familiar: \(classified.familiar.count)")
        print("  - Unfamiliar: \(classified.unfamiliar.count)")
        print("  - Difficult: \(classified.difficult.count)")
        print("  - Very difficult: \(classified.veryDifficult.count)")
        #endif
        
        return DwellTimeAnalysis(
            sortedByDwellTime: sorted,
            veryFamiliar: classified.veryFamiliar,
            familiar: classified.familiar,
            unfamiliar: classified.unfamiliar,
            difficult: classified.difficult,
            veryDifficult: classified.veryDifficult,
            totalWords: sorted.count,
            avgDwellTime: stats.average,
            medianDwellTime: stats.median,
            distribution: distribution
        )
    }
    
    func analyze(_ records: [Int: WordLearningRecord], wordLookup: (Int) -> String?) -> EnhancedDwellTimeAnalysis {
        let basic = analyze(records)
        
        // 增强：添加单词文本
        let enhancedSorted = basic.sortedByDwellTime.map { record in
            EnhancedWordRecord(
                record: record,
                word: wordLookup(record.id) ?? "unknown"
            )
        }
        
        return EnhancedDwellTimeAnalysis(
            basicAnalysis: basic,
            sortedWithWords: enhancedSorted,
            topDifficultWords: Array(enhancedSorted.prefix(10).map { $0.word })
        )
    }
    
    // MARK: - Private Methods
    
    /// 过滤有效记录
    private func filterValidRecords(_ records: [Int: WordLearningRecord]) -> [WordLearningRecord] {
        records.values.filter { record in
            // 过滤：至少曝光过一次
            guard record.totalExposureCount >= config.minimumExposures else {
                return false
            }
            
            // 过滤：停留时间为0的记录（如果配置不包含）
            if !config.includeZeroDwell && record.avgDwellTime == 0 {
                return false
            }
            
            return true
        }
    }
    
    /// 按停留时间降序排序（核心算法）⭐
    private func sortByDwellTime(_ records: [WordLearningRecord]) -> [WordLearningRecord] {
        records.sorted { $0.avgDwellTime > $1.avgDwellTime }
    }
    
    /// 按停留时间分类
    private func classifyByDwellTime(_ records: [WordLearningRecord]) -> (
        veryFamiliar: [WordLearningRecord],
        familiar: [WordLearningRecord],
        unfamiliar: [WordLearningRecord],
        difficult: [WordLearningRecord],
        veryDifficult: [WordLearningRecord]
    ) {
        var veryFamiliar: [WordLearningRecord] = []
        var familiar: [WordLearningRecord] = []
        var unfamiliar: [WordLearningRecord] = []
        var difficult: [WordLearningRecord] = []
        var veryDifficult: [WordLearningRecord] = []
        
        for record in records {
            let range = DwellTimeRange.fromDwellTime(record.avgDwellTime)
            
            switch range {
            case .veryFast:
                veryFamiliar.append(record)
            case .fast:
                familiar.append(record)
            case .medium:
                unfamiliar.append(record)
            case .slow:
                difficult.append(record)
            case .verySlow:
                veryDifficult.append(record)
            }
        }
        
        return (veryFamiliar, familiar, unfamiliar, difficult, veryDifficult)
    }
    
    /// 计算统计指标
    private func calculateStatistics(_ records: [WordLearningRecord]) -> (average: TimeInterval, median: TimeInterval) {
        guard !records.isEmpty else {
            return (0, 0)
        }
        
        // 平均值
        let total = records.reduce(0.0) { $0 + $1.avgDwellTime }
        let average = total / Double(records.count)
        
        // 中位数
        let sortedTimes = records.map { $0.avgDwellTime }.sorted()
        let median: TimeInterval
        if sortedTimes.count % 2 == 0 {
            let mid = sortedTimes.count / 2
            median = (sortedTimes[mid - 1] + sortedTimes[mid]) / 2
        } else {
            median = sortedTimes[sortedTimes.count / 2]
        }
        
        return (average, median)
    }
    
    /// 计算停留时间分布
    private func calculateDistribution(_ records: [WordLearningRecord]) -> [DwellTimeRange: Int] {
        var distribution: [DwellTimeRange: Int] = [:]
        
        for range in DwellTimeRange.allCases {
            distribution[range] = 0
        }
        
        for record in records {
            let range = DwellTimeRange.fromDwellTime(record.avgDwellTime)
            distribution[range, default: 0] += 1
        }
        
        return distribution
    }
}

// MARK: - 增强分析结果（包含单词文本）

/// 增强的停留时间分析结果（包含单词文本）
struct EnhancedDwellTimeAnalysis {
    let basicAnalysis: DwellTimeAnalysis
    let sortedWithWords: [EnhancedWordRecord]
    let topDifficultWords: [String]  // AI短文生成直接可用 ⭐
    
    var avgDwellTime: TimeInterval {
        basicAnalysis.avgDwellTime
    }
    
    var masteryRate: Double {
        basicAnalysis.masteryRate
    }
    
    var difficultyRate: Double {
        basicAnalysis.difficultyRate
    }
}

/// 增强的单词记录（包含单词文本）
struct EnhancedWordRecord {
    let record: WordLearningRecord
    let word: String
    
    var wid: Int { record.id }
    var avgDwellTime: TimeInterval { record.avgDwellTime }
    var swipeRightCount: Int { record.swipeRightCount }
    var swipeLeftCount: Int { record.swipeLeftCount }
    var remainingExposures: Int { record.remainingExposures }
    
    // 显示格式
    var dwellTimeFormatted: String {
        String(format: "%.1fs", avgDwellTime)
    }
    
    var swipeIndicator: String {
        if swipeRightCount > swipeLeftCount {
            return "→\(swipeRightCount)"
        } else {
            return "←\(swipeLeftCount)"
        }
    }
}

// MARK: - 高级分析器（多维度分析）

/// 高级停留时间分析器
///
/// 提供更多分析维度：
/// - 时间趋势（前半vs后半）
/// - 效率曲线
/// - 困难词簇
final class AdvancedDwellTimeAnalyzer: DwellTimeAnalyzer {
    
    private let baseAnalyzer: DefaultDwellTimeAnalyzer
    
    init(config: DefaultDwellTimeAnalyzer.Config = .default) {
        self.baseAnalyzer = DefaultDwellTimeAnalyzer(config: config)
    }
    
    func analyze(_ records: [Int: WordLearningRecord]) -> DwellTimeAnalysis {
        baseAnalyzer.analyze(records)
    }
    
    func analyze(_ records: [Int: WordLearningRecord], wordLookup: (Int) -> String?) -> EnhancedDwellTimeAnalysis {
        baseAnalyzer.analyze(records, wordLookup: wordLookup)
    }
    
    /// 分析时间趋势（学习效率变化）
    func analyzeTrend(_ records: [Int: WordLearningRecord]) -> TimeTrend {
        let sorted = records.values
            .filter { $0.totalExposureCount > 0 }
            .sorted { $0.id < $1.id }  // 按学习顺序
        
        guard sorted.count >= 10 else {
            return TimeTrend(improving: false, stable: true)
        }
        
        // 前半部分 vs 后半部分
        let midPoint = sorted.count / 2
        let firstHalf = sorted.prefix(midPoint)
        let secondHalf = sorted.suffix(sorted.count - midPoint)
        
        let avgFirst = firstHalf.reduce(0.0) { $0 + $1.avgDwellTime } / Double(firstHalf.count)
        let avgSecond = secondHalf.reduce(0.0) { $0 + $1.avgDwellTime } / Double(secondHalf.count)
        
        // 后半部分停留时间更短 = 学习效率提升
        let improving = avgSecond < avgFirst * 0.9
        let stable = abs(avgSecond - avgFirst) < avgFirst * 0.1
        
        #if DEBUG
        print("[AdvancedAnalyzer] Trend: first=\(String(format: "%.2f", avgFirst))s, second=\(String(format: "%.2f", avgSecond))s, improving=\(improving)")
        #endif
        
        return TimeTrend(improving: improving, stable: stable)
    }
}

struct TimeTrend {
    let improving: Bool  // 学习效率提升
    let stable: Bool  // 稳定
    
    var description: String {
        if improving {
            return "学习效率提升中"
        } else if stable {
            return "学习状态稳定"
        } else {
            return "需要调整学习方法"
        }
    }
}

// MARK: - 分析器工厂

/// 停留时间分析器工厂
enum DwellTimeAnalyzerFactory {
    
    /// 获取默认分析器
    static func defaultAnalyzer() -> DwellTimeAnalyzer {
        DefaultDwellTimeAnalyzer()
    }
    
    /// 获取高级分析器
    static func advancedAnalyzer() -> AdvancedDwellTimeAnalyzer {
        AdvancedDwellTimeAnalyzer()
    }
    
    /// 获取自定义配置的分析器
    static func customAnalyzer(minimumExposures: Int, includeZeroDwell: Bool = false) -> DwellTimeAnalyzer {
        let config = DefaultDwellTimeAnalyzer.Config(
            minimumExposures: minimumExposures,
            includeZeroDwell: includeZeroDwell
        )
        return DefaultDwellTimeAnalyzer(config: config)
    }
}

// MARK: - 辅助扩展

extension DwellTimeAnalysis {
    
    /// 生成文本摘要
    var textSummary: String {
        """
        停留时间分析：
        • 总词数：\(totalWords)
        • 平均停留：\(String(format: "%.1f", avgDwellTime))秒
        • 中位数：\(String(format: "%.1f", medianDwellTime))秒
        • 掌握率：\(Int(masteryRate * 100))%
        • 困难率：\(Int(difficultyRate * 100))%
        
        分类：
        • 非常熟悉(<2s)：\(veryFamiliar.count)个
        • 基本熟悉(2-5s)：\(familiar.count)个
        • 不够熟悉(5-8s)：\(unfamiliar.count)个
        • 困难(8-10s)：\(difficult.count)个
        • 极度困难(>10s)：\(veryDifficult.count)个
        """
    }
    
    /// 生成简洁摘要
    var briefSummary: String {
        """
        共\(totalWords)词，平均停留\(String(format: "%.1f", avgDwellTime))秒
        熟悉\(veryFamiliar.count + familiar.count)个，困难\(unfamiliar.count + difficult.count + veryDifficult.count)个
        """
    }
    
    /// 打印时间表（前10个最困难的）
    func printTopDifficult(count: Int = 10) {
        print("\n=== 困难词Top \(count)（按停留时间排序）===")
        for (index, record) in sortedByDwellTime.prefix(count).enumerated() {
            let range = DwellTimeRange.fromDwellTime(record.avgDwellTime)
            print("\(index + 1). wid=\(record.id): \(String(format: "%.1f", record.avgDwellTime))s, right=\(record.swipeRightCount), left=\(record.swipeLeftCount), \(range.displayName) \(range.emoji)")
        }
        print("=====================================\n")
    }
}

// MARK: - 使用示例和文档

/*
 
 ## 使用示例
 
 ### 基本使用
 
 ```swift
 // 创建分析器
 let analyzer = DwellTimeAnalyzerFactory.defaultAnalyzer()
 
 // 分析学习记录
 let analysis = analyzer.analyze(learningRecords)
 
 // 查看结果
 print(analysis.textSummary)
 analysis.printTopDifficult(count: 10)
 
 // 获取困难词（用于AI短文）
 let difficultWords = analysis.getTopDifficultWords(count: 10)
 ```
 
 ### 在 ReportViewModel 中使用
 
 ```swift
 class ReportViewModel {
     private let dwellAnalyzer: DwellTimeAnalyzer
     
     init(dwellAnalyzer: DwellTimeAnalyzer = DwellTimeAnalyzerFactory.defaultAnalyzer()) {
         self.dwellAnalyzer = dwellAnalyzer
     }
     
     func generateDailyReport(
         goal: LearningGoal,
         day: Int,
         records: [Int: WordLearningRecord],
         duration: TimeInterval,
         totalExposures: Int,
         words: [Word]
     ) -> DailyReport {
         // 使用分析器生成停留时间分析 ⭐
         let analysis = dwellAnalyzer.analyze(records) { wid in
             words.first(where: { $0.id == wid })?.word
         }
         
         // 生成报告
         return DailyReport(
             id: day,
             goalId: goal.id,
             reportDate: Date(),
             day: day,
             totalWordsStudied: analysis.totalWords,
             totalExposures: totalExposures,
             studyDuration: duration,
             swipeRightCount: records.values.reduce(0) { $0 + $1.swipeRightCount },
             swipeLeftCount: records.values.reduce(0) { $0 + $1.swipeLeftCount },
             avgDwellTime: analysis.avgDwellTime,
             sortedByDwellTime: analysis.sortedWithWords.map { ... },  // 转换
             familiarWords: analysis.basicAnalysis.veryFamiliar.map { $0.id },
             unfamiliarWords: (analysis.basicAnalysis.unfamiliar + analysis.basicAnalysis.difficult + analysis.basicAnalysis.veryDifficult).map { $0.id }
         )
     }
 }
 ```
 
 ### 自动触发AI短文生成
 
 ```swift
 func completeStudy() {
     // 生成分析
     let analysis = dwellAnalyzer.analyze(learningRecords, wordLookup: getWordText)
     
     // 检查是否需要生成AI短文
     if analysis.basicAnalysis.difficultyRate > 0.3 {  // 困难率>30%
         let difficultWords = analysis.topDifficultWords
         
         Task {
             let passage = try await deepSeekService.generateReadingPassage(
                 difficultWords: difficultWords,
                 topic: .auto
             )
             print("[AI] Generated reading passage with \(difficultWords.count) difficult words")
         }
     }
 }
 ```
 
 ### 选择明日复习词
 
 ```swift
 // TaskScheduler 中
 func selectReviewWords(from yesterdayAnalysis: DwellTimeAnalysis) -> [Int] {
     // 选择停留时间最长的20个词作为明日复习 ⭐
     yesterdayAnalysis.getWordsNeedingReview(count: 20)
 }
 ```
 
 ## 业务价值
 
 ### 1. 每日时间表生成 ⭐⭐⭐
 
 ```
 学习完成 → 分析器 → 按停留时间排序 → 每日时间表
 
 时间表示例：
 1. abandonment  12.5s  ←3  (极度困难)
 2. resilient    9.8s   ←2  (困难)
 3. elaborate    8.3s   ←2  (困难)
 ...
 50. ability     1.2s   →9  (非常熟悉)
 ```
 
 ### 2. 自动识别困难词 ⭐⭐⭐
 
 ```
 停留>5s → 标记为困难词 → 明日重点复习
 停留>8s → 生成AI短文 → 加深理解
 ```
 
 ### 3. 学习效率洞察 ⭐⭐
 
 ```
 前半部分平均停留 vs 后半部分
 → 判断学习效率是否提升
 → 给出调整建议
 ```
 
 ### 4. 支持多种视图 ⭐⭐
 
 ```
 DwellTimeAnalysis → DailyReportView（每日报告）
                  → StatisticsView（统计页面）
                  → AI短文生成（困难词输入）
                  → 任务调度（明日复习词）
 ```
 
 ## 设计模式
 
 ### 策略模式
 - DwellTimeAnalyzer 协议定义接口
 - DefaultDwellTimeAnalyzer 标准实现
 - AdvancedDwellTimeAnalyzer 高级实现
 
 ### 工厂模式
 - DwellTimeAnalyzerFactory 创建分析器
 
 ### 值对象模式
 - DwellTimeAnalysis 不可变结果对象
 - EnhancedDwellTimeAnalysis 增强结果
 
 ## 性能特点
 
 - 排序复杂度：O(n log n)
 - 分类复杂度：O(n)
 - 统计复杂度：O(n)
 - 总体：O(n log n)，对于几百个单词非常快
 
 */

