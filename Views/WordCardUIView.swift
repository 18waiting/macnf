//
//  WordCardUIView.swift
//  NFwordsDemo
//
//  Koloda 的 UIKit 卡片视图
//  纯 UIView 实现，高性能，支持点击展开/收起
//

import UIKit

class WordCardUIView: UIView {
    
    // MARK: - Properties
    
    private var card: StudyCard?
    private var exposureInfo: (current: Int, total: Int)?  // ⭐ 新增：曝光次数信息（已曝光/总曝光）
    
    // UI 组件
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let wordLabel = UILabel()
    private let phoneticLabel = UILabel()
    private let firstTranslationStack = UIStackView()
    private let expandHintView = UIView()
    private let expandedContentView = UIView()
    private let exposureLabel = UILabel()  // ⭐ 新增：曝光次数标签
    
    // 方向指示器
    private let leftIndicator = UIImageView()
    private let rightIndicator = UIImageView()
    
    // 状态
    private var isExpanded = false
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Configuration
    
    func configure(with card: StudyCard, exposureInfo: (current: Int, total: Int)? = nil) {
        self.card = card
        self.exposureInfo = exposureInfo
        updateContent()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 20
        layer.shadowOffset = CGSize(width: 0, height: 10)
        
        setupScrollView()
        setupWordHeader()
        setupExposureLabel()  // ⭐ 新增：设置曝光次数标签
        setupExpandHint()
        setupExpandedContent()
        setupDirectionIndicators()
        setupTapGesture()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupWordHeader() {
        // 单词标签
        wordLabel.translatesAutoresizingMaskIntoConstraints = false
        wordLabel.font = .systemFont(ofSize: 52, weight: .bold)
        wordLabel.textColor = .label
        wordLabel.textAlignment = .center
        wordLabel.numberOfLines = 0
        contentView.addSubview(wordLabel)
        
        // 音标标签
        phoneticLabel.translatesAutoresizingMaskIntoConstraints = false
        phoneticLabel.font = .systemFont(ofSize: 20)
        phoneticLabel.textColor = .secondaryLabel
        phoneticLabel.textAlignment = .center
        contentView.addSubview(phoneticLabel)
        
        // 第一个释义（折叠时显示）
        firstTranslationStack.translatesAutoresizingMaskIntoConstraints = false
        firstTranslationStack.axis = .horizontal
        firstTranslationStack.spacing = 8
        firstTranslationStack.alignment = .center
        contentView.addSubview(firstTranslationStack)
        
        NSLayoutConstraint.activate([
            wordLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),
            wordLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            wordLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            
            phoneticLabel.topAnchor.constraint(equalTo: wordLabel.bottomAnchor, constant: 16),
            phoneticLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            phoneticLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            
            firstTranslationStack.topAnchor.constraint(equalTo: phoneticLabel.bottomAnchor, constant: 16),
            firstTranslationStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    // ⭐ 新增：设置曝光次数标签
    private func setupExposureLabel() {
        exposureLabel.translatesAutoresizingMaskIntoConstraints = false
        exposureLabel.font = .systemFont(ofSize: 16, weight: .medium)
        exposureLabel.textColor = .systemBlue
        exposureLabel.textAlignment = .center
        exposureLabel.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        exposureLabel.layer.cornerRadius = 12
        exposureLabel.clipsToBounds = true
        exposureLabel.isHidden = true  // 默认隐藏，有数据时显示
        addSubview(exposureLabel)
        
        NSLayoutConstraint.activate([
            exposureLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            exposureLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            exposureLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            exposureLabel.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func setupExpandHint() {
        expandHintView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(expandHintView)
        
        let icon = UIImageView(image: UIImage(systemName: "hand.tap.fill"))
        icon.tintColor = .systemBlue.withAlphaComponent(0.6)
        icon.translatesAutoresizingMaskIntoConstraints = false
        expandHintView.addSubview(icon)
        
        let label = UILabel()
        label.text = "点击查看更多"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        expandHintView.addSubview(label)
        
        NSLayoutConstraint.activate([
            expandHintView.topAnchor.constraint(equalTo: firstTranslationStack.bottomAnchor, constant: 20),
            expandHintView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            expandHintView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            expandHintView.heightAnchor.constraint(equalToConstant: 60),
            
            icon.centerXAnchor.constraint(equalTo: expandHintView.centerXAnchor),
            icon.topAnchor.constraint(equalTo: expandHintView.topAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),
            
            label.centerXAnchor.constraint(equalTo: expandHintView.centerXAnchor),
            label.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 8)
        ])
    }
    
    private func setupExpandedContent() {
        expandedContentView.translatesAutoresizingMaskIntoConstraints = false
        expandedContentView.isHidden = true
        contentView.addSubview(expandedContentView)
        
        NSLayoutConstraint.activate([
            expandedContentView.topAnchor.constraint(equalTo: firstTranslationStack.bottomAnchor, constant: 24),
            expandedContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            expandedContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            expandedContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func setupDirectionIndicators() {
        // 右滑指示器（绿色 ✓）
        rightIndicator.translatesAutoresizingMaskIntoConstraints = false
        rightIndicator.image = UIImage(systemName: "checkmark.circle.fill")
        rightIndicator.tintColor = .systemGreen
        rightIndicator.alpha = 0
        addSubview(rightIndicator)
        
        // 左滑指示器（橙色 ✗）
        leftIndicator.translatesAutoresizingMaskIntoConstraints = false
        leftIndicator.image = UIImage(systemName: "xmark.circle.fill")
        leftIndicator.tintColor = .systemOrange
        leftIndicator.alpha = 0
        addSubview(leftIndicator)
        
        NSLayoutConstraint.activate([
            rightIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            rightIndicator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30),
            rightIndicator.widthAnchor.constraint(equalToConstant: 80),
            rightIndicator.heightAnchor.constraint(equalToConstant: 80),
            
            leftIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            leftIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            leftIndicator.widthAnchor.constraint(equalToConstant: 80),
            leftIndicator.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Content Update
    
    private func updateContent() {
        guard let card = card else { return }
        
        wordLabel.text = card.word.word
        
        if let phonetic = card.word.phonetic {
            phoneticLabel.text = phonetic
            phoneticLabel.isHidden = false
        } else {
            phoneticLabel.isHidden = true
        }
        
        // ⭐ 更新曝光次数显示
        if let exposureInfo = exposureInfo {
            exposureLabel.text = "\(exposureInfo.current)/\(exposureInfo.total)"
            exposureLabel.isHidden = false
        } else {
            exposureLabel.isHidden = true
        }
        
        updateFirstTranslation()
        updateExpandedContent()
    }
    
    private func updateFirstTranslation() {
        // 清除旧的视图
        firstTranslationStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard let card = card,
              let firstTranslation = card.word.translations.first else {
            return
        }
        
        // 词性标签
        let posLabel = UILabel()
        posLabel.text = firstTranslation.displayPartOfSpeech
        posLabel.font = .systemFont(ofSize: 12, weight: .bold)
        posLabel.textColor = .white
        posLabel.backgroundColor = .systemBlue.withAlphaComponent(0.6)
        posLabel.textAlignment = .center
        posLabel.layer.cornerRadius = 6
        posLabel.clipsToBounds = true
        posLabel.translatesAutoresizingMaskIntoConstraints = false
        posLabel.textAlignment = .center
        NSLayoutConstraint.activate([
            posLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            posLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // 释义标签
        let meaningLabel = UILabel()
        meaningLabel.text = firstTranslation.meaning
        meaningLabel.font = .systemFont(ofSize: 20)
        meaningLabel.textColor = .secondaryLabel
        
        firstTranslationStack.addArrangedSubview(posLabel)
        firstTranslationStack.addArrangedSubview(meaningLabel)
    }
    
    private func updateExpandedContent() {
        // 清除旧内容
        expandedContentView.subviews.forEach { $0.removeFromSuperview() }
        
        guard let card = card else { return }
        
        var lastView: UIView?
        var topSpacing: CGFloat = 0
        
        // 所有释义
        for translation in card.word.translations {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 12
            stack.alignment = .top
            stack.translatesAutoresizingMaskIntoConstraints = false
            expandedContentView.addSubview(stack)
            
            let posLabel = UILabel()
            posLabel.text = translation.displayPartOfSpeech
            posLabel.font = .systemFont(ofSize: 12, weight: .bold)
            posLabel.textColor = .white
            posLabel.backgroundColor = .systemBlue.withAlphaComponent(0.6)
            posLabel.textAlignment = .center
            posLabel.layer.cornerRadius = 6
            posLabel.clipsToBounds = true
            posLabel.translatesAutoresizingMaskIntoConstraints = false
            posLabel.textAlignment = .center
            NSLayoutConstraint.activate([
                posLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
                posLabel.heightAnchor.constraint(equalToConstant: 24)
            ])
            
            let meaningLabel = UILabel()
            meaningLabel.text = translation.meaning
            meaningLabel.font = .systemFont(ofSize: 16)
            meaningLabel.textColor = .label
            meaningLabel.numberOfLines = 0
            
            stack.addArrangedSubview(posLabel)
            stack.addArrangedSubview(meaningLabel)
            
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: expandedContentView.topAnchor, constant: topSpacing),
                stack.leadingAnchor.constraint(equalTo: expandedContentView.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: expandedContentView.trailingAnchor)
            ])
            
            lastView = stack
            topSpacing += 40
        }
        
        // 短语搭配
        if !card.word.phrases.isEmpty {
            let divider = UIView()
            divider.backgroundColor = .separator
            divider.translatesAutoresizingMaskIntoConstraints = false
            expandedContentView.addSubview(divider)
            
            NSLayoutConstraint.activate([
                divider.topAnchor.constraint(equalTo: (lastView ?? expandedContentView).bottomAnchor, constant: 20),
                divider.leadingAnchor.constraint(equalTo: expandedContentView.leadingAnchor),
                divider.trailingAnchor.constraint(equalTo: expandedContentView.trailingAnchor),
                divider.heightAnchor.constraint(equalToConstant: 1)
            ])
            
            let phraseTitle = UILabel()
            phraseTitle.text = "常用搭配"
            phraseTitle.font = .systemFont(ofSize: 18, weight: .semibold)
            phraseTitle.textColor = .label
            phraseTitle.translatesAutoresizingMaskIntoConstraints = false
            expandedContentView.addSubview(phraseTitle)
            
            NSLayoutConstraint.activate([
                phraseTitle.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 16),
                phraseTitle.leadingAnchor.constraint(equalTo: expandedContentView.leadingAnchor)
            ])
            
            lastView = phraseTitle
            topSpacing = 0
            
            for phrase in card.word.phrases.prefix(3) {
                let phraseView = UIView()
                phraseView.backgroundColor = .systemGray6
                phraseView.layer.cornerRadius = 10
                phraseView.translatesAutoresizingMaskIntoConstraints = false
                expandedContentView.addSubview(phraseView)
                
                let englishLabel = UILabel()
                englishLabel.text = phrase.english
                englishLabel.font = .systemFont(ofSize: 16, weight: .semibold)
                englishLabel.textColor = .label
                englishLabel.translatesAutoresizingMaskIntoConstraints = false
                phraseView.addSubview(englishLabel)
                
                let chineseLabel = UILabel()
                chineseLabel.text = phrase.chinese
                chineseLabel.font = .systemFont(ofSize: 14)
                chineseLabel.textColor = .secondaryLabel
                chineseLabel.translatesAutoresizingMaskIntoConstraints = false
                phraseView.addSubview(chineseLabel)
                
                NSLayoutConstraint.activate([
                    phraseView.topAnchor.constraint(equalTo: (lastView ?? expandedContentView).bottomAnchor, constant: topSpacing + 12),
                    phraseView.leadingAnchor.constraint(equalTo: expandedContentView.leadingAnchor),
                    phraseView.trailingAnchor.constraint(equalTo: expandedContentView.trailingAnchor),
                    
                    englishLabel.topAnchor.constraint(equalTo: phraseView.topAnchor, constant: 12),
                    englishLabel.leadingAnchor.constraint(equalTo: phraseView.leadingAnchor, constant: 12),
                    englishLabel.trailingAnchor.constraint(equalTo: phraseView.trailingAnchor, constant: -12),
                    
                    chineseLabel.topAnchor.constraint(equalTo: englishLabel.bottomAnchor, constant: 4),
                    chineseLabel.leadingAnchor.constraint(equalTo: phraseView.leadingAnchor, constant: 12),
                    chineseLabel.trailingAnchor.constraint(equalTo: phraseView.trailingAnchor, constant: -12),
                    chineseLabel.bottomAnchor.constraint(equalTo: phraseView.bottomAnchor, constant: -12)
                ])
                
                lastView = phraseView
                topSpacing = 0
            }
        }
        
        // 更新 contentView 高度
        if let lastView = lastView {
            NSLayoutConstraint.activate([
                expandedContentView.bottomAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 40)
            ])
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        guard let card = card else { return }
        
        #if DEBUG
        print("[WordCardUIView] 👆 点击卡片: \(card.word.word), isExpanded: \(isExpanded)")
        #endif
        
        isExpanded.toggle()
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0) {
            self.expandHintView.isHidden = self.isExpanded
            self.expandedContentView.isHidden = !self.isExpanded
            self.layoutIfNeeded()
        }
        
        #if DEBUG
        print("[WordCardUIView] ✅ 展开状态更新: \(isExpanded)")
        #endif
    }
    
    // MARK: - Direction Indicator
    
    func updateDirectionIndicator(offset: CGFloat) {
        let percentage = min(abs(offset) / 200.0, 1.0)
        
        if offset > 0 {
            // 右滑（会写）
            rightIndicator.alpha = percentage
            leftIndicator.alpha = 0
        } else if offset < 0 {
            // 左滑（不会写）
            leftIndicator.alpha = percentage
            rightIndicator.alpha = 0
        } else {
            // ⭐ 修复：当 offset 为 0 时，重置指示器
            resetDirectionIndicators()
        }
    }
    
    // ⭐ 新增：重置方向指示器（用于拖拽取消时）
    func resetDirectionIndicators() {
        UIView.animate(withDuration: 0.2) {
            self.rightIndicator.alpha = 0
            self.leftIndicator.alpha = 0
        }
    }
}

// MARK: - UIScrollViewDelegate

extension WordCardUIView: UIScrollViewDelegate {
    // 可以在这里处理滚动事件
}


