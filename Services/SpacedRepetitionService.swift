//
//  SpacedRepetitionService.swift
//  NFwordsDemo
//
//  间隔重复算法服务（基于 SM-2 算法）
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 间隔重复算法服务
/// 基于 SuperMemo 2 (SM-2) 算法的间隔重复服务
/// 
/// SM-2 算法是 Anki 等主流学习软件使用的核心算法，通过动态调整复习间隔
/// 来优化记忆效果，减少无效重复，提高学习效率。
final class SpacedRepetitionService {
    static let shared = SpacedRepetitionService()
    
    private init() {}
    
    // MARK: - 算法参数
    
    /// 易度因子的最小值和最大值
    private let minEaseFactor: Double = 1.3
    private let maxEaseFactor: Double = 2.5
    private let defaultEaseFactor: Double = 2.5
    
    /// 初始间隔（天）
    private let initialInterval: Int = 1
    
    /// 质量评分到易度因子调整的映射
    /// Quality: 0=完全忘记, 1=困难, 2=一般, 3=容易, 4=非常简单, 5=完美
    private func easeFactorAdjustment(for quality: Int) -> Double {
        switch quality {
        case 0: return -0.20  // 完全忘记，大幅降低
        case 1: return -0.15  // 困难，降低
        case 2: return -0.10  // 一般，小幅降低
        case 3: return 0.0    // 容易，不变
        case 4: return 0.05   // 非常简单，小幅提升
        case 5: return 0.10   // 完美，提升
        default: return 0.0
        }
    }
    
    // MARK: - 核心算法
    
    /// 计算下次复习时间和新的易度因子
    /// - Parameters:
    ///   - currentInterval: 当前间隔（天）
    ///   - easeFactor: 当前易度因子
    ///   - quality: 用户回答质量（0-5）
    ///   - lastReviewDate: 上次复习日期
    /// - Returns: 新的间隔、易度因子和下次复习日期
    func calculateNextReview(
        currentInterval: Int,
        easeFactor: Double,
        quality: Int,
        lastReviewDate: Date
    ) -> (interval: Int, easeFactor: Double, nextReviewDate: Date) {
        
        // 1. 调整易度因子
        let adjustment = easeFactorAdjustment(for: quality)
        var newEaseFactor = easeFactor + adjustment
        
        // 限制易度因子范围
        newEaseFactor = max(minEaseFactor, min(maxEaseFactor, newEaseFactor))
        
        // 2. 计算新间隔
        let newInterval: Int
        
        if quality < 3 {
            // 回答质量低于3（困难/一般），重置间隔
            newInterval = initialInterval
        } else {
            // 回答质量≥3，根据易度因子和当前间隔计算新间隔
            if currentInterval == 0 {
                // 首次学习
                newInterval = initialInterval
            } else {
                // 后续复习：新间隔 = 当前间隔 × 易度因子
                newInterval = Int(ceil(Double(currentInterval) * newEaseFactor))
            }
        }
        
        // 3. 计算下次复习日期
        let calendar = Calendar.current
        let nextReviewDate = calendar.date(
            byAdding: .day,
            value: newInterval,
            to: lastReviewDate
        ) ?? lastReviewDate
        
        return (newInterval, newEaseFactor, nextReviewDate)
    }
    
    /// 根据滑动方向和停留时间计算质量评分
    /// - Parameters:
    ///   - direction: 滑动方向（right=会写, left=不会写）
    ///   - dwellTime: 停留时间（秒）
    ///   - avgDwellTime: 平均停留时间（用于对比）
    /// - Returns: 质量评分（0-5）
    func calculateQuality(
        direction: SwipeDirection,
        dwellTime: TimeInterval,
        avgDwellTime: TimeInterval = 0
    ) -> Int {
        switch direction {
        case .right:
            // 右滑（会写）
            if dwellTime < 1.0 {
                return 5  // 非常快，完美
            } else if dwellTime < 2.0 {
                return 4  // 快，非常简单
            } else if dwellTime < 3.0 {
                return 3  // 正常，容易
            } else {
                return 2  // 较慢，一般
            }
            
        case .left:
            // 左滑（不会写）
            if dwellTime < 2.0 {
                return 1  // 快速放弃，困难
            } else {
                return 0  // 长时间思考后放弃，完全忘记
            }
        }
    }
    
    /// 检查单词是否需要复习
    /// - Parameters:
    ///   - nextReviewDate: 下次复习日期
    ///   - currentDate: 当前日期（默认今天）
    /// - Returns: 是否需要复习
    func shouldReview(
        nextReviewDate: Date?,
        currentDate: Date = Date()
    ) -> Bool {
        guard let nextReviewDate = nextReviewDate else {
            // 如果没有下次复习日期，需要复习
            return true
        }
        
        let calendar = Calendar.current
        let comparison = calendar.compare(currentDate, to: nextReviewDate, toGranularity: .day)
        
        // 如果当前日期 >= 下次复习日期，需要复习
        return comparison != .orderedAscending
    }
    
    /// 获取需要复习的单词列表
    /// - Parameters:
    ///   - records: 所有学习记录
    ///   - currentDate: 当前日期
    /// - Returns: 需要复习的单词ID列表
    func getWordsDueForReview(
        records: [Int: WordLearningRecord],
        currentDate: Date = Date()
    ) -> [Int] {
        records.compactMap { (wordId, record) in
            if shouldReview(nextReviewDate: record.nextReviewDate, currentDate: currentDate) {
                return wordId
            }
            return nil
        }
    }
    
    /// 计算学习阶段
    /// - Parameters:
    ///   - reviewCount: 复习次数
    ///   - interval: 当前间隔（天）
    ///   - easeFactor: 易度因子
    /// - Returns: 学习阶段
    func calculateLearningPhase(
        reviewCount: Int,
        interval: Int,
        easeFactor: Double
    ) -> LearningPhase {
        if reviewCount == 0 {
            return .initial
        } else if reviewCount < 3 || interval < 7 {
            return .reinforcement
        } else if interval < 30 {
            return .consolidation
        } else {
            return .maintenance
        }
    }
    
    /// 计算掌握等级
    /// - Parameters:
    ///   - reviewCount: 复习次数
    ///   - interval: 当前间隔（天）
    ///   - consecutiveCorrect: 连续正确次数
    ///   - lapses: 遗忘次数
    /// - Returns: 掌握等级
    func calculateMasteryLevel(
        reviewCount: Int,
        interval: Int,
        consecutiveCorrect: Int,
        lapses: Int
    ) -> MasteryLevel {
        // 如果连续正确≥5次且间隔≥30天，认为已掌握
        if consecutiveCorrect >= 5 && interval >= 30 && lapses == 0 {
            return .mastered
        }
        
        // 如果连续正确≥3次且间隔≥14天，认为高级
        if consecutiveCorrect >= 3 && interval >= 14 {
            return .advanced
        }
        
        // 如果复习次数≥2，认为中级
        if reviewCount >= 2 {
            return .intermediate
        }
        
        // 否则为初级
        return .beginner
    }
}

// MARK: - 学习阶段枚举
enum LearningPhase: String, Codable, CaseIterable {
    case initial = "initial"                    // 初始学习
    case reinforcement = "reinforcement"        // 强化阶段
    case consolidation = "consolidation"        // 巩固阶段
    case maintenance = "maintenance"            // 维持阶段
    
    var displayName: String {
        switch self {
        case .initial: return "初始学习"
        case .reinforcement: return "强化阶段"
        case .consolidation: return "巩固阶段"
        case .maintenance: return "维持阶段"
        }
    }
}

// MARK: - 掌握等级枚举
enum MasteryLevel: String, Codable, CaseIterable {
    case beginner = "beginner"          // 初级
    case intermediate = "intermediate"   // 中级
    case advanced = "advanced"         // 高级
    case mastered = "mastered"          // 已掌握
    
    var displayName: String {
        switch self {
        case .beginner: return "初级"
        case .intermediate: return "中级"
        case .advanced: return "高级"
        case .mastered: return "已掌握"
        }
    }
    
    var progress: Double {
        switch self {
        case .beginner: return 0.25
        case .intermediate: return 0.50
        case .advanced: return 0.75
        case .mastered: return 1.0
        }
    }
}

