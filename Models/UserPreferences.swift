//
//  UserPreferences.swift
//  NFwordsDemo
//
//  用户偏好设置模型
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 用户偏好设置
struct UserPreferences: Codable, Equatable {
    // MARK: - 学习目标
    
    /// 每日学习目标（分钟）
    var dailyGoalMinutes: Int = 30
    
    /// 每日学习目标（单词数）
    var dailyGoalWords: Int = 100
    
    /// 难度级别
    var difficultyLevel: DifficultyLevel = .medium
    
    // MARK: - 音频设置
    
    /// 是否启用音频
    var audioEnabled: Bool = true
    
    /// 是否自动播放音频
    var autoPlayAudio: Bool = true
    
    /// 音频播放速度（0.5-2.0）
    var audioPlaybackSpeed: Double = 1.0
    
    // MARK: - 通知设置
    
    /// 是否启用通知
    var notificationsEnabled: Bool = true
    
    /// 提醒时间
    var reminderTime: Date?
    
    /// 学习提醒日期（1=周一，7=周日）
    var studyReminderDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    
    // MARK: - 界面设置
    
    /// 应用主题
    var theme: AppTheme = .system
    
    /// 卡片动画速度
    var cardAnimationSpeed: AnimationSpeed = .normal
    
    /// 是否显示音标
    var showPhonetic: Bool = true
    
    /// 是否显示例句
    var showExamples: Bool = true
    
    // MARK: - 学习设置
    
    /// 新词默认曝光次数
    var defaultNewWordExposures: Int = 10
    
    /// 复习词默认曝光次数
    var defaultReviewExposures: Int = 5
    
    /// 是否启用间隔重复算法
    var enableSpacedRepetition: Bool = true
    
    /// 是否启用自动复习
    var enableAutoReview: Bool = true
    
    // MARK: - 数据设置
    
    /// 是否启用学习分析
    var enableAnalytics: Bool = true
    
    /// 是否启用数据同步
    var enableSync: Bool = true
    
    // MARK: - 初始化
    
    static let `default` = UserPreferences()
    
    // MARK: - 辅助方法
    
    /// 检查今天是否需要提醒
    func shouldRemindToday() -> Bool {
        guard notificationsEnabled else { return false }
        guard let reminderTime = reminderTime else { return false }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Calendar 的 weekday: 1=周日, 2=周一, ..., 7=周六
        // 转换为我们的格式: 1=周一, 7=周日
        let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
        
        return studyReminderDays.contains(adjustedWeekday)
    }
    
    /// 获取下次提醒时间
    func getNextReminderDate() -> Date? {
        guard let reminderTime = reminderTime else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        let reminderComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        var components = DateComponents()
        components.year = todayComponents.year
        components.month = todayComponents.month
        components.day = todayComponents.day
        components.hour = reminderComponents.hour
        components.minute = reminderComponents.minute
        
        guard var nextReminder = calendar.date(from: components) else { return nil }
        
        // 如果今天的提醒时间已过，设置为明天
        if nextReminder < now {
            nextReminder = calendar.date(byAdding: .day, value: 1, to: nextReminder) ?? nextReminder
        }
        
        return nextReminder
    }
}

// MARK: - 难度级别
enum DifficultyLevel: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case adaptive = "adaptive"
    
    var displayName: String {
        switch self {
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        case .adaptive: return "自适应"
        }
    }
    
    var description: String {
        switch self {
        case .easy:
            return "适合初学者，学习节奏较慢"
        case .medium:
            return "平衡的学习节奏，推荐选择"
        case .hard:
            return "适合有基础的用户，学习节奏较快"
        case .adaptive:
            return "根据你的表现自动调整难度"
        }
    }
}

// MARK: - 应用主题
// 注意：AppTheme 定义在 ContentView.swift 中，这里不再重复定义

// MARK: - 动画速度
enum AnimationSpeed: String, Codable, CaseIterable {
    case slow = "slow"
    case normal = "normal"
    case fast = "fast"
    
    var displayName: String {
        switch self {
        case .slow: return "慢速"
        case .normal: return "正常"
        case .fast: return "快速"
        }
    }
    
    var duration: Double {
        switch self {
        case .slow: return 0.5
        case .normal: return 0.3
        case .fast: return 0.15
        }
    }
}

