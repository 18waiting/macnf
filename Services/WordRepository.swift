//
//  WordRepository.swift
//  NFwordsDemo
//
//  将 JSONL 数据、缓存表、学习记录串联的仓库层
//  Created by 虚拟助手 on 2025/11/4.
//

import Foundation

final class WordRepository {
    static let shared = WordRepository()
    
    private let dataSource = WordJSONLDataSource.shared
    private var wordCache: [Int: Word] = [:]
    private var cacheRecords: [Int: WordCacheRecord] = [:]
    private var allWordIds: [Int] = []
    private let lock = NSLock()
    
    private init() {}
    
    // MARK: - Public API
    func preloadIfNeeded(limit: Int? = nil) throws {
        if !wordCache.isEmpty { return }
        try loadWordsIntoCache(limit: limit)
    }
    
    func fetchWords(limit: Int) throws -> [Word] {
        try preloadIfNeeded(limit: limit)
        lock.lock(); defer { lock.unlock() }
        let slice = allWordIds.prefix(limit)
        let now = Date()
        for wid in slice {
            if var record = cacheRecords[wid] {
                record.accessCount += 1
                record.lastAccessedAt = now
                cacheRecords[wid] = record
            }
        }
        return slice.compactMap { wordCache[$0] }
    }
    
    /// ⭐ 修复：根据单词ID列表获取单词
    func fetchWordsByIds(_ wordIds: [Int]) throws -> [Word] {
        try preloadIfNeeded(limit: nil)  // 预加载所有单词
        lock.lock(); defer { lock.unlock() }
        let now = Date()
        var words: [Word] = []
        var missingIds: [Int] = []
        
        for wid in wordIds {
            if let word = wordCache[wid] {
                words.append(word)
                // 更新访问记录
                if var record = cacheRecords[wid] {
                    record.accessCount += 1
                    record.lastAccessedAt = now
                    cacheRecords[wid] = record
                }
            } else {
                missingIds.append(wid)
            }
        }
        
        #if DEBUG
        if !missingIds.isEmpty {
            print("[Repository] ⚠️ 警告：\(missingIds.count) 个单词ID未找到: \(missingIds.prefix(10))")
        }
        #endif
        
        return words
    }
    
    func fetchStudyCards(limit: Int, exposuresPerWord: Int = 10) throws -> ([StudyCard], [Int: WordLearningRecord]) {
        #if DEBUG
        print("[Repository] fetchStudyCards: limit=\(limit), exposuresPerWord=\(exposuresPerWord)")
        #endif
        
        let words = try fetchWords(limit: limit)
        
        #if DEBUG
        print("[Repository] Got \(words.count) words")
        if words.isEmpty {
            print("[Repository] ERROR: Word list is empty")
        } else {
            print("[Repository] Sample words: \(words.prefix(3).map { $0.word }.joined(separator: ", "))")
        }
        #endif
        
        var learningRecords: [Int: WordLearningRecord] = [:]
        var cards: [StudyCard] = []
        
        for word in words {
            var record = WordLearningRecord.initial(wid: word.id, targetExposures: exposuresPerWord)
            if let cached = cacheRecords[word.id] {
                record.totalExposureCount = cached.accessCount
                record.remainingExposures = max(exposuresPerWord - cached.accessCount, 0)
            }
            
            // ⭐ P2 修复：先保存到 learningRecords，确保数据一致性
            // 这样即使创建多个卡片，它们都引用同一个 learningRecords 字典中的数据
            learningRecords[word.id] = record
            
            // ⭐ P1 修复：只有当 remainingExposures > 0 时才创建卡片
            let exposuresToSchedule = max(record.remainingExposures, 0)
            if exposuresToSchedule > 0 {
                // ⭐ P0 修复：移除 record 参数，StudyCard 不再包含 record 字段
                // ⭐ P2 修复：所有卡片都通过 word.id 从 learningRecords 获取数据，确保一致性
                for _ in 0..<exposuresToSchedule {
                    cards.append(StudyCard(word: word))
                }
                
                #if DEBUG
                // 验证：确保创建的卡片数量与计划一致
                let createdCards = cards.filter { $0.word.id == word.id }.count
                if createdCards != exposuresToSchedule {
                    print("[Repository] ⚠️ 警告：单词 \(word.word) (id: \(word.id)) 创建的卡片数量不匹配！计划: \(exposuresToSchedule), 实际: \(createdCards)")
                }
                #endif
            }
        }
        
        cards.shuffle()
        
        #if DEBUG
        print("[Repository] Generated \(cards.count) cards, \(learningRecords.count) learning records")
        #endif
        
        return (cards, learningRecords)
    }
    
    /// ⭐ 修复：根据任务中的单词ID列表获取学习卡片
    /// - Parameters:
    ///   - newWordIds: 新词ID列表（通常需要更多曝光次数）
    ///   - reviewWordIds: 复习词ID列表（通常需要较少曝光次数）
    ///   - newWordExposures: 新词的曝光次数（默认10）
    ///   - reviewWordExposures: 复习词的曝光次数（默认5）
    func fetchStudyCardsForTask(
        newWordIds: [Int],
        reviewWordIds: [Int],
        newWordExposures: Int = 10,
        reviewWordExposures: Int = 5
    ) throws -> ([StudyCard], [Int: WordLearningRecord]) {
        #if DEBUG
        print("[Repository] fetchStudyCardsForTask: newWords=\(newWordIds.count), reviewWords=\(reviewWordIds.count)")
        #endif
        
        // 获取所有单词
        let allWordIds = newWordIds + reviewWordIds
        let words = try fetchWordsByIds(allWordIds)
        
        #if DEBUG
        print("[Repository] Got \(words.count) words from IDs (requested \(allWordIds.count))")
        if words.count != allWordIds.count {
            print("[Repository] ⚠️ 警告：部分单词ID未找到，可能数据不完整")
        }
        #endif
        
        var learningRecords: [Int: WordLearningRecord] = [:]
        var cards: [StudyCard] = []
        
        // 创建新词的卡片
        let newWordIdSet = Set(newWordIds)
        for word in words {
            let isNewWord = newWordIdSet.contains(word.id)
            let exposuresPerWord = isNewWord ? newWordExposures : reviewWordExposures
            
            var record = WordLearningRecord.initial(wid: word.id, targetExposures: exposuresPerWord)
            if let cached = cacheRecords[word.id] {
                record.totalExposureCount = cached.accessCount
                record.remainingExposures = max(exposuresPerWord - cached.accessCount, 0)
            }
            
            learningRecords[word.id] = record
            
            // ⭐ P1 修复：只有当 remainingExposures > 0 时才创建卡片
            let exposuresToSchedule = max(record.remainingExposures, 0)
            if exposuresToSchedule > 0 {
                for _ in 0..<exposuresToSchedule {
                    cards.append(StudyCard(word: word))
                }
            }
        }
        
        cards.shuffle()
        
        #if DEBUG
        print("[Repository] Generated \(cards.count) cards from task (new: \(newWordIds.count), review: \(reviewWordIds.count))")
        #endif
        
        return (cards, learningRecords)
    }
    
    func cacheRecord(for wid: Int) -> WordCacheRecord? {
        lock.lock(); defer { lock.unlock() }
        return cacheRecords[wid]
    }
    
    func exportCacheRecords() -> [Int: WordCacheRecord] {
        lock.lock(); defer { lock.unlock() }
        return cacheRecords
    }
    
    // MARK: - Internal Loading
    private func loadWordsIntoCache(limit: Int?) throws {
        #if DEBUG
        print("[Repository] loadWordsIntoCache: limit=\(limit ?? -1)")
        #endif
        
        lock.lock(); defer { lock.unlock() }
        let records = try dataSource.loadRecords(limit: limit)
        
        #if DEBUG
        print("[Repository] Loaded \(records.count) records from JSONL")
        if records.isEmpty {
            print("[Repository] ERROR: No JSONL records loaded")
        }
        #endif
        
        let now = Date()
        wordCache.removeAll(keepingCapacity: true)
        cacheRecords.removeAll(keepingCapacity: true)
        allWordIds.removeAll(keepingCapacity: true)
        
        for record in records {
            let word = Word(record: record)
            wordCache[word.id] = word
            allWordIds.append(word.id)
            cacheRecords[word.id] = WordCacheRecord(
                wid: word.id,
                word: word.word,
                phonetic: word.phonetic,
                translations: record.translations,
                phrases: record.phrases,
                frequency: nil,
                lastAccessedAt: now,
                accessCount: 0,
                cachedAt: now
            )
        }
        
        #if DEBUG
        print("[Repository] Cache updated: \(wordCache.count) words")
        if !wordCache.isEmpty {
            let sampleWords = Array(wordCache.values.prefix(3)).map { $0.word }
            print("[Repository] Sample: \(sampleWords.joined(separator: ", "))")
        }
        #endif
    }
}


