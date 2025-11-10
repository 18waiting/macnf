//
//  KolodaCardsView.swift
//  NFwordsDemo
//
//  基于 Koloda 的滑卡视图（手动集成版本）
//  完整实现 Tinder/探探 风格的卡片交互
//
//  ⭐ 注意：此版本不需要 import Koloda
//  因为 Koloda 源码文件直接放在项目中

import SwiftUI
import UIKit

// MARK: - SwiftUI 主视图

struct KolodaCardsView: View {
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
                
                // 卡片区域 (Koloda)
                ZStack {
                    if viewModel.visibleCards.isEmpty {
                        emptyStateView
                    } else {
                        KolodaViewWrapper(
                            viewModel: viewModel,
                            onSwipe: { wordId, direction, dwellTime in
                                // ⭐ P1 修复：直接传递 wordId，避免通过 cardId 查找可能失败
                                handleSwipe(wordId: wordId, direction: direction, dwellTime: dwellTime)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            print("[KolodaCardsView] 📱 视图出现")
            print("[KolodaCardsView] visibleCards 数量: \(viewModel.visibleCards.count)")
            for (index, card) in viewModel.visibleCards.enumerated() {
                print("[KolodaCardsView]   [\(index)]: \(card.word.word) (id: \(card.id))")
            }
            #endif
            viewModel.startCurrentCardTracking()
        }
        .onDisappear {
            #if DEBUG
            print("[KolodaCardsView] 📱 视图消失")
            #endif
        }
    }
    
    // MARK: - 子视图
    
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
    
    private var topStatusBar: some View {
        HStack {
            // 返回按钮
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // ⭐ 移除：剩余次数显示（已移到卡片上）
            
            // 进度显示
            // ⭐ 修复：确保 UI 能观察到 completedCount 和 totalCount 的变化
            Text("进度 \(viewModel.completedCount)/\(viewModel.totalCount)")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
        }
    }
    
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
    
    // MARK: - 业务逻辑
    
    // ⭐ P1 修复：直接接收 wordId，避免通过 cardId 查找可能失败
    private func handleSwipe(wordId: Int, direction: SwipeDirection, dwellTime: TimeInterval) {
        #if DEBUG
        print("[KolodaCardsView] 🎯 接收到滑动: wordId=\(wordId), direction=\(direction.rawValue), dwell=\(String(format: "%.2f", dwellTime))s")
        #endif
        
        // 直接调用 ViewModel，不需要查找卡片
        viewModel.handleSwipe(
            wordId: wordId,
            direction: direction,
            dwellTime: dwellTime
        )
    }
}

// MARK: - UIViewRepresentable 桥接层

struct KolodaViewWrapper: UIViewRepresentable {
    // ⭐ 修复：直接使用 ViewModel 引用，而不是 cards 副本
    let viewModel: StudyViewModel
    // ⭐ P1 修复：改为传递 wordId 而不是 cardId，避免查找失败
    let onSwipe: (Int, SwipeDirection, TimeInterval) -> Void
    
    func makeUIView(context: Context) -> KolodaView {
        let kolodaView = KolodaView()
        
        // 初始化协调器（必须在设置数据源之前）
        context.coordinator.viewModel = viewModel
        context.coordinator.onSwipe = onSwipe
        
        // 配置 KolodaView
        kolodaView.dataSource = context.coordinator
        kolodaView.delegate = context.coordinator
        kolodaView.countOfVisibleCards = 3
        kolodaView.alphaValueSemiTransparent = 0.1
        
        #if DEBUG
        print("[KolodaViewWrapper] ✅ makeUIView 完成, cards: \(viewModel.visibleCards.count)")
        #endif
        
        // ⭐ 关键：必须在设置数据源后调用 reloadData() 来加载卡片
        DispatchQueue.main.async {
            kolodaView.reloadData()
        }
        
        return kolodaView
    }
    
    func updateUIView(_ uiView: KolodaView, context: Context) {
        // ⭐ 修复：直接使用 ViewModel 的 visibleCards，不维护副本
        let previousCards = context.coordinator.viewModel?.visibleCards ?? []
        let currentCards = viewModel.visibleCards
        
        // 更新 ViewModel 引用
        context.coordinator.viewModel = viewModel
        context.coordinator.onSwipe = onSwipe
        
        // ⭐ 修复：检查队列数量是否改变（不仅仅是 visibleCards）
        let previousQueueCount = context.coordinator.viewModel?.queueCount ?? 0
        let currentQueueCount = viewModel.queueCount
        
        // 检查数据是否真正改变
        let cardsChanged = previousCards.count != currentCards.count || 
                          previousCards.map { $0.id } != currentCards.map { $0.id } ||
                          previousQueueCount != currentQueueCount
        
        // 只有在数据真正改变时才刷新视图
        if cardsChanged {
            DispatchQueue.main.async {
                // ⭐ 修复：当队列数量改变时，重新加载数据，确保 Koloda 知道新的卡片数量
                uiView.reloadData()
                #if DEBUG
                print("[KolodaViewWrapper] 🔄 reloadData called: queueCount=\(currentQueueCount), visible=\(currentCards.count)")
                #endif
            }
        }
        
        #if DEBUG
        print("[KolodaViewWrapper] 🔄 updateUIView, queueCount: \(previousQueueCount)->\(currentQueueCount), visible: \(currentCards.count), changed: \(cardsChanged)")
        #endif
    }
    
    func makeCoordinator() -> KolodaCardsCoordinator {
        return KolodaCardsCoordinator(viewModel: viewModel, onSwipe: onSwipe)
    }
}

// MARK: - 协调器（数据源 + 委托）

class KolodaCardsCoordinator: NSObject {
    // ⭐ 修复：直接使用 ViewModel 引用，不维护 cards 副本
    weak var viewModel: StudyViewModel?
    // ⭐ P1 修复：改为传递 wordId 而不是 cardId，避免查找失败
    var onSwipe: (Int, SwipeDirection, TimeInterval) -> Void
    
    // ⭐ 修复：移除重复的停留时间追踪，统一使用 ViewModel 的 DwellTimeTracker
    
    // ⭐ P1 修复：视图重用池
    private var cardViewPool: [WordCardUIView] = []
    private let maxPoolSize = 5  // 最多保留5个视图
    
    init(viewModel: StudyViewModel, onSwipe: @escaping (Int, SwipeDirection, TimeInterval) -> Void) {
        self.viewModel = viewModel
        self.onSwipe = onSwipe
        super.init()
        
        #if DEBUG
        print("[KolodaCoordinator] 🎬 初始化, cards: \(viewModel.visibleCards.count)")
        #endif
    }
    
    // ⭐ 修复：Koloda 需要访问整个队列，而不仅仅是 visibleCards
    // visibleCards 只用于 UI 显示，但 Koloda 需要知道总共有多少张卡片
    // 注意：Koloda 会根据索引从队列中获取卡片，索引是相对于整个队列的
    private var totalCardCount: Int {
        // ⭐ 修复：明确使用 @Published 属性 queueCount，避免歧义
        guard let vm = viewModel else { return 0 }
        return vm.queueCount  // 使用 @Published var queueCount
    }
    
    // ⭐ 辅助属性：获取可见卡片（用于调试）
    private var visibleCards: [StudyCard] {
        return viewModel?.visibleCards ?? []
    }
    
    // ⭐ P1 修复：从重用池获取或创建视图
    private func dequeueCardView() -> WordCardUIView {
        if let reusedView = cardViewPool.popLast() {
            #if DEBUG
            print("[KolodaCoordinator] ♻️ 重用卡片视图")
            #endif
            return reusedView
        } else {
            #if DEBUG
            print("[KolodaCoordinator] ✨ 创建新卡片视图")
            #endif
            return WordCardUIView()
        }
    }
    
    // ⭐ P1 修复：将视图回收到重用池
    private func enqueueCardView(_ view: WordCardUIView) {
        // 清理视图状态
        view.subviews.forEach { $0.removeFromSuperview() }
        
        // 如果池未满，则回收
        if cardViewPool.count < maxPoolSize {
            cardViewPool.append(view)
            #if DEBUG
            print("[KolodaCoordinator] ♻️ 回收卡片视图到池中 (池大小: \(cardViewPool.count))")
            #endif
        } else {
            #if DEBUG
            print("[KolodaCoordinator] 🗑️ 池已满，丢弃视图")
            #endif
        }
    }
}

// MARK: - KolodaViewDataSource

extension KolodaCardsCoordinator: KolodaViewDataSource {
    func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
        // ⭐ 修复：返回整个队列的数量，而不是 visibleCards 的数量
        let count = totalCardCount
        #if DEBUG
        print("[KolodaCoordinator] kolodaNumberOfCards: \(count) (visible: \(visibleCards.count))")
        #endif
        return count
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        // ⭐ 修复：从整个队列中获取卡片，而不是从 visibleCards
        guard let viewModel = viewModel,
              let card = viewModel.getCard(at: index) else {
            #if DEBUG
            print("[KolodaCoordinator] ⚠️ 无法获取卡片: index=\(index), queueCount=\(totalCardCount)")
            #endif
            return UIView()
        }
        
        // ⭐ P1 修复：从重用池获取视图，而不是每次都创建新的
        let cardView = dequeueCardView()
        
        // ⭐ 新增：获取曝光次数信息并传递给卡片视图
        var exposureInfo: (current: Int, total: Int)? = nil
        if let record = viewModel.getLearningRecord(for: card.word.id) {
            let current = record.targetExposures - record.remainingExposures
            exposureInfo = (current: current, total: record.targetExposures)
        }
        cardView.configure(with: card, exposureInfo: exposureInfo)
        
        // ⭐ 修复：使用 ViewModel 的 DwellTimeTracker 开始计时
        // ⚠️ 注意：viewModel 已经在 guard let 中解包，直接使用即可
        if index == 0 {
            viewModel.dwellTimeTracker.startTracking(wordId: card.word.id)
            #if DEBUG
            print("[KolodaCoordinator] ⏱️ 使用 DwellTimeTracker 开始计时: \(card.word.word)")
            #endif
        }
        
        #if DEBUG
        print("[KolodaCoordinator] 📄 提供卡片视图: index=\(index), word=\(card.word.word)")
        #endif
        
        return cardView
    }
    
    func koloda(_ koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
        return nil
    }
}

// MARK: - KolodaViewDelegate

extension KolodaCardsCoordinator: KolodaViewDelegate {
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {
        // ⭐ 修复：从整个队列中获取卡片，而不是从 visibleCards
        guard let viewModel = viewModel,
              let card = viewModel.getCard(at: index) else {
            #if DEBUG
            print("[KolodaCoordinator] ⚠️ didSwipeCardAt: 无法获取卡片 index=\(index), queueCount=\(totalCardCount)")
            #endif
            return
        }
        
        // ⭐ 修复：使用 ViewModel 的 DwellTimeTracker 获取停留时间
        let dwellTime = viewModel.dwellTimeTracker.stopTracking()
        
        // 转换方向 (Koloda 的 SwipeResultDirection → 我们的 SwipeDirection)
        let swipeDirection: SwipeDirection
        switch direction {
        case .left, .topLeft, .bottomLeft:
            swipeDirection = .left
        case .right, .topRight, .bottomRight:
            swipeDirection = .right
        default:
            swipeDirection = .left
        }
        
        #if DEBUG
        print("[KolodaCoordinator] 🎯 didSwipeCardAt: word=\(card.word.word), direction=\(swipeDirection.rawValue), dwell=\(String(format: "%.2f", dwellTime))s")
        #endif
        
        // 📞 触发回调 (通知 ViewModel)
        // ⭐ P1 修复：直接传递 wordId 而不是 cardId，避免查找失败
        onSwipe(card.word.id, swipeDirection, dwellTime)
        
        // ⭐ 修复：使用 ViewModel 的 DwellTimeTracker 开始下一张卡的计时
        let nextIndex = index + 1
        if let nextCard = viewModel.getCard(at: nextIndex) {
            viewModel.dwellTimeTracker.startTracking(wordId: nextCard.word.id)
            #if DEBUG
            print("[KolodaCoordinator] ⏱️ 使用 DwellTimeTracker 开始计时下一张: \(nextCard.word.word)")
            #endif
        }
    }
    
    func koloda(_ koloda: KolodaView, draggedCardWithPercentage finishPercentage: CGFloat, in direction: SwipeResultDirection) {
        // 更新方向指示器 (绿色 ✓ / 橙色 ✗)
        if let cardView = koloda.viewForCard(at: koloda.currentCardIndex) as? WordCardUIView {
            let offset: CGFloat
            switch direction {
            case .left, .topLeft, .bottomLeft:
                offset = -finishPercentage * 200  // 左滑为负
            case .right, .topRight, .bottomRight:
                offset = finishPercentage * 200    // 右滑为正
            default:
                offset = 0
            }
            cardView.updateDirectionIndicator(offset: offset)
        }
    }
    
    // ⭐ 修复：拖拽取消时重置指示器
    func kolodaDidResetCard(_ koloda: KolodaView) {
        if let cardView = koloda.viewForCard(at: koloda.currentCardIndex) as? WordCardUIView {
            cardView.resetDirectionIndicators()
            #if DEBUG
            print("[KolodaCoordinator] 🔄 卡片重置，清除方向指示器")
            #endif
        }
    }
    
    // ⭐ 新增：卡片显示时更新曝光次数信息
    func koloda(_ koloda: KolodaView, didShowCardAt index: Int) {
        guard let viewModel = viewModel,
              let card = viewModel.getCard(at: index),
              let cardView = koloda.viewForCard(at: index) as? WordCardUIView else {
            return
        }
        
        // 更新曝光次数信息
        var exposureInfo: (current: Int, total: Int)? = nil
        if let record = viewModel.getLearningRecord(for: card.word.id) {
            let current = record.targetExposures - record.remainingExposures
            exposureInfo = (current: current, total: record.targetExposures)
        }
        cardView.configure(with: card, exposureInfo: exposureInfo)
        
        #if DEBUG
        if let exposureInfo = exposureInfo {
            print("[KolodaCoordinator] 📊 更新卡片曝光次数: \(card.word.word) = \(exposureInfo.current)/\(exposureInfo.total)")
        }
        #endif
    }
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        #if DEBUG
        let currentQueueCount = totalCardCount
        let currentVisibleCount = visibleCards.count
        print("[KolodaCoordinator] 📭 卡片用完了")
        print("[KolodaCoordinator]   当前队列数量: \(currentQueueCount)")
        print("[KolodaCoordinator]   当前可见卡片: \(currentVisibleCount)")
        print("[KolodaCoordinator]   Koloda currentCardIndex: \(koloda.currentCardIndex)")
        
        // ⭐ 修复：如果队列中还有卡片，说明是同步问题，需要重新加载
        if currentQueueCount > 0 {
            print("[KolodaCoordinator] ⚠️ 警告：队列中还有 \(currentQueueCount) 张卡片，但 Koloda 认为用完了")
            print("[KolodaCoordinator]   这可能是索引同步问题，尝试重新加载...")
            DispatchQueue.main.async {
                koloda.reloadData()
            }
        }
        #endif
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        // 点击卡片展开/收起（由 WordCardUIView 内部处理）
        #if DEBUG
        print("[KolodaCoordinator] 👆 点击卡片: index=\(index)")
        #endif
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

