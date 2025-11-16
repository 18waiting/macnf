//
//  LearningPathView.swift
//  NFwordsDemo
//
//  学习路径界面
//  Created by AI Assistant on 2025-01-XX.
//

import SwiftUI

// MARK: - 学习路径主视图
struct LearningPathView: View {
    @StateObject private var viewModel = LearningPathViewModel()
    let packId: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 路径概览卡片
                pathOverviewCard
                
                // 当前里程碑
                currentMilestoneCard
                
                // 等级列表
                levelList
            }
            .padding()
        }
        .navigationTitle("学习路径")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadPath(packId: packId)
        }
    }
    
    // MARK: - 路径概览卡片
    private var pathOverviewCard: some View {
        VStack(spacing: 16) {
            // 进度环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: viewModel.path?.progress ?? 0)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: viewModel.path?.progress)
                
                VStack {
                    Text("\(Int((viewModel.path?.progress ?? 0) * 100))%")
                        .font(.system(size: 32, weight: .bold))
                    Text("完成")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 统计信息
            HStack(spacing: 20) {
                PathStatItem(
                    icon: "checkmark.circle.fill",
                    title: "已完成",
                    value: "\(viewModel.path?.completedLevelsCount ?? 0)",
                    color: .green
                )
                
                PathStatItem(
                    icon: "arrow.right.circle.fill",
                    title: "当前等级",
                    value: "\(viewModel.path?.currentLevel ?? 1)",
                    color: .blue
                )
                
                PathStatItem(
                    icon: "lock.fill",
                    title: "总等级",
                    value: "\(viewModel.path?.totalLevels ?? 0)",
                    color: .gray
                )
            }
            
            // 预计完成时间
            if let estimatedCompletion = viewModel.path?.estimatedCompletion {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text("预计完成时间：")
                        .font(.subheadline)
                        Text(estimatedCompletion, style: .date)
                        .font(.subheadline.bold())
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
    
    // MARK: - 当前里程碑卡片
    private var currentMilestoneCard: some View {
        if let milestone = viewModel.path?.getCurrentMilestone() {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.orange)
                    Text("当前里程碑")
                        .font(.headline)
                }
                
                Text(milestone.title)
                    .font(.title3.bold())
                
                Text(milestone.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let reward = milestone.reward {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.purple)
                        Text("奖励：\(reward)")
                            .font(.subheadline.bold())
                            .foregroundColor(.purple)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
        }
    }
    
    // MARK: - 等级列表
    private var levelList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("等级列表")
                .font(.headline)
            
            if let path = viewModel.path {
                ForEach(1...path.totalLevels, id: \.self) { level in
                    LevelRow(
                        level: level,
                        isCompleted: path.completedLevels.contains(level),
                        isUnlocked: path.unlockedLevels.contains(level),
                        isCurrent: level == path.currentLevel,
                        milestone: path.milestones.first { $0.level == level }
                    )
                }
            }
        }
    }
}

// MARK: - 路径统计项
struct PathStatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 等级行组件
struct LevelRow: View {
    let level: Int
    let isCompleted: Bool
    let isUnlocked: Bool
    let isCurrent: Bool
    let milestone: Milestone?
    
    var body: some View {
        HStack(spacing: 16) {
            // 等级图标
            ZStack {
                Circle()
                    .fill(levelCircleColor)
                    .frame(width: 50, height: 50)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                } else if isCurrent {
                    Text("\(level)")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                } else if isUnlocked {
                    Text("\(level)")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white)
                }
            }
            
            // 等级信息
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone?.title ?? "第 \(level) 级")
                    .font(.headline)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(milestone?.description ?? "完成第 \(level) 级学习")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let reward = milestone?.reward, isUnlocked {
                    HStack {
                        Image(systemName: "gift.fill")
                            .font(.caption2)
                        Text(reward)
                            .font(.caption.bold())
                    }
                    .foregroundColor(.purple)
                }
            }
            
            Spacer()
            
            // 状态图标
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else if isCurrent {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            } else if !isUnlocked {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            isCurrent ? Color.blue.opacity(0.1) : Color(.systemBackground)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
    
    private var levelCircleColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .blue
        } else if isUnlocked {
            return .blue.opacity(0.7)
        } else {
            return .gray
        }
    }
}

// MARK: - 视图模型
@MainActor
class LearningPathViewModel: ObservableObject {
    @Published var path: LearningPath?
    
    private let service = LearningPathService.shared
    
    func loadPath(packId: Int) {
        // TODO: 从存储加载或创建学习路径
        // path = loadFromStorage(packId: packId) ?? service.createLearningPath(packId: packId)
    }
}

// MARK: - 预览
struct LearningPathView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LearningPathView(packId: 1)
        }
    }
}

