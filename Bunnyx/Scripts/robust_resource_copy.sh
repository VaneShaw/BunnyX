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
