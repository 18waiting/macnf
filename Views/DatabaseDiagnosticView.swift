//
//  DatabaseDiagnosticView.swift
//  NFwordsDemo
//
//  数据库诊断工具 - 检查数据完整性
//  Created by AI Assistant on 2025/11/5.
//

import SwiftUI

struct DatabaseDiagnosticView: View {
    @State private var diagnosticResult: String = "点击按钮开始诊断..."
    @State private var isRunning = false
    @State private var showBundleCheck = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 说明
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("此工具用于诊断学习功能问题")
                                .font(.headline)
                            Text("如果你无法看到单词或无法开始学习，请运行诊断。")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 诊断结果
                    GroupBox("诊断结果") {
                        Text(diagnosticResult)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // 操作按钮
                    VStack(spacing: 12) {
                        Button(action: runDiagnostic) {
                            HStack {
                                if isRunning {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "stethoscope")
                                }
                                Text(isRunning ? "诊断中..." : "开始诊断")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(isRunning)
                        
                        Button(action: { showBundleCheck = true }) {
                            HStack {
                                Image(systemName: "doc.text.magnifyingglass")
                                Text("检查 Bundle 资源")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                        }
                        .disabled(isRunning)
                        
                        Button(action: fixDatabase) {
                            HStack {
                                Image(systemName: "wrench.and.screwdriver")
                                Text("修复数据库")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                        }
                        .disabled(isRunning)
                    }
                }
                .padding()
            }
            .navigationTitle("数据库诊断")
            .sheet(isPresented: $showBundleCheck) {
                BundleResourcesView()
            }
        }
    }
    
    private func runDiagnostic() {
        isRunning = true
        diagnosticResult = "正在诊断...\n\n"
        
        Task {
            var result = ""
            
            // 1. 检查词书
            do {
                let packStorage = LocalPackStorage()
                let packs = try packStorage.fetchAll()
                result += "✅ 词书数量: \(packs.count)\n"
                for pack in packs {
                    result += "   - \(pack.title): \(pack.totalCount)词, entries=\(pack.entries.count)\n"
                    if pack.entries.isEmpty {
                        result += "      ⚠️ 警告: entries 为空！\n"
                    }
                }
            } catch {
                result += "❌ 词书检查失败: \(error.localizedDescription)\n"
            }
            
            result += "\n"
            
            // 2. 检查学习目标
            do {
                let goalStorage = LearningGoalStorage()
                let goals = try goalStorage.fetchAll()
                result += "✅ 学习目标数量: \(goals.count)\n"
                for goal in goals {
                    result += "   - \(goal.packName): 第\(goal.currentDay)天, 状态=\(goal.status)\n"
                }
                if goals.isEmpty {
                    result += "   ⚠️ 警告: 没有学习目标！\n"
                }
            } catch {
                result += "❌ 学习目标检查失败: \(error.localizedDescription)\n"
            }
            
            result += "\n"
            
            // 3. 检查今日任务
            do {
                let taskStorage = DailyTaskStorage()
                let tasks = try taskStorage.fetchAll()
                result += "✅ 任务数量: \(tasks.count)\n"
                for task in tasks {
                    result += "   - 第\(task.day)天: \(task.newWords.count)新词, 状态=\(task.status)\n"
                    if task.newWords.isEmpty {
                        result += "      ⚠️ 警告: newWords 为空！\n"
                    }
                }
                if tasks.isEmpty {
                    result += "   ⚠️ 警告: 没有任务！\n"
                }
            } catch {
                result += "❌ 任务检查失败: \(error.localizedDescription)\n"
            }
            
            result += "\n"
            
            // 4. 检查单词缓存
            do {
                let cacheStorage = WordCacheStorage()
                let caches = try cacheStorage.fetchAll()
                result += "✅ 单词缓存数量: \(caches.count)\n"
                if caches.isEmpty {
                    result += "   ⚠️ 警告: 单词缓存为空！\n"
                }
            } catch {
                result += "❌ 单词缓存检查失败: \(error.localizedDescription)\n"
            }
            
            result += "\n"
            
            // 5. 检查 WordRepository
            result += "🔍 检查 WordRepository...\n"
            do {
                let (cards, records) = try WordRepository.shared.fetchStudyCards(limit: 10)
                result += "✅ WordRepository 可正常获取单词\n"
                result += "   - 获取到 \(cards.count) 张卡片\n"
                result += "   - 获取到 \(records.count) 条记录\n"
            } catch {
                result += "❌ WordRepository 获取失败: \(error.localizedDescription)\n"
            }
            
            result += "\n"
            
            // 6. 检查 Bundle 资源
            result += "🔍 检查 Bundle 资源...\n"
            if let manifestURL = Bundle.main.url(forResource: "manifest", withExtension: "json") {
                result += "✅ manifest.json 在 Bundle 中: \(manifestURL.path)\n"
            } else {
                result += "❌ manifest.json 不在 Bundle 中\n"
            }
            
            if let pack1URL = Bundle.main.url(forResource: "pack_cet4_manifest", withExtension: "json") {
                result += "✅ pack_cet4_manifest.json 在 Bundle 中\n"
            } else {
                result += "❌ pack_cet4_manifest.json 不在 Bundle 中\n"
            }
            
            result += "\n=== 诊断完成 ==="
            
            await MainActor.run {
                diagnosticResult = result
                isRunning = false
            }
        }
    }
    
    private func fixDatabase() {
        isRunning = true
        diagnosticResult = "正在修复数据库...\n\n"
        
        Task {
            var result = ""
            
            do {
                // 1. 重置并重新播种
                result += "🔧 重置数据库...\n"
                try DatabaseResetService.shared.resetAndReseed()
                result += "✅ 重置完成\n\n"
                
                // 2. 检查词书 entries
                let packStorage = LocalPackStorage()
                let packs = try packStorage.fetchAll()
                
                result += "🔧 检查词书 entries...\n"
                for pack in packs {
                    if pack.entries.isEmpty {
                        result += "⚠️ \(pack.title) 的 entries 为空，尝试修复...\n"
                        
                        // 尝试从 WordRepository 生成一个临时的 entries
                        let tempEntries = generateTempEntries(packId: pack.packId, count: min(pack.totalCount, 3000))
                        
                        var fixedPack = pack
                        fixedPack.entries = tempEntries
                        try packStorage.upsert(fixedPack)
                        
                        result += "✅ 已为 \(pack.title) 生成 \(tempEntries.count) 个临时 entries\n"
                    } else {
                        result += "✅ \(pack.title) entries 正常 (\(pack.entries.count))\n"
                    }
                }
                
                result += "\n=== 修复完成 ===\n"
                result += "请返回学习页面重试"
                
            } catch {
                result += "❌ 修复失败: \(error.localizedDescription)\n"
            }
            
            await MainActor.run {
                diagnosticResult = result
                isRunning = false
            }
        }
    }
    
    /// 生成临时的 entries（从 WordRepository 的缓存中获取）
    private func generateTempEntries(packId: Int, count: Int) -> [Int] {
        let cacheRecords = WordRepository.shared.exportCacheRecords()
        let wids = Array(cacheRecords.keys.sorted().prefix(count))
        return wids
    }
}

// MARK: - 预览
struct DatabaseDiagnosticView_Previews: PreviewProvider {
    static var previews: some View {
        DatabaseDiagnosticView()
    }
}

