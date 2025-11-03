//
//  LearningGoal.swift
//  NFwordsDemo
//
//  学习目标模型 - 10天3000词
//  Created by 甘名杨 on 2025/11/3.
//

import Foundation

// MARK: - 学习目标
struct LearningGoal: Identifiable, Codable {
    let id: Int
    let packId: Int                 // 词库ID
    let packName: String            // 词库名称
    let totalWords: Int             // 总词数（如3000）
    let durationDays: Int           // 学习天数（如10天）
    let dailyNewWords: Int          // 每日新词数（如300）
    let startDate: Date             // 开始日期
    let endDate: Date               // 结束日期
    var status: GoalStatus          // 状态
    var currentDay: Int             // 当前第几天
    var completedWords: Int         // 已完成单词数
    var completedExposures: Int     // 已完成曝光次数
    
    // 计算属性
    var progress: Double {
        guard totalWords > 0 else { return 0 }
        return Double(completedWords) / Double(totalWords)
    }
    
    var daysRemaining: Int {
        max(0, durationDays - currentDay + 1)
    }
    
    var isCompleted: Bool {
        status == .completed
    }
    
    var isActive: Bool {
        status == .inProgress
    }
}

// MARK: - 目标状态
enum GoalStatus: String, Codable {
    case inProgress = "in_progress"   // 进行中
    case completed = "completed"       // 已完成
    case abandoned = "abandoned"       // 已放弃
}

// MARK: - 示例数据
extension LearningGoal {
    static let example = LearningGoal(
        id: 1,
        packId: 1,
        packName: "CET-4 核心词汇",
        totalWords: 3000,
        durationDays: 10,
        dailyNewWords: 300,
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
        status: .inProgress,
        currentDay: 3,
        completedWords: 900,
        completedExposures: 9150
    )
}

