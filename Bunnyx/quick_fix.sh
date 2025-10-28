#!/bin/bash

# 快速修复沙盒权限问题
# 适用于大多数 iOS 项目

set -e

echo "🚀 快速修复沙盒权限问题..."

# 1. 备份原始文件
echo "📁 备份原始文件..."
cp Podfile Podfile.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# 2. 创建简化的 Podfile
echo "📦 创建简化的 Podfile..."
cat > Podfile << 'EOF'
platform :ios, '12.0'
use_frameworks!

# 优化安装设置
install! 'cocoapods',
  :disable_input_output_paths => true,
  :integrate_targets => true,
  :preserve_pod_file_structure => true

target 'Bunnyx' do
  pod 'AFNetworking', '~> 4.0'
  pod 'SDWebImage','5.19.2',:modular_headers => true
  pod 'Masonry'
  pod 'MJRefresh'
  pod 'ReactiveObjC'
  pod 'YYModel'
  pod 'YYCache'
  pod 'SVProgressHUD'
  pod 'IQKeyboardManager'
  pod 'FMDB'
  pod 'CocoaLumberjack/Swift'
  pod 'DZNEmptyDataSet'
  pod 'TZImagePickerController',:modular_headers => true
  pod 'Toast'
  pod 'YYCategories'
  pod 'YYText'
end

target 'BunnyxTests' do
  inherit! :search_paths
end

target 'BunnyxUITests' do
  inherit! :search_paths
end

# 后安装脚本 - 解决权限问题
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 禁用 Bitcode
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # 解决权限问题
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      
      # 优化构建
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      config.build_settings['VALIDATE_PRODUCT'] = 'NO'
      config.build_settings['SKIP_INSTALL'] = 'YES'
      
      # 解决警告
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
    end
  end
end
EOF

# 3. 清理并重新安装
echo "🧹 清理并重新安装 Pods..."
pod deintegrate
pod install

# 4. 清理构建缓存
echo "🗑️ 清理构建缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Bunnyx-*
rm -rf build/

# 5. 测试构建
echo "🏗️ 测试构建..."
xcodebuild clean -workspace Bunnyx.xcworkspace -scheme Bunnyx
xcodebuild -workspace Bunnyx.xcworkspace -scheme Bunnyx -destination 'platform=iOS Simulator,name=iPhone 16' build

echo "✅ 修复完成！"
echo ""
echo "💡 如果仍有问题，请检查："
echo "1. Xcode 版本是否支持当前 iOS 版本"
echo "2. 模拟器是否正常运行"
echo "3. 网络连接是否正常"
