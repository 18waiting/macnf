//
//  AnalyticsService.swift
//  NFwordsDemo
//
//  学习分析服务
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 学习分析服务
final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    // MARK: - 学习曲线计算
    
    /// 计算学习曲线
    /// - Parameter sessions: 学习会话列表
    /// - Returns: 学习曲线数据点
    func calculateLearningCurve(sessions: [StudySession]) -> [LearningCurvePoint] {
        guard !sessions.isEmpty else { return [] }
        
        // 按日期分组
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
        
        // 按日期排序
        let sortedDates = grouped.keys.sorted()
        
        var points: [LearningCurvePoint] = []
        var cumulativeWords = 0
        
        for date in sortedDates {
            guard let daySessions = grouped[date] else { continue }
            
            let wordsLearned = daySessions.reduce(0) { $0 + $1.cardsStudied }
            let totalCorrect = daySessions.reduce(0) { $0 + $1.correctCount }
            let totalCards = daySessions.reduce(0) { $0 + $1.cardsStudied }
            let accuracy = totalCards > 0 ? Double(totalCorrect) / Double(totalCards) : 0.0
            
            let totalTime = daySessions.reduce(0.0) { $0 + $1.timeSpent }
            let averageTime = wordsLearned > 0 ? totalTime / Double(wordsLearned) : 0.0
            
            cumulativeWords += wordsLearned
            
            let point = LearningCurvePoint(
                date: date,
                wordsLearned: cumulativeWords,
                accuracy: accuracy,
                averageTime: averageTime
            )
            points.append(point)
        }
        
        return points
    }
    
    // MARK: - 时间分布分析
    
    /// 计算学习时间分布（按小时）
    /// - Parameter sessions: 学习会话列表
    /// - Returns: [小时: 学习时长]
    func calculateTimeDistribution(sessions: [StudySession]) -> [Int: TimeInterval] {
        var distribution: [Int: TimeInterval] = [:]
        let calendar = Calendar.current
        
        for session in sessions {
            let hour = calendar.component(.hour, from: session.startTime)
            distribution[hour, default: 0] += session.timeSpent
        }
        
        return distribution
    }
    
    /// 计算最佳学习时段
    /// - Parameter distribution: 时间分布
    /// - Returns: 最佳学习时段（小时）列表，按活跃度排序
    func calculatePeakHours(distribution: [Int: TimeInterval]) -> [Int] {
        let sorted = distribution.sorted { $0.value > $1.value }
        return sorted.prefix(3).map { $0.key }
    }
    
    // MARK: - 效率分析
    
    /// 计算学习效率分数
    /// - Parameters:
    ///   - sessions: 学习会话列表
    ///   - recentDays: 最近天数（默认7天）
    /// - Returns: 效率分数（0-100）
    func calculateEfficiencyScore(
        sessions: [StudySession],
        recentDays: Int = 7
    ) -> Double {
        guard !sessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -recentDays, to: Date()) ?? Date()
        
        let recentSessions = sessions.filter { $0.startTime >= cutoffDate }
        guard !recentSessions.isEmpty else { return 0 }
        
        // 1. 准确率分数（40%）
        let totalCards = recentSessions.reduce(0) { $0 + $1.cardsStudied }
        let totalCorrect = recentSessions.reduce(0) { $0 + $1.correctCount }
        let accuracy = totalCards > 0 ? Double(totalCorrect) / Double(totalCards) : 0.0
        let accuracyScore = accuracy * 40
        
        // 2. 连续性分数（30%）
        let daysWithStudy = Set(recentSessions.map { calendar.startOfDay(for: $0.startTime) }).count
        let continuityScore = (Double(daysWithStudy) / Double(recentDays)) * 30
        
        // 3. 学习时长分数（30%）
        let totalTime = recentSessions.reduce(0.0) { $0 + $1.timeSpent }
        let averageDailyTime = totalTime / Double(recentDays)
        // 假设每天30分钟为满分
        let timeScore = min(averageDailyTime / (30 * 60), 1.0) * 30
        
        return accuracyScore + continuityScore + timeScore
    }
}

