//
//  ExposureStrategy.swift
//  NFwordsDemo
//
//  曝光策略核心组件 - 体现"量变引起质变"理念
//  Created by AI Assistant on 2025/11/5.
//

import Foundation

// MARK: - 曝光策略协议

/// 曝光策略协议
/// 定义如何决定每个单词需要曝光的次数
protocol ExposureStrategy {
    /// 计算单词需要的曝光次数
    /// - Parameter state: 单词学习状态
    /// - Returns: 建议的曝光次数
    func calculateExposures(for state: WordLearningRecord) -> Int
    
    /// 判断是否需要继续曝光
    /// - Parameter state: 单词学习状态
    /// - Returns: true = 继续曝光，false = 已掌握，可停止
    func shouldContinueExposure(for state: WordLearningRecord) -> Bool
    
    /// 获取策略名称和描述
    var strategyName: String { get }
    var strategyDescription: String { get }
}

// MARK: - 基于停留时间的曝光策略（核心实现）⭐

/// 基于停留时间的量化曝光策略
///
/// 核心理念：停留时间越长 = 越不熟悉 = 需要更多次曝光
///
/// 算法：
/// - 停留<2秒（熟悉）→ 3次曝光
/// - 停留2-5秒（一般）→ 5次曝光
/// - 停留5-8秒（不熟）→ 7次曝光
/// - 停留>8秒（陌生）→ 10次曝光
///
/// 调整因子：
/// - 连续右滑（会写）→ 减少曝光
/// - 连续左滑（不会写）→ 增加曝光
final class DwellTimeExposureStrategy: ExposureStrategy {
    
    // MARK: - 配置参数（可调整）
    
    /// 停留时间阈值（秒）
    struct Thresholds {
        let veryFamiliar: TimeInterval  // <2s
        let familiar: TimeInterval  // 2-5s
        let unfamiliar: TimeInterval  // 5-8s
        let veryUnfamiliar: TimeInterval  // >8s
        
        static let `default` = Thresholds(
            veryFamiliar: 2.0,
            familiar: 5.0,
            unfamiliar: 8.0,
            veryUnfamiliar: Double.infinity
        )
    }
    
    /// 曝光次数配置
    struct ExposureCounts {
        let veryFamiliar: Int  // 3次
        let familiar: Int  // 5次
        let unfamiliar: Int  // 7次
        let veryUnfamiliar: Int  // 10次
        
        static let `default` = ExposureCounts(
            veryFamiliar: 3,
            familiar: 5,
            unfamiliar: 7,
            veryUnfamiliar: 10
        )
    }
    
    /// 调整因子配置
    struct AdjustmentFactors {
        let rightSwipeBonus: Int  // 右滑奖励：-1次
        let leftSwipePenalty: Int  // 左滑惩罚：+2次
        let minExposures: Int  // 最少曝光
        let maxExposures: Int  // 最多曝光
        
        static let `default` = AdjustmentFactors(
            rightSwipeBonus: -1,
            leftSwipePenalty: 2,
            minExposures: 2,
            maxExposures: 15
        )
    }
    
    // MARK: - Properties
    
    private let thresholds: Thresholds
    private let exposureCounts: ExposureCounts
    private let adjustmentFactors: AdjustmentFactors
    
    var strategyName: String {
        "量化曝光策略（基于停留时间）"
    }
    
    var strategyDescription: String {
        """
        核心理念：量变引起质变
        
        算法：
        • 停留<\(thresholds.veryFamiliar)秒 → \(exposureCounts.veryFamiliar)次曝光
        • 停留\(thresholds.veryFamiliar)-\(thresholds.familiar)秒 → \(exposureCounts.familiar)次曝光
        • 停留\(thresholds.familiar)-\(thresholds.unfamiliar)秒 → \(exposureCounts.unfamiliar)次曝光
        • 停留>\(thresholds.unfamiliar)秒 → \(exposureCounts.veryUnfamiliar)次曝光
        
        调整：
        • 连续右滑 → 减少曝光
        • 连续左滑 → 增加曝光
        """
    }
    
    // MARK: - Initialization
    
    init(
        thresholds: Thresholds = .default,
        exposureCounts: ExposureCounts = .default,
        adjustmentFactors: AdjustmentFactors = .default
    ) {
        self.thresholds = thresholds
        self.exposureCounts = exposureCounts
        self.adjustmentFactors = adjustmentFactors
        
        #if DEBUG
        print("[ExposureStrategy] Initialized: \(strategyName)")
        print("[ExposureStrategy] Thresholds: <\(thresholds.veryFamiliar)s, \(thresholds.veryFamiliar)-\(thresholds.familiar)s, \(thresholds.familiar)-\(thresholds.unfamiliar)s, >\(thresholds.unfamiliar)s")
        print("[ExposureStrategy] Counts: \(exposureCounts.veryFamiliar), \(exposureCounts.familiar), \(exposureCounts.unfamiliar), \(exposureCounts.veryUnfamiliar)")
        #endif
    }
    
    // MARK: - ExposureStrategy Protocol
    
    func calculateExposures(for state: WordLearningRecord) -> Int {
        // 1. 基于停留时间的基础曝光次数
        let baseExposures = calculateBaseExposures(dwellTime: state.avgDwellTime)
        
        // 2. 基于左右滑的调整
        let swipeAdjustment = calculateSwipeAdjustment(
            rightCount: state.swipeRightCount,
            leftCount: state.swipeLeftCount
        )
        
        // 3. 最终曝光次数（带上下限）
        let totalExposures = baseExposures + swipeAdjustment
        let clampedExposures = clamp(
            totalExposures,
            min: adjustmentFactors.minExposures,
            max: adjustmentFactors.maxExposures
        )
        
        #if DEBUG
        if state.totalExposureCount > 0 {  // 只对已有记录的单词打印
            print("[ExposureStrategy] wid=\(state.id): dwell=\(String(format: "%.1f", state.avgDwellTime))s, base=\(baseExposures), adjust=\(swipeAdjustment), final=\(clampedExposures)")
        }
        #endif
        
        return clampedExposures
    }
    
    func shouldContinueExposure(for state: WordLearningRecord) -> Bool {
        // 1. 检查剩余次数
        guard state.remainingExposures > 0 else {
            #if DEBUG
            print("[ExposureStrategy] wid=\(state.id): No remaining exposures, stop")
            #endif
            return false
        }
        
        // 2. 提前掌握检查（优化：避免过度曝光）
        if isEarlyMastery(state) {
            #if DEBUG
            print("[ExposureStrategy] wid=\(state.id): Early mastery detected (right≥3, dwell<2s), can stop")
            #endif
            return false
        }
        
        // 3. 需要继续
        return true
    }
    
    // MARK: - Private Helpers
    
    /// 计算基础曝光次数（基于停留时间）
    private func calculateBaseExposures(dwellTime: TimeInterval) -> Int {
        switch dwellTime {
        case 0..<thresholds.veryFamiliar:
            return exposureCounts.veryFamiliar  // <2s → 3次
        case thresholds.veryFamiliar..<thresholds.familiar:
            return exposureCounts.familiar  // 2-5s → 5次
        case thresholds.familiar..<thresholds.unfamiliar:
            return exposureCounts.unfamiliar  // 5-8s → 7次
        default:
            return exposureCounts.veryUnfamiliar  // >8s → 10次
        }
    }
    
    /// 计算左右滑调整值
    private func calculateSwipeAdjustment(rightCount: Int, leftCount: Int) -> Int {
        var adjustment = 0
        
        // 连续右滑（会写）→ 减少曝光
        if rightCount > leftCount {
            let rightDominance = rightCount - leftCount
            adjustment += rightDominance * adjustmentFactors.rightSwipeBonus  // -1次
        }
        
        // 连续左滑（不会写）→ 增加曝光
        if leftCount > rightCount {
            let leftDominance = leftCount - rightCount
            adjustment += leftDominance * adjustmentFactors.leftSwipePenalty  // +2次
        }
        
        return adjustment
    }
    
    /// 提前掌握判定（优化学习效率）
    private func isEarlyMastery(_ state: WordLearningRecord) -> Bool {
        // 条件：右滑≥3次 且 平均停留<2秒
        state.swipeRightCount >= 3 && state.avgDwellTime < thresholds.veryFamiliar
    }
    
    /// 数值限制
    private func clamp(_ value: Int, min minValue: Int, max maxValue: Int) -> Int {
        max(minValue, min(maxValue, value))
    }
}

// MARK: - 固定曝光策略（简单模式）

/// 固定曝光次数策略（不考虑停留时间）
///
/// 适用场景：
/// - 快速测试
/// - 不需要复杂算法的场景
final class FixedExposureStrategy: ExposureStrategy {
    private let fixedCount: Int
    
    var strategyName: String {
        "固定曝光策略"
    }
    
    var strategyDescription: String {
        "所有单词固定曝光 \(fixedCount) 次"
    }
    
    init(exposureCount: Int = 10) {
        self.fixedCount = exposureCount
    }
    
    func calculateExposures(for state: WordLearningRecord) -> Int {
        fixedCount
    }
    
    func shouldContinueExposure(for state: WordLearningRecord) -> Bool {
        state.remainingExposures > 0
    }
}

// MARK: - 自适应曝光策略（高级）

/// 自适应曝光策略（根据学习进度动态调整）
///
/// 特点：
/// - 学习初期：高曝光（帮助建立记忆）
/// - 学习中期：中曝光（巩固记忆）
/// - 学习后期：低曝光（维持记忆）
final class AdaptiveExposureStrategy: ExposureStrategy {
    
    private let baseStrategy: DwellTimeExposureStrategy
    private let currentDay: Int  // 当前第几天
    private let totalDays: Int  // 总天数
    
    var strategyName: String {
        "自适应曝光策略（第\(currentDay)/\(totalDays)天）"
    }
    
    var strategyDescription: String {
        """
        根据学习进度动态调整：
        • 前期（1-3天）：高曝光，帮助建立记忆
        • 中期（4-7天）：标准曝光
        • 后期（8-10天）：低曝光，快速复习
        """
    }
    
    init(currentDay: Int, totalDays: Int, baseStrategy: DwellTimeExposureStrategy = DwellTimeExposureStrategy()) {
        self.currentDay = currentDay
        self.totalDays = totalDays
        self.baseStrategy = baseStrategy
    }
    
    func calculateExposures(for state: WordLearningRecord) -> Int {
        let baseCount = baseStrategy.calculateExposures(for: state)
        
        // 根据学习阶段调整
        let progress = Double(currentDay) / Double(totalDays)
        let modifier: Double
        
        switch progress {
        case 0..<0.3:  // 前30%（1-3天）
            modifier = 1.2  // +20%
        case 0.3..<0.7:  // 中40%（4-7天）
            modifier = 1.0  // 标准
        default:  // 后30%（8-10天）
            modifier = 0.8  // -20%
        }
        
        let adjusted = Int(Double(baseCount) * modifier)
        
        #if DEBUG
        print("[AdaptiveStrategy] Day \(currentDay)/\(totalDays): base=\(baseCount), modifier=\(modifier), final=\(adjusted)")
        #endif
        
        return max(2, adjusted)  // 最少2次
    }
    
    func shouldContinueExposure(for state: WordLearningRecord) -> Bool {
        baseStrategy.shouldContinueExposure(for: state)
    }
}

// MARK: - 曝光策略工厂

/// 曝光策略工厂
/// 根据不同场景创建合适的策略
enum ExposureStrategyFactory {
    
    /// 获取默认策略（推荐）
    static func defaultStrategy() -> ExposureStrategy {
        DwellTimeExposureStrategy()
    }
    
    /// 获取简单策略（测试用）
    static func simpleStrategy(exposureCount: Int = 10) -> ExposureStrategy {
        FixedExposureStrategy(exposureCount: exposureCount)
    }
    
    /// 获取自适应策略（高级）
    static func adaptiveStrategy(currentDay: Int, totalDays: Int) -> ExposureStrategy {
        AdaptiveExposureStrategy(currentDay: currentDay, totalDays: totalDays)
    }
    
    /// 根据学习目标创建策略
    static func strategyForGoal(_ goal: LearningGoal) -> ExposureStrategy {
        // 如果是10天快速冲刺，使用自适应策略
        if goal.durationDays <= 10 {
            return adaptiveStrategy(currentDay: goal.currentDay, totalDays: goal.durationDays)
        }
        
        // 否则使用标准策略
        return defaultStrategy()
    }
}

// MARK: - 曝光决策器（高级功能）

/// 曝光决策器
/// 结合策略和实际情况，做出最终决策
final class ExposureDecisionMaker {
    private let strategy: ExposureStrategy
    
    init(strategy: ExposureStrategy) {
        self.strategy = strategy
    }
    
    /// 为新单词分配初始曝光次数
    func assignInitialExposures(for wordId: Int, dwellTime: TimeInterval = 0) -> Int {
        // 新词默认给一个中等停留时间（假设不熟悉）
        let mockState = WordLearningRecord(
            id: wordId,
            swipeRightCount: 0,
            swipeLeftCount: 0,
            totalExposureCount: 0,
            remainingExposures: 0,
            targetExposures: 0,
            dwellTimes: [],
            totalDwellTime: 0
        )
        
        return strategy.calculateExposures(for: mockState)
    }
    
    /// 学习过程中动态调整曝光次数
    func adjustExposures(for state: WordLearningRecord) -> Int {
        let recommended = strategy.calculateExposures(for: state)
        
        // 如果已曝光次数接近目标，不再增加
        if state.totalExposureCount >= state.targetExposures {
            return state.targetExposures
        }
        
        // 动态调整目标曝光次数
        return max(recommended, state.targetExposures)
    }
    
    /// 判断是否可以提前结束曝光（优化学习效率）
    func canStopEarly(for state: WordLearningRecord) -> Bool {
        !strategy.shouldContinueExposure(for: state)
    }
}

// MARK: - 使用示例和文档

/*
 
 ## 使用示例
 
 ### 基本使用
 
 ```swift
 // 创建策略
 let strategy = DwellTimeExposureStrategy()
 
 // 计算曝光次数
 let exposures = strategy.calculateExposures(for: wordState)
 // 停留3.5秒 → 返回 5次
 
 // 判断是否继续
 let shouldContinue = strategy.shouldContinueExposure(for: wordState)
 ```
 
 ### 在 StudyViewModel 中使用
 
 ```swift
 class StudyViewModel {
     private let exposureStrategy: ExposureStrategy
     
     init(exposureStrategy: ExposureStrategy = ExposureStrategyFactory.defaultStrategy()) {
         self.exposureStrategy = exposureStrategy
     }
     
     func setupStudyCards(words: [Word]) {
         for word in words {
             // 使用策略分配曝光次数
             let exposures = exposureStrategy.calculateExposures(for: initialState(word))
             
             // 生成对应数量的卡片
             for _ in 0..<exposures {
                 cards.append(StudyCard(word: word, ...))
             }
         }
     }
     
     func handleSwipe(...) {
         // 记录滑动后，检查是否可以提前停止
         if !exposureStrategy.shouldContinueExposure(for: state) {
             // 提前掌握，从队列移除
             removeFromQueue(wordId)
         }
     }
 }
 ```
 
 ### 根据学习目标选择策略
 
 ```swift
 // 10天快速冲刺 → 自适应策略
 let goal = LearningGoal(durationDays: 10, ...)
 let strategy = ExposureStrategyFactory.strategyForGoal(goal)
 
 // Day 1: 高曝光
 // Day 5: 标准曝光
 // Day 10: 低曝光，快速复习
 ```
 
 ### 自定义配置
 
 ```swift
 // 自定义阈值
 let customThresholds = DwellTimeExposureStrategy.Thresholds(
     veryFamiliar: 1.5,  // 更严格的熟悉标准
     familiar: 4.0,
     unfamiliar: 7.0,
     veryUnfamiliar: .infinity
 )
 
 // 自定义曝光次数
 let customCounts = DwellTimeExposureStrategy.ExposureCounts(
     veryFamiliar: 2,  // 熟悉的只曝光2次
     familiar: 4,
     unfamiliar: 6,
     veryUnfamiliar: 12  // 陌生的曝光12次
 )
 
 let strategy = DwellTimeExposureStrategy(
     thresholds: customThresholds,
     exposureCounts: customCounts
 )
 ```
 
 ## 设计模式
 
 ### 策略模式 (Strategy Pattern)
 - ExposureStrategy 协议定义接口
 - DwellTimeExposureStrategy 实现核心算法
 - FixedExposureStrategy 提供简单实现
 - AdaptiveExposureStrategy 提供高级实现
 
 ### 工厂模式 (Factory Pattern)
 - ExposureStrategyFactory 创建合适的策略
 - 根据场景自动选择
 
 ### 决策模式 (Decision Pattern)
 - ExposureDecisionMaker 封装决策逻辑
 - 结合策略和实际情况
 
 ## 扩展性
 
 ### 添加新策略
 
 ```swift
 // 基于艾宾浩斯曲线的策略（如果需要对比）
 class EbbinghausExposureStrategy: ExposureStrategy {
     func calculateExposures(for state: WordLearningRecord) -> Int {
         // 实现艾宾浩斯算法
     }
 }
 ```
 
 ### A/B 测试
 
 ```swift
 // 对比不同策略效果
 let strategyA = DwellTimeExposureStrategy()
 let strategyB = AdaptiveExposureStrategy(...)
 
 // 随机分配用户
 let strategy = userId.hashValue % 2 == 0 ? strategyA : strategyB
 ```
 
 ## 性能考虑
 
 - 所有计算都是 O(1) 复杂度
 - 无副作用（纯函数）
 - 线程安全（无共享状态）
 - 可以并行计算多个单词
 
 */

