//
//  StudySession.swift
//  NFwordsDemo
//
//  学习会话模型
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 学习会话
struct StudySession: Identifiable, Codable {
    let id: UUID
    let goalId: Int?
    let sessionType: SessionType
    let startTime: Date
    var endTime: Date?
    
    var cardsStudied: Int = 0
    var correctCount: Int = 0
    var incorrectCount: Int = 0
    var timeSpent: TimeInterval = 0
    
    // MARK: - 计算属性
    
    /// 准确率
    var accuracy: Double {
        guard cardsStudied > 0 else { return 0 }
        return Double(correctCount) / Double(cardsStudied)
    }
    
    /// 学习时长（分钟）
    var durationMinutes: Int {
        Int(timeSpent / 60)
    }
    
    /// 是否已完成
    var isCompleted: Bool {
        endTime != nil
    }
    
    /// 平均每张卡片用时（秒）
    var averageTimePerCard: TimeInterval {
        guard cardsStudied > 0 else { return 0 }
        return timeSpent / Double(cardsStudied)
    }
    
    // MARK: - 方法
    
    /// 结束会话
    mutating func end() {
        guard endTime == nil else { return }
        endTime = Date()
        timeSpent = endTime!.timeIntervalSince(startTime)
    }
    
    /// 记录卡片学习
    mutating func recordCard(isCorrect: Bool) {
        cardsStudied += 1
        if isCorrect {
            correctCount += 1
        } else {
            incorrectCount += 1
        }
    }
    
    // MARK: - 初始化
    
    init(
        id: UUID = UUID(),
        goalId: Int? = nil,
        sessionType: SessionType,
        startTime: Date = Date()
    ) {
        self.id = id
        self.goalId = goalId
        self.sessionType = sessionType
        self.startTime = startTime
    }
}

// MARK: - 会话类型
enum SessionType: String, Codable, CaseIterable {
    case flashcards = "flashcards"  // 卡片学习
    case review = "review"          // 复习
    case test = "test"              // 测试
    case practice = "practice"      // 练习
    
    var displayName: String {
        switch self {
        case .flashcards: return "卡片学习"
        case .review: return "复习"
        case .test: return "测试"
        case .practice: return "练习"
        }
    }
    
    var icon: String {
        switch self {
        case .flashcards: return "rectangle.stack"
        case .review: return "arrow.counterclockwise"
        case .test: return "checkmark.circle"
        case .practice: return "pencil"
        }
    }
}

