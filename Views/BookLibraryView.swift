//
//  BookLibraryView.swift
//  NFwordsDemo
//
//  词库管理页面（墨墨式）
//  Created by 甘名杨 on 2025/11/3.
//

import SwiftUI

// MARK: - 词库管理视图
struct BookLibraryView: View {
    var onSelectPack: (() -> Void)? = nil
    @State private var showingAddPack = false
    @State private var showAbandonConfirmation = false
    @State private var pendingPack: LocalPackRecord? = nil
    @State private var showPlanSelection = false
    @EnvironmentObject var appState: AppState
    
    // 当前目标
    private var currentGoal: LearningGoal? {
        appState.dashboard.goal
    }
    
    // 今日任务
    private var todayTask: DailyTask? {
        appState.dashboard.todayTask
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 当前词库
                    currentPackCard
                    
                    // 推荐词库
                    recommendedPacksSection
                    
                    // 自定义导入
                    customImportSection
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("📚 我的词库")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddPack = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showPlanSelection) {
                if let pack = pendingPack {
                    PlanSelectionView(pack: pack)
                        .environmentObject(appState)
                }
            }
            .overlay {
                // 放弃确认弹窗
                if showAbandonConfirmation, let goal = currentGoal {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showAbandonConfirmation = false
                                pendingPack = nil
                            }
                        
                        AbandonConfirmationView(
                            goal: goal,
                            onConfirm: {
                                handleAbandonGoal()
                            },
                            onCancel: {
                                showAbandonConfirmation = false
                                pendingPack = nil
                            }
                        )
                        .padding()
                    }
                }
            }
        }
    }
    
    // MARK: - 子视图
    
    private var currentPackCard: some View {
        Group {
            if let goal = currentGoal, goal.status == .inProgress {
                CurrentPackCard(
                    goal: goal,
                    task: todayTask,
                    onContinueLearning: {
                        // 继续学习 - 导航到学习页面
                        onSelectPack?()
                    },
                    onSwitchPack: {
                        // 切换词库 - 显示放弃确认
                        // 这里不直接显示，而是等待用户点击推荐词库
                    }
                )
            } else {
                EmptyPackPlaceholder(onSelectPack: {
                    // 选择词库 - 显示计划选择
                    // 这里需要先选择词库，暂时使用占位符
                })
            }
        }
    }
    
    private var recommendedPacksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("推荐词库")
                .font(.headline)
                .padding(.horizontal)
            
            let availablePacks = appState.localDatabase.packs.filter { pack in
                // 排除当前正在学习的词书
                if let currentGoal = appState.dashboard.goal {
                    return pack.packId != currentGoal.packId
                }
                return true
            }
            
            if availablePacks.isEmpty {
                Text("暂无可用词库")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(availablePacks) { pack in
                        RecommendedPackCard(
                            pack: pack,
                            isCurrentPack: currentGoal?.packId == pack.packId,
                            onSelect: {
                                handleSelectPack(pack)
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var customImportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("自定义词库")
                .font(.headline)
                .padding(.horizontal)
            
            Button(action: {
                showingAddPack = true
                onSelectPack?()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("导入词库")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("支持：Excel / CSV / TXT")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 处理逻辑
    
    /// 处理选择词库
    private func handleSelectPack(_ pack: LocalPackRecord) {
        // 1. 检查是否有进行中的目标
        if let goal = currentGoal, goal.status == .inProgress {
            // 2. 显示放弃确认弹窗
            pendingPack = pack
            showAbandonConfirmation = true
        } else {
            // 3. 直接进入计划选择
            pendingPack = pack
            showPlanSelection = true
        }
    }
    
    /// 处理放弃目标
    private func handleAbandonGoal() {
        guard let goal = currentGoal else { return }
        
        do {
            // 1. 放弃当前目标（直接实现，避免依赖 GoalService）
            try abandonGoal(goal)
            
            // 2. 清除应用状态
            appState.updateGoal(nil as LearningGoal?, task: nil as DailyTask?, report: nil as DailyReport?)
            
            // 3. 关闭确认弹窗
            showAbandonConfirmation = false
            
            // 4. 进入计划选择
            if let pack = pendingPack {
                showPlanSelection = true
            }
            
            #if DEBUG
            print("[BookLibraryView] ✅ 目标已放弃，进入计划选择")
            #endif
        } catch {
            #if DEBUG
            print("[BookLibraryView] ⚠️ 放弃目标失败: \(error)")
            #endif
            // TODO: 显示错误提示
        }
    }
    
    /// 放弃学习目标（独立实现）
    private func abandonGoal(_ goal: LearningGoal) throws {
        #if DEBUG
        print("[BookLibraryView] 放弃学习目标: id=\(goal.id), pack=\(goal.packName)")
        #endif
        
        // 1. 创建更新后的目标（endDate 是 let，需要创建新实例）
        let updatedGoal = LearningGoal(
            id: goal.id,
            packId: goal.packId,
            packName: goal.packName,
            totalWords: goal.totalWords,
            durationDays: goal.durationDays,
            dailyNewWords: goal.dailyNewWords,
            startDate: goal.startDate,
            endDate: Date(),  // 更新为当前日期
            status: .abandoned,  // 更新状态
            currentDay: goal.currentDay,
            completedWords: goal.completedWords,
            completedExposures: goal.completedExposures
        )
        
        // 2. 保存到数据库
        let goalStorage = LearningGoalStorage()
        try goalStorage.update(updatedGoal)
        
        // 3. 清理当前任务（如果有未完成的）
        let taskStorage = DailyTaskStorage()
        if let task = try? taskStorage.fetchToday(),
           task.goalId == goal.id,
           task.status == .inProgress {
            // 创建更新后的任务
            let updatedTask = DailyTask(
                id: task.id,
                goalId: task.goalId,
                day: task.day,
                date: task.date,
                newWords: task.newWords,
                reviewWords: task.reviewWords,
                totalExposures: task.totalExposures,
                completedExposures: task.completedExposures,
                status: .pending,  // 标记为待开始，而不是删除
                startTime: task.startTime,
                endTime: task.endTime
            )
            try taskStorage.update(updatedTask)
        }
        
        #if DEBUG
        print("[BookLibraryView] ✅ 目标已放弃")
        #endif
    }
}

// MARK: - 词库卡片
struct PackCard: View {
    let name: String
    let wordCount: Int
    var onSelect: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.largeTitle)
                .foregroundColor(.blue.opacity(0.6))
            
            Text(name)
                .font(.headline)
            
            Text("\(wordCount)词")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("开始学习") {
                onSelect?()
            }
            .font(.caption.bold())
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

// MARK: - 当前词库卡片
private struct CurrentPackCard: View {
    let goal: LearningGoal
    let task: DailyTask?
    let onContinueLearning: () -> Void
    let onSwitchPack: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.blue)
                Text(goal.packName)
                    .font(.headline)
                Spacer()
                Button("切换") {
                    onSwitchPack()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // 进度信息
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("第 \(goal.currentDay) 天 / 共 \(goal.durationDays) 天")
                    Spacer()
                    Text("\(Int(goal.progress * 100))%")
                }
                
                ProgressView(value: goal.progress)
                
                Text("已完成 \(goal.completedWords) / \(goal.totalWords) 词")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 今日任务
            if let task = task {
                HStack {
                    Label("\(task.newWordsCount) 新词", systemImage: "sparkles")
                    Label("\(task.reviewWordsCount) 复习", systemImage: "arrow.clockwise")
                    Spacer()
                    if task.status == .completed {
                        Label("已完成", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .font(.subheadline)
            }
            
            // 操作按钮
            if let task = task, task.status != .completed {
                Button(action: onContinueLearning) {
                    Text("继续学习")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
            } else {
                Button(action: {
                    // 查看详情
                }) {
                    Text("查看详情")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 15)
    }
}

// MARK: - 推荐词库卡片
private struct RecommendedPackCard: View {
    let pack: LocalPackRecord
    let isCurrentPack: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Spacer()
                    if isCurrentPack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Text(pack.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(pack.totalCount) 词")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrentPack ? Color.green : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.05), radius: 8)
        }
    }
}

// MARK: - 空状态
private struct EmptyPackPlaceholder: View {
    var onSelectPack: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("还没有选择词库")
                .font(.headline)
            
            Text("挑选一个目标词库，系统会为你生成 10 天冲刺计划。")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                onSelectPack?()
            }) {
                Text("选择词库")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 12)
    }
}

// MARK: - 预览
struct BookLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        BookLibraryView()
            .environmentObject(AppState(dashboard: .demo))
    }
}

