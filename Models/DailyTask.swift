//
//  DailyTask.swift
//  NFwordsDemo
//
//  每日任务模型
//  Created by 甘名杨 on 2025/11/3.
//

import Foundation

// MARK: - 每日任务
struct DailyTask: Identifiable, Codable {
    let id: Int
    let goalId: Int                 // 关联的学习目标
    let day: Int                    // 第几天
    let date: Date                  // 任务日期
    let newWords: [Int]             // 新词wid列表
    let reviewWords: [Int]          // 复习词wid列表
    let totalExposures: Int         // 总曝光次数
    var completedExposures: Int     // 已完成曝光次数
    var status: TaskStatus          // 任务状态
    var startTime: Date?            // 开始时间
    var endTime: Date?              // 完成时间
    
    // 计算属性
    var newWordsCount: Int {
        newWords.count
    }
    
    var reviewWordsCount: Int {
        reviewWords.count
    }
    
    var totalWords: Int {
        newWordsCount + reviewWordsCount
    }
    
    var progress: Double {
        guard totalExposures > 0 else { return 0 }
        return Double(completedExposures) / Double(totalExposures)
    }
    
    var estimatedMinutes: Int {
        // 假设每次曝光平均3秒
        Int(Double(totalExposures) * 3.0 / 60.0)
    }
    
    var remainingExposures: Int {
        max(0, totalExposures - completedExposures)
    }
    
    var isCompleted: Bool {
        status == .completed
    }
}

// MARK: - 任务状态
enum TaskStatus: String, Codable {
    case pending = "pending"         // 待开始
    case inProgress = "in_progress"  // 进行中
    case completed = "completed"     // 已完成
}

// MARK: - 示例数据
extension DailyTask {
    static let example = DailyTask(
        id: 1,
        goalId: 1,
        day: 3,
        date: Date(),
        newWords: Array(901...1200),  // 300个新词
        reviewWords: Array(1...20),    // 20个复习词
        totalExposures: 3100,          // 300×10 + 20×5
        completedExposures: 310,
        status: .inProgress,
        startTime: Date().addingTimeInterval(-1800),
        endTime: nil
    )
}

