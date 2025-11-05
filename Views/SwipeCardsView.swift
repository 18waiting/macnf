//
//  SwipeCardsView.swift
//  NFwordsDemo
//
//  Created by 甘名杨 on 2025/11/1.
//  Updated by 甘名杨 on 2025/11/3 - Tinder式3层堆叠
//

//
//  SwipeCardsView.swift
//  NFwords Demo
//
//  滑卡容器视图 - 管理卡片队列
//

import SwiftUI

struct SwipeCardsView: View {
    @StateObject private var viewModel = StudyViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部状态栏（Tinder式）⭐
                topStatusBar
                    .padding(.top, 50)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                // Tinder式卡片堆叠（3层）⭐
                ZStack {
                    if viewModel.visibleCards.isEmpty {
                        // 空状态提示
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("正在加载单词...")
                                .font(.title3)
                                .foregroundColor(.white)
                            
                            Text("如果长时间未加载，请返回检查词库设置")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    } else {
                        ForEach(Array(viewModel.visibleCards.enumerated()).reversed(), id: \.element.id) { index, card in
                            let cardIndex = index
                            
                            WordCardView(
                                word: card.word,
                                record: card.record,
                                isTopCard: cardIndex == 0,
                                onSwipe: { direction, dwellTime in
                                    #if DEBUG
                                    print("[SwipeCard] Card \(card.id) swiped, direction: \(direction.rawValue)")
                                    #endif
                                    viewModel.handleSwipe(
                                        wordId: card.word.id,
                                        direction: direction,
                                        dwellTime: dwellTime
                                    )
                                }
                            )
                            .id(card.id)  // 关键修复：使用卡片唯一ID，确保每张卡片有独立的视图实例
                            .zIndex(Double(viewModel.visibleCards.count - cardIndex))
                            .scaleEffect(getScale(for: cardIndex))
                            .offset(y: getOffset(for: cardIndex))
                            .opacity(getOpacity(for: cardIndex))
                            .allowsHitTesting(cardIndex == 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.visibleCards.count)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 550)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 滑动提示（Tinder式）
                swipeHints
                    .padding(.vertical, 20)
                
                // 底部工具栏
                bottomToolbar
                    .padding(.bottom, 40)
                    .padding(.horizontal, 20)
            }
            
            // 完成庆祝动画
            if viewModel.isCompleted {
                CompletionView()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 启动第一张卡片的计时
            viewModel.startCurrentCardTracking()
        }
    }
    
    // MARK: - 卡片堆叠参数
    
    /// 获取卡片缩放比例（统一大小）
    private func getScale(for index: Int) -> CGFloat {
        return 1.0  // 所有卡片大小一致
    }
    
    /// 获取卡片偏移量（轻微堆叠效果）
    private func getOffset(for index: Int) -> CGFloat {
        return CGFloat(index) * -5  // 每张卡片向上偏移5pt
    }
    
    /// 获取卡片透明度（统一不透明）
    private func getOpacity(for index: Int) -> Double {
        return 1.0  // 所有卡片完全不透明
    }
    
    // MARK: - 子视图
    
    /// 顶部状态栏（参考总览设计）⭐
    private var topStatusBar: some View {
        HStack {
            // 返回按钮
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // 剩余次数（当前卡片）⭐
            if let currentCard = viewModel.visibleCards.first {
                Text("剩 \(currentCard.record.remainingExposures) 次")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
            }
            
            Spacer()
            
            // 进度显示 ⭐
            Text("进度 \(viewModel.completedCount)/\(viewModel.totalCount)")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
        }
    }
    
    /// 滑动提示（Tinder式）⭐
    private var swipeHints: some View {
        HStack(spacing: 40) {
            // 左滑提示
            HStack(spacing: 8) {
                Image(systemName: "arrow.left")
                    .font(.title3)
                Text("不会写")
                    .font(.callout)
            }
            .foregroundColor(.orange)
            
            Text("|")
                .foregroundColor(.white.opacity(0.3))
            
            // 右滑提示
            HStack(spacing: 8) {
                Text("会写")
                    .font(.callout)
                Image(systemName: "arrow.right")
                    .font(.title3)
            }
            .foregroundColor(.green)
        }
    }
    
    /// 底部工具栏
    private var bottomToolbar: some View {
        HStack(spacing: 40) {
            // 发音按钮
            Button(action: {
                // TODO: 播放发音
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                    Text("发音")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
            
            Spacer()
            
            // 撤回按钮
            Button(action: {
                // TODO: 撤回上一次操作
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title2)
                    Text("撤回")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
            
            Spacer()
            
            // 更多按钮
            Button(action: {
                // TODO: 显示更多选项
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title2)
                    Text("更多")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
        }
    }
}

// MARK: - 完成视图
struct CompletionView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 庆祝图标
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                
                Text("今日学习完成！")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("正在生成学习报告...")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .transition(.opacity)
    }
}

// MARK: - 预览
struct SwipeCardsView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeCardsView()
    }
}

