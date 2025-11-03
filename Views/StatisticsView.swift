//
//  StatisticsView.swift
//  NFwordsDemo
//
//  学习统计面板：摘要 + 详情面板
//  Reimagined by 虚拟助手 on 2025/11/4.
//

import SwiftUI

// MARK: - 摘要卡片模型
struct StatisticsSummary: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let accentColor: Color
    let detail: StatisticsDetailDisplay
}

// MARK: - 统计页面
struct StatisticsView: View {
    @EnvironmentObject var appState: AppState
    
    private let goal = LearningGoal.example
    private let task = DailyTask.example
    private let report = DailyReport.example
    
    private var summaries: [StatisticsSummary] {
        [
            StatisticsSummary(
                icon: "target",
                title: "学习计划",
                value: "完成率 \(Int(goal.progress * 100))%",
                subtitle: "\(goal.packName) · 第 \(goal.currentDay) 天",
                accentColor: .blue,
                detail: .plan
            ),
            StatisticsSummary(
                icon: "bolt.fill",
                title: "今日任务",
                value: "已完成 \(task.completedExposures) / \(task.totalExposures)",
                subtitle: "剩余约 \(task.estimatedMinutes) 分钟",
                accentColor: .green,
                detail: .todayTask
            ),
            StatisticsSummary(
                icon: "chart.bar.fill",
                title: "昨日复盘",
                value: "掌握率 \(Int(report.masteryRate * 100))%",
                subtitle: "平均停留 \(String(format: "%.1f", report.avgDwellTime))s",
                accentColor: .purple,
                detail: .review
            )
        ]
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(summaries) { summary in
                        StatisticsSummaryCard(summary: summary) {
                            appState.activeStatisticDetail = summary.detail
                        }
                    }
                    
                    QuickTipsCard()
                }
                .padding(20)
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("📊 学习统计")
        }
        .sheet(item: Binding(
            get: { appState.activeStatisticDetail },
            set: { appState.activeStatisticDetail = $0 }
        )) { detail in
            StatisticsDetailSheet(detail: detail, goal: goal, task: task, report: report)
        }
    }
}

// MARK: - 摘要卡片
struct StatisticsSummaryCard: View {
    let summary: StatisticsSummary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(summary.accentColor.opacity(0.12))
                        .frame(width: 58, height: 58)
                    Image(systemName: summary.icon)
                        .foregroundColor(summary.accentColor)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(summary.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(summary.value)
                        .font(.title3.bold())
                        .foregroundColor(summary.accentColor)
                    Text(summary.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 详情面板
struct StatisticsDetailSheet: View {
    let detail: StatisticsDetailDisplay
    let goal: LearningGoal
    let task: DailyTask
    let report: DailyReport
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    switch detail {
                    case .plan:
                        planDetail
                    case .todayTask:
                        todayTaskDetail
                    case .review:
                        reviewDetail
                    }
                }
                .padding(24)
            }
            .background(Color.gray.opacity(0.05).ignoresSafeArea())
            .navigationTitle(detailTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var planDetail: some View {
        VStack(spacing: 20) {
            QuickProgressCard(goal: goal, task: task)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("计划分解")
                    .font(.headline)
                
                DataItem(title: "总词数", value: "\(goal.totalWords)")
                DataItem(title: "日均新词", value: "\(goal.dailyNewWords)")
                DataItem(
                    title: "预计完成",
                    value: goal.endDate.formatted(date: .abbreviated, time: .omitted)
                )
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10)
        }
    }
    
    private var todayTaskDetail: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("今日任务概览")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    TaskRow(icon: "plus.circle.fill", color: .blue, title: "新词", value: "\(task.newWordsCount) 个")
                    TaskRow(icon: "arrow.clockwise.circle.fill", color: .orange, title: "复习", value: "\(task.reviewWordsCount) 个")
                    TaskRow(icon: "eye.fill", color: .purple, title: "总曝光", value: "\(task.totalExposures) 次")
                    TaskRow(icon: "clock.fill", color: .green, title: "预计时长", value: "约 \(task.estimatedMinutes) 分钟")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10)
                
                ProgressView(value: task.progress)
                    .tint(.green)
                    .scaleEffect(y: 1.8)
                    .padding(.horizontal)
                
                Text("已完成 \(task.completedExposures) 次曝光，剩余 \(task.remainingExposures) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            Button {
                dismiss()
            } label: {
                Text("继续学习")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [Color.green, Color.blue], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
            }
        }
    }
    
    private var reviewDetail: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("昨日复盘")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DataItem(title: "学习时长", value: report.studyDurationFormatted)
                    DataItem(title: "总曝光", value: "\(report.totalExposures)")
                    DataItem(title: "平均停留", value: String(format: "%.1f秒", report.avgDwellTime), highlight: true)
                    DataItem(title: "掌握率", value: "\(Int(report.masteryRate * 100))%", highlight: true)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("困难词 Top 5")
                    .font(.headline)
                
                ForEach(Array(report.sortedByDwellTime.prefix(5).enumerated()), id: \.offset) { index, word in
                    DifficultWordRow(
                        rank: index + 1,
                        word: word.word,
                        swipes: word.swipeIndicator,
                        time: word.dwellTimeFormatted
                    )
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("学习建议")
                    .font(.headline)
                SuggestionItem(text: "使用困难词生成AI短文，加深理解。")
                SuggestionItem(text: "对停留>5秒的词，明日优先复习 2 次。")
                SuggestionItem(text: "保持每天 40 分钟学习节奏，完成复盘。")
            }
            .padding()
            .background(Color.blue.opacity(0.06))
            .cornerRadius(16)
        }
    }
    
    private var detailTitle: String {
        switch detail {
        case .plan:
            return "学习计划详情"
        case .todayTask:
            return "今日任务"
        case .review:
            return "昨日复盘"
        }
    }
}

// MARK: - 快速提示卡片
struct QuickTipsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 NFwords 提示")
                .font(.headline)
            Text("· 右滑越多，AI会减少出现频率\n· 停留时间越长，复习排序越靠前\n· 勾选词库后可随时调整任务量")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }
}

// MARK: - 辅助组件
struct TaskRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title + "：")
                .font(.callout)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.callout.bold())
                .foregroundColor(.primary)
        }
    }
}

struct DataItem: View {
    let title: String
    let value: String
    var highlight: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(highlight ? .blue : .primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(highlight ? Color.blue.opacity(0.1) : Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
}

struct DifficultWordRow: View {
    let rank: Int
    let word: String
    let swipes: String
    let time: String
    
    var body: some View {
        HStack {
            Text("\(rank)")
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.orange))
            
            Text(word)
                .font(.body.bold())
            Spacer()
            Text(swipes)
                .font(.caption.bold())
                .foregroundColor(.orange)
            Text(time)
                .font(.callout.bold())
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
    }
}

struct SuggestionItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .foregroundColor(.blue)
            Text(text)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - 预览
struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StatisticsView()
                .environmentObject(AppState(hasActiveGoal: true))
        }
    }
}
