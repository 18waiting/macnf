//
//  LearningAnalytics.swift
//  NFwordsDemo
//
//  学习分析模型
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 学习分析
struct LearningAnalytics: Codable {
    // MARK: - 时间分布
    
    /// 按小时的学习时间分布 [小时(0-23): 学习时长(秒)]
    var studyTimeDistribution: [Int: TimeInterval] = [:]
    
    /// 按周的学习时间分布 [日期: 学习时长(秒)]
    var weeklyStudyTime: [Date: TimeInterval] = [:]
    
    /// 按月的学习时间分布 [日期: 学习时长(秒)]
    var monthlyStudyTime: [Date: TimeInterval] = [:]
    
    // MARK: - 学习曲线
    
    /// 学习曲线数据点
    var learningCurve: [LearningCurvePoint] = []
    
    /// 遗忘曲线数据点
    var forgettingCurve: [ForgettingCurvePoint] = []
    
    // MARK: - 效率分析
    
    /// 学习效率分数（0-100）
    var efficiencyScore: Double = 0
    
    /// 最佳学习时段（小时）
    var peakStudyHours: [Int] = []
    
    /// 难度趋势 [日期: 平均难度分数]
    var difficultyTrend: [Date: Double] = [:]
    
    // MARK: - 计算属性
    
    /// 最活跃的学习时段
    var mostActiveHour: Int? {
        studyTimeDistribution.max(by: { $0.value < $1.value })?.key
    }
    
    /// 平均每日学习时长（分钟）
    var averageDailyStudyTime: TimeInterval {
        guard !weeklyStudyTime.isEmpty else { return 0 }
        let total = weeklyStudyTime.values.reduce(0, +)
        return total / Double(weeklyStudyTime.count)
    }
    
    // MARK: - 初始化
    
    static let empty = LearningAnalytics()
}

// MARK: - 学习曲线数据点
struct LearningCurvePoint: Identifiable, Codable {
    let id: UUID
    let date: Date
    let wordsLearned: Int
    let accuracy: Double
    let averageTime: TimeInterval
    
    init(
        id: UUID = UUID(),
        date: Date,
        wordsLearned: Int,
        accuracy: Double,
        averageTime: TimeInterval
    ) {
        self.id = id
        self.date = date
        self.wordsLearned = wordsLearned
        self.accuracy = accuracy
        self.averageTime = averageTime
    }
}

// MARK: - 遗忘曲线数据点
struct ForgettingCurvePoint: Identifiable, Codable {
    let id: UUID
    let daysSinceLearning: Int
    let retentionRate: Double  // 保留率（0-1）
    let reviewCount: Int
    
    init(
        id: UUID = UUID(),
        daysSinceLearning: Int,
        retentionRate: Double,
        reviewCount: Int
    ) {
        self.id = id
        self.daysSinceLearning = daysSinceLearning
        self.retentionRate = retentionRate
        self.reviewCount = reviewCount
    }
}

