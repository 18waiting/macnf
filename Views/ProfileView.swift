//
//  ProfileView.swift
//  NFwordsDemo
//
//  个人中心页面（墨墨式）
//  Created by 甘名杨 on 2025/11/3.
//

import SwiftUI

// MARK: - 个人中心视图
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var statisticsViewModel = StatisticsViewModel()
    @State private var showResetConfirmation = false
    @State private var showResetProgress = false
    @State private var isResetting = false
    @State private var resetError: String?
    @State private var progressSummary: ProgressSummary?
    @State private var showDiagnostic = false
    @State private var showThemeSelector = false
    @State private var showSettings = false
    @State private var showAchievements = false
    @State private var showStatistics = false
    @State private var showHistory = false
    @State private var showAnalytics = false
    @State private var showLearningPath = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 个人信息卡片
                    profileCard
                    
                    // 学习数据
                    studyDataSection
                    
                    // 成就徽章
                    achievementsSection
                    
                    // 功能菜单
                    menuSection
                    
                    // 外观设置
                    appearanceSection
                    
                    // 其他
                    otherSection
                    
                    // 危险区域：重置进度
                    dangerZoneSection
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("👤 我的")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                UserPreferencesView()
            }
            .alert("确认重置学习进度？", isPresented: $showResetConfirmation) {
                Button("取消", role: .cancel) { }
                Button("确认重置", role: .destructive) {
                    performReset()
                }
            } message: {
                if let summary = progressSummary {
                    Text("将删除以下数据：\n\n\(summary.description)\n\n词书和单词缓存将保留。此操作不可撤销！")
                } else {
                    Text("将清空所有学习进度，词书和单词缓存将保留。此操作不可撤销！")
                }
            }
            .alert("重置进度", isPresented: $showResetProgress) {
                Button("确定", role: .cancel) { }
            } message: {
                if let error = resetError {
                    Text("重置失败：\(error)")
                } else {
                    Text("学习进度已成功重置！\n\n已为你创建新的学习计划，可以重新开始学习了。")
                }
            }
        }
    }
    
    // MARK: - 子视图
    
    private var profileCard: some View {
        VStack(spacing: 16) {
            // 头像和昵称
            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue.opacity(0.6))
                
                Text("学习者")
                    .font(.title3.bold())
            }
            
            // 学习天数和连续签到
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("\(statisticsViewModel.studyDays)")
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                    Text("学习天数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(statisticsViewModel.currentStreak)")
                        .font(.title2.bold())
                        .foregroundColor(.orange)
                    Text("连续学习")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // 本周和累计
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("本周学习: \(statisticsViewModel.weeklyWords)词")
                        .font(.callout)
                    Text("累计: \(statisticsViewModel.totalWords)词")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 等级进度（如果有UserProgress数据）
            if statisticsViewModel.hasProgress {
                VStack(spacing: 8) {
                    HStack {
                        Text("等级: Lv.\(statisticsViewModel.level)")
                            .font(.callout.bold())
                        Spacer()
                        Text("\(statisticsViewModel.levelProgressPercent)%")
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                    }
                    
                    ProgressView(value: statisticsViewModel.levelProgress)
                        .tint(.blue)
                        .scaleEffect(y: 2)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
        .onAppear {
            statisticsViewModel.load()
        }
    }
    
    private var studyDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习数据")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DataCard(icon: "book.fill", title: "词汇量", value: "\(statisticsViewModel.totalWords)词")
                DataCard(icon: "clock.fill", title: "学习时长", value: statisticsViewModel.totalTimeFormatted)
                DataCard(icon: "target", title: "准确率", value: "\(Int(statisticsViewModel.accuracy * 100))%")
                DataCard(icon: "flame.fill", title: "最长连续", value: "\(statisticsViewModel.longestStreak)天")
            }
            .padding(.horizontal)
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就徽章")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                AchievementBadge(icon: "medal.fill", title: "初学者", color: .green)
                AchievementBadge(icon: "star.fill", title: "坚持者", color: .orange)
                AchievementBadge(icon: "crown.fill", title: "单词达人", color: .yellow)
                
                Spacer()
                
                Button("全部 →") {
                    showAchievements = true
                }
                .font(.caption)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var menuSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("功能菜单")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                MenuRow(icon: "books.vertical.fill", title: "我的词库") {
                    // 跳转到词库Tab
                }
                Divider().padding(.leading, 60)
                MenuRow(icon: "chart.bar.fill", title: "学习统计") {
                    showStatistics = true
                }
                Divider().padding(.leading, 60)
                MenuRow(icon: "trophy.fill", title: "成就系统") {
                    showAchievements = true
                }
                Divider().padding(.leading, 60)
                MenuRow(icon: "doc.text.fill", title: "学习历史") {
                    showHistory = true
                }
                Divider().padding(.leading, 60)
                MenuRow(icon: "chart.line.uptrend.xyaxis", title: "学习分析") {
                    showAnalytics = true
                }
                Divider().padding(.leading, 60)
                MenuRow(icon: "map.fill", title: "学习路径") {
                    showLearningPath = true
                }
                Divider().padding(.leading, 60)
                MenuRow(icon: "gearshape.fill", title: "设置") {
                    showSettings = true
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .sheet(isPresented: $showSettings) {
            UserPreferencesView()
        }
        .sheet(isPresented: $showAchievements) {
            AchievementView()
        }
        .sheet(isPresented: $showStatistics) {
            StatisticsDashboardView()
        }
        .sheet(isPresented: $showHistory) {
            StudyHistoryView()
        }
        .sheet(isPresented: $showAnalytics) {
            AnalyticsView()
        }
        .sheet(isPresented: $showLearningPath) {
            if let goal = appState.dashboard.goal {
                NavigationView {
                    LearningPathView(packId: goal.packId)
                }
            }
        }
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("外观设置")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                // 主题选择器
                HStack {
                    Image(systemName: themeManager.currentTheme.icon)
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    Text("外观")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        showThemeSelector = true
                    }) {
                        HStack(spacing: 4) {
                            Text(themeManager.currentTheme.displayName)
                                .font(.callout)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                
                Divider().padding(.leading, 60)
                
                // 快速切换（3个选项）
                HStack(spacing: 12) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    Text("外观模式")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 3个切换按钮
                    HStack(spacing: 8) {
                        ForEach(AppTheme.allCases) { theme in
                            ThemeButton(
                                theme: theme,
                                isSelected: themeManager.currentTheme == theme,
                                action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        themeManager.setTheme(theme)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .actionSheet(isPresented: $showThemeSelector) {
            ActionSheet(
                title: Text("选择外观模式"),
                message: Text("选择你喜欢的外观"),
                buttons: [
                    .default(Text("🌓 跟随系统")) {
                        themeManager.setTheme(.system)
                    },
                    .default(Text("☀️ 浅色模式")) {
                        themeManager.setTheme(.light)
                    },
                    .default(Text("🌙 深色模式")) {
                        themeManager.setTheme(.dark)
                    },
                    .cancel(Text("取消"))
                ]
            )
        }
    }
    
    private var otherSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("其他")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                Button(action: {
                    showDiagnostic = true
                }) {
                    HStack {
                        Image(systemName: "stethoscope")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        
                        Text("数据库诊断")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                Divider().padding(.leading, 60)
                MenuRow(icon: "questionmark.circle.fill", title: "帮助与反馈")
                Divider().padding(.leading, 60)
                MenuRow(icon: "info.circle.fill", title: "关于NFwords")
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .sheet(isPresented: $showDiagnostic) {
            DatabaseDiagnosticView()
        }
        .onAppear {
            statisticsViewModel.load()
        }
    }
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("危险区域")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("重置学习进度")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("清空所有学习记录、目标、任务和报告。词书和单词缓存将保留，可以重新开始学习。")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: {
                    prepareReset()
                }) {
                    HStack {
                        if isResetting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("重置中...")
                        } else {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                            Text("重置学习进度")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isResetting)
            }
            .padding()
            .background(Color.red.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.3), lineWidth: 2)
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - 重置逻辑
    
    private func prepareReset() {
        // 获取当前进度摘要
        do {
            progressSummary = try DatabaseResetService.shared.getProgressSummary()
        } catch {
            progressSummary = nil
        }
        
        // 显示确认对话框
        showResetConfirmation = true
    }
    
    private func performReset() {
        isResetting = true
        resetError = nil
        
        Task {
            do {
                // 1. 重置数据库
                try DatabaseResetService.shared.resetAndReseed()
                
                // 2. 重置学习 ViewModel
                await MainActor.run {
                    appState.studyViewModel.reset()
                }
                
                // 3. 重新加载数据到 AppState
                try await LocalDatabaseCoordinator.shared.bootstrap(appState: appState)
                
                // 4. 显示成功提示
                await MainActor.run {
                    isResetting = false
                    showResetProgress = true
                }
                
                #if DEBUG
                print("✅ 学习进度重置成功！")
                #endif
                
            } catch {
                await MainActor.run {
                    isResetting = false
                    resetError = error.localizedDescription
                    showResetProgress = true
                }
                
                #if DEBUG
                print("❌ 重置失败: \(error)")
                #endif
            }
        }
    }
}

// MARK: - 辅助组件

struct ThemeButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: theme.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(getShortName(for: theme))
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .frame(width: 70, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func getShortName(for theme: AppTheme) -> String {
        switch theme {
        case .system: return "自动"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}

struct DataCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 5)
    }
}

struct AchievementBadge: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    let action: (() -> Void)?
    
    init(icon: String, title: String, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - 预览
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

