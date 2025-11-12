//
//  AbandonConfirmationView.swift
//  NFwordsDemo
//
//  放弃确认弹窗组件
//  Created by AI Assistant on 2025-01-XX.
//

import SwiftUI

// MARK: - 放弃确认弹窗
struct AbandonConfirmationView: View {
    let goal: LearningGoal
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 图标
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            // 标题
            Text("放弃当前学习？")
                .font(.title2)
                .fontWeight(.bold)
            
            // 当前学习信息
            VStack(alignment: .leading, spacing: 12) {
                Text("您正在学习：")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(.blue)
                    Text(goal.packName)
                        .font(.body.bold())
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("第 \(goal.currentDay) 天 / 共 \(goal.durationDays) 天", systemImage: "calendar")
                    Label("已完成 \(goal.completedWords) / \(goal.totalWords) 词", systemImage: "checkmark.circle")
                    
                    // 检查今日任务状态
                    if let taskStatus = getTaskStatus() {
                        Label(taskStatus, systemImage: "list.bullet")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // 提示信息
            VStack(alignment: .leading, spacing: 8) {
                Text("放弃后将：")
                    .font(.headline)
                Text("• 停止当前学习计划")
                Text("• 学习记录将保留")
                Text("• 可以随时重新开始")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 按钮
            HStack(spacing: 12) {
                Button("取消", action: onCancel)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                
                Button("确认放弃", action: onConfirm)
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 20)
    }
    
    private func getTaskStatus() -> String? {
        // 这里可以根据实际情况获取任务状态
        // 暂时返回 nil，后续可以传入 task 参数
        return nil
    }
}

// MARK: - 预览
struct AbandonConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        AbandonConfirmationView(
            goal: .example,
            onConfirm: {},
            onCancel: {}
        )
    }
}

