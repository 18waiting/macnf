//
//  SwipeCardsView.swift
//  NFwordsDemo
//
//  重构版本 - 参考 Tinder/探探滑卡逻辑
//  核心思想：永远只关注当前卡，滑走即销毁
//

import SwiftUI

// ⚠️ 备份文件：此文件中的 SwipeCardsView 已重命名，避免与主文件冲突
private struct SwipeCardsView_Backup: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    private var viewModel: StudyViewModel {
        appState.studyViewModel
    }
    
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
                // 顶部状态栏
                topStatusBar
                    .padding(.top, 50)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                // 卡片堆叠区域
                ZStack {
                    if viewModel.visibleCards.isEmpty {
                        emptyStateView
                    } else {
                        cardStackView
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 550)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 滑动提示
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
            #if DEBUG
            print("[SwipeCardsView] 📱 视图出现")
            print("[SwipeCardsView] visibleCards 数量: \(viewModel.visibleCards.count)")
            for (index, card) in viewModel.visibleCards.enumerated() {
                print("[SwipeCardsView]   [\(index)]: \(card.word.word) (id: \(card.id))")
            }
            #endif
            viewModel.startCurrentCardTracking()
        }
        .onDisappear {
            #if DEBUG
            print("[SwipeCardsView] 📱 视图消失")
            #endif
        }
    }
    
    // MARK: - 卡片堆叠视图（核心重构）⭐
    
    private var cardStackView: some View {
        ZStack {
            // 底层装饰卡（从后往前渲染，只为视觉效果）
            ForEach(Array(viewModel.visibleCards.dropFirst().enumerated()), id: \.element.id) { index, card in
                // 底层卡：纯装饰，无交互
                CardBackdrop(
                    word: card.word,
                    index: index + 1  // +1 因为我们跳过了第一张
                )
                #if DEBUG
                .onAppear {
                    print("[CardBackdrop] 底层卡出现: \(card.word.word) (index: \(index + 1))")
                }
                #endif
            }
            
            // 顶层卡：唯一可交互的卡片 ⭐
            if let topCard = viewModel.visibleCards.first {
                InteractiveCard(
                    card: topCard,
                    onSwipe: { direction, dwellTime in
                        #if DEBUG
                        print("[SwipeCardsView] 🎯 接收到滑动: \(topCard.word.word), direction: \(direction.rawValue)")
                        #endif
                        viewModel.handleSwipe(
                            wordId: topCard.word.id,
                            direction: direction,
                            dwellTime: dwellTime
                        )
                    }
                )
                .id(topCard.id)  // ⭐⭐⭐ 关键：强制每张新卡重建视图
                .zIndex(1000)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .offset(x: 500).combined(with: .opacity)
                ))
            }
        }
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
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
    }
    
    // MARK: - 顶部状态栏
    
    private var topStatusBar: some View {
        HStack {
            // 返回按钮
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // 剩余次数
            // ⭐ P0 修复：从 learningRecords 获取最新数据，而不是使用过时的 card.record
            if let currentCard = viewModel.visibleCards.first,
               let record = viewModel.getLearningRecord(for: currentCard.word.id) {
                Text("剩 \(record.remainingExposures) 次")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
            }
            
            Spacer()
            
            // 进度显示
            Text("进度 \(viewModel.completedCount)/\(viewModel.totalCount)")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
        }
    }
    
    // MARK: - 滑动提示
    
    private var swipeHints: some View {
        HStack(spacing: 40) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left")
                    .font(.title3)
                Text("不会写")
                    .font(.callout)
            }
            .foregroundColor(.orange)
            
            Text("|")
                .foregroundColor(.white.opacity(0.3))
            
            HStack(spacing: 8) {
                Text("会写")
                    .font(.callout)
                Image(systemName: "arrow.right")
                    .font(.title3)
            }
            .foregroundColor(.green)
        }
    }
    
    // MARK: - 底部工具栏
    
    private var bottomToolbar: some View {
        HStack(spacing: 40) {
            Button(action: {}) {
                VStack(spacing: 4) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                    Text("发音")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {}) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title2)
                    Text("撤回")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {}) {
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

// MARK: - 底层装饰卡（纯视觉，无交互）

private struct CardBackdrop: View {
    let word: Word
    let index: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text(word.word)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            if let phonetic = word.phonetic {
                Text(phonetic)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        .scaleEffect(1.0 - CGFloat(index) * 0.02)  // 轻微缩小
        .offset(y: CGFloat(index) * -5)  // 向上偏移
        .allowsHitTesting(false)  // 完全禁用交互
    }
}

// MARK: - 可交互顶卡（核心组件）⭐

private struct InteractiveCard: View {
    let card: StudyCard
    let onSwipe: (SwipeDirection, TimeInterval) -> Void
    
    // 卡片自己的状态（每次重建都会重置）
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var isExpanded: Bool = false
    @State private var startTime: Date = Date()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 60)
                        
                        // 单词头部
                        wordHeader
                        
                        // 展开内容或提示
                        if isExpanded {
                            expandedContent
                                .transition(.move(edge: .top).combined(with: .opacity))
                        } else {
                            expandHint
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 30)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            .overlay(directionIndicators)
            .offset(x: offset.width, y: offset.height * 0.1)
            .rotationEffect(.degrees(rotation))
            .simultaneousGesture(
                // ⭐ 点击手势：优先级高，不被拖拽拦截
                TapGesture()
                    .onEnded { _ in
                        #if DEBUG
                        print("[InteractiveCard] 👆 点击卡片: \(card.word.word), 当前 isExpanded: \(isExpanded)")
                        #endif
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                            #if DEBUG
                            print("[InteractiveCard] ✅ 切换后 isExpanded: \(isExpanded)")
                            #endif
                        }
                    }
            )
            .simultaneousGesture(
                // ⭐ 拖拽手势：与点击手势共存
                DragGesture(minimumDistance: 15)
                    .onChanged { gesture in
                        offset = gesture.translation
                        rotation = Double(gesture.translation.width / 20).clamped(to: -15...15)
                    }
                    .onEnded { gesture in
                        handleDragEnd(translation: gesture.translation)
                    }
            )
        }
        .onAppear {
            startTime = Date()
            #if DEBUG
            print("[InteractiveCard] ✨ 新卡片出现: \(card.word.word) (id: \(card.id))")
            print("[InteractiveCard]    - offset: \(offset)")
            print("[InteractiveCard]    - isExpanded: \(isExpanded)")
            print("[InteractiveCard]    - startTime 已重置")
            #endif
        }
        .onDisappear {
            #if DEBUG
            print("[InteractiveCard] 👋 卡片消失: \(card.word.word) (id: \(card.id))")
            #endif
        }
    }
    
    // MARK: - 子视图
    
    private var wordHeader: some View {
        VStack(spacing: 16) {
            Text(card.word.word)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            if let phonetic = card.word.phonetic {
                Text(phonetic)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            if !isExpanded, let firstTranslation = card.word.translations.first {
                HStack(spacing: 8) {
                    Text(firstTranslation.displayPartOfSpeech)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.6))
                        .cornerRadius(6)
                    
                    Text(firstTranslation.meaning)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Divider().padding(.horizontal, 20)
            
            // 所有释义
            VStack(alignment: .leading, spacing: 12) {
                ForEach(card.word.translations, id: \.self) { translation in
                    HStack(alignment: .top, spacing: 12) {
                        Text(translation.displayPartOfSpeech)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.6))
                            .cornerRadius(6)
                        
                        Text(translation.meaning)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
            
            // 短语搭配
            if !card.word.phrases.isEmpty {
                Divider().padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("常用搭配")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(card.word.phrases.prefix(3), id: \.self) { phrase in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phrase.english)
                                .font(.body.bold())
                                .foregroundColor(.primary)
                            
                            Text(phrase.chinese)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    private var expandHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .font(.title3)
                .foregroundColor(.blue.opacity(0.6))
            
            Text("点击查看更多")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private var directionIndicators: some View {
        ZStack {
            if offset.width > 30 {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                            .opacity(Double(min(abs(offset.width) / 120.0, 1.0)))
                            .padding(.trailing, 30)
                            .padding(.top, 50)
                    }
                    Spacer()
                }
            }
            
            if offset.width < -30 {
                VStack {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                            .opacity(Double(min(abs(offset.width) / 120.0, 1.0)))
                            .padding(.leading, 30)
                            .padding(.top, 50)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - 手势处理
    
    private func handleDragEnd(translation: CGSize) {
        let threshold: CGFloat = 100
        
        if abs(translation.width) > threshold {
            // 触发滑动
            let direction: SwipeDirection = translation.width > 0 ? .right : .left
            let dwellTime = Date().timeIntervalSince(startTime)
            
            #if DEBUG
            print("[InteractiveCard] 🚀 滑动触发: \(card.word.word), direction: \(direction.rawValue), dwell: \(String(format: "%.2f", dwellTime))s")
            #endif
            
            // 飞出动画
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                offset = CGSize(width: translation.width > 0 ? 500 : -500, height: 0)
                rotation = translation.width > 0 ? 15 : -15
            }
            
            // ⭐ 立即回调，不要延迟（Tinder 真实机制）
            onSwipe(direction, dwellTime)
            
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            // 回弹
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                offset = .zero
                rotation = 0
            }
        }
    }
}

// MARK: - 完成视图

private struct CompletionView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
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

// MARK: - 辅助扩展
// 注：Double.clamped(to:) 扩展已在 WordCardView.swift 中定义

// MARK: - 预览

private struct SwipeCardsView_Backup_Previews: PreviewProvider {
    static var previews: some View {
        SwipeCardsView_Backup()
            .environmentObject(AppState(dashboard: .demo))
    }
}
