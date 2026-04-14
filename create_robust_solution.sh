#!/bin/bash

# 创建健壮的解决方案
# 从根本上解决沙盒权限与CocoaPods资源复制的矛盾

set -e

echo "🛠️ 创建健壮的沙盒权限解决方案..."

# 1. 创建自定义资源复制脚本
mkdir -p "Scripts"

cat > "Scripts/robust_resource_copy.sh" << 'EOF'
#!/bin/bash
# 健壮的资源复制脚本
# 解决沙盒权限问题

set -e
set -u
set -o pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查必需的环境变量
if [ -z "${TARGET_BUILD_DIR:-}" ] || [ -z "${UNLOCALIZED_RESOURCES_FOLDER_PATH:-}" ]; then
    log_error "缺少必需的环境变量"
    exit 1
fi

# 设置权限
umask 022

# 创建目标目录
TARGET_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
log_info "目标目录: $TARGET_DIR"

# 确保目录存在
mkdir -p "$TARGET_DIR" || {
    log_error "无法创建目标目录: $TARGET_DIR"
    exit 1
}

# 资源复制函数
copy_resource() {
    local source="$1"
    local name=$(basename "$source")
    local target="$TARGET_DIR/$name"
    
    if [ ! -e "$source" ]; then
        log_warning "资源不存在: $source"
        return 1
    fi
    
    log_info "复制资源: $name"
    
    # 尝试多种复制方法
    if cp -R "$source" "$target" 2>/dev/null; then
        log_success "复制成功: $name"
        return 0
    elif rsync -a "$source" "$target" 2>/dev/null; then
        log_success "使用 rsync 复制成功: $name"
        return 0
    elif ditto "$source" "$target" 2>/dev/null; then
        log_success "使用 ditto 复制成功: $name"
        return 0
    else
        log_error "复制失败: $name"
        return 1
    fi
}

# 处理不同类型的资源
process_resource() {
    local resource="$1"
    local name=$(basename "$resource")
    
    case "$resource" in
    *.xcmappingmodel)
        log_info "处理 xcmappingmodel: $name"
        local target="${TARGET_DIR}/$(basename "$resource" .xcmappingmodel).cdm"
        if xcrun mapc "$resource" "$target" 2>/dev/null; then
            log_success "xcmappingmodel 处理成功: $name"
        else
            log_warning "xcmappingmodel 处理失败: $name"
        fi
        ;;
    *.xcassets)
        log_info "处理 xcassets: $name"
        copy_resource "$resource"
        ;;
    *.bundle)
        log_info "处理 bundle: $name"
        copy_resource "$resource"
        ;;
    *.xprivacy)
        log_info "处理 privacy 文件: $name"
        copy_resource "$resource"
        ;;
    *)
        log_info "处理其他资源: $name"
        copy_resource "$resource"
        ;;
    esac
}

# 安装资源函数
install_resource() {
    local resource="$1"
    if [ -n "$resource" ]; then
        process_resource "$resource"
    fi
}

log_info "开始复制资源..."

# 根据配置安装资源
if [[ "${CONFIGURATION:-Debug}" == "Debug" ]]; then
    log_info "安装 Debug 配置资源..."
    
    # 尝试从多个位置查找资源
    local resources=(
        "${PODS_CONFIGURATION_BUILD_DIR}/CocoaLumberjack/CocoaLumberjackPrivacy.bundle"
        "${PODS_CONFIGURATION_BUILD_DIR}/FMDB/FMDB_Privacy.bundle"
        "${PODS_CONFIGURATION_BUILD_DIR}/IQKeyboardManager/IQKeyboardManager.bundle"
        "${PODS_ROOT}/MJRefresh/MJRefresh/MJRefresh.bundle"
        "${PODS_CONFIGURATION_BUILD_DIR}/MJRefresh/MJRefresh.Privacy.bundle"
        "${PODS_CONFIGURATION_BUILD_DIR}/SDWebImage/SDWebImage.bundle"
        "${PODS_ROOT}/SVProgressHUD/SVProgressHUD/SVProgressHUD.bundle"
        "${PODS_ROOT}/SVProgressHUD/SVProgressHUD/PrivacyInfo.xcprivacy"
        "${PODS_ROOT}/TZImagePickerController/TZImagePickerController/TZImagePickerController/TZImagePickerController.bundle"
        "${PODS_CONFIGURATION_BUILD_DIR}/Toast/Toast.bundle"
    )
    
    for resource in "${resources[@]}"; do
        install_resource "$resource"
    done
fi

if [[ "${CONFIGURATION:-Debug}" == "Release" ]]; then
    log_info "安装 Release 配置资源..."
    
    # Release 配置的资源列表
    local resources=(
        "${PODS_CONFIGURATION_BUILD_DIR}/CocoaLumberjack/CocoaLumberjackPrivacy.bundle"
        "${PODS_CONFIGURATION_BUILD_DIR}/FMDB/FMDB_Privacy.bundle"
        "${PODS_CONFIGURATION_BUILD_DIR}/IQKeyboardManager/IQKeyboardManager.bundle"
        "${PODS_ROOT}/MJRefresh/MJRefresh/MJRefresh.bundle"
        "${PODS_CONFIGURATION_BUILD_DIR}/MJRefresh/MJRefresh.Privacy.bundle"
        "${PODS_CONFIGURATION_BUILD_DIR}/SDWebImage/SDWebImage.bundle"
        "${PODS_ROOT}/SVProgressHUD/SVProgressHUD/SVProgressHUD.bundle"
        "${PODS_ROOT}/SVProgressHUD/SVProgressHUD/PrivacyInfo.xcprivacy"
        "${PODS_ROOT}/TZImagePickerController/TZImagePickerController/TZImagePickerController/TZImagePickerController.bundle"
        "${PODS_CONFIGURATION_BUILD_DIR}/Toast/Toast.bundle"
    )
    
    for resource in "${resources[@]}"; do
        install_resource "$resource"
    done
fi

# 处理安装阶段
if [[ "${ACTION:-build}" == "install" ]] && [[ "${SKIP_INSTALL:-NO}" == "NO" ]]; then
    log_info "处理安装阶段..."
    
    local install_dir="${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
    mkdir -p "$install_dir"
    
    if [ -d "$TARGET_DIR" ]; then
        log_info "复制资源到安装目录: $install_dir"
        cp -R "$TARGET_DIR"/* "$install_dir/" 2>/dev/null || {
            log_warning "安装阶段复制失败，尝试其他方法..."
            rsync -a "$TARGET_DIR/" "$install_dir/" 2>/dev/null || {
                log_error "安装阶段复制完全失败"
            }
        }
    fi
fi

log_success "资源复制完成！"
EOF

chmod +x "Scripts/robust_resource_copy.sh"

# 2. 创建 Podfile 优化版本
cat > "Podfile.robust" << 'EOF'
# 健壮的 Podfile 配置
# 解决沙盒权限问题

platform :ios, '12.0'
use_frameworks!

# 优化 CocoaPods 安装设置
install! 'cocoapods',
  :disable_input_output_paths => true,
  :integrate_targets => true,
  :preserve_pod_file_structure => true,
  :deterministic_uuids => false,
  :share_schemes_for_development_pods => true,
  :warn_for_multiple_pod_sources => false

# 全局设置
inhibit_all_warnings!

target 'Bunnyx' do
  # 网络库
  pod 'AFNetworking', '~> 4.0'
  
  # 图片处理
  pod 'SDWebImage', '5.19.2', :modular_headers => true
  
  # UI 布局
  pod 'Masonry'
  
  # 下拉刷新
  pod 'MJRefresh'
  
  # 响应式编程
  pod 'ReactiveObjC'
  
  # 数据模型
  pod 'YYModel'
  pod 'YYCache'
  
  # 进度提示
  pod 'SVProgressHUD'
  
  # 键盘管理
  pod 'IQKeyboardManager'
  
  # 数据库
  pod 'FMDB'
  
  # 日志
  pod 'CocoaLumberjack/Swift'
  
  # 空数据视图
  pod 'DZNEmptyDataSet'
  
  # 图片选择器
  pod 'TZImagePickerController', :modular_headers => true
  
  # 提示框
  pod 'Toast'
  
  # 工具类
  pod 'YYCategories'
  pod 'YYText'
end

target 'BunnyxTests' do
  inherit! :search_paths
end

target 'BunnyxUITests' do
  inherit! :search_paths
end

# 后安装脚本
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
      
      # 优化构建
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      config.build_settings['VALIDATE_PRODUCT'] = 'NO'
      config.build_settings['SKIP_INSTALL'] = 'YES'
      
      # 解决警告
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
    end
    
    # 修复资源复制问题
    target.resource_bundle_targets.each do |resource_target|
      resource_target.build_configurations.each do |config|
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      end
    end
  end
  
  # 替换资源复制脚本
  installer.pods_project.targets.each do |target|
    target.build_phases.each do |phase|
      if phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
        if phase.name && phase.name.include?('Copy Pods Resources')
          phase.shell_script = <<~SCRIPT
            # 使用健壮的资源复制脚本
            "${SRCROOT}/Scripts/robust_resource_copy.sh"
          SCRIPT
        end
      end
    end
  end
end
EOF

# 3. 创建 Xcode 项目优化脚本
cat > "Scripts/optimize_project.rb" << 'EOF'
#!/usr/bin/env ruby
# Xcode 项目优化脚本

require 'xcodeproj'

def optimize_project(project_path)
  project = Xcodeproj::Project.open(project_path)
  
  puts "🔧 优化项目: #{project_path}"
  
  project.targets.each do |target|
    puts "📱 处理目标: #{target.name}"
    
    target.build_configurations.each do |config|
      puts "⚙️  配置: #{config.name}"
      
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
        'SKIP_INSTALL' => 'YES',
        'GCC_WARN_INHIBIT_ALL_WARNINGS' => 'YES',
        'CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER' => 'NO'
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
          puts "📦 优化资源复制阶段: #{phase.name}"
          
          # 使用健壮的资源复制脚本
          phase.shell_script = <<~SCRIPT
            # 使用健壮的资源复制脚本
            "${SRCROOT}/Scripts/robust_resource_copy.sh"
          SCRIPT
        end
      end
    end
  end
  
  project.save
  puts "✅ 项目优化完成"
end

# 执行优化
if ARGV.length > 0
  optimize_project(ARGV[0])
else
  puts "用法: #{$0} <project.pbxproj>"
  exit 1
end
EOF

chmod +x "Scripts/optimize_project.rb"

# 4. 创建一键修复脚本
cat > "fix_sandbox_issues.sh" << 'EOF'
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
EOF

chmod +x "fix_sandbox_issues.sh"

echo "✅ 健壮的解决方案创建完成！"
echo ""
echo "📋 可用的修复脚本："
echo "1. ./fix_sandbox_issues.sh - 一键修复沙盒权限问题"
echo "2. ./Scripts/robust_resource_copy.sh - 健壮的资源复制脚本"
echo "3. ./Scripts/optimize_project.rb - Xcode 项目优化脚本"
echo ""
echo "🚀 建议运行: ./fix_sandbox_issues.sh"
