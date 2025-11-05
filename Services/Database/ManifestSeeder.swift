//
//  ManifestSeeder.swift
//  NFwordsDemo
//
//  Loads packs/manifest.json and seeds local SQLite tables.
//

import Foundation

struct PacksManifest: Codable {
    let generatedAt: String?
    let packCount: Int?
    let packs: [PackManifestEntry]
}

final class ManifestSeeder {
    static func seedIfNeeded(manifestURL: URL? = nil) throws {
        let dbManager = DatabaseManager.shared
        let currentCount = try dbManager.localPacksCount()
        guard currentCount == 0 else { return }

        let manifestURL = try manifestURL ?? defaultManifestURL()
        let manifestDir = manifestURL.deletingLastPathComponent()
        let manifestData = try Data(contentsOf: manifestURL)
        let decoder = JSONDecoder()
        let manifest = try decoder.decode(PacksManifest.self, from: manifestData)

        for entry in manifest.packs {
            let entries = try loadEntriesIfAvailable(for: entry, baseURL: manifestDir, decoder: decoder)
            try dbManager.upsertManifestCache(from: entry)
            try dbManager.upsertLocalPack(from: entry, entries: entries)
        }
    }

    private static func defaultManifestURL() throws -> URL {
        #if DEBUG
        print("🔍 [ManifestSeeder] 尝试查找 manifest.json...")
        #endif
        
        // 方式1: Bundle 根目录直接查找（适用于文件被平铺的情况）
        if let bundled = Bundle.main.url(forResource: "manifest", withExtension: "json") {
            #if DEBUG
            print("✅ 找到 Bundle 根目录路径: \(bundled.path)")
            #endif
            return bundled
        }
        
        // 方式2: Bundle.main.url(forResource:withExtension:subdirectory:)
        if let bundled = Bundle.main.url(forResource: "manifest", withExtension: "json", subdirectory: "packs") {
            #if DEBUG
            print("✅ 找到 Bundle packs 子目录路径: \(bundled.path)")
            #endif
            return bundled
        }
        
        // 方式3: Bundle.main.path(forResource:ofType:inDirectory:) 转 URL
        if let bundledPath = Bundle.main.path(forResource: "manifest", ofType: "json", inDirectory: "packs") {
            let url = URL(fileURLWithPath: bundledPath)
            #if DEBUG
            print("✅ 找到 Bundle 路径（方式3）: \(url.path)")
            #endif
            return url
        }
        
        // 方式4: Bundle.main.resourceURL + manifest.json
        if let resourceURL = Bundle.main.resourceURL {
            let candidate = resourceURL.appendingPathComponent("manifest.json")
            if FileManager.default.fileExists(atPath: candidate.path) {
                #if DEBUG
                print("✅ 找到 Bundle resourceURL 根目录路径: \(candidate.path)")
                #endif
                return candidate
            }
        }
        
        // 方式5: Documents 目录
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let candidate = documents.appendingPathComponent("packs/manifest.json")
        if FileManager.default.fileExists(atPath: candidate.path) {
            #if DEBUG
            print("✅ 找到 Documents 路径: \(candidate.path)")
            #endif
            return candidate
        }

        #if DEBUG
        // 调试：列出 Bundle.main.resourceURL 下所有内容
        if let resourceURL = Bundle.main.resourceURL {
            print("❌ 未找到 manifest.json，Bundle.main.resourceURL 内容:")
            if let contents = try? FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil) {
                contents.prefix(20).forEach { print("  - \($0.lastPathComponent)") }
            }
        }
        #endif

        throw NSError(domain: "ManifestSeeder",
                      code: 404,
                      userInfo: [NSLocalizedDescriptionKey: "manifest.json 未找到，请确认已添加到 Bundle 或 Documents 目录"])
    }

    private static func loadEntriesIfAvailable(for entry: PackManifestEntry, baseURL: URL, decoder: JSONDecoder) throws -> [Int]? {
        let fileName = entry.entriesFile
        let fileNameWithoutExt = (fileName as NSString).deletingPathExtension
        let fileExt = (fileName as NSString).pathExtension
        
        #if DEBUG
        print("🔍 查找 entries 文件: \(fileName)")
        #endif
        
        // 尝试多个位置查找文件
        var candidateURLs: [URL] = []
        
        // 方式1: baseURL + fileName（如果 manifest 和 pack 文件在同一目录）
        candidateURLs.append(baseURL.appendingPathComponent(fileName))
        
        // 方式2: baseURL + "packs/" + fileName
        candidateURLs.append(baseURL.appendingPathComponent("packs").appendingPathComponent(fileName))
        
        // 方式3: Bundle.main.url(forResource:withExtension:)（Bundle 根目录）
        if let bundleURL = Bundle.main.url(forResource: fileNameWithoutExt, withExtension: fileExt) {
            candidateURLs.append(bundleURL)
        }
        
        // 方式4: Bundle.main.url(forResource:withExtension:subdirectory:)（packs 子目录）
        if let bundleURL = Bundle.main.url(forResource: fileNameWithoutExt, withExtension: fileExt, subdirectory: "packs") {
            candidateURLs.append(bundleURL)
        }
        
        // 方式5: Bundle.main.path(forResource:ofType:inDirectory:)
        if let bundlePath = Bundle.main.path(forResource: fileNameWithoutExt, ofType: fileExt, inDirectory: "packs") {
            candidateURLs.append(URL(fileURLWithPath: bundlePath))
        }
        
        // 方式6: Bundle.main.resourceURL + fileName
        if let resourceURL = Bundle.main.resourceURL {
            candidateURLs.append(resourceURL.appendingPathComponent(fileName))
            candidateURLs.append(resourceURL.appendingPathComponent("packs").appendingPathComponent(fileName))
        }
        
        // 尝试每个候选路径
        for candidateURL in candidateURLs {
            if FileManager.default.fileExists(atPath: candidateURL.path) {
                #if DEBUG
                print("✅ 找到 entries 文件: \(candidateURL.path)")
                #endif
                
                do {
                    let data = try Data(contentsOf: candidateURL)
                    let detail = try decoder.decode(PackDetail.self, from: data)
                    
                    guard detail.pid == entry.pid else {
                        #if DEBUG
                        print("⚠️ pid mismatch: expected \(entry.pid) got \(detail.pid)")
                        #endif
                        return detail.entries
                    }
                    
                    #if DEBUG
                    print("✅ 成功加载 \(detail.entries.count) 个 entries")
                    #endif
                    
                    return detail.entries
                } catch {
                    #if DEBUG
                    print("⚠️ 解析失败: \(error.localizedDescription)")
                    #endif
                    continue
                }
            }
        }
        
        #if DEBUG
        print("❌ entries 文件未找到: \(fileName)")
        print("   尝试的路径:")
        for url in candidateURLs.prefix(5) {
            print("   - \(url.path)")
        }
        #endif
        
        return nil
    }
}

// MARK: - Pack detail DTO

private struct PackDetail: Codable {
    let pid: Int
    let title: String?
    let version: String?
    let wordsCount: Int?
    let hash: String?
    let entries: [Int]
    let missingWords: [String]?

    enum CodingKeys: String, CodingKey {
        case pid
        case title
        case version
        case wordsCount = "words_count"
        case hash
        case entries
        case missingWords = "missing_words"
    }
}

