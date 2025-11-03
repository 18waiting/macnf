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

// MARK: - 全局应用状态
enum StatisticsDetailDisplay: Int, Identifiable {
    case plan = 1
    case todayTask
    case review
    
    var id: Int { rawValue }
}

@MainActor
final class AppState: ObservableObject {
    @Published var hasActiveGoal: Bool
    @Published var activeStatisticDetail: StatisticsDetailDisplay?
    
    init(hasActiveGoal: Bool = false) {
        self.hasActiveGoal = hasActiveGoal
        self.activeStatisticDetail = nil
    }
}

struct ContentView: View {
    @State private var hasSeenWelcome = false
    @StateObject private var appState = AppState()
    
    var body: some View {
        if hasSeenWelcome {
            // 主应用（Tab导航）
            MainTabView()
                .environmentObject(appState)
        } else {
            // 欢迎页
            WelcomeView(onContinue: {
                withAnimation {
                    hasSeenWelcome = true
                }
            })
        }
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
            .environmentObject(AppState(hasActiveGoal: true))
    }
}

