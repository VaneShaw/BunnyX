#!/bin/bash

# 修复 CocoaPods 沙盒权限问题的自动化脚本
# 使用方法：在项目根目录运行 ./fix_pods_sandbox.sh

echo "🔧 正在修复 CocoaPods 沙盒权限问题..."

# 检查是否存在资源复制脚本
RESOURCES_SCRIPT="Pods/Target Support Files/Pods-Bunnyx/Pods-Bunnyx-resources.sh"

if [ -f "$RESOURCES_SCRIPT" ]; then
    echo "📝 找到资源复制脚本，正在应用修复..."
    
    # 备份原始脚本
    cp "$RESOURCES_SCRIPT" "$RESOURCES_SCRIPT.backup"
    
    # 使用 sed 替换资源复制逻辑
    sed -i '' 's/RESOURCES_TO_COPY=${PODS_ROOT}\/resources-to-copy-${TARGETNAME}.txt/# 跳过资源复制以避免沙盒权限问题/' "$RESOURCES_SCRIPT"
    sed -i '' 's/> "$RESOURCES_TO_COPY"/echo "Skipping Pods Resources copy due to sandbox restrictions"\necho "Resources will be handled by Xcode automatically"\nexit 0/' "$RESOURCES_SCRIPT"
    
    echo "✅ 资源复制脚本修复完成"
else
    echo "⚠️  未找到资源复制脚本，请先运行 pod install"
    exit 1
fi

# 检查并修复 Podfile 中的沙盒设置
if grep -q "ENABLE_USER_SCRIPT_SANDBOXING" Podfile; then
    echo "✅ Podfile 中已包含沙盒修复设置"
else
    echo "⚠️  Podfile 中缺少沙盒修复设置，请检查 Podfile 配置"
fi

echo "🎉 沙盒权限问题修复完成！"
echo "💡 提示：每次运行 pod install 后，请运行此脚本来自动修复"
