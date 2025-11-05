//
//  WordJSONLDataSource.swift
//  NFwordsDemo
//
//  JSONL词汇数据读取器（用于 output_jsonl_phrases/*.jsonl）
//  Created by 虚拟助手 on 2025/11/4.
//

import Foundation

// MARK: - JSONL 单词原始结构
struct WordJSONLRecord: Decodable {
    let wid: Int
    let w: String
    let tr: [[String]]
    let ph: String?
    let phr: [[String]]
    
    var translations: [WordTranslationRecord] {
        tr.compactMap { entry in
            guard let meaning = entry.last else { return nil }
            let pos = entry.first ?? ""
            return WordTranslationRecord(partOfSpeech: pos, meaning: meaning)
        }
    }
    
    var phrases: [WordPhraseRecord] {
        phr.compactMap { entry in
            guard entry.count >= 2 else { return nil }
            return WordPhraseRecord(english: entry[0], chinese: entry[1])
        }
    }
}

// MARK: - JSONL 数据源
final class WordJSONLDataSource {
    static let shared = WordJSONLDataSource()
    
    private let fileNames: [String]
    private let subdirectory = "output_jsonl_phrases"
    private let decoder = JSONDecoder()
    
    private init() {
        // 默认按 README 中给出的 8 个切片文件命名
        fileNames = (1...8).map { String(format: "words-%04d", $0) }
    }
    
    func loadRecords(limit: Int? = nil) throws -> [WordJSONLRecord] {
        #if DEBUG
        print("[JSONL] loadRecords called, limit: \(limit?.description ?? "unlimited")")
        #endif
        
        var records: [WordJSONLRecord] = []
        var remaining = limit
        var filesChecked = 0
        var filesLoaded = 0
        
        for name in fileNames {
            filesChecked += 1
            
            guard let url = locateResource(named: name) else {
                #if DEBUG
                print("[JSONL] File not found: \(name).jsonl (checked \(filesChecked)/\(fileNames.count))")
                #endif
                continue
            }
            
            #if DEBUG
            print("[JSONL] Loading: \(name).jsonl from \(url.path)")
            #endif
            
            let fileRecords = try parseFile(at: url, limit: remaining)
            records.append(contentsOf: fileRecords)
            filesLoaded += 1
            
            #if DEBUG
            print("[JSONL] Loaded \(fileRecords.count) records from \(name).jsonl (total: \(records.count))")
            #endif
            
            if let currentLimit = remaining {
                remaining = max(currentLimit - fileRecords.count, 0)
                if remaining == 0 { break }
            }
        }
        
        #if DEBUG
        print("[JSONL] Summary: checked \(filesChecked) files, loaded \(filesLoaded) files, total records: \(records.count)")
        if records.isEmpty {
            print("[JSONL] ERROR: No records loaded! Check if output_jsonl_phrases folder is in Bundle")
        }
        #endif
        
        return records
    }
    
    func loadRecord(byWordId wid: Int) throws -> WordJSONLRecord? {
        for name in fileNames {
            guard let url = locateResource(named: name) else { continue }
            let data = try Data(contentsOf: url)
            guard let content = String(data: data, encoding: .utf8) else { continue }
            for line in content.split(whereSeparator: \ .isNewline) {
                guard let lineData = line.data(using: .utf8) else { continue }
                let record = try decoder.decode(WordJSONLRecord.self, from: lineData)
                if record.wid == wid { return record }
            }
        }
        return nil
    }
    
    // MARK: - Helpers
    private func parseFile(at url: URL, limit: Int?) throws -> [WordJSONLRecord] {
        var parsed: [WordJSONLRecord] = []
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else { return parsed }
        
        for line in content.split(whereSeparator: \.isNewline) {
            guard let data = line.data(using: .utf8) else { continue }
            let record = try decoder.decode(WordJSONLRecord.self, from: data)
            parsed.append(record)
            if let limit, parsed.count >= limit { break }
        }
        
        return parsed
    }
    
    private func locateResource(named name: String) -> URL? {
        let fileName = "\(name).jsonl"
        
        // 方式1: Bundle.main.url(forResource:withExtension:) - Bundle 根目录（最优先，打包后文件被平铺）
        if let bundleURL = Bundle.main.url(forResource: name, withExtension: "jsonl") {
            #if DEBUG
            print("[JSONL] Found in Bundle root: \(bundleURL.path)")
            #endif
            return bundleURL
        }
        
        // 方式2: Bundle.main.url(forResource:withExtension:subdirectory:) - 子目录
        if let bundleURL = Bundle.main.url(forResource: name, withExtension: "jsonl", subdirectory: subdirectory) {
            #if DEBUG
            print("[JSONL] Found in subdirectory \(subdirectory): \(bundleURL.path)")
            #endif
            return bundleURL
        }
        
        // 方式3: Bundle.main.path(forResource:ofType:) - Bundle 根目录（备选）
        if let bundlePath = Bundle.main.path(forResource: name, ofType: "jsonl") {
            #if DEBUG
            print("[JSONL] Found via path (root): \(bundlePath)")
            #endif
            return URL(fileURLWithPath: bundlePath)
        }
        
        // 方式4: Bundle.main.path(forResource:ofType:inDirectory:) - 子目录（备选）
        if let bundlePath = Bundle.main.path(forResource: name, ofType: "jsonl", inDirectory: subdirectory) {
            #if DEBUG
            print("[JSONL] Found via path (subdir): \(bundlePath)")
            #endif
            return URL(fileURLWithPath: bundlePath)
        }
        
        // 方式5: Bundle.main.resourceURL - Bundle 根目录
        if let resourceRoot = Bundle.main.resourceURL {
            let candidate = resourceRoot.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: candidate.path) {
                #if DEBUG
                print("[JSONL] Found in resourceURL root: \(candidate.path)")
                #endif
                return candidate
            }
        }
        
        // 方式6: Bundle.main.resourceURL + subdirectory - 子目录
        if let resourceRoot = Bundle.main.resourceURL?.appendingPathComponent(subdirectory) {
            let candidate = resourceRoot.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: candidate.path) {
                #if DEBUG
                print("[JSONL] Found in resourceURL subdir: \(candidate.path)")
                #endif
                return candidate
            }
        }
        
        // 方式7: 开发环境 fallback - 相对工程根目录
        let projectRelativePath = "\(subdirectory)/\(fileName)"
        let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let relativeURL = currentDirectoryURL.appendingPathComponent(projectRelativePath)
        if FileManager.default.fileExists(atPath: relativeURL.path) {
            #if DEBUG
            print("[JSONL] Found in project directory: \(relativeURL.path)")
            #endif
            return relativeURL
        }
        
        #if DEBUG
        print("[JSONL] Not found anywhere: \(fileName)")
        #endif
        
        return nil
    }
}


