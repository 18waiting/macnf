//
//  LearningGoalView.swift
//  NFwordsDemo
//
//  学习目标创建界面 - 10天3000词
//  Created by 甘名杨 on 2025/11/3.
//

import SwiftUI

// MARK: - 学习目标创建视图
struct LearningGoalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedPack: VocabularyPack = .cet4
    @State private var selectedDays: Int = 10
    @State private var showConfirmation = false
    
    // 计算属性
    private var dailyNewWords: Int {
        selectedPack.totalWords / selectedDays
    }
    
    private var dailyExposures: Int {
        dailyNewWords * 10 + 20 * 5  // 新词10次 + 约20个复习5次
    }
    
    private var dailyMinutes: Int {
        Int(Double(dailyExposures) * 3.0 / 60.0)  // 假设每次3秒
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 选择词库
                    packSelectionSection
                    
                    // 学习周期
                    durationSelectionSection
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // 系统自动计算
                    calculationSection
                    
                    // 额度检查
                    quotaCheckSection
                    
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
            .navigationTitle("创建学习目标")
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
                Text("将创建 \(selectedDays) 天学习计划，每天约 \(dailyMinutes) 分钟")
            }
        }
    }
    
    // MARK: - 子视图
    
    /// 词库选择
    private var packSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择词库")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(VocabularyPack.allCases, id: \.self) { pack in
                Button(action: {
                    selectedPack = pack
                }) {
                    HStack {
                        Image(systemName: selectedPack == pack ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedPack == pack ? .blue : .gray)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pack.name)
                                .font(.body.bold())
                                .foregroundColor(.primary)
                            
                            Text("\(pack.totalWords)词")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(selectedPack == pack ? Color.blue.opacity(0.1) : Color.white)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    /// 学习周期选择
    private var durationSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习周期")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // 天数选择器
                Picker("天数", selection: $selectedDays) {
                    Text("7天").tag(7)
                    Text("10天").tag(10)
                    Text("20天").tag(20)
                    Text("30天").tag(30)
                    Text("60天").tag(60)
                }
                .pickerStyle(.segmented)
                
                // 强度指示
                HStack {
                    Text("学习强度：")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(0..<intensityStars, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    
                    ForEach(0..<(5 - intensityStars), id: \.self) { _ in
                        Image(systemName: "star")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Text(intensityLabel)
                        .font(.caption.bold())
                        .foregroundColor(intensityColor)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    /// 系统自动计算
    private var calculationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 系统自动计算")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                CalculationRow(title: "每天新词", value: "\(dailyNewWords) 词")
                CalculationRow(title: "每天复习", value: "约 20-50 词")
                CalculationRow(title: "每天曝光", value: "约 \(dailyExposures) 次")
                CalculationRow(title: "预计时长", value: "每天 \(dailyMinutes) 分钟")
                CalculationRow(title: "每个单词", value: "预计出现 10 次")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    /// 额度检查
    private var quotaCheckSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💰 额度检查")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("需要额度：")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(selectedPack.totalWords) 个")
                        .font(.headline)
                }
                
                HStack {
                    Text("剩余额度：")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("6,120 个")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text("✅")
                }
                
                HStack {
                    Text("使用后剩余：")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(6120 - selectedPack.totalWords) 个")
                        .font(.headline)
                }
            }
            .padding()
            .background(Color.green.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
            )
        }
    }
    
    /// 日期范围
    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("开始日期")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(Date(), style: .date)
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
                    Text(endDate, style: .date)
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
    }
    
    // MARK: - 辅助计算
    
    private var intensityStars: Int {
        switch selectedDays {
        case 7: return 5
        case 10: return 4
        case 20: return 3
        case 30: return 2
        default: return 1
        }
    }
    
    private var intensityLabel: String {
        switch selectedDays {
        case 7: return "极速突击"
        case 10: return "快速冲刺"
        case 20: return "稳健学习"
        case 30: return "舒适节奏"
        default: return "从容备考"
        }
    }
    
    private var intensityColor: Color {
        switch selectedDays {
        case 7: return .red
        case 10: return .orange
        case 20: return .blue
        default: return .green
        }
    }
    
    private var endDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedDays, to: Date()) ?? Date()
    }
    
    // MARK: - 操作
    
    private func createGoal() {
        // TODO: 创建学习目标
        print("📅 创建学习目标：\(selectedPack.name)，\(selectedDays)天")
        dismiss()
    }
}

// MARK: - 计算行
struct CalculationRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text("• \(title)：")
                .font(.callout)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.callout.bold())
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 词库枚举（临时，实际应从服务器获取）
enum VocabularyPack: String, CaseIterable {
    case cet4 = "CET-4 核心词汇"
    case cet6 = "CET-6"
    case kaoyan = "考研核心"
    case toefl = "TOEFL"
    
    var name: String { rawValue }
    
    var totalWords: Int {
        switch self {
        case .cet4: return 3000
        case .cet6: return 5500
        case .kaoyan: return 5500
        case .toefl: return 8000
        }
    }
}

// MARK: - 预览
struct LearningGoalView_Previews: PreviewProvider {
    static var previews: some View {
        LearningGoalView()
    }
}

