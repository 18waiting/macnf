//
//  ProfileView.swift
//  NFwordsDemo
//
//  个人中心页面（墨墨式）
//  Created by 甘名杨 on 2025/11/3.
//

import SwiftUI

// MARK: - 个人中心视图
struct ProfileView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 个人信息卡片
                    profileCard
                    
                    // 学习数据
                    studyDataSection
                    
                    // 成就徽章
                    achievementsSection
                    
                    // 功能菜单
                    menuSection
                    
                    // 其他
                    otherSection
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("👤 我的")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 设置
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
    }
    
    // MARK: - 子视图
    
    private var profileCard: some View {
        VStack(spacing: 16) {
            // 头像和昵称
            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue.opacity(0.6))
                
                Text("学习者")
                    .font(.title3.bold())
            }
            
            // 学习天数和连续签到
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("67")
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                    Text("学习天数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("23")
                        .font(.title2.bold())
                        .foregroundColor(.orange)
                    Text("连续签到")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // 本周和累计
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("本周学习: 1,280词")
                        .font(.callout)
                    Text("累计: 8,640词")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 等级进度
            VStack(spacing: 8) {
                HStack {
                    Text("等级: Lv.12 进阶学习者")
                        .font(.callout.bold())
                    Spacer()
                    Text("75%")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: 0.75)
                    .tint(.blue)
                    .scaleEffect(y: 2)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    private var studyDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习数据")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DataCard(icon: "book.fill", title: "词汇量", value: "8,640词")
                DataCard(icon: "clock.fill", title: "学习时长", value: "126小时")
                DataCard(icon: "target", title: "完成率", value: "87%")
                DataCard(icon: "flame.fill", title: "最长连续", value: "45天")
            }
            .padding(.horizontal)
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就徽章")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                AchievementBadge(icon: "medal.fill", title: "初学者", color: .green)
                AchievementBadge(icon: "star.fill", title: "坚持者", color: .orange)
                AchievementBadge(icon: "crown.fill", title: "单词达人", color: .yellow)
                
                Spacer()
                
                Button("全部 →") {
                    // TODO: 查看全部成就
                }
                .font(.caption)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var menuSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("功能菜单")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                MenuRow(icon: "books.vertical.fill", title: "我的词库")
                Divider().padding(.leading, 60)
                MenuRow(icon: "chart.bar.fill", title: "学习统计")
                Divider().padding(.leading, 60)
                MenuRow(icon: "star.fill", title: "生词本")
                Divider().padding(.leading, 60)
                MenuRow(icon: "doc.text.fill", title: "学习历史")
                Divider().padding(.leading, 60)
                MenuRow(icon: "target", title: "学习计划")
                Divider().padding(.leading, 60)
                MenuRow(icon: "gearshape.fill", title: "设置")
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var otherSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("其他")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                MenuRow(icon: "questionmark.circle.fill", title: "帮助与反馈")
                Divider().padding(.leading, 60)
                MenuRow(icon: "info.circle.fill", title: "关于NFwords")
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

// MARK: - 辅助组件

struct DataCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 5)
    }
}

struct AchievementBadge: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {
            // TODO: 导航
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - 预览
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

