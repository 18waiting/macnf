//
//  PlanSelectionView.swift
//  NFwordsDemo
//
//  计划选择页面 - 选择学习周期和创建目标
//  Created by AI Assistant on 2025-01-XX.
//

import SwiftUI
import Foundation

// MARK: - 计划选择视图
struct PlanSelectionView: View {
    let pack: LocalPackRecord
    @State private var selectedPlan: LearningPlan = .standard
    @State private var showConfirmation = false
    @State private var isCreating = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    // 计算属性
    private var calculation: PlanCalculation {
        return calculatePlan(totalWords: pack.totalCount, plan: selectedPlan)
    }
    
    // MARK: - 计划计算（独立实现，避免依赖 GoalService）
    
    /// 计算计划参数
    private func calculatePlan(totalWords: Int, plan: LearningPlan) -> PlanCalculation {
        let durationDays = plan.durationDays
        
        // 计算每日新词数
        let dailyNewWords = totalWords / durationDays
        
        // 计算每日复习词数（基于遗忘曲线）
        // 平均每天约 20-50 个复习词
        let averageReviewRatio = 0.3
        let averageDaysToReview = 3.0
        let estimatedReviewWords = Int(Double(dailyNewWords) * averageDaysToReview * averageReviewRatio)
        let dailyReviewWords = min(max(estimatedReviewWords, 20), 50)
        
        // 计算每日曝光次数
        // 新词：10次曝光/词
        // 复习词：5次曝光/词
        let dailyNewExposures = dailyNewWords * 10
        let dailyReviewExposures = dailyReviewWords * 5
        let totalDailyExposures = dailyNewExposures + dailyReviewExposures
        
        // 计算预计时间（假设每次曝光3秒）
        let estimatedMinutes = Int(Double(totalDailyExposures) * 3.0 / 60.0)
        
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
        
        return PlanCalculation(
            dailyNewWords: dailyNewWords,
            dailyReviewWords: dailyReviewWords,
            dailyExposures: totalDailyExposures,
            estimatedMinutes: estimatedMinutes,
            startDate: startDate,
            endDate: endDate
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 已选择词库
                    selectedPackCard
                    
                    // 计划选择
                    planSelectionSection
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // 系统计算
                    calculationSection
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // 日期范围
                    dateRangeSection
                    
                    // 创建按钮
                    createButton
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("创建学习计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("确认创建？", isPresented: $showConfirmation) {
                Button("取消", role: .cancel) { }
                Button("确认创建") {
                    createGoal()
                }
            } message: {
                Text("将创建 \(selectedPlan.durationDays) 天学习计划，每天约 \(calculation.estimatedMinutes) 分钟")
            }
            .disabled(isCreating)
            .overlay {
                if isCreating {
                    ProgressView("正在创建计划...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
        }
    }
    
    // MARK: - 子视图
    
    /// 已选择词库卡片
    private var selectedPackCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("已选择词库")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.title)
                        .font(.title3.bold())
                    
                    Text("\(pack.totalCount) 词")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    /// 计划选择区域
    private var planSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习周期")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(LearningPlan.allCases, id: \.self) { plan in
                    PlanCard(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        onSelect: {
                            selectedPlan = plan
                        }
                    )
                }
            }
        }
    }
    
    /// 系统计算区域
    private var calculationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 系统自动计算")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                CalculationRow(title: "每天新词", value: "\(calculation.dailyNewWords) 词")
                CalculationRow(title: "每天复习", value: "约 \(calculation.dailyReviewWords) 词")
                CalculationRow(title: "每天曝光", value: "约 \(calculation.dailyExposures) 次")
                CalculationRow(title: "预计时长", value: "每天 \(calculation.estimatedMinutes) 分钟")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    /// 日期范围
    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习日期")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("开始日期")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(calculation.startDate, style: .date)
                        .font(.body.bold())
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("结束日期")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(calculation.endDate, style: .date)
                        .font(.body.bold())
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    /// 创建按钮
    private var createButton: some View {
        Button(action: {
            showConfirmation = true
        }) {
            Text("确认创建")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
        }
        .disabled(isCreating)
    }
    
    // MARK: - 操作
    
    /// 创建学习目标
    private func createGoal() {
        isCreating = true
        
        Task {
            do {
                // 1. 创建目标和任务（直接实现，避免依赖 GoalService）
                let (goal, task) = try await createGoalAndTask()
                
                // 2. 更新应用状态
                await MainActor.run {
                    appState.updateGoal(goal, task: task, report: nil)
                    isCreating = false
                    dismiss()
                    
                    #if DEBUG
                    print("[PlanSelectionView] ✅ 目标创建成功: \(goal.packName)")
                    #endif
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    #if DEBUG
                    print("[PlanSelectionView] ⚠️ 创建目标失败: \(error)")
                    #endif
                    // TODO: 显示错误提示
                }
            }
        }
    }
    
    /// 创建学习目标和任务（独立实现）
    private func createGoalAndTask() async throws -> (goal: LearningGoal, task: DailyTask) {
        let calc = calculation
        let goalId = Int(Date().timeIntervalSince1970)
        
        // 1. 创建学习目标
        let goal = LearningGoal(
            id: goalId,
            packId: pack.packId,
            packName: pack.title,
            totalWords: pack.totalCount,
            durationDays: selectedPlan.durationDays,
            dailyNewWords: calc.dailyNewWords,
            startDate: calc.startDate,
            endDate: calc.endDate,
            status: .inProgress,
            currentDay: 1,
            completedWords: 0,
            completedExposures: 0
        )
        
        // 2. 保存目标到数据库
        let goalStorage = LearningGoalStorage()
        _ = try goalStorage.insert(goal)
        
        // 3. 获取词库的单词ID列表
        let packStorage = LocalPackStorage()
        let packs = try packStorage.fetchAll()
        let packEntries: [Int]
        if let foundPack = packs.first(where: { $0.packId == pack.packId }), !foundPack.entries.isEmpty {
            packEntries = foundPack.entries
        } else {
            // 如果没有 entries，使用临时数据
            packEntries = Array(1...pack.totalCount)
        }
        
        // 4. 获取单词并生成今日任务
        let wordRepository = WordRepository.shared
        let allWords = try wordRepository.fetchWordsByIds(packEntries)
        let shuffledWords = allWords.shuffled()
        
        // 计算新词（第1天）
        let startIndex = 0
        let endIndex = min(calc.dailyNewWords, shuffledWords.count)
        let newWords = Array(shuffledWords[startIndex..<endIndex])
        
        // 第1天无复习词
        let reviewWords: [Word] = []
        
        // 计算曝光次数
        let newExposures = newWords.count * 10
        let reviewExposures = reviewWords.count * 5
        let totalExposures = newExposures + reviewExposures
        
        // 5. 创建今日任务
        let task = DailyTask(
            id: goalId * 1000 + 1,
            goalId: goalId,
            day: 1,
            date: calc.startDate,
            newWords: newWords.map { $0.id },
            reviewWords: reviewWords.map { $0.id },
            totalExposures: totalExposures,
            completedExposures: 0,
            status: .pending,
            startTime: nil,
            endTime: nil
        )
        
        // 6. 保存任务到数据库
        let taskStorage = DailyTaskStorage()
        _ = try taskStorage.insert(task)
        
        // 7. 异步生成所有任务（不阻塞）
        Task.detached {
            do {
                try await self.generateAllTasks(for: goal, packEntries: packEntries, shuffledWords: shuffledWords)
                #if DEBUG
                print("[PlanSelectionView] ✅ 所有任务已生成")
                #endif
            } catch {
                #if DEBUG
                print("[PlanSelectionView] ⚠️ 生成所有任务失败: \(error)")
                #endif
            }
        }
        
        return (goal, task)
    }
    
    /// 生成所有任务（异步）
    private func generateAllTasks(
        for goal: LearningGoal,
        packEntries: [Int],
        shuffledWords: [Word]
    ) async throws {
        let taskStorage = DailyTaskStorage()
        
        for day in 1...goal.durationDays {
            let startIndex = (day - 1) * goal.dailyNewWords
            let endIndex = min(startIndex + goal.dailyNewWords, shuffledWords.count)
            let newWords = Array(shuffledWords[startIndex..<endIndex])
            
            // 计算复习词（简化版，第1天无复习）
            let reviewWords: [Word] = day > 1 ? calculateReviewWords(
                currentDay: day,
                shuffledWords: shuffledWords,
                dailyNewWords: goal.dailyNewWords
            ) : []
            
            // 计算曝光次数
            let newExposures = newWords.count * 10
            let reviewExposures = reviewWords.count * 5
            let totalExposures = newExposures + reviewExposures
            
            // 创建任务
            let task = DailyTask(
                id: goal.id * 1000 + day,
                goalId: goal.id,
                day: day,
                date: Calendar.current.date(byAdding: .day, value: day - 1, to: goal.startDate)!,
                newWords: newWords.map { $0.id },
                reviewWords: reviewWords.map { $0.id },
                totalExposures: totalExposures,
                completedExposures: 0,
                status: .pending,
                startTime: nil,
                endTime: nil
            )
            
            // 保存任务（第1天的任务已经保存，跳过）
            if day > 1 {
                try taskStorage.insert(task)
            }
        }
    }
    
    /// 计算复习词（简化版）
    private func calculateReviewWords(
        currentDay: Int,
        shuffledWords: [Word],
        dailyNewWords: Int
    ) -> [Word] {
        guard currentDay > 1 else { return [] }
        
        var reviewWords: [Word] = []
        let previousDays = Array(1..<currentDay)
        
        for day in previousDays {
            let daysAgo = currentDay - day
            let reviewRatio: Double
            switch daysAgo {
            case 1: reviewRatio = 0.2
            case 2: reviewRatio = 0.3
            case 3: reviewRatio = 0.4
            case 4...7: reviewRatio = 0.5
            default: reviewRatio = 0.3
            }
            
            let startIndex = (day - 1) * dailyNewWords
            let endIndex = min(startIndex + dailyNewWords, shuffledWords.count)
            let words = Array(shuffledWords[startIndex..<endIndex])
            let reviewCount = Int(Double(words.count) * reviewRatio)
            reviewWords.append(contentsOf: words.prefix(reviewCount))
        }
        
        // 限制每日复习词数量
        let maxReviewWords = min(reviewWords.count, 50)
        return Array(reviewWords.shuffled().prefix(maxReviewWords))
    }
}

// MARK: - 计划卡片
private struct PlanCard: View {
    let plan: LearningPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                Image(systemName: plan.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : colorForPlan(plan))
                
                Text(plan.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text("\(plan.durationDays) 天")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                
                Text(plan.description)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isSelected ?
                LinearGradient(
                    colors: [colorForPlan(plan), colorForPlan(plan).opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [Color.white, Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isSelected ? colorForPlan(plan).opacity(0.3) : .black.opacity(0.05), radius: isSelected ? 10 : 5)
        }
    }
    
    private func colorForPlan(_ plan: LearningPlan) -> Color {
        switch plan.color {
        case "red": return .red
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        default: return .blue
        }
    }
}

// MARK: - 计算行（复用自 LearningGoalView）
// 注意：CalculationRow 已在 LearningGoalView.swift 中定义，这里不再重复定义

// MARK: - 预览
struct PlanSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        PlanSelectionView(pack: LocalPackRecord(
            packId: 1,
            title: "CET-4 核心词汇",
            description: "大学英语四级核心词汇",
            category: "考试",
            level: "四级",
            status: .learning,
            progressPercent: 0,
            learnedCount: 0,
            totalCount: 3000,
            completedAt: nil,
            entries: [],
            version: "1",
            hash: ""
        ))
        .environmentObject(AppState(dashboard: .demo))
    }
}

