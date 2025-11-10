#!/bin/bash

# Koloda 源码下载脚本
# 使用方法：在终端运行 ./download_koloda.sh

echo "📦 开始下载 Koloda 源码..."

# 项目根目录
PROJECT_DIR="/Users/jefferygan/xcode4ios/NFwordsDemo/NFwordsDemo"
KOLODA_DIR="$PROJECT_DIR/Koloda"

# 创建 Koloda 目录
mkdir -p "$KOLODA_DIR"

# 临时目录
TEMP_DIR="/tmp/koloda_download"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

cd "$TEMP_DIR"

echo "📥 正在从 GitHub 克隆 Koloda..."
git clone --depth 1 https://github.com/Yalantis/Koloda.git

if [ $? -ne 0 ]; then
    echo "❌ Git 克隆失败，尝试下载 ZIP..."
    curl -L -o koloda.zip https://github.com/Yalantis/Koloda/archive/refs/heads/master.zip
    unzip -q koloda.zip
    SOURCE_DIR="Koloda-master"
else
    SOURCE_DIR="Koloda"
fi

# 复制源码文件
echo "📋 复制源码文件到项目..."
cp -r "$SOURCE_DIR/Koloda/"*.swift "$KOLODA_DIR/"

# 清理临时文件
rm -rf "$TEMP_DIR"

echo "✅ Koloda 源码已下载到: $KOLODA_DIR"
echo ""
echo "📝 下一步："
echo "1. 在 Xcode 中，右键点击项目根目录"
echo "2. 选择 'Add Files to NFwordsDemo...'"
echo "3. 选择 $KOLODA_DIR 目录中的所有 .swift 文件"
echo "4. 确保勾选 'Create groups' 和正确的 Target"
echo "5. 编译项目测试"

