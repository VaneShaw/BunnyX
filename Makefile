# Makefile for Bunnyx iOS Project
# 使用方法：make install 或 make update

.PHONY: install update fix-sandbox clean

# 安装 Pods 并自动修复沙盒问题
install:
	@echo "📦 正在安装 CocoaPods 依赖..."
	pod install
	@echo "🔧 正在修复沙盒权限问题..."
	./fix_pods_sandbox.sh
	@echo "✅ 安装完成！"

# 更新 Pods 并自动修复沙盒问题
update:
	@echo "🔄 正在更新 CocoaPods 依赖..."
	pod update
	@echo "🔧 正在修复沙盒权限问题..."
	./fix_pods_sandbox.sh
	@echo "✅ 更新完成！"

# 仅修复沙盒问题
fix-sandbox:
	@echo "🔧 正在修复沙盒权限问题..."
	./fix_pods_sandbox.sh

# 清理项目
clean:
	@echo "🧹 正在清理项目..."
	rm -rf Pods/
	rm -rf ~/Library/Developer/Xcode/DerivedData/Bunnyx-*
	@echo "✅ 清理完成！"

# 完整重建
rebuild: clean install
	@echo "🏗️  项目重建完成！"
