//
//  BundleResourcesView.swift
//  NFwordsDemo
//
//  Bundle 资源检查工具 - 查看文件位置
//  Created by AI Assistant on 2025/11/5.
//

import SwiftUI

struct BundleResourcesView: View {
    @State private var bundleInfo: String = "点击按钮检查 Bundle 资源..."
    @State private var isChecking = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 说明
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bundle 资源检查")
                                .font(.headline)
                            Text("查看 pack_*.json 文件是否正确加入到 Bundle，以及它们的实际路径。")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 检查结果
                    GroupBox("检查结果") {
                        Text(bundleInfo)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // 操作按钮
                    Button(action: checkBundleResources) {
                        HStack {
                            if isChecking {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "doc.text.magnifyingglass")
                            }
                            Text(isChecking ? "检查中..." : "检查 Bundle 资源")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isChecking)
                }
                .padding()
            }
            .navigationTitle("Bundle 资源")
        }
    }
    
    private func checkBundleResources() {
        isChecking = true
        
        Task {
            var info = "=== Bundle 资源检查 ===\n\n"
            
            // 1. Bundle 基本信息
            info += "📦 Bundle 信息:\n"
            info += "   路径: \(Bundle.main.bundlePath)\n"
            if let resourcePath = Bundle.main.resourcePath {
                info += "   资源路径: \(resourcePath)\n"
            }
            if let resourceURL = Bundle.main.resourceURL {
                info += "   资源URL: \(resourceURL.path)\n"
            }
            info += "\n"
            
            // 2. 检查 manifest.json
            info += "🔍 查找 manifest.json:\n"
            let manifestFound = checkFileInBundle(fileName: "manifest", ext: "json", info: &info)
            info += "\n"
            
            // 3. 检查所有 pack_*.json 文件
            let packFiles = [
                "pack_cet4_manifest",
                "pack_cet6_manifest",
                "pack_ielts_manifest",
                "pack_p8_manifest"
            ]
            
            info += "🔍 查找 pack_*.json 文件:\n"
            for packFile in packFiles {
                _ = checkFileInBundle(fileName: packFile, ext: "json", info: &info)
            }
            info += "\n"
            
            // 4. 列出 Bundle 根目录下所有 JSON 文件
            info += "📂 Bundle 根目录下的 JSON 文件:\n"
            if let resourceURL = Bundle.main.resourceURL {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(
                        at: resourceURL,
                        includingPropertiesForKeys: nil
                    )
                    let jsonFiles = contents.filter { $0.pathExtension == "json" }
                    if jsonFiles.isEmpty {
                        info += "   （无 JSON 文件）\n"
                    } else {
                        for file in jsonFiles.prefix(20) {
                            info += "   ✅ \(file.lastPathComponent)\n"
                        }
                    }
                } catch {
                    info += "   ❌ 无法读取: \(error.localizedDescription)\n"
                }
            }
            info += "\n"
            
            // 5. 检查 packs 子目录
            info += "📂 packs/ 子目录:\n"
            if let resourceURL = Bundle.main.resourceURL {
                let packsURL = resourceURL.appendingPathComponent("packs")
                if FileManager.default.fileExists(atPath: packsURL.path) {
                    info += "   ✅ packs/ 目录存在\n"
                    do {
                        let contents = try FileManager.default.contentsOfDirectory(
                            at: packsURL,
                            includingPropertiesForKeys: nil
                        )
                        info += "   文件数量: \(contents.count)\n"
                        for file in contents.prefix(20) {
                            info += "   - \(file.lastPathComponent)\n"
                        }
                    } catch {
                        info += "   ⚠️ 无法读取: \(error.localizedDescription)\n"
                    }
                } else {
                    info += "   ❌ packs/ 目录不存在\n"
                }
            }
            info += "\n"
            
            // 6. 总结
            info += "=== 检查完成 ===\n"
            if !manifestFound {
                info += "\n⚠️ manifest.json 未找到！\n"
                info += "请确保在 Xcode 中添加文件时勾选了：\n"
                info += "- Copy items if needed\n"
                info += "- Add to targets: NFwordsDemo\n"
            }
            
            await MainActor.run {
                bundleInfo = info
                isChecking = false
            }
        }
    }
    
    @discardableResult
    private func checkFileInBundle(fileName: String, ext: String, info: inout String) -> Bool {
        var found = false
        
        // 方式1: Bundle.main.url(forResource:withExtension:)
        if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
            info += "   ✅ 方式1: \(url.path)\n"
            found = true
        }
        
        // 方式2: Bundle.main.url(forResource:withExtension:subdirectory:)
        if let url = Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: "packs") {
            info += "   ✅ 方式2 (packs/): \(url.path)\n"
            found = true
        }
        
        // 方式3: Bundle.main.path(forResource:ofType:)
        if let path = Bundle.main.path(forResource: fileName, ofType: ext) {
            info += "   ✅ 方式3: \(path)\n"
            found = true
        }
        
        // 方式4: Bundle.main.path(forResource:ofType:inDirectory:)
        if let path = Bundle.main.path(forResource: fileName, ofType: ext, inDirectory: "packs") {
            info += "   ✅ 方式4 (packs/): \(path)\n"
            found = true
        }
        
        if !found {
            info += "   ❌ 未找到 \(fileName).\(ext)\n"
        }
        
        return found
    }
}

// MARK: - 预览
struct BundleResourcesView_Previews: PreviewProvider {
    static var previews: some View {
        BundleResourcesView()
    }
}

