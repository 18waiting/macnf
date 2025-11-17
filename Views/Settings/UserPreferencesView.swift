//
//  UserPreferencesView.swift
//  NFwordsDemo
//
//  用户偏好设置界面
//  Created by AI Assistant on 2025-01-XX.
//

import SwiftUI
import Combine

// MARK: - 用户偏好设置视图
struct UserPreferencesView: View {
    @StateObject private var viewModel = UserPreferencesViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // 学习目标
                learningGoalsSection
                
                // 音频设置
                audioSettingsSection
                
                // 通知设置
                notificationSettingsSection
                
                // 界面设置
                appearanceSettingsSection
                
                // 学习设置
                studySettingsSection
                
                // 数据设置
                dataSettingsSection
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        viewModel.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                viewModel.load()
            }
        }
    }
    
    // MARK: - 学习目标部分
    private var learningGoalsSection: some View {
        Section {
            // 每日学习时长
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("每日学习时长")
                        .font(.body)
                    Spacer()
                    Text("\(viewModel.preferences.dailyGoalMinutes) 分钟")
                        .font(.body.bold())
                        .foregroundColor(.blue)
                }
                
                Slider(
                    value: Binding(
                        get: { Double(viewModel.preferences.dailyGoalMinutes) },
                        set: { viewModel.preferences.dailyGoalMinutes = Int($0) }
                    ),
                    in: 10...120,
                    step: 5
                )
                .accentColor(.blue)
                
                HStack {
                    Text("10分钟")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("120分钟")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            // 每日学习单词数
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("每日学习单词数")
                        .font(.body)
                    Spacer()
                    Text("\(viewModel.preferences.dailyGoalWords) 词")
                        .font(.body.bold())
                        .foregroundColor(.blue)
                }
                
                Slider(
                    value: Binding(
                        get: { Double(viewModel.preferences.dailyGoalWords) },
                        set: { viewModel.preferences.dailyGoalWords = Int($0) }
                    ),
                    in: 20...500,
                    step: 10
                )
                .accentColor(.blue)
                
                HStack {
                    Text("20词")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("500词")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            // 难度级别
            Picker("难度级别", selection: $viewModel.preferences.difficultyLevel) {
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    HStack {
                        Text(level.displayName)
                        Spacer()
                        Text(level.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(level)
                }
            }
        } header: {
            Text("学习目标")
        } footer: {
            Text("根据你的时间和能力设置合适的学习目标")
        }
    }
    
    // MARK: - 音频设置部分
    private var audioSettingsSection: some View {
        Section {
            Toggle("启用音频", isOn: $viewModel.preferences.audioEnabled)
            
            if viewModel.preferences.audioEnabled {
                Toggle("自动播放音频", isOn: $viewModel.preferences.autoPlayAudio)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("播放速度")
                            .font(.body)
                        Spacer()
                        Text(String(format: "%.1fx", viewModel.preferences.audioPlaybackSpeed))
                            .font(.body.bold())
                            .foregroundColor(.blue)
                    }
                    
                    Slider(
                        value: $viewModel.preferences.audioPlaybackSpeed,
                        in: 0.5...2.0,
                        step: 0.1
                    )
                    .accentColor(.blue)
                    
                    HStack {
                        Text("0.5x")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("2.0x")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("音频设置")
        }
    }
    
    // MARK: - 通知设置部分
    private var notificationSettingsSection: some View {
        Section {
            Toggle("启用通知", isOn: $viewModel.preferences.notificationsEnabled)
            
            if viewModel.preferences.notificationsEnabled {
                DatePicker(
                    "提醒时间",
                    selection: Binding(
                        get: { viewModel.preferences.reminderTime ?? Date() },
                        set: { viewModel.preferences.reminderTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
                
                // 学习提醒日期
                VStack(alignment: .leading, spacing: 12) {
                    Text("学习提醒日期")
                        .font(.body)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(1...7, id: \.self) { day in
                            let dayName = getDayName(day)
                            let isSelected = viewModel.preferences.studyReminderDays.contains(day)
                            
                            Button(action: {
                                if isSelected {
                                    viewModel.preferences.studyReminderDays.remove(day)
                                } else {
                                    viewModel.preferences.studyReminderDays.insert(day)
                                }
                            }) {
                                Text(dayName)
                                    .font(.caption.bold())
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .frame(width: 40, height: 40)
                                    .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("通知设置")
        } footer: {
            Text("设置学习提醒，帮助你保持学习习惯")
        }
    }
    
    // MARK: - 界面设置部分
    private var appearanceSettingsSection: some View {
        Section {
            Picker("主题", selection: $viewModel.preferences.theme) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            
            Picker("动画速度", selection: $viewModel.preferences.cardAnimationSpeed) {
                ForEach(AnimationSpeed.allCases, id: \.self) { speed in
                    Text(speed.displayName).tag(speed)
                }
            }
            
            Toggle("显示音标", isOn: $viewModel.preferences.showPhonetic)
            Toggle("显示例句", isOn: $viewModel.preferences.showExamples)
        } header: {
            Text("界面设置")
        }
    }
    
    // MARK: - 学习设置部分
    private var studySettingsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("新词默认曝光次数")
                        .font(.body)
                    Spacer()
                    Text("\(viewModel.preferences.defaultNewWordExposures) 次")
                        .font(.body.bold())
                        .foregroundColor(.blue)
                }
                
                Stepper(
                    "",
                    value: $viewModel.preferences.defaultNewWordExposures,
                    in: 5...20,
                    step: 1
                )
            }
            .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("复习词默认曝光次数")
                        .font(.body)
                    Spacer()
                    Text("\(viewModel.preferences.defaultReviewExposures) 次")
                        .font(.body.bold())
                        .foregroundColor(.blue)
                }
                
                Stepper(
                    "",
                    value: $viewModel.preferences.defaultReviewExposures,
                    in: 3...10,
                    step: 1
                )
            }
            .padding(.vertical, 4)
            
            Toggle("启用间隔重复算法", isOn: $viewModel.preferences.enableSpacedRepetition)
            Toggle("启用自动复习", isOn: $viewModel.preferences.enableAutoReview)
        } header: {
            Text("学习设置")
        } footer: {
            Text("间隔重复算法可以智能安排复习时间，提高学习效率")
        }
    }
    
    // MARK: - 数据设置部分
    private var dataSettingsSection: some View {
        Section {
            Toggle("启用学习分析", isOn: $viewModel.preferences.enableAnalytics)
            Toggle("启用数据同步", isOn: $viewModel.preferences.enableSync)
        } header: {
            Text("数据设置")
        } footer: {
            Text("学习分析可以帮助你了解学习进度和效率")
        }
    }
    
    // MARK: - 辅助方法
    private func getDayName(_ day: Int) -> String {
        let days = ["一", "二", "三", "四", "五", "六", "日"]
        return days[day - 1]
    }
}

// MARK: - 视图模型
@MainActor
class UserPreferencesViewModel: ObservableObject {
    @Published var preferences: UserPreferences = .default
    
    private let storage = UserPreferencesStorage.shared
    
    func load() {
        preferences = storage.load()
    }
    
    func save() {
        do {
            try storage.save(preferences)
        } catch {
            #if DEBUG
            print("[UserPreferencesView] ⚠️ 保存失败: \(error)")
            #endif
        }
    }
}

// MARK: - 预览
struct UserPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        UserPreferencesView()
    }
}

