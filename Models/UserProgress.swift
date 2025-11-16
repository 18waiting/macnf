//
//  UserProgress.swift
//  NFwordsDemo
//
//  用户进度模型（XP/等级系统）
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 用户进度
struct UserProgress: Codable {
    // MARK: - XP 和等级
    
    /// 当前等级的经验值
    var xp: Int = 0
    
    /// 当前等级
    var level: Int = 1
    
    /// 总经验值（累计）
    var totalXP: Int = 0
    
    // MARK: - 成就和徽章
    
    /// 成就列表
    var achievements: [Achievement] = []
    
    /// 徽章列表
    var badges: [Badge] = []
    
    // MARK: - 每日目标
    
    /// 每日目标列表
    var dailyGoals: [DailyGoal] = []
    
    // MARK: - 计算属性
    
    /// 升级所需经验值
    var xpToNextLevel: Int {
        level * 100  // 每级需要 100 XP
    }
    
    /// 当前等级进度（0-1）
    var levelProgress: Double {
        guard xpToNextLevel > 0 else { return 1.0 }
        return min(Double(xp) / Double(xpToNextLevel), 1.0)
    }
    
    /// 当前等级进度百分比（0-100）
    var levelProgressPercent: Int {
        Int(levelProgress * 100)
    }
    
    /// 已解锁成就数量
    var unlockedAchievementsCount: Int {
        achievements.filter { $0.unlocked }.count
    }
    
    /// 已解锁徽章数量
    var unlockedBadgesCount: Int {
        badges.filter { $0.unlocked }.count
    }
    
    /// 成就完成率
    var achievementCompletionRate: Double {
        guard !achievements.isEmpty else { return 0 }
        return Double(unlockedAchievementsCount) / Double(achievements.count)
    }
    
    // MARK: - 方法
    
    /// 添加经验值
    mutating func addXP(_ amount: Int) {
        xp += amount
        totalXP += amount
        
        // 检查是否升级
        while xp >= xpToNextLevel {
            levelUp()
        }
    }
    
    /// 升级
    mutating func levelUp() {
        let excessXP = xp - xpToNextLevel
        level += 1
        xp = excessXP
    }
    
    /// 获取成就
    func getAchievement(id: String) -> Achievement? {
        achievements.first { $0.id == id }
    }
    
    /// 更新成就进度
    mutating func updateAchievement(id: String, progress: Int) {
        guard let index = achievements.firstIndex(where: { $0.id == id }) else { return }
        achievements[index].updateProgress(progress)
    }
    
    /// 增加成就进度
    mutating func addAchievementProgress(id: String, amount: Int) {
        guard let index = achievements.firstIndex(where: { $0.id == id }) else { return }
        achievements[index].addProgress(amount)
    }
    
    /// 解锁徽章
    mutating func unlockBadge(id: String) {
        guard let index = badges.firstIndex(where: { $0.id == id }) else { return }
        guard !badges[index].unlocked else { return }
        
        badges[index].unlocked = true
        badges[index].unlockedAt = Date()
        
        // 解锁徽章奖励 XP
        addXP(50)
    }
    
    /// 初始化（加载预定义成就和徽章）
    static func initial() -> UserProgress {
        var progress = UserProgress()
        progress.achievements = Achievement.getAllAchievements()
        progress.badges = Badge.getAllBadges()
        return progress
    }
}

// MARK: - 每日目标
struct DailyGoal: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: DailyGoalType
    var target: Int
    var current: Int
    var completed: Bool
    
    // MARK: - 计算属性
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
    
    var progressPercent: Int {
        Int(progress * 100)
    }
    
    // MARK: - 初始化
    
    init(
        id: UUID = UUID(),
        date: Date,
        type: DailyGoalType,
        target: Int,
        current: Int = 0,
        completed: Bool = false
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.target = target
        self.current = current
        self.completed = completed
    }
}

// MARK: - 每日目标类型
enum DailyGoalType: String, Codable, CaseIterable {
    case words = "words"       // 单词数
    case time = "time"         // 学习时长（分钟）
    case sessions = "sessions" // 学习会话数
    case accuracy = "accuracy" // 准确率
    
    var displayName: String {
        switch self {
        case .words: return "单词数"
        case .time: return "学习时长"
        case .sessions: return "学习会话"
        case .accuracy: return "准确率"
        }
    }
    
    var unit: String {
        switch self {
        case .words: return "词"
        case .time: return "分钟"
        case .sessions: return "次"
        case .accuracy: return "%"
        }
    }
}

