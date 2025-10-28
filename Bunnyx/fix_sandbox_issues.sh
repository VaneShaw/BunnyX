#!/bin/bash
# 一键修复沙盒权限问题

set -e

echo "🚀 开始修复沙盒权限问题..."

# 1. 备份重要文件
echo "📁 备份重要文件..."
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -f "Podfile" ]; then
    cp "Podfile" "$BACKUP_DIR/Podfile.backup"
fi

if [ -f "Bunnyx.xcodeproj/project.pbxproj" ]; then
    cp "Bunnyx.xcodeproj/project.pbxproj" "$BACKUP_DIR/project.pbxproj.backup"
fi

# 2. 使用健壮的 Podfile
echo "📦 使用健壮的 Podfile 配置..."
if [ -f "Podfile.robust" ]; then
    cp "Podfile.robust" "Podfile"
    echo "✅ 已应用健壮的 Podfile 配置"
else
    echo "⚠️  未找到 Podfile.robust，跳过此步骤"
fi

# 3. 清理并重新安装 Pods
echo "🧹 清理并重新安装 Pods..."
pod deintegrate
pod install

# 4. 优化 Xcode 项目
echo "⚙️ 优化 Xcode 项目..."
if [ -f "Scripts/optimize_project.rb" ]; then
    ruby "Scripts/optimize_project.rb" "Bunnyx.xcodeproj/project.pbxproj"
else
    echo "⚠️  未找到优化脚本，跳过此步骤"
fi

# 5. 清理构建缓存
echo "🗑️ 清理构建缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Bunnyx-*
rm -rf build/

# 6. 测试构建
echo "🏗️ 测试构建..."
xcodebuild clean -workspace Bunnyx.xcworkspace -scheme Bunnyx
xcodebuild -workspace Bunnyx.xcworkspace -scheme Bunnyx -destination 'platform=iOS Simulator,name=iPhone 16' build

echo "🎉 沙盒权限问题修复完成！"
echo "📁 备份文件保存在: $BACKUP_DIR"
echo ""
echo "💡 如果仍有问题，请检查："
echo "1. Xcode 版本是否支持当前 iOS 版本"
echo "2. 模拟器是否正常运行"
echo "3. 网络连接是否正常"
echo "4. 查看构建日志中的具体错误信息"
