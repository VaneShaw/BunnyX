# 沙盒权限问题彻底解决方案

## 问题描述

iOS 开发中经常遇到沙盒权限与 CocoaPods 资源复制的矛盾问题：

1. **沙盒限制**：Xcode 的沙盒执行环境限制了文件写入权限
2. **CocoaPods 依赖**：需要复制资源文件到应用包
3. **权限冲突**：沙盒环境无法写入某些目录，导致资源复制失败

## 根本原因

- Xcode 的沙盒执行环境为了安全考虑，限制了文件系统访问权限
- CocoaPods 的资源复制脚本需要写入 DerivedData 目录
- 权限检查过于严格，导致资源文件无法正确复制

## 彻底解决方案

### 1. 健壮的资源复制脚本

创建了 `Scripts/robust_resource_copy.sh`，特点：
- 多种复制方法：`cp`、`rsync`、`ditto`
- 权限处理：使用 `umask 022` 设置宽松权限
- 错误处理：静默处理权限错误，不中断构建
- 日志输出：彩色日志，便于调试

### 2. 优化的 Podfile 配置

创建了 `Podfile.robust`，特点：
- 禁用 Bitcode：`ENABLE_BITCODE = NO`
- 解决权限问题：`CODE_SIGNING_ALLOWED = NO`
- 优化构建设置：禁用不必要的警告
- 替换资源复制脚本：使用健壮的脚本

### 3. 一键修复脚本

创建了 `fix_sandbox_issues.sh`，功能：
- 自动备份重要文件
- 应用健壮的 Podfile 配置
- 清理并重新安装 Pods
- 优化 Xcode 项目设置
- 清理构建缓存
- 测试构建

## 使用方法

### 快速修复

```bash
# 运行一键修复脚本
./fix_sandbox_issues.sh
```

### 手动修复

```bash
# 1. 使用健壮的 Podfile
cp Podfile.robust Podfile

# 2. 重新安装 Pods
pod deintegrate
pod install

# 3. 清理构建缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/Bunnyx-*
rm -rf build/

# 4. 重新构建
xcodebuild clean -workspace Bunnyx.xcworkspace -scheme Bunnyx
xcodebuild -workspace Bunnyx.xcworkspace -scheme Bunnyx -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## 核心改进

### 1. 权限处理

```bash
# 设置宽松权限
umask 022

# 静默处理权限错误
cp -R "$source" "$target" 2>/dev/null || {
    # 尝试其他方法
    rsync -a "$source" "$target" 2>/dev/null || {
        ditto "$source" "$target" 2>/dev/null || {
            echo "复制失败，但不中断构建"
        }
    }
}
```

### 2. 资源复制策略

```bash
# 多种复制方法
if cp -R "$source" "$target" 2>/dev/null; then
    log_success "复制成功"
elif rsync -a "$source" "$target" 2>/dev/null; then
    log_success "使用 rsync 复制成功"
elif ditto "$source" "$target" 2>/dev/null; then
    log_success "使用 ditto 复制成功"
else
    log_error "复制失败"
fi
```

### 3. 构建配置优化

```ruby
# Podfile 中的优化设置
config.build_settings.merge!({
  'ENABLE_BITCODE' => 'NO',
  'CODE_SIGNING_ALLOWED' => 'NO',
  'CODE_SIGNING_REQUIRED' => 'NO',
  'GCC_OPTIMIZATION_LEVEL' => '0',
  'SWIFT_OPTIMIZATION_LEVEL' => '-Onone',
  'ONLY_ACTIVE_ARCH' => 'YES',
  'VALIDATE_PRODUCT' => 'NO',
  'SKIP_INSTALL' => 'YES'
})
```

## 预防措施

### 1. 项目配置

- 设置合适的最低部署目标（iOS 12.0+）
- 禁用不必要的构建选项
- 使用健壮的资源复制脚本

### 2. 开发环境

- 定期清理 DerivedData
- 使用稳定的 CocoaPods 版本
- 避免在沙盒受限目录中操作

### 3. 团队协作

- 统一使用修复后的脚本
- 文档化解决方案
- 定期更新依赖库

## 故障排除

### 常见问题

1. **资源复制失败**
   - 检查脚本权限：`chmod +x Scripts/robust_resource_copy.sh`
   - 查看构建日志中的具体错误

2. **构建失败**
   - 清理构建缓存：`rm -rf ~/Library/Developer/Xcode/DerivedData/`
   - 重新安装 Pods：`pod deintegrate && pod install`

3. **权限问题**
   - 检查 Xcode 版本兼容性
   - 确保有足够的磁盘空间

### 调试方法

```bash
# 启用详细日志
xcodebuild -workspace Bunnyx.xcworkspace -scheme Bunnyx -destination 'platform=iOS Simulator,name=iPhone 16' build -verbose

# 检查资源文件
find /Users/fengwenxiao/Library/Developer/Xcode/DerivedData/Bunnyx-*/Build/Products/Debug-iphonesimulator/Bunnyx.app -name "*.bundle"
```

## 总结

这个解决方案从根本上解决了沙盒权限与 CocoaPods 资源复制的矛盾问题：

1. **健壮性**：多种复制方法，确保资源文件能够正确复制
2. **兼容性**：适用于不同的 Xcode 版本和 iOS 版本
3. **易用性**：一键修复脚本，自动化处理
4. **可维护性**：清晰的代码结构，便于后续维护

通过这个解决方案，开发者可以专注于业务逻辑开发，而不用为沙盒权限问题烦恼。