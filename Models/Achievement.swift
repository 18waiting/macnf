//
//  Achievement.swift
//  NFwordsDemo
//
//  成就系统模型
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 成就
struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    var progress: Int
    let maxProgress: Int
    var unlocked: Bool
    var unlockedAt: Date?
    
    // MARK: - 计算属性
    
    /// 进度百分比（0-1）
    var progressPercentage: Double {
        guard maxProgress > 0 else { return 0 }
        return min(Double(progress) / Double(maxProgress), 1.0)
    }
    
    /// 进度百分比（0-100）
    var progressPercent: Int {
        Int(progressPercentage * 100)
    }
    
    /// 是否已完成
    var isCompleted: Bool {
        progress >= maxProgress
    }
    
    /// 剩余进度
    var remainingProgress: Int {
        max(0, maxProgress - progress)
    }
    
    // MARK: - 方法
    
    /// 更新进度
    mutating func updateProgress(_ newProgress: Int) {
        let oldProgress = progress
        progress = min(newProgress, maxProgress)
        
        // 如果从未解锁变为已完成，记录解锁时间
        if !unlocked && progress >= maxProgress && oldProgress < maxProgress {
            unlocked = true
            unlockedAt = Date()
        }
    }
    
    /// 增加进度
    mutating func addProgress(_ amount: Int) {
        updateProgress(progress + amount)
    }
    
    // MARK: - 初始化
    
    init(
        id: String,
        title: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        maxProgress: Int,
        progress: Int = 0,
        unlocked: Bool = false,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.maxProgress = maxProgress
        self.progress = min(progress, maxProgress)
        self.unlocked = self.progress >= maxProgress || unlocked
        self.unlockedAt = unlockedAt
    }
}

// MARK: - 成就类别
enum AchievementCategory: String, Codable, CaseIterable {
    case streak = "streak"           // 连续学习
    case words = "words"             // 单词数量
    case time = "time"               // 学习时长
    case perfect = "perfect"         // 完美学习
    case speed = "speed"             // 学习速度
    case mastery = "mastery"         // 掌握程度
    case consistency = "consistency"  // 学习一致性
    
    var displayName: String {
        switch self {
        case .streak: return "连续学习"
        case .words: return "单词数量"
        case .time: return "学习时长"
        case .perfect: return "完美学习"
        case .speed: return "学习速度"
        case .mastery: return "掌握程度"
        case .consistency: return "学习一致性"
        }
    }
    
    var icon: String {
        switch self {
        case .streak: return "flame.fill"
        case .words: return "book.fill"
        case .time: return "clock.fill"
        case .perfect: return "star.fill"
        case .speed: return "bolt.fill"
        case .mastery: return "trophy.fill"
        case .consistency: return "calendar"
        }
    }
}

// MARK: - 徽章
struct Badge: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let rarity: BadgeRarity
    var unlocked: Bool
    var unlockedAt: Date?
    
    // MARK: - 初始化
    
    init(
        id: String,
        title: String,
        description: String,
        icon: String,
        rarity: BadgeRarity,
        unlocked: Bool = false,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.rarity = rarity
        self.unlocked = unlocked
        self.unlockedAt = unlockedAt
    }
}

// MARK: - 徽章稀有度
enum BadgeRarity: String, Codable, CaseIterable {
    case common = "common"       // 普通
    case rare = "rare"           // 稀有
    case epic = "epic"           // 史诗
    case legendary = "legendary" // 传说
    
    var displayName: String {
        switch self {
        case .common: return "普通"
        case .rare: return "稀有"
        case .epic: return "史诗"
        case .legendary: return "传说"
        }
    }
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }
}

// MARK: - 预定义成就列表
extension Achievement {
    /// 获取所有预定义成就
    static func getAllAchievements() -> [Achievement] {
        [
            // 连续学习成就
            Achievement(
                id: "streak_3",
                title: "初出茅庐",
                description: "连续学习 3 天",
                icon: "flame.fill",
                category: .streak,
                maxProgress: 3
            ),
            Achievement(
                id: "streak_7",
                title: "坚持不懈",
                description: "连续学习 7 天",
                icon: "flame.fill",
                category: .streak,
                maxProgress: 7
            ),
            Achievement(
                id: "streak_30",
                title: "学习达人",
                description: "连续学习 30 天",
                icon: "flame.fill",
                category: .streak,
                maxProgress: 30
            ),
            Achievement(
                id: "streak_100",
                title: "学习大师",
                description: "连续学习 100 天",
                icon: "flame.fill",
                category: .streak,
                maxProgress: 100
            ),
            
            // 单词数量成就
            Achievement(
                id: "words_100",
                title: "百词斩",
                description: "学习 100 个单词",
                icon: "book.fill",
                category: .words,
                maxProgress: 100
            ),
            Achievement(
                id: "words_500",
                title: "五百词",
                description: "学习 500 个单词",
                icon: "book.fill",
                category: .words,
                maxProgress: 500
            ),
            Achievement(
                id: "words_1000",
                title: "千词达人",
                description: "学习 1000 个单词",
                icon: "book.fill",
                category: .words,
                maxProgress: 1000
            ),
            Achievement(
                id: "words_5000",
                title: "词汇大师",
                description: "学习 5000 个单词",
                icon: "book.fill",
                category: .words,
                maxProgress: 5000
            ),
            
            // 学习时长成就
            Achievement(
                id: "time_1h",
                title: "一小时",
                description: "累计学习 1 小时",
                icon: "clock.fill",
                category: .time,
                maxProgress: 3600  // 秒
            ),
            Achievement(
                id: "time_10h",
                title: "十小时",
                description: "累计学习 10 小时",
                icon: "clock.fill",
                category: .time,
                maxProgress: 36000
            ),
            Achievement(
                id: "time_100h",
                title: "百小时",
                description: "累计学习 100 小时",
                icon: "clock.fill",
                category: .time,
                maxProgress: 360000
            ),
            
            // 完美学习成就
            Achievement(
                id: "perfect_10",
                title: "完美十连",
                description: "连续 10 次完美学习（100% 准确率）",
                icon: "star.fill",
                category: .perfect,
                maxProgress: 10
            ),
            Achievement(
                id: "perfect_50",
                title: "完美五十",
                description: "连续 50 次完美学习",
                icon: "star.fill",
                category: .perfect,
                maxProgress: 50
            ),
            
            // 学习速度成就
            Achievement(
                id: "speed_10s",
                title: "闪电学习",
                description: "平均每词学习时间 < 10 秒",
                icon: "bolt.fill",
                category: .speed,
                maxProgress: 1
            ),
            
            // 掌握程度成就
            Achievement(
                id: "mastery_100",
                title: "百词掌握",
                description: "掌握 100 个单词",
                icon: "trophy.fill",
                category: .mastery,
                maxProgress: 100
            ),
            Achievement(
                id: "mastery_500",
                title: "五百掌握",
                description: "掌握 500 个单词",
                icon: "trophy.fill",
                category: .mastery,
                maxProgress: 500
            )
        ]
    }
}

// MARK: - 预定义徽章列表
extension Badge {
    /// 获取所有预定义徽章
    static func getAllBadges() -> [Badge] {
        [
            Badge(
                id: "first_study",
                title: "初次学习",
                description: "完成第一次学习",
                icon: "star.circle.fill",
                rarity: .common
            ),
            Badge(
                id: "week_warrior",
                title: "周战士",
                description: "一周内每天学习",
                icon: "calendar.badge.clock",
                rarity: .rare
            ),
            Badge(
                id: "month_master",
                title: "月度大师",
                description: "一个月内每天学习",
                icon: "calendar.badge.exclamationmark",
                rarity: .epic
            ),
            Badge(
                id: "perfect_session",
                title: "完美会话",
                description: "完成一次 100% 准确率的学习会话",
                icon: "checkmark.circle.fill",
                rarity: .rare
            ),
            Badge(
                id: "speed_demon",
                title: "速度恶魔",
                description: "在 5 分钟内学习 50 个单词",
                icon: "bolt.circle.fill",
                rarity: .epic
            ),
            Badge(
                id: "vocabulary_king",
                title: "词汇之王",
                description: "掌握 1000 个单词",
                icon: "crown.fill",
                rarity: .legendary
            )
        ]
    }
}

