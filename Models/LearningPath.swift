//
//  LearningPath.swift
//  NFwordsDemo
//
//  学习路径模型
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 学习路径
struct LearningPath: Identifiable, Codable {
    let id: Int
    let packId: Int
    var currentLevel: Int
    var completedLevels: Set<Int>
    var unlockedLevels: Set<Int>
    var progress: Double
    var estimatedCompletion: Date?
    var milestones: [Milestone]
    
    // MARK: - 计算属性
    
    /// 总等级数
    var totalLevels: Int {
        milestones.count
    }
    
    /// 已完成等级数
    var completedLevelsCount: Int {
        completedLevels.count
    }
    
    /// 进度百分比（0-100）
    var progressPercent: Int {
        Int(progress * 100)
    }
    
    /// 下一等级
    var nextLevel: Int? {
        let allLevels = Set(milestones.map { $0.level })
        let available = unlockedLevels.subtracting(completedLevels)
        return available.sorted().first
    }
    
    /// 是否已完成所有等级
    var isCompleted: Bool {
        completedLevels.count == totalLevels
    }
    
    // MARK: - 方法
    
    /// 完成一个等级
    mutating func completeLevel(_ level: Int) {
        guard unlockedLevels.contains(level) else { return }
        guard !completedLevels.contains(level) else { return }
        
        completedLevels.insert(level)
        
        // 解锁下一等级
        let nextLevel = level + 1
        if nextLevel <= totalLevels {
            unlockedLevels.insert(nextLevel)
        }
        
        // 更新进度
        updateProgress()
        
        // 检查里程碑
        checkMilestones(level: level)
    }
    
    /// 解锁等级
    mutating func unlockLevel(_ level: Int) {
        guard level > 0 && level <= totalLevels else { return }
        unlockedLevels.insert(level)
    }
    
    /// 更新进度
    mutating func updateProgress() {
        guard totalLevels > 0 else {
            progress = 0
            return
        }
        progress = Double(completedLevelsCount) / Double(totalLevels)
        
        // 更新预计完成时间
        updateEstimatedCompletion()
    }
    
    /// 更新预计完成时间
    mutating func updateEstimatedCompletion() {
        guard let nextLevel = nextLevel else {
            estimatedCompletion = nil
            return
        }
        
        // 简化计算：假设每天完成一个等级
        let remainingLevels = totalLevels - completedLevelsCount
        if let completionDate = Calendar.current.date(byAdding: .day, value: remainingLevels, to: Date()) {
            estimatedCompletion = completionDate
        }
    }
    
    /// 检查并完成里程碑
    mutating func checkMilestones(level: Int) {
        for index in milestones.indices {
            if milestones[index].level == level && !milestones[index].achieved {
                milestones[index].achieved = true
                milestones[index].achievedAt = Date()
            }
        }
    }
    
    /// 获取当前里程碑
    func getCurrentMilestone() -> Milestone? {
        milestones.first { milestone in
            milestone.level == currentLevel && !milestone.achieved
        }
    }
    
    /// 获取已完成的里程碑
    func getCompletedMilestones() -> [Milestone] {
        milestones.filter { $0.achieved }
    }
    
    /// 获取未完成的里程碑
    func getPendingMilestones() -> [Milestone] {
        milestones.filter { !$0.achieved }
    }
    
    // MARK: - 初始化
    
    /// 创建默认学习路径
    static func createDefault(
        id: Int,
        packId: Int,
        totalLevels: Int = 10
    ) -> LearningPath {
        var milestones: [Milestone] = []
        
        for level in 1...totalLevels {
            let milestone = Milestone(
                level: level,
                title: "第 \(level) 级",
                description: "完成第 \(level) 级学习",
                reward: level % 5 == 0 ? "解锁新功能" : nil
            )
            milestones.append(milestone)
        }
        
        var path = LearningPath(
            id: id,
            packId: packId,
            currentLevel: 1,
            completedLevels: [],
            unlockedLevels: [1],  // 第一级默认解锁
            progress: 0,
            milestones: milestones
        )
        
        return path
    }
}

// MARK: - 里程碑
struct Milestone: Identifiable, Codable, Equatable {
    let id: UUID
    let level: Int
    let title: String
    let description: String
    let reward: String?
    var achieved: Bool
    var achievedAt: Date?
    
    // MARK: - 初始化
    
    init(
        id: UUID = UUID(),
        level: Int,
        title: String,
        description: String,
        reward: String? = nil,
        achieved: Bool = false,
        achievedAt: Date? = nil
    ) {
        self.id = id
        self.level = level
        self.title = title
        self.description = description
        self.reward = reward
        self.achieved = achieved
        self.achievedAt = achievedAt
    }
}

