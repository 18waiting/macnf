//
//  StatisticsDashboardView.swift
//  NFwordsDemo
//
//  用户统计仪表板
//  Created by AI Assistant on 2025-01-XX.
//

import SwiftUI
import Combine

// MARK: - 统计仪表板主视图
struct StatisticsDashboardView: View {
    @StateObject private var viewModel = StatisticsDashboardViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 连续学习卡片
                    streakCard
                    
                    // 总体统计
                    overallStatistics
                    
                    // 本周统计
                    weeklyStatistics
                    
                    // 掌握分布
                    masteryDistribution
                }
                .padding()
            }
            .navigationTitle("学习统计")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.load()
            }
        }
    }
    
    // MARK: - 连续学习卡片
    private var streakCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("连续学习")
                        .font(.headline)
                    Text("\(viewModel.statistics.currentStreak) 天")
                        .font(.title.bold())
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("最长记录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.statistics.longestStreak) 天")
                        .font(.headline)
                }
            }
            
            if viewModel.statistics.hasStudiedToday {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("今日已完成学习")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("今日尚未学习")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.red.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
    
    // MARK: - 总体统计
    private var overallStatistics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("总体统计")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(
                    icon: "clock.fill",
                    title: "总学习时长",
                    value: formatTime(viewModel.statistics.totalStudyTime),
                    color: .blue
                )
                
                StatCard(
                    icon: "book.fill",
                    title: "总学习单词",
                    value: "\(viewModel.statistics.totalCardsStudied)",
                    color: .green
                )
                
                StatCard(
                    icon: "checkmark.circle.fill",
                    title: "总准确率",
                    value: String(format: "%.1f%%", viewModel.statistics.overallAccuracy * 100),
                    color: .purple
                )
                
                StatCard(
                    icon: "rectangle.stack.fill",
                    title: "总会话数",
                    value: "\(viewModel.statistics.totalSessions)",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - 本周统计
    private var weeklyStatistics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("本周统计")
                .font(.headline)
            
            if let weekProgress = viewModel.statistics.weeklyProgress.last {
                VStack(spacing: 12) {
                    HStack {
                        Text("学习时长")
                            .font(.subheadline)
                        Spacer()
                        Text(formatTime(weekProgress.studyTime))
                            .font(.subheadline.bold())
                    }
                    
                    HStack {
                        Text("学习单词")
                            .font(.subheadline)
                        Spacer()
                        Text("\(weekProgress.wordsStudied) 词")
                            .font(.subheadline.bold())
                    }
                    
                    HStack {
                        Text("学习会话")
                            .font(.subheadline)
                        Spacer()
                        Text("\(weekProgress.sessions) 次")
                            .font(.subheadline.bold())
                    }
                    
                    HStack {
                        Text("准确率")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f%%", weekProgress.accuracy * 100))
                            .font(.subheadline.bold())
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
            }
        }
    }
    
    // MARK: - 掌握分布
    private var masteryDistribution: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("掌握分布")
                .font(.headline)
            
            if !viewModel.statistics.masteryDistribution.isEmpty {
                ForEach(MasteryLevel.allCases, id: \.self) { level in
                    if let count = viewModel.statistics.masteryDistribution[level.rawValue], count > 0 {
                        HStack {
                            Text(level.displayName)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(count)")
                                .font(.subheadline.bold())
                            
                            ProgressView(value: Double(count))
                                .frame(width: 100)
                                .tint(levelColor(level))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 辅助方法
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    private func levelColor(_ level: MasteryLevel) -> Color {
        switch level {
        case .beginner: return .gray
        case .intermediate: return .blue
        case .advanced: return .purple
        case .mastered: return .green
        }
    }
}

// MARK: - 统计卡片组件
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - 视图模型
@MainActor
class StatisticsDashboardViewModel: ObservableObject {
    @Published var statistics: UserStatistics = .empty
    
    func load() {
        do {
            // 1. 从数据库加载报告、任务、目标
            let reportStorage = DailyReportStorage()
            let taskStorage = DailyTaskStorage()
            let goalStorage = LearningGoalStorage()
            
            let allReports = try reportStorage.fetchAll()
            let allTasks = try taskStorage.fetchAll()
            let allGoals = try goalStorage.fetchAll()
            
            // 2. 从报告构建学习会话
            var sessions: [StudySession] = []
            for report in allReports {
                let session = StudySession(
                    id: UUID(),
                    goalId: report.goalId,
                    sessionType: .flashcards,
                    startTime: report.reportDate
                )
                
                var mutableSession = session
                mutableSession.endTime = report.reportDate
                mutableSession.cardsStudied = report.totalWordsStudied
                mutableSession.correctCount = report.swipeRightCount
                mutableSession.incorrectCount = report.swipeLeftCount
                mutableSession.timeSpent = report.studyDuration
                
                sessions.append(mutableSession)
            }
            
            // 3. 计算总体统计
            let totalStudyTime = allReports.reduce(0) { $0 + $1.studyDuration }
            let totalCardsStudied = allReports.reduce(0) { $0 + $1.totalWordsStudied }
            let totalSessions = sessions.count
            let totalCorrectCount = allReports.reduce(0) { $0 + $1.swipeRightCount }
            let totalIncorrectCount = allReports.reduce(0) { $0 + $1.swipeLeftCount }
            
            // 4. 计算连续学习天数
            let uniqueDates = Set(allTasks.map { Calendar.current.startOfDay(for: $0.date) })
            let sortedDates = uniqueDates.sorted(by: >)
            let currentStreak = calculateCurrentStreak(sortedDates: sortedDates)
            let longestStreak = calculateLongestStreak(sortedDates: sortedDates)
            let lastStudyDate = sortedDates.first
            
            // 5. 计算周进度和月进度
            let weeklyProgress = calculateWeeklyProgress(reports: allReports)
            let monthlyProgress = calculateMonthlyProgress(reports: allReports)
            
            // 6. 构建 UserStatistics
            statistics = UserStatistics(
                totalStudyTime: totalStudyTime,
                totalCardsStudied: totalCardsStudied,
                totalSessions: totalSessions,
                totalCorrectCount: totalCorrectCount,
                totalIncorrectCount: totalIncorrectCount,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                lastStudyDate: lastStudyDate,
                weeklyProgress: weeklyProgress,
                monthlyProgress: monthlyProgress,
                masteryDistribution: [:]
            )
            
            #if DEBUG
            print("[StatisticsDashboardViewModel] ✅ 数据加载完成:")
            print("  - 总会话数: \(totalSessions)")
            print("  - 总学习时长: \(Int(totalStudyTime / 60)) 分钟")
            print("  - 当前连续: \(currentStreak) 天")
            #endif
            
        } catch {
            #if DEBUG
            print("[StatisticsDashboardViewModel] ⚠️ 加载数据失败: \(error)")
            #endif
            
            // 加载失败时使用空数据
            statistics = .empty
        }
    }
    
    // MARK: - 辅助方法
    
    /// 计算当前连续学习天数
    private func calculateCurrentStreak(sortedDates: [Date]) -> Int {
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
    
    /// 计算周进度
    private func calculateWeeklyProgress(reports: [DailyReport]) -> [WeeklyProgress] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: reports) { report in
            calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: report.reportDate))!
        }
        
        return grouped.map { (date, weekReports) in
            let studyTime = weekReports.reduce(0) { $0 + $1.studyDuration }
            let wordsStudied = weekReports.reduce(0) { $0 + $1.totalWordsStudied }
            let sessions = weekReports.count
            let totalRight = weekReports.reduce(0) { $0 + $1.swipeRightCount }
            let totalLeft = weekReports.reduce(0) { $0 + $1.swipeLeftCount }
            let totalSwipes = totalRight + totalLeft
            let accuracy = totalSwipes > 0 ? Double(totalRight) / Double(totalSwipes) : 0
            
            return WeeklyProgress(
                date: date,
                studyTime: studyTime,
                wordsStudied: wordsStudied,
                sessions: sessions,
                accuracy: accuracy
            )
        }.sorted { $0.date > $1.date }
    }
    
    /// 计算月进度
    private func calculateMonthlyProgress(reports: [DailyReport]) -> [MonthlyProgress] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: reports) { report in
            let components = calendar.dateComponents([.year, .month], from: report.reportDate)
            return calendar.date(from: components)!
        }
        
        return grouped.map { (date, monthReports) in
            let studyTime = monthReports.reduce(0) { $0 + $1.studyDuration }
            let wordsStudied = monthReports.reduce(0) { $0 + $1.totalWordsStudied }
            let sessions = monthReports.count
            let totalRight = monthReports.reduce(0) { $0 + $1.swipeRightCount }
            let totalLeft = monthReports.reduce(0) { $0 + $1.swipeLeftCount }
            let totalSwipes = totalRight + totalLeft
            let accuracy = totalSwipes > 0 ? Double(totalRight) / Double(totalSwipes) : 0
            
            // 计算该月的连续天数（简化版）
            let uniqueDates = Set(monthReports.map { calendar.startOfDay(for: $0.reportDate) })
            let streak = calculateLongestStreak(sortedDates: Array(uniqueDates).sorted(by: >))
            
            return MonthlyProgress(
                date: date,
                studyTime: studyTime,
                wordsStudied: wordsStudied,
                sessions: sessions,
                accuracy: accuracy,
                streak: streak
            )
        }.sorted { $0.date > $1.date }
    }
}

// MARK: - 预览
struct StatisticsDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsDashboardView()
    }
}

