#!/bin/bash

# Xcode 构建优化脚本
# 解决沙盒权限问题并优化构建过程

set -e

echo "🚀 开始优化 Xcode 构建配置..."

# 1. 检查 Xcode 项目文件
PROJECT_FILE="Bunnyx.xcodeproj/project.pbxproj"
if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ 找不到 Xcode 项目文件: $PROJECT_FILE"
    exit 1
fi

# 2. 备份项目文件
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo "📁 已备份项目文件"

# 3. 创建构建阶段脚本
cat > "Scripts/fix_build_phases.sh" << 'EOF'
#!/bin/bash
# 构建阶段修复脚本

# 设置更宽松的权限
umask 022

# 确保目标目录存在
mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

# 设置环境变量
export COCOAPODS_DISABLE_STATS=1
export COCOAPODS_SKIP_CACHE=1

# 继续执行原始脚本
exec "$@"
EOF

chmod +x "Scripts/fix_build_phases.sh"

# 4. 创建 Podfile 优化配置
cat > "Podfile.optimized" << 'EOF'
# 优化后的 Podfile 配置
# 解决沙盒权限问题

platform :ios, '12.0'
use_frameworks!

# 禁用统计和缓存
install! 'cocoapods', 
  :disable_input_output_paths => true,
  :disable_input_output_paths => true,
  :integrate_targets => true,
  :preserve_pod_file_structure => true,
  :deterministic_uuids => false,
  :share_schemes_for_development_pods => true

# 优化资源复制
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 禁用 Bitcode
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # 优化编译设置
      config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
      config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
      
      # 解决权限问题
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
    end
    
    # 修复资源复制问题
    target.resource_bundle_targets.each do |resource_target|
      resource_target.build_configurations.each do |config|
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      end
    end
  end
  
  # 修复资源复制脚本
  installer.pods_project.targets.each do |target|
    target.build_phases.each do |phase|
      if phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
        if phase.name == '[CP] Copy Pods Resources'
          # 修改脚本以处理权限问题
          phase.shell_script = <<~SCRIPT
            set -e
            set -u
            set -o pipefail
            
            # 设置权限
            umask 022
            
            # 确保目录存在
            mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
            
            # 执行原始资源复制逻辑
            "${PODS_ROOT}/Target Support Files/Pods-${TARGET_NAME}/Pods-${TARGET_NAME}-resources.sh"
          SCRIPT
        end
      end
    end
  end
end

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
EOF

# 5. 创建 Xcode 构建设置优化脚本
cat > "Scripts/optimize_build_settings.rb" << 'EOF'
#!/usr/bin/env ruby
# Xcode 构建设置优化脚本

require 'xcodeproj'

def optimize_project(project_path)
  project = Xcodeproj::Project.open(project_path)
  
  project.targets.each do |target|
    target.build_configurations.each do |config|
      # 优化构建设置
      config.build_settings.merge!({
        'ENABLE_BITCODE' => 'NO',
        'CODE_SIGNING_ALLOWED' => 'NO',
        'CODE_SIGNING_REQUIRED' => 'NO',
        'CODE_SIGN_IDENTITY' => '',
        'PROVISIONING_PROFILE' => '',
        'GCC_OPTIMIZATION_LEVEL' => '0',
        'SWIFT_OPTIMIZATION_LEVEL' => '-Onone',
        'DEBUG_INFORMATION_FORMAT' => 'dwarf',
        'ONLY_ACTIVE_ARCH' => 'YES',
        'VALIDATE_PRODUCT' => 'NO',
        'SKIP_INSTALL' => 'YES'
      })
      
      # 修复资源复制问题
      if target.name.include?('Pods')
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      end
    end
    
    # 优化构建阶段
    target.build_phases.each do |phase|
      if phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
        if phase.name && phase.name.include?('Copy Pods Resources')
          # 修改脚本以处理权限问题
          phase.shell_script = <<~SCRIPT
            set -e
            set -u
            set -o pipefail
            
            # 设置权限
            umask 022
            
            # 确保目录存在
            mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
            
            # 执行资源复制
            "${PODS_ROOT}/Target Support Files/Pods-${TARGET_NAME}/Pods-${TARGET_NAME}-resources.sh"
          SCRIPT
        end
      end
    end
  end
  
  project.save
  puts "✅ 已优化项目: #{project_path}"
end

# 执行优化
if ARGV.length > 0
  optimize_project(ARGV[0])
else
  puts "用法: #{$0} <project.pbxproj>"
  exit 1
end
EOF

chmod +x "Scripts/optimize_build_settings.rb"

# 6. 创建一键修复脚本
cat > "fix_all_issues.sh" << 'EOF'
#!/bin/bash
# 一键修复所有沙盒权限问题

set -e

echo "🔧 开始一键修复所有问题..."

# 1. 运行 CocoaPods 沙盒修复
echo "📦 修复 CocoaPods 沙盒权限..."
./fix_pods_sandbox.sh

# 2. 清理并重新安装 Pods
echo "🧹 清理并重新安装 Pods..."
pod deintegrate
pod install

# 3. 优化 Xcode 项目
echo "⚙️ 优化 Xcode 项目..."
mkdir -p Scripts
./Scripts/optimize_build_settings.rb Bunnyx.xcodeproj/project.pbxproj

# 4. 清理构建缓存
echo "🗑️ 清理构建缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Bunnyx-*
rm -rf build/

# 5. 重新构建
echo "🏗️ 重新构建项目..."
xcodebuild clean -workspace Bunnyx.xcworkspace -scheme Bunnyx
xcodebuild -workspace Bunnyx.xcworkspace -scheme Bunnyx -destination 'platform=iOS Simulator,name=iPhone 16' build

echo "🎉 所有问题修复完成！"
echo ""
echo "💡 如果仍有问题，请检查："
echo "1. Xcode 版本是否支持当前 iOS 版本"
echo "2. 模拟器是否正常运行"
echo "3. 网络连接是否正常"
EOF

chmod +x "fix_all_issues.sh"

echo "✅ 优化脚本创建完成！"
echo ""
echo "📋 可用的修复脚本："
echo "1. ./fix_pods_sandbox.sh - 修复 CocoaPods 沙盒权限"
echo "2. ./fix_all_issues.sh - 一键修复所有问题"
echo "3. ./Scripts/optimize_build_settings.rb - 优化 Xcode 项目"
echo ""
echo "🚀 建议运行: ./fix_all_issues.sh"
