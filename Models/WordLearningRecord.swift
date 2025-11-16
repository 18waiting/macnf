//
//  WordLearningRecord.swift
//  NFwordsDemo
//
//  Created by 甘名杨 on 2025/11/1.
//

//
//  WordLearningRecord.swift
//  NFwords Demo
//
//  单词学习记录模型 - 支持间隔重复算法
//

import Foundation

// MARK: - 学习记录
struct WordLearningRecord: Identifiable, Codable {
    let id: Int  // wid
    var swipeRightCount: Int = 0  // 右滑次数（会写）
    var swipeLeftCount: Int = 0  // 左滑次数（不会写）
    var totalExposureCount: Int = 0  // 总曝光次数
    var remainingExposures: Int = 10  // 剩余曝光次数（兼容旧逻辑）
    var targetExposures: Int = 10  // 目标曝光次数
    
    var dwellTimes: [TimeInterval] = []  // 每次停留时间
    var totalDwellTime: TimeInterval = 0
    
    // MARK: - ⭐ 新增：间隔重复算法支持
    
    /// 易度因子（1.3-2.5），默认 2.5
    /// 值越大，复习间隔增长越快
    var easeFactor: Double = 2.5
    
    /// 当前复习间隔（天）
    var interval: Int = 0
    
    /// 上次复习日期
    var lastReviewDate: Date?
    
    /// 下次复习日期
    var nextReviewDate: Date?
    
    /// 复习次数
    var reviewCount: Int = 0
    
    /// 遗忘次数（连续错误）
    var lapses: Int = 0
    
    /// 连续正确次数
    var consecutiveCorrect: Int = 0
    
    /// 连续错误次数
    var consecutiveIncorrect: Int = 0
    
    /// 学习阶段
    var learningPhase: LearningPhase = .initial
    
    /// 掌握等级
    var masteryLevel: MasteryLevel = .beginner
    
    /// 首次学习日期
    var firstLearnedDate: Date?
    
    // MARK: - 计算属性
    
    var avgDwellTime: TimeInterval {
        guard !dwellTimes.isEmpty else { return 0 }
        return dwellTimes.reduce(0, +) / Double(dwellTimes.count)
    }
    
    /// 是否已掌握（兼容旧逻辑，同时考虑新算法）
    var isMastered: Bool {
        // 新算法：掌握等级为 mastered
        if masteryLevel == .mastered {
            return true
        }
        
        // 旧逻辑：右滑≥3次 且 平均停留<2秒
        return swipeRightCount >= 3 && avgDwellTime < 2.0
    }
    
    /// 熟悉度分数（0-100）
    var familiarityScore: Int {
        // 基于掌握等级的基础分数
        let masteryScore = masteryLevel.progress * 50
        
        // 基于正确率
        let rightRatio = Double(swipeRightCount) / max(Double(totalExposureCount), 1.0)
        let accuracyScore = rightRatio * 30
        
        // 基于停留时间（停留越短分数越高）
        let dwellScore = max(0, (3.0 - avgDwellTime) / 3.0) * 20
        
        return Int(masteryScore + accuracyScore + dwellScore)
    }
    
    /// 是否需要复习
    var isDueForReview: Bool {
        guard let nextReviewDate = nextReviewDate else {
            // 如果没有下次复习日期，需要复习
            return true
        }
        
        let calendar = Calendar.current
        let comparison = calendar.compare(Date(), to: nextReviewDate, toGranularity: .day)
        return comparison != .orderedAscending
    }
    
    /// 距离下次复习的天数
    var daysUntilReview: Int? {
        guard let nextReviewDate = nextReviewDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: nextReviewDate)
        return components.day
    }
    
    // MARK: - 方法
    
    /// 记录滑动（兼容旧逻辑，同时更新间隔重复算法数据）
    mutating func recordSwipe(direction: SwipeDirection, dwellTime: TimeInterval) {
        let now = Date()
        
        // 更新基础统计
        totalExposureCount += 1
        remainingExposures = max(0, remainingExposures - 1)
        dwellTimes.append(dwellTime)
        totalDwellTime += dwellTime
        
        // 记录首次学习日期
        if firstLearnedDate == nil {
            firstLearnedDate = now
        }
        
        // 更新滑动计数
        switch direction {
        case .right:
            swipeRightCount += 1
            consecutiveCorrect += 1
            consecutiveIncorrect = 0
        case .left:
            swipeLeftCount += 1
            consecutiveIncorrect += 1
            consecutiveCorrect = 0
            lapses += 1
        }
        
        // 使用间隔重复算法计算下次复习
        let service = SpacedRepetitionService.shared
        let quality = service.calculateQuality(
            direction: direction,
            dwellTime: dwellTime,
            avgDwellTime: avgDwellTime
        )
        
        let lastReview = lastReviewDate ?? now
        let (newInterval, newEaseFactor, nextReview) = service.calculateNextReview(
            currentInterval: interval,
            easeFactor: easeFactor,
            quality: quality,
            lastReviewDate: lastReview
        )
        
        // 更新间隔重复算法数据
        interval = newInterval
        easeFactor = newEaseFactor
        lastReviewDate = now
        nextReviewDate = nextReview
        
        // 如果是复习（不是首次学习），增加复习次数
        if reviewCount > 0 || lastReviewDate != nil {
            reviewCount += 1
        }
        
        // 更新学习阶段和掌握等级
        learningPhase = service.calculateLearningPhase(
            reviewCount: reviewCount,
            interval: interval,
            easeFactor: easeFactor
        )
        
        masteryLevel = service.calculateMasteryLevel(
            reviewCount: reviewCount,
            interval: interval,
            consecutiveCorrect: consecutiveCorrect,
            lapses: lapses
        )
    }
    
    /// 初始化学习记录（支持间隔重复算法）
    static func initial(wid: Int, targetExposures: Int = 10) -> WordLearningRecord {
        WordLearningRecord(
            id: wid,
            remainingExposures: targetExposures,
            targetExposures: targetExposures,
            easeFactor: 2.5,
            interval: 0,
            learningPhase: .initial,
            masteryLevel: .beginner,
            firstLearnedDate: Date()
        )
    }
}

// MARK: - 滑动方向
enum SwipeDirection: String {
    case left = "left"   // 不会写
    case right = "right"  // 会写
}

