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
    var onGoalCreated: (() -> Void)? = nil
    @State private var selectedPlan: LearningPlan = .standard
    @State private var showConfirmation = false
    @State private var isCreating = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    
    // MARK: - 计划计算（使用 GoalService）
    
    /// 计算计划参数（委托给 GoalService）
    private var calculation: PlanCalculation {
        GoalService.shared.calculatePlan(
            totalWords: pack.totalCount,
            plan: selectedPlan
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
            .alert("错误", isPresented: $showErrorAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "未知错误")
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
    
    /// 创建学习目标（使用 GoalService）
    private func createGoal() {
        isCreating = true
        
        Task {
            do {
                // 1. 使用 GoalService 创建目标和任务
                let (goal, task) = try GoalService.shared.createGoal(
                    packId: pack.packId,
                    packName: pack.title,
                    totalWords: pack.totalCount,
                    plan: selectedPlan
                )
                
                // 2. 更新应用状态
                await MainActor.run {
                    appState.updateGoal(goal, task: task, report: nil)
                    
                    // 3. 通知 StudyViewModel 重新加载数据
                    appState.studyViewModel.reloadFromDatabase()
                    
                    isCreating = false
                    dismiss()
                    
                    // 4. 通知父视图目标已创建（用于导航）
                    onGoalCreated?()
                    
                    #if DEBUG
                    print("[PlanSelectionView] ✅ 目标创建成功: \(goal.packName)")
                    print("[PlanSelectionView] ✅ StudyViewModel 已刷新")
                    #endif
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    #if DEBUG
                    print("[PlanSelectionView] ⚠️ 创建目标失败: \(error)")
                    #endif
                    // TODO: 显示错误提示
                    showError(error)
                }
            }
        }
    }
    
    /// 显示错误提示
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        showErrorAlert = true
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

