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
        // TODO: 从存储加载用户统计
        // statistics = loadFromStorage()
    }
}

// MARK: - 预览
struct StatisticsDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsDashboardView()
    }
}

