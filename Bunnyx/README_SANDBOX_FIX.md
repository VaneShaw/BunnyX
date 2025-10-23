# CocoaPods 沙盒权限问题修复指南

## 问题描述
在 macOS 上使用 Xcode 构建 iOS 项目时，可能会遇到以下沙盒权限错误：
```
Sandbox: bash(3047) deny(1) file-write-data /Users/xxx/Pods/resources-to-copy-Bunnyx.txt
```

## 解决方案

### 方案1：自动修复（推荐）
现在 Podfile 已经配置了自动修复功能，每次运行 `pod install` 或 `pod update` 时会自动应用修复。

### 方案2：使用 Makefile
```bash
# 安装依赖并自动修复
make install

# 更新依赖并自动修复
make update

# 仅修复沙盒问题
make fix-sandbox

# 清理项目
make clean

# 完整重建
make rebuild
```

### 方案3：手动运行修复脚本
```bash
# 运行自动修复脚本
./fix_pods_sandbox.sh
```

## 修复内容

1. **Podfile 配置**：
   - 禁用用户脚本沙盒：`ENABLE_USER_SCRIPT_SANDBOXING = 'NO'`
   - 禁用严格 Objective-C 消息发送检查
   - 禁用代码签名验证

2. **资源复制脚本修改**：
   - 跳过资源复制以避免沙盒权限问题
   - 让 Xcode 自动处理资源复制

## 注意事项

- 每次运行 `pod install` 或 `pod update` 后，修复会自动应用
- 如果遇到问题，可以运行 `make clean` 清理后重新安装
- 修复脚本已添加到 Git hooks 中，切换分支时会自动检查

## 验证修复

运行以下命令验证修复是否成功：
```bash
xcodebuild -workspace Bunnyx.xcworkspace -scheme Bunnyx -destination 'platform=iOS Simulator,name=iPhone 16' build
```

如果看到 "BUILD SUCCEEDED"，说明修复成功。
