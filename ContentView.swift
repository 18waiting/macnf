//
//  ContentView.swift
//  NFwordsDemo
//
//  Created by 甘名杨 on 2025/11/1.
//  Updated by 甘名杨 on 2025/11/3 - Tab导航结构
//

//
//  ContentView.swift
//  NFwords Demo
//
//  主界面 - Tab导航 + 欢迎页
//

import SwiftUI
import Combine

// MARK: - 主题模式枚举
enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - 主题管理器
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            saveTheme()
            #if DEBUG
            print("[Theme] Theme changed to: \(currentTheme.displayName)")
            #endif
        }
    }
    
    private let themeKey = "app_theme_preference"
    
    private init() {
        // 从 UserDefaults 加载保存的主题
        if let savedTheme = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
            #if DEBUG
            print("[Theme] Loaded saved theme: \(theme.displayName)")
            #endif
        } else {
            currentTheme = .system
            #if DEBUG
            print("[Theme] Using default theme: system")
            #endif
        }
    }
    
    // MARK: - Public Methods
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }
    
    func cycleTheme() {
        let themes: [AppTheme] = [.system, .light, .dark]
        if let currentIndex = themes.firstIndex(of: currentTheme) {
            let nextIndex = (currentIndex + 1) % themes.count
            currentTheme = themes[nextIndex]
        }
    }
    
    // MARK: - Private Methods
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
        #if DEBUG
        print("[Theme] Theme saved: \(currentTheme.rawValue)")
        #endif
    }
}

// MARK: - 学习面板数据快照（共享状态）
struct DashboardSnapshot {
    var goal: LearningGoal?
    var todayTask: DailyTask?
    var yesterdayReport: DailyReport?
    var quickStats: [QuickStat]
    var tips: [String]
    
    static let empty = DashboardSnapshot(
        goal: nil,
        todayTask: nil,
        yesterdayReport: nil,
        quickStats: [],
        tips: []
    )
    
    static let demo = DashboardSnapshot(
        goal: .example,
        todayTask: .example,
        yesterdayReport: .example,
        quickStats: [
            QuickStat(icon: "bolt.fill", label: "已复习", value: "220 / 400"),
            QuickStat(icon: "timer", label: "今日停留", value: "38 分")
        ],
        tips: [
            "右滑越多，AI 会减少出现频率",
            "停留时间越长，复习排序越靠前",
            "勾选词库后可随时调整任务量"
        ]
    )
}

struct QuickStat: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let value: String
}

// MARK: - 全局应用状态
enum StatisticsDetailDisplay: Int, Identifiable {
    case plan = 1
    case todayTask
    case review
    
    var id: Int { rawValue }
}

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var hasActiveGoal: Bool
    @Published var activeStatisticDetail: StatisticsDetailDisplay?
    @Published var dashboard: DashboardSnapshot {
        didSet {
            hasActiveGoal = dashboard.goal != nil
        }
    }
    @Published var localDatabase: LocalDatabaseSnapshot
    
    // 全局学习 ViewModel（避免每次创建新实例）
    let studyViewModel = StudyViewModel()
    
    init(dashboard: DashboardSnapshot = .demo) {
        self.dashboard = dashboard
        self.hasActiveGoal = dashboard.goal != nil
        self.activeStatisticDetail = nil
        self.localDatabase = .empty
    }

    func updateGoal(_ goal: LearningGoal?, task: DailyTask?, report: DailyReport?) {
        dashboard.goal = goal
        dashboard.todayTask = task
        dashboard.yesterdayReport = report
        hasActiveGoal = goal != nil
    }
    
    func updateQuickStats(_ stats: [QuickStat]) {
        dashboard.quickStats = stats
    }
    
    func updateTips(_ tips: [String]) {
        dashboard.tips = tips
    }
    
    func resetDashboard() {
        dashboard = .empty
    }
    
    func loadDemoDashboard() {
        dashboard = .demo
    }
    
    func updateLocalDatabase(_ transform: (inout LocalDatabaseSnapshot) -> Void) {
        var snapshot = localDatabase
        transform(&snapshot)
        localDatabase = snapshot
    }
}

struct ContentView: View {
    @State private var hasSeenWelcome = false
    @StateObject private var appState = AppState()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var didPreloadWords = false
    @State private var didBootstrapDatabase = false
    
    var body: some View {
        Group {
            if hasSeenWelcome {
                // 主应用（Tab导航）
                MainTabView()
                    .environmentObject(appState)
                    .task {
                        await bootstrapLocalDatabaseIfNeeded()
                        await preloadWordDataIfNeeded()
                    }
            } else {
                // 欢迎页
                WelcomeView(onContinue: {
                    withAnimation {
                        hasSeenWelcome = true
                    }
                })
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

// MARK: - 欢迎页
struct WelcomeView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo和标题
                VStack(spacing: 16) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("NFwords")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("为应试考试而生")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // 核心特性
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "hand.point.up.left.fill", text: "Tinder式滑卡：会写/不会写")
                    FeatureRow(icon: "target", text: "目标导向：10天3000词")
                    FeatureRow(icon: "timer", text: "停留时间：智能排序复习")
                    FeatureRow(icon: "doc.text.fill", text: "AI短文：考研风格阅读")
                    FeatureRow(icon: "arrow.counterclockwise", text: "量变质变：摒弃艾宾浩斯")
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                
                // 开始使用按钮
                Button(action: {
                    onContinue()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("开始使用 NFwords")
                    }
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - 数据预加载
extension ContentView {
    @MainActor
    private func bootstrapLocalDatabaseIfNeeded() async {
        guard !didBootstrapDatabase else { return }
        didBootstrapDatabase = true
        await LocalDatabaseCoordinator.shared.bootstrap(appState: appState)
    }

    private func preloadWordDataIfNeeded() async {
        guard !didPreloadWords else { return }
        didPreloadWords = true
        do {
            let cache = try await Task.detached(priority: .background) { () -> [Int: WordCacheRecord] in
                try WordRepository.shared.preloadIfNeeded(limit: 400)
                return WordRepository.shared.exportCacheRecords()
            }.value
            let slicesLoaded = max(1, (cache.count + 1999) / 2000)
            await MainActor.run {
                appState.updateLocalDatabase { snapshot in
                    snapshot.wordCaches = cache
                }
                let stats = [
                    QuickStat(icon: "book.fill", label: "词条缓存", value: "\(cache.count)"),
                    QuickStat(icon: "square.stack.3d.up.fill", label: "切片", value: "\(slicesLoaded)")
                ]
                appState.updateQuickStats(stats)
            }
        } catch {
            #if DEBUG
            print("⚠️ 词汇预加载失败: \(error)")
            #endif
        }
    }
}

// MARK: - 功能行
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState(dashboard: .demo))
    }
}

