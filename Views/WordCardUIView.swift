//
//  WordCardUIView.swift
//  NFwordsDemo
//
//  ZLSwipeableViewSwift 的 UIKit 卡片视图
//  纯 UIView 实现，高性能，支持点击展开/收起
//

import UIKit

class WordCardUIView: UIView {
    
    // MARK: - Properties
    
    var card: StudyCard? {
        didSet {
            updateContent()
        }
    }
    
    var isExpanded: Bool = false {
        didSet {
            updateExpandedState()
        }
    }
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.layer.shadowRadius = 20
        return view
    }()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()
    
    // 单词头部
    private let wordLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 52, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private let phoneticLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let primaryMeaningContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    private let partOfSpeechTag: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        return label
    }()
    
    private let meaningLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // 展开提示
    private let expandHintContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    private let expandHintIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "hand.tap.fill"))
        iv.tintColor = UIColor.systemBlue.withAlphaComponent(0.6)
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let expandHintLabel: UILabel = {
        let label = UILabel()
        label.text = "点击查看更多"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    // 展开内容
    private let expandedContentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .leading
        stack.distribution = .fill
        stack.isHidden = true
        return stack
    }()
    
    private let translationsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .leading
        stack.distribution = .fill
        return stack
    }()
    
    private let phrasesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private let phrasesTitle: UILabel = {
        let label = UILabel()
        label.text = "常用搭配"
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    // 方向指示器
    private let rightIndicator: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iv.tintColor = .systemGreen
        iv.contentMode = .scaleAspectFit
        iv.alpha = 0
        return iv
    }()
    
    private let leftIndicator: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        iv.alpha = 0
        return iv
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        // 容器
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // ScrollView
        containerView.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // ContentStack
        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 60),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 30),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -30),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -40),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -60)
        ])
        
        // 单词头部
        contentStack.addArrangedSubview(wordLabel)
        contentStack.addArrangedSubview(phoneticLabel)
        
        // 主要释义容器
        primaryMeaningContainer.addSubview(partOfSpeechTag)
        primaryMeaningContainer.addSubview(meaningLabel)
        
        partOfSpeechTag.translatesAutoresizingMaskIntoConstraints = false
        meaningLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            partOfSpeechTag.topAnchor.constraint(equalTo: primaryMeaningContainer.topAnchor),
            partOfSpeechTag.leadingAnchor.constraint(equalTo: primaryMeaningContainer.leadingAnchor),
            partOfSpeechTag.heightAnchor.constraint(equalToConstant: 24),
            partOfSpeechTag.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            meaningLabel.topAnchor.constraint(equalTo: primaryMeaningContainer.topAnchor),
            meaningLabel.leadingAnchor.constraint(equalTo: partOfSpeechTag.trailingAnchor, constant: 8),
            meaningLabel.trailingAnchor.constraint(equalTo: primaryMeaningContainer.trailingAnchor),
            meaningLabel.bottomAnchor.constraint(equalTo: primaryMeaningContainer.bottomAnchor)
        ])
        
        contentStack.addArrangedSubview(primaryMeaningContainer)
        
        // 展开提示
        expandHintContainer.addSubview(expandHintIcon)
        expandHintContainer.addSubview(expandHintLabel)
        
        expandHintIcon.translatesAutoresizingMaskIntoConstraints = false
        expandHintLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            expandHintIcon.topAnchor.constraint(equalTo: expandHintContainer.topAnchor),
            expandHintIcon.centerXAnchor.constraint(equalTo: expandHintContainer.centerXAnchor),
            expandHintIcon.widthAnchor.constraint(equalToConstant: 24),
            expandHintIcon.heightAnchor.constraint(equalToConstant: 24),
            
            expandHintLabel.topAnchor.constraint(equalTo: expandHintIcon.bottomAnchor, constant: 8),
            expandHintLabel.leadingAnchor.constraint(equalTo: expandHintContainer.leadingAnchor),
            expandHintLabel.trailingAnchor.constraint(equalTo: expandHintContainer.trailingAnchor),
            expandHintLabel.bottomAnchor.constraint(equalTo: expandHintContainer.bottomAnchor)
        ])
        
        contentStack.addArrangedSubview(expandHintContainer)
        
        // 展开内容
        expandedContentStack.addArrangedSubview(createDivider())
        expandedContentStack.addArrangedSubview(translationsStack)
        expandedContentStack.addArrangedSubview(createDivider())
        expandedContentStack.addArrangedSubview(phrasesTitle)
        expandedContentStack.addArrangedSubview(phrasesStack)
        
        contentStack.addArrangedSubview(expandedContentStack)
        
        NSLayoutConstraint.activate([
            expandedContentStack.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        ])
        
        // 方向指示器
        containerView.addSubview(rightIndicator)
        containerView.addSubview(leftIndicator)
        
        rightIndicator.translatesAutoresizingMaskIntoConstraints = false
        leftIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            rightIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 50),
            rightIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            rightIndicator.widthAnchor.constraint(equalToConstant: 80),
            rightIndicator.heightAnchor.constraint(equalToConstant: 80),
            
            leftIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 50),
            leftIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            leftIndicator.widthAnchor.constraint(equalToConstant: 80),
            leftIndicator.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    private func createDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        guard card != nil else { return }
        
        #if DEBUG
        print("[WordCardUIView] 👆 点击卡片: \(card?.word.word ?? "unknown"), isExpanded: \(isExpanded)")
        #endif
        
        isExpanded.toggle()
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.updateExpandedState()
        }
    }
    
    // MARK: - Content Updates
    
    private func updateContent() {
        guard let card = card else { return }
        
        let word = card.word
        
        // 基本信息
        wordLabel.text = word.word
        phoneticLabel.text = word.phonetic ?? ""
        phoneticLabel.isHidden = word.phonetic == nil
        
        // 主要释义
        if let firstTranslation = word.translations.first {
            partOfSpeechTag.text = " \(firstTranslation.displayPartOfSpeech) "
            meaningLabel.text = firstTranslation.meaning
            primaryMeaningContainer.isHidden = false
        } else {
            primaryMeaningContainer.isHidden = true
        }
        
        // 所有释义
        translationsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for translation in word.translations {
            let row = createTranslationRow(translation: translation)
            translationsStack.addArrangedSubview(row)
        }
        
        // 短语
        phrasesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let phrasesToShow = Array(word.phrases.prefix(3))
        if !phrasesToShow.isEmpty {
            for phrase in phrasesToShow {
                let phraseView = createPhraseView(phrase: phrase)
                phrasesStack.addArrangedSubview(phraseView)
            }
            phrasesTitle.isHidden = false
            phrasesStack.isHidden = false
        } else {
            phrasesTitle.isHidden = true
            phrasesStack.isHidden = true
        }
        
        // 重置展开状态
        isExpanded = false
        updateExpandedState()
    }
    
    private func updateExpandedState() {
        expandHintContainer.isHidden = isExpanded
        expandedContentStack.isHidden = !isExpanded
        
        #if DEBUG
        print("[WordCardUIView] ✅ 展开状态更新: \(isExpanded)")
        #endif
    }
    
    private func createTranslationRow(translation: Word.Translation) -> UIView {
        let container = UIView()
        
        let posLabel = UILabel()
        posLabel.text = " \(translation.displayPartOfSpeech) "
        posLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        posLabel.textColor = .white
        posLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.6)
        posLabel.textAlignment = .center
        posLabel.layer.cornerRadius = 6
        posLabel.layer.masksToBounds = true
        
        let meaningLabel = UILabel()
        meaningLabel.text = translation.meaning
        meaningLabel.font = UIFont.systemFont(ofSize: 16)
        meaningLabel.textColor = .label
        meaningLabel.numberOfLines = 0
        
        container.addSubview(posLabel)
        container.addSubview(meaningLabel)
        
        posLabel.translatesAutoresizingMaskIntoConstraints = false
        meaningLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            posLabel.topAnchor.constraint(equalTo: container.topAnchor),
            posLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            posLabel.heightAnchor.constraint(equalToConstant: 24),
            posLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            meaningLabel.topAnchor.constraint(equalTo: container.topAnchor),
            meaningLabel.leadingAnchor.constraint(equalTo: posLabel.trailingAnchor, constant: 12),
            meaningLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            meaningLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func createPhraseView(phrase: Word.Phrase) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemGray.withAlphaComponent(0.1)
        container.layer.cornerRadius = 10
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        
        let englishLabel = UILabel()
        englishLabel.text = phrase.english
        englishLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        englishLabel.textColor = .label
        englishLabel.numberOfLines = 0
        
        let chineseLabel = UILabel()
        chineseLabel.text = phrase.chinese
        chineseLabel.font = UIFont.systemFont(ofSize: 14)
        chineseLabel.textColor = .secondaryLabel
        chineseLabel.numberOfLines = 0
        
        stack.addArrangedSubview(englishLabel)
        stack.addArrangedSubview(chineseLabel)
        
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        
        return container
    }
    
    // MARK: - Direction Indicators
    
    func updateDirectionIndicator(offset: CGFloat) {
        let threshold: CGFloat = 30
        let maxOpacity: CGFloat = 1.0
        let maxOffset: CGFloat = 120
        
        if offset > threshold {
            let progress = min((offset - threshold) / maxOffset, maxOpacity)
            rightIndicator.alpha = progress
            leftIndicator.alpha = 0
        } else if offset < -threshold {
            let progress = min((abs(offset) - threshold) / maxOffset, maxOpacity)
            leftIndicator.alpha = progress
            rightIndicator.alpha = 0
        } else {
            rightIndicator.alpha = 0
            leftIndicator.alpha = 0
        }
    }
}

