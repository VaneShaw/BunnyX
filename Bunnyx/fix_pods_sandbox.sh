#!/bin/bash

# CocoaPods 沙盒权限修复脚本
# 解决 Xcode 沙盒环境与 CocoaPods 资源复制的权限冲突问题

set -e

echo "🔧 开始修复 CocoaPods 沙盒权限问题..."

# 1. 备份原始脚本
BACKUP_DIR="./pods_scripts_backup"
mkdir -p "$BACKUP_DIR"

# 2. 查找所有 CocoaPods 资源复制脚本
find "Pods/Target Support Files" -name "*-resources.sh" | while read script_path; do
    echo "📝 处理脚本: $script_path"
    
    # 备份原始脚本
    cp "$script_path" "$BACKUP_DIR/$(basename "$script_path").backup"
    
    # 创建修复后的脚本
    cat > "$script_path" << 'EOF'
#!/bin/sh
set -e
set -u
set -o pipefail

function on_error {
  echo "$(realpath "${0}"):$1: error: Unexpected failure"
}
trap 'on_error $LINENO' ERR

if [ -z ${UNLOCALIZED_RESOURCES_FOLDER_PATH+x} ]; then
  # If UNLOCALIZED_RESOURCES_FOLDER_PATH is not set, then there's nowhere for us to copy
  # resources to, so exit 0 (signalling the script phase was successful).
  exit 0
fi

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

# 使用临时目录避免权限问题
TEMP_RESOURCES_DIR="${TARGET_BUILD_DIR}/temp_resources_${TARGETNAME}"
mkdir -p "$TEMP_RESOURCES_DIR"

# 清理函数
cleanup() {
    if [ -d "$TEMP_RESOURCES_DIR" ]; then
        rm -rf "$TEMP_RESOURCES_DIR" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# 直接复制资源，避免使用中间文件
copy_resource() {
    local resource_path="$1"
    local resource_name=$(basename "$resource_path")
    local target_path="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/${resource_name}"
    
    if [ -e "$resource_path" ]; then
        echo "📦 复制资源: $resource_name"
        cp -R "$resource_path" "$target_path" 2>/dev/null || {
            echo "⚠️ 复制失败，尝试其他方法: $resource_name"
            # 尝试使用 rsync
            rsync -a "$resource_path" "$target_path" 2>/dev/null || {
                echo "❌ 无法复制资源: $resource_name"
                return 1
            }
        }
        return 0
    else
        echo "⚠️ 资源不存在: $resource_path"
        return 1
    fi
}

# 处理不同类型的资源
process_resource() {
    local resource_path="$1"
    local resource_name=$(basename "$resource_path")
    
    case "$resource_path" in
    *.xcmappingmodel)
      echo "xcrun mapc \"$resource_path\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$resource_path" .xcmappingmodel`.cdm\"" || true
      xcrun mapc "$resource_path" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$resource_path" .xcmappingmodel`.cdm"
      ;;
    *.xcassets)
      # 对于 xcassets，直接复制
      copy_resource "$resource_path"
      ;;
    *)
      # 对于其他资源，直接复制
      copy_resource "$resource_path"
      ;;
    esac
}

# 安装资源函数
install_resource() {
    local resource_path="$1"
    if [ -n "$resource_path" ] && [ -e "$resource_path" ]; then
        process_resource "$resource_path"
    fi
}

# 根据配置安装资源
if [[ "$CONFIGURATION" == "Debug" ]]; then
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/CocoaLumberjack/CocoaLumberjackPrivacy.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/FMDB/FMDB_Privacy.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/IQKeyboardManager/IQKeyboardManager.bundle"
  install_resource "${PODS_ROOT}/MJRefresh/MJRefresh/MJRefresh.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/MJRefresh/MJRefresh.Privacy.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/SDWebImage/SDWebImage.bundle"
  install_resource "${PODS_ROOT}/SVProgressHUD/SVProgressHUD/SVProgressHUD.bundle"
  install_resource "${PODS_ROOT}/SVProgressHUD/SVProgressHUD/PrivacyInfo.xcprivacy"
  install_resource "${PODS_ROOT}/TZImagePickerController/TZImagePickerController/TZImagePickerController/TZImagePickerController.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/Toast/Toast.bundle"
fi

if [[ "$CONFIGURATION" == "Release" ]]; then
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/CocoaLumberjack/CocoaLumberjackPrivacy.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/FMDB/FMDB_Privacy.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/IQKeyboardManager/IQKeyboardManager.bundle"
  install_resource "${PODS_ROOT}/MJRefresh/MJRefresh/MJRefresh.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/MJRefresh/MJRefresh.Privacy.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/SDWebImage/SDWebImage.bundle"
  install_resource "${PODS_ROOT}/SVProgressHUD/SVProgressHUD/SVProgressHUD.bundle"
  install_resource "${PODS_ROOT}/SVProgressHUD/SVProgressHUD/PrivacyInfo.xcprivacy"
  install_resource "${PODS_ROOT}/TZImagePickerController/TZImagePickerController/TZImagePickerController/TZImagePickerController.bundle"
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/Toast/Toast.bundle"
fi

# 处理安装阶段
if [[ "${ACTION}" == "install" ]] && [[ "${SKIP_INSTALL}" == "NO" ]]; then
  mkdir -p "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  # 复制所有已安装的资源到安装目录
  if [ -d "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}" ]; then
    cp -R "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"/* "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/" 2>/dev/null || true
  fi
fi

echo "✅ 资源复制完成"
EOF

    # 确保脚本有执行权限
    chmod +x "$script_path"
    echo "✅ 已修复: $script_path"
done

echo "🎉 CocoaPods 沙盒权限修复完成！"
echo "📁 原始脚本已备份到: $BACKUP_DIR"
echo ""
echo "💡 建议："
echo "1. 运行 'pod install' 重新安装依赖"
echo "2. 清理并重新构建项目"
echo "3. 如果仍有问题，可以运行 'pod deintegrate && pod install' 完全重新安装"