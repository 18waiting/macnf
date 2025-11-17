//
//  AchievementView.swift
//  NFwordsDemo
//
//  成就系统界面
//  Created by AI Assistant on 2025-01-XX.
//

import SwiftUI
import Combine

// MARK: - 成就系统主视图
struct AchievementView: View {
    @StateObject private var viewModel = AchievementViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 用户进度卡片
                    userProgressCard
                    
                    // 成就统计
                    achievementStatistics
                    
                    // 成就列表
                    achievementList
                }
                .padding()
            }
            .navigationTitle("成就")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.load()
            }
        }
    }
    
    // MARK: - 用户进度卡片
    private var userProgressCard: some View {
        VStack(spacing: 16) {
            // 等级和XP
            HStack(spacing: 20) {
                // 等级徽章
                VStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Text("\(viewModel.progress.level)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("等级")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // XP进度
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("经验值")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.progress.xp) / \(viewModel.progress.xpToNextLevel)")
                            .font(.subheadline.bold())
                            .foregroundColor(.blue)
                    }
                    
                    ProgressView(value: viewModel.progress.levelProgress)
                        .tint(.blue)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    Text("距离下一级还需 \(viewModel.progress.xpToNextLevel - viewModel.progress.xp) XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // 统计信息
            HStack(spacing: 20) {
                AchievementStatItem(
                    icon: "trophy.fill",
                    title: "成就",
                    value: "\(viewModel.progress.unlockedAchievementsCount)/\(viewModel.progress.achievements.count)",
                    color: Color.orange
                )
                
                AchievementStatItem(
                    icon: "seal.fill",
                    title: "徽章",
                    value: "\(viewModel.progress.unlockedBadgesCount)/\(viewModel.progress.badges.count)",
                    color: Color.purple
                )
                
                AchievementStatItem(
                    icon: "star.fill",
                    title: "完成率",
                    value: "\(Int(viewModel.progress.achievementCompletionRate * 100))%",
                    color: Color.yellow
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
    
    // MARK: - 成就统计
    private var achievementStatistics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就统计")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    let stats = viewModel.statistics.byCategory[category] ?? (unlocked: 0, total: 0)
                    
                    CategoryStatCard(
                        category: category,
                        unlocked: stats.unlocked,
                        total: stats.total
                    )
                }
            }
        }
    }
    
    // MARK: - 成就列表
    private var achievementList: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 分段控制器
            Picker("", selection: $viewModel.selectedFilter) {
                Text("全部").tag(AchievementFilter.all)
                Text("已解锁").tag(AchievementFilter.unlocked)
                Text("未解锁").tag(AchievementFilter.locked)
            }
            .pickerStyle(.segmented)
            
            // 按类别分组显示
            ForEach(AchievementCategory.allCases, id: \.self) { category in
                let achievements = viewModel.getAchievementsByCategory(category)
                
                if !achievements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(.blue)
                            Text(category.displayName)
                                .font(.headline)
                        }
                        
                        ForEach(achievements) { achievement in
                            AchievementRow(achievement: achievement)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 统计项组件
private struct AchievementStatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 类别统计卡片
struct CategoryStatCard: View {
    let category: AchievementCategory
    let unlocked: Int
    let total: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(.blue)
                Spacer()
                Text("\(unlocked)/\(total)")
                    .font(.headline)
            }
            
            Text(category.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: Double(unlocked) / Double(total))
                .tint(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - 成就行组件
struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(achievement.unlocked ? Color.orange.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(achievement.unlocked ? .orange : .gray)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(achievement.unlocked ? .primary : .secondary)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // 进度条
                if !achievement.unlocked {
                    ProgressView(value: achievement.progressPercentage)
                        .tint(.blue)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("已解锁")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            // 进度文本
            if !achievement.unlocked {
                VStack {
                    Text("\(achievement.progress)")
                        .font(.headline)
                    Text("/ \(achievement.maxProgress)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .opacity(achievement.unlocked ? 1.0 : 0.7)
    }
}

// MARK: - 视图模型
@MainActor
class AchievementViewModel: ObservableObject {
    @Published var progress: UserProgress = .initial()
    @Published var statistics: AchievementStatistics = AchievementStatistics(
        totalAchievements: 0,
        unlockedCount: 0,
        lockedCount: 0,
        completionRate: 0,
        byCategory: [:]
    )
    @Published var selectedFilter: AchievementFilter = .all
    
    private let service = AchievementService.shared
    
    func load() {
        do {
            // 1. 从数据库加载报告、任务、目标
            let reportStorage = DailyReportStorage()
            let taskStorage = DailyTaskStorage()
            let goalStorage = LearningGoalStorage()
            
            let allReports = try reportStorage.fetchAll()
            let allTasks = try taskStorage.fetchAll()
            let allGoals = try goalStorage.fetchAll()
            
            // 2. 计算总学习时长（用于 XP 计算）
            let totalStudyTime = allReports.reduce(0) { $0 + $1.studyDuration }
            let totalWordsStudied = allReports.reduce(0) { $0 + $1.totalWordsStudied }
            let totalSessions = allReports.count
            
            // 3. 计算 XP（基于学习时长和单词数）
            // 每 1 分钟学习 = 10 XP，每 1 个单词 = 5 XP
            let timeXP = Int(totalStudyTime / 60) * 10
            let wordsXP = totalWordsStudied * 5
            let totalXP = timeXP + wordsXP
            
            // 4. 计算等级（每 100 XP = 1 级）
            let level = max(1, (totalXP / 100) + 1)
            let xp = totalXP % 100
            
            // 5. 初始化 UserProgress
            var userProgress = UserProgress.initial()
            userProgress.totalXP = totalXP
            userProgress.level = level
            userProgress.xp = xp
            
            // 6. 构建 UserStatistics（用于更新成就）
            let currentStreak = calculateCurrentStreak(tasks: allTasks)
            let uniqueDates = Set(allTasks.map { Calendar.current.startOfDay(for: $0.date) })
            let sortedDates = uniqueDates.sorted(by: >)
            let longestStreak = calculateLongestStreak(sortedDates: sortedDates)
            
            var userStatistics = UserStatistics()
            userStatistics.totalStudyTime = totalStudyTime
            userStatistics.totalCardsStudied = totalWordsStudied
            userStatistics.totalSessions = totalSessions
            userStatistics.currentStreak = currentStreak
            userStatistics.longestStreak = longestStreak
            userStatistics.lastStudyDate = sortedDates.first
            
            // 7. 更新成就进度（使用 AchievementService）
            service.updateAchievements(progress: &userProgress, statistics: userStatistics)
            
            progress = userProgress
            statistics = service.getAchievementStatistics(progress)
            
            #if DEBUG
            print("[AchievementViewModel] ✅ 数据加载完成:")
            print("  - 总XP: \(totalXP)")
            print("  - 等级: \(level)")
            print("  - 已解锁成就: \(progress.unlockedAchievementsCount)")
            #endif
            
        } catch {
            #if DEBUG
            print("[AchievementViewModel] ⚠️ 加载数据失败: \(error)")
            #endif
            
            // 加载失败时使用初始值
            progress = .initial()
            statistics = service.getAchievementStatistics(progress)
        }
    }
    
    // MARK: - 辅助方法
    
    /// 计算当前连续学习天数
    private func calculateCurrentStreak(tasks: [DailyTask]) -> Int {
        let uniqueDates = Set(tasks.map { Calendar.current.startOfDay(for: $0.date) })
        let sortedDates = uniqueDates.sorted(by: >)
        
        guard !sortedDates.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var expectedDate = calendar.startOfDay(for: Date())
        
        for date in sortedDates {
            let dayDate = calendar.startOfDay(for: date)
            if dayDate == expectedDate || dayDate == calendar.date(byAdding: .day, value: -1, to: expectedDate) {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: dayDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    /// 计算最长连续学习天数
    private func calculateLongestStreak(sortedDates: [Date]) -> Int {
        guard !sortedDates.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var maxStreak = 0
        var currentStreak = 1
        
        for i in 1..<sortedDates.count {
            let prevDate = calendar.startOfDay(for: sortedDates[i - 1])
            let currDate = calendar.startOfDay(for: sortedDates[i])
            
            if let daysDiff = calendar.dateComponents([.day], from: currDate, to: prevDate).day,
               abs(daysDiff) == 1 {
                currentStreak += 1
            } else {
                maxStreak = max(maxStreak, currentStreak)
                currentStreak = 1
            }
        }
        
        return max(maxStreak, currentStreak)
    }
    
    func getAchievementsByCategory(_ category: AchievementCategory) -> [Achievement] {
        let all = service.getAchievementsByCategory(progress, category: category)
        
        switch selectedFilter {
        case .all:
            return all
        case .unlocked:
            return all.filter { $0.unlocked }
        case .locked:
            return all.filter { !$0.unlocked }
        }
    }
}

// MARK: - 成就过滤器
enum AchievementFilter {
    case all
    case unlocked
    case locked
}

// MARK: - 预览
struct AchievementView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementView()
    }
}

