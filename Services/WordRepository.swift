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
            learningRecords[word.id] = record
            let exposuresToSchedule = max(record.remainingExposures, 1)
            for _ in 0..<exposuresToSchedule {
                cards.append(StudyCard(word: word, record: record))
            }
        }
        
        cards.shuffle()
        
        #if DEBUG
        print("[Repository] Generated \(cards.count) cards, \(learningRecords.count) learning records")
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


