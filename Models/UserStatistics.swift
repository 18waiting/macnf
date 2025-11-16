//
//  UserStatistics.swift
//  NFwordsDemo
//
//  用户统计模型
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 用户统计
struct UserStatistics: Codable {
    // MARK: - 总体统计
    
    /// 总学习时长（秒）
    var totalStudyTime: TimeInterval = 0
    
    /// 总学习单词数
    var totalCardsStudied: Int = 0
    
    /// 总会话数
    var totalSessions: Int = 0
    
    /// 总正确次数
    var totalCorrectCount: Int = 0
    
    /// 总错误次数
    var totalIncorrectCount: Int = 0
    
    // MARK: - 连续学习（Streak）
    
    /// 当前连续天数
    var currentStreak: Int = 0
    
    /// 最长连续天数
    var longestStreak: Int = 0
    
    /// 上次学习日期
    var lastStudyDate: Date?
    
    // MARK: - 进度统计
    
    /// 周进度
    var weeklyProgress: [WeeklyProgress] = []
    
    /// 月进度
    var monthlyProgress: [MonthlyProgress] = []
    
    /// 掌握等级分布
    var masteryDistribution: [String: Int] = [:]  // MasteryLevel.rawValue: count
    
    // MARK: - 计算属性
    
    /// 总准确率
    var overallAccuracy: Double {
        let total = totalCorrectCount + totalIncorrectCount
        guard total > 0 else { return 0 }
        return Double(totalCorrectCount) / Double(total)
    }
    
    /// 平均每次学习时长（分钟）
    var averageSessionDuration: TimeInterval {
        guard totalSessions > 0 else { return 0 }
        return totalStudyTime / Double(totalSessions)
    }
    
    /// 平均每日学习时长（分钟）
    var averageDailyStudyTime: TimeInterval {
        guard let firstDate = weeklyProgress.first?.date else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: firstDate, to: Date()).day ?? 1
        guard days > 0 else { return 0 }
        return totalStudyTime / Double(days)
    }
    
    /// 今日是否已学习
    var hasStudiedToday: Bool {
        guard let lastDate = lastStudyDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
    
    // MARK: - 初始化
    
    static let empty = UserStatistics()
    
    // MARK: - 方法
    
    /// 更新连续天数
    mutating func updateStreak() {
        let today = Date()
        let calendar = Calendar.current
        
        guard let lastDate = lastStudyDate else {
            // 首次学习
            currentStreak = 1
            longestStreak = 1
            lastStudyDate = today
            return
        }
        
        // 检查是否连续
        if calendar.isDateInToday(lastDate) {
            // 今天已经学习过，不更新
            return
        }
        
        let daysSince = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 0
        
        if daysSince == 1 {
            // 连续学习
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else if daysSince > 1 {
            // 中断了，重置连续天数
            currentStreak = 1
        }
        
        lastStudyDate = today
    }
    
    /// 添加学习会话
    mutating func addSession(
        duration: TimeInterval,
        cardsStudied: Int,
        correctCount: Int,
        incorrectCount: Int
    ) {
        totalStudyTime += duration
        totalCardsStudied += cardsStudied
        totalSessions += 1
        totalCorrectCount += correctCount
        totalIncorrectCount += incorrectCount
        
        // 更新连续天数
        updateStreak()
    }
}

// MARK: - 周进度
struct WeeklyProgress: Identifiable, Codable {
    let id: UUID
    let date: Date
    let studyTime: TimeInterval
    let wordsStudied: Int
    let sessions: Int
    let accuracy: Double
    
    init(
        id: UUID = UUID(),
        date: Date,
        studyTime: TimeInterval,
        wordsStudied: Int,
        sessions: Int,
        accuracy: Double
    ) {
        self.id = id
        self.date = date
        self.studyTime = studyTime
        self.wordsStudied = wordsStudied
        self.sessions = sessions
        self.accuracy = accuracy
    }
}

// MARK: - 月进度
struct MonthlyProgress: Identifiable, Codable {
    let id: UUID
    let date: Date
    let studyTime: TimeInterval
    let wordsStudied: Int
    let sessions: Int
    let accuracy: Double
    let streak: Int
    
    init(
        id: UUID = UUID(),
        date: Date,
        studyTime: TimeInterval,
        wordsStudied: Int,
        sessions: Int,
        accuracy: Double,
        streak: Int
    ) {
        self.id = id
        self.date = date
        self.studyTime = studyTime
        self.wordsStudied = wordsStudied
        self.sessions = sessions
        self.accuracy = accuracy
        self.streak = streak
    }
}

