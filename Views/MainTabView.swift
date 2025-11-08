//
//  MainTabView.swift
//  NFwordsDemo
//
//  主Tab导航界面 - Tinder式学习 + 墨墨式管理
//  Created by 甘名杨 on 2025/11/3.
//

import SwiftUI

// MARK: - 主Tab导航
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LearningHomeView()
                .tabItem {
                    Label("学习", systemImage: "play.circle.fill")
                }
                .tag(0)
            
            BookLibraryView(onSelectPack: {
                appState.loadDemoDashboard()
            })
            .tabItem {
                Label("词库", systemImage: "books.vertical.fill")
            }
            .tag(1)
            
            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

// MARK: - 学习页（极简入口）
struct LearningHomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showStudyFlow = false
    @State private var showLibrary = false
    
    // 从数据库读取当前目标和任务
    private var currentGoal: LearningGoal? {
        appState.dashboard.goal ?? appState.localDatabase.goals.first(where: { $0.status == .inProgress })
    }
    
    private var todayTask: DailyTask? {
        if let task = appState.dashboard.todayTask {
            return task
        }
        // 从数据库查找今日任务
        let today = Calendar.current.startOfDay(for: Date())
        return appState.localDatabase.tasks.first { task in
            Calendar.current.isDate(task.date, inSameDayAs: today) && task.status != .completed
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)
                
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.blue.opacity(0.8))
                    
                    Text("今日背词")
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)
                    
                    Text("一次滑动，一次记忆。保持专注，快速进入学习节奏。")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                
        
                if let goal = currentGoal,
                   let task = todayTask {
                    QuickProgressCard(goal: goal, task: task)
                }
                
                Button(action: startLearning) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text(appState.hasActiveGoal ? "开始今日学习" : "选择词库后开始")
                            .fontWeight(.semibold)
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [Color.green, Color.blue], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(18)
                    .shadow(color: Color.blue.opacity(0.25), radius: 16, y: 8)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    showLibrary = true
                }) {
                    Text(appState.hasActiveGoal ? "查看/调整学习计划" : "去选择词库")
                        .font(.callout)
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    if appState.dashboard.quickStats.isEmpty {
                        Text("暂无学习数据，先挑选词库开始吧。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .opacity(0.6)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(appState.dashboard.quickStats) { stat in
                                QuickStatPill(icon: stat.icon, label: stat.label, value: stat.value)
                            }
                        }
                        .opacity(appState.hasActiveGoal ? 1 : 0.3)
                    }
                    
                    if appState.dashboard.tips.isEmpty {
                        Text("没有学习计划时，会自动带你挑选词库。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(appState.dashboard.tips, id: \.self) { tip in
                                Text("· \(tip)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.05).ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            guard !appState.hasActiveGoal else { return }
            showLibrary = true
        }
        .fullScreenCover(isPresented: $showStudyFlow) {
            // ⭐ 使用 ZLSwipeableViewSwift 重构版本 (基于 UIKit)
            ZLSwipeCardsView()
                .environmentObject(appState)
                .id("swipe-cards-view")
        }
        .sheet(isPresented: $showLibrary) {
            NavigationView {
                BookLibraryView(onSelectPack: handleGoalSelection)
            }
            .environmentObject(appState)
        }
    }
    
    private func startLearning() {
        if appState.hasActiveGoal {
            showStudyFlow = true
        } else {
            showLibrary = true
        }
    }
    
    private func handleGoalSelection() {
        appState.loadDemoDashboard()
        showLibrary = false
    }
}

// MARK: - 子视图（学习页）

struct QuickProgressCard: View {
    let goal: LearningGoal
    let task: DailyTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(goal.packName)
                    .font(.headline)
                Spacer()
                Text("第 \(goal.currentDay)/\(goal.durationDays) 天")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: goal.progress)
                .progressViewStyle(.linear)
                .tint(.blue)
                .scaleEffect(y: 1.6)
                .animation(.easeOut(duration: 0.3), value: goal.progress)
            
            HStack {
                Label("已学 \(goal.completedWords) 词", systemImage: "checkmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Label("今日新词 \(task.newWordsCount)", systemImage: "sparkles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }
}

struct QuickStatPill: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.callout.bold())
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - 预览
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppState(dashboard: .demo))
    }
}

