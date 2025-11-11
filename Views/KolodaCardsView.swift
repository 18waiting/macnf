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
    @ObservedObject private var viewModel: StudyViewModel
    @Environment(\.dismiss) var dismiss

    init(viewModel: StudyViewModel) {
        _viewModel = ObservedObject(initialValue: viewModel)
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
        
        // ⭐ 修复：优化滑动体验
        // 降低旋转角度，让滑动更流畅
        kolodaView.rotationAngle = CGFloat(Double.pi) / 20.0  // 从 18° 降低到 9°
        // 设置最小缩放比例，让背景卡片更明显
        kolodaView.scaleMin = 0.9  // 从 0.8 提高到 0.9
        
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
        let previousQueueCount = context.coordinator.viewModel?.queueCount ?? 0
        
        // 更新 ViewModel 引用
        context.coordinator.viewModel = viewModel
        context.coordinator.onSwipe = onSwipe
        
        // ⭐ 修复：检查队列数量是否改变（不仅仅是 visibleCards）
        let currentQueueCount = viewModel.queueCount
        
        // 检查数据是否真正改变
        let cardsChanged = previousCards.count != currentCards.count || 
                          previousCards.map { $0.id } != currentCards.map { $0.id } ||
                          previousQueueCount != currentQueueCount
        
        // ⭐ 关键修复：当队列数量改变时，检查是否需要重置 Koloda 的索引
        // 注意：滑动后的重置由 didSwipeCardAt 处理，这里只处理其他情况
        if cardsChanged {
            DispatchQueue.main.async {
                let oldIndex = uiView.currentCardIndex
                
                // ⭐ 只在索引超出范围时才重置（滑动后的重置由 didSwipeCardAt 处理）
                if oldIndex >= currentQueueCount {
                    // ⭐ 索引超出范围，强制重置
                    uiView.resetCurrentCardIndex()
                    #if DEBUG
                    print("[KolodaViewWrapper] 🔄 索引超出范围，强制重置: oldIndex=\(oldIndex) >= queueCount=\(currentQueueCount)")
                    #endif
                } else if previousQueueCount == currentQueueCount {
                    // 如果只是卡片内容变化（队列数量没变），只需重新加载
                    uiView.reloadData()
                    #if DEBUG
                    print("[KolodaViewWrapper] 🔄 reloadData: queueCount=\(currentQueueCount), visible=\(currentCards.count)")
                    #endif
                }
                // 注意：如果队列数量变化，重置由 didSwipeCardAt 处理，这里不做处理
            }
        }
        
        #if DEBUG
        if cardsChanged {
            print("[KolodaViewWrapper] 🔄 updateUIView, queueCount: \(previousQueueCount)->\(currentQueueCount), visible: \(currentCards.count), changed: \(cardsChanged)")
        }
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
    
    // ⭐ 重新设计：Koloda 只看到剩余的队列，而不是整个列表
    // 这样 Koloda 的索引（0 到 queueCount-1）直接对应队列索引，无需映射
    // 当队列变化时，调用 reloadData() 重置 Koloda 的索引
    private var totalCardCount: Int {
        guard let vm = viewModel else { return 0 }
        // ⭐ 关键修复：返回当前队列数量，而不是初始总数
        // 这样 Koloda 的索引范围是 0 到 queueCount-1，直接对应队列索引
        return vm.queueCount
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
        guard let viewModel = viewModel else { return UIView() }
        
        // ⭐ 修复：Koloda 的索引直接对应队列索引（0 到 queueCount-1）
        guard index >= 0 && index < viewModel.queueCount,
              let card = viewModel.getCard(at: index) else {
            #if DEBUG
            print("[KolodaCoordinator] ⚠️ viewForCardAt: 索引越界 index=\(index), queueCount=\(viewModel.queueCount)")
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
        // 只有当前显示的卡片（索引 0）才需要开始计时
        if index == 0 {
            viewModel.dwellTimeTracker.startTracking(wordId: card.word.id)
            #if DEBUG
            print("[KolodaCoordinator] ⏱️ 使用 DwellTimeTracker 开始计时: \(card.word.word), index=\(index)")
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
        guard let viewModel = viewModel else { return }
        
        // ⭐ 修复：Koloda 的索引直接对应队列索引（0 到 queueCount-1）
        guard index >= 0 && index < viewModel.queueCount,
              let card = viewModel.getCard(at: index) else {
            #if DEBUG
            print("[KolodaCoordinator] ⚠️ didSwipeCardAt: 索引越界 index=\(index), queueCount=\(viewModel.queueCount)")
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
        
        // ⭐ 关键修复：滑动完成后，队列会变化，需要重置 Koloda 的索引
        // 延迟重置，确保滑动动画完成后再重置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 检查队列是否还有卡片
            if let vm = self.viewModel, vm.queueCount > 0 {
                // 重置 Koloda 的索引，让它重新从队列的第一张开始
                koloda.resetCurrentCardIndex()
                #if DEBUG
                print("[KolodaCoordinator] 🔄 滑动完成，重置索引: queueCount=\(vm.queueCount)")
                #endif
            }
        }
        
        // ⭐ 修复：使用 ViewModel 的 DwellTimeTracker 开始下一张卡的计时
        // 下一张卡片的索引是 0（因为队列的第一张已经被移除，新的第一张是索引 0）
        if viewModel.queueCount > 0,
           let nextCard = viewModel.getCard(at: 0) {
            // 延迟开始计时，等待重置完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                viewModel.dwellTimeTracker.startTracking(wordId: nextCard.word.id)
                #if DEBUG
                print("[KolodaCoordinator] ⏱️ 使用 DwellTimeTracker 开始计时下一张: \(nextCard.word.word), index=0")
                #endif
            }
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
        // ⭐ 修复：确保重置时使用正确的索引
        let currentIndex = koloda.currentCardIndex
        if currentIndex >= 0 && currentIndex < (viewModel?.queueCount ?? 0),
           let cardView = koloda.viewForCard(at: currentIndex) as? WordCardUIView {
            cardView.resetDirectionIndicators()
            #if DEBUG
            print("[KolodaCoordinator] 🔄 卡片重置，清除方向指示器, index=\(currentIndex)")
            #endif
        }
    }
    
    // ⭐ 新增：降低滑动阈值，让滑动更容易触发
    // 返回 0.25 表示只需要拖动 25% 的屏幕宽度就能触发滑动（默认是 100%）
    func kolodaSwipeThresholdRatioMargin(_ koloda: KolodaView) -> CGFloat? {
        return 0.25  // 25% 的阈值，更容易触发滑动
    }
    
    // ⭐ 新增：卡片显示时更新曝光次数信息
    func koloda(_ koloda: KolodaView, didShowCardAt index: Int) {
        guard let viewModel = viewModel else { return }
        
        // ⭐ 修复：Koloda 的索引直接对应队列索引（0 到 queueCount-1）
        guard index >= 0 && index < viewModel.queueCount,
              let card = viewModel.getCard(at: index) else {
            #if DEBUG
            print("[KolodaCoordinator] ⚠️ didShowCardAt: 索引越界 index=\(index), queueCount=\(viewModel.queueCount)")
            #endif
            return
        }
        
        // ⭐ 修复：确保卡片视图存在且正确更新
        if let cardView = koloda.viewForCard(at: index) as? WordCardUIView {
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
        } else {
            #if DEBUG
            print("[KolodaCoordinator] ⚠️ didShowCardAt: 卡片视图不存在 index=\(index)")
            #endif
        }
    }
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        #if DEBUG
        let currentQueueCount = totalCardCount
        let currentVisibleCount = visibleCards.count
        print("[KolodaCoordinator] 📭 卡片用完了")
        print("[KolodaCoordinator]   当前队列数量: \(currentQueueCount)")
        print("[KolodaCoordinator]   当前可见卡片: \(currentVisibleCount)")
        print("[KolodaCoordinator]   Koloda currentCardIndex: \(koloda.currentCardIndex)")
        
        // ⭐ 修复：如果队列中还有卡片，说明是同步问题，需要强制重置
        if currentQueueCount > 0 {
            print("[KolodaCoordinator] ⚠️ 警告：队列中还有 \(currentQueueCount) 张卡片，但 Koloda 认为用完了")
            print("[KolodaCoordinator]   这可能是索引同步问题，尝试强制重置...")
            DispatchQueue.main.async {
                // ⭐ 使用 resetCurrentCardIndex() 强制重置索引
                koloda.resetCurrentCardIndex()
                #if DEBUG
                print("[KolodaCoordinator] ✅ 已调用 resetCurrentCardIndex()，索引应已重置为 0")
                #endif
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

