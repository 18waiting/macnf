//
//  AnalyticsView.swift
//  NFwordsDemo
//
//  学习分析可视化界面
//  Created by AI Assistant on 2025-01-XX.
//

import SwiftUI

// MARK: - 学习分析主视图
struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 效率分数卡片
                    efficiencyScoreCard
                    
                    // 学习曲线
                    learningCurveSection
                    
                    // 时间分布
                    timeDistributionSection
                    
                    // 遗忘曲线
                    forgettingCurveSection
                }
                .padding()
            }
            .navigationTitle("学习分析")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.load()
            }
        }
    }
    
    // MARK: - 效率分数卡片
    private var efficiencyScoreCard: some View {
        VStack(spacing: 16) {
            Text("学习效率")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: viewModel.analytics.efficiencyScore / 100)
                    .stroke(
                        efficiencyColor,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: viewModel.analytics.efficiencyScore)
                
                VStack {
                    Text("\(Int(viewModel.analytics.efficiencyScore))")
                        .font(.system(size: 48, weight: .bold))
                    Text("分")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(efficiencyDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
    
    // MARK: - 学习曲线部分
    private var learningCurveSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习曲线")
                .font(.headline)
            
            if !viewModel.analytics.learningCurve.isEmpty {
                LearningCurveChart(points: viewModel.analytics.learningCurve)
                    .frame(height: 200)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
            } else {
                EmptyChartView(message: "暂无学习曲线数据")
            }
        }
    }
    
    // MARK: - 时间分布部分
    private var timeDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习时间分布")
                .font(.headline)
            
            if !viewModel.analytics.studyTimeDistribution.isEmpty {
                TimeDistributionChart(distribution: viewModel.analytics.studyTimeDistribution)
                    .frame(height: 200)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                
                if let peakHours = viewModel.analytics.peakStudyHours.first {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("最佳学习时段：\(peakHours):00 - \(peakHours + 1):00")
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                }
            } else {
                EmptyChartView(message: "暂无时间分布数据")
            }
        }
    }
    
    // MARK: - 遗忘曲线部分
    private var forgettingCurveSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("遗忘曲线")
                .font(.headline)
            
            if !viewModel.analytics.forgettingCurve.isEmpty {
                ForgettingCurveChart(points: viewModel.analytics.forgettingCurve)
                    .frame(height: 200)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
            } else {
                EmptyChartView(message: "暂无遗忘曲线数据")
            }
        }
    }
    
    // MARK: - 计算属性
    private var efficiencyColor: Color {
        let score = viewModel.analytics.efficiencyScore
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .blue
        } else if score >= 40 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var efficiencyDescription: String {
        let score = viewModel.analytics.efficiencyScore
        if score >= 80 {
            return "优秀！继续保持这个学习节奏"
        } else if score >= 60 {
            return "良好，还有提升空间"
        } else if score >= 40 {
            return "一般，建议增加学习频率"
        } else {
            return "需要改进，建议制定学习计划"
        }
    }
}

// MARK: - 学习曲线图表
struct LearningCurveChart: View {
    let points: [LearningCurvePoint]
    
    var body: some View {
        GeometryReader { geometry in
            let maxWords = points.map { $0.wordsLearned }.max() ?? 1
            let maxAccuracy = 1.0
            
            Path { path in
                for (index, point) in points.enumerated() {
                    let x = CGFloat(index) / CGFloat(max(points.count - 1, 1)) * geometry.size.width
                    let y = (1 - CGFloat(point.wordsLearned) / CGFloat(maxWords)) * geometry.size.height
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.blue, lineWidth: 3)
        }
    }
}

// MARK: - 时间分布图表
struct TimeDistributionChart: View {
    let distribution: [Int: TimeInterval]
    
    var body: some View {
        GeometryReader { geometry in
            let maxTime = distribution.values.max() ?? 1
            let hours = Array(0...23)
            
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(hours, id: \.self) { hour in
                    let time = distribution[hour] ?? 0
                    let height = CGFloat(time / maxTime) * geometry.size.height
                    
                    Rectangle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: (geometry.size.width - 46) / 24, height: max(height, 2))
                }
            }
        }
    }
}

// MARK: - 遗忘曲线图表
struct ForgettingCurveChart: View {
    let points: [ForgettingCurvePoint]
    
    var body: some View {
        GeometryReader { geometry in
            let maxDays = points.map { $0.daysSinceLearning }.max() ?? 1
            
            Path { path in
                for (index, point) in points.enumerated() {
                    let x = CGFloat(point.daysSinceLearning) / CGFloat(maxDays) * geometry.size.width
                    let y = (1 - CGFloat(point.retentionRate)) * geometry.size.height
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.orange, lineWidth: 3)
        }
    }
}

// MARK: - 空图表视图
struct EmptyChartView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 视图模型
@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var analytics: LearningAnalytics = .empty
    
    private let service = AnalyticsService.shared
    
    func load() {
        // TODO: 从存储加载会话和历史记录
        // let sessions = loadSessions()
        // let records = loadRecords()
        // analytics = calculateAnalytics(sessions: sessions, records: records)
    }
}

// MARK: - 预览
struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
    }
}

