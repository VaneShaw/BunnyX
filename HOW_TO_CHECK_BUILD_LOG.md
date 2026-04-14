# 如何查看 Xcode 构建日志并验证 Crashlytics 脚本执行

## 方法一：使用 Xcode 的 Report Navigator（推荐）

### 步骤：

1. **打开 Report Navigator**
   - 在 Xcode 左侧导航栏，点击最后一个图标（报告图标）📊
   - 或者使用快捷键：`⌘ + 9`（Command + 9）

2. **查看最新的构建报告**
   - 在报告列表中，找到最新的构建记录（通常是最上面的）
   - 点击该构建记录

3. **展开脚本执行阶段**
   - 在构建日志中，找到 `[Firebase] Upload dSYM to Crashlytics` 阶段
   - 点击左侧的三角形 ▶️ 展开该阶段

4. **查看脚本输出**
   - 展开后可以看到脚本的详细执行日志
   - 如果成功，会看到类似以下内容：
     ```
     Running script '[Firebase] Upload dSYM to Crashlytics'
     /Users/.../FirebaseCrashlytics/upload-symbols -gsp ... -p ios ...
     Successfully uploaded dSYM to Firebase Crashlytics
     ```
   - 如果有错误，会显示错误信息

## 方法二：使用 Xcode 的构建日志窗口

### 步骤：

1. **开始构建项目**
   - 按 `⌘ + B`（Command + B）开始构建

2. **打开构建日志窗口**
   - 构建开始后，点击 Xcode 顶部工具栏右侧的 **"Show Build Log"** 按钮
   - 或者：`View` > `Navigators` > `Show Build Log`
   - 或者：`⌘ + Shift + Y`（Command + Shift + Y）

3. **查看脚本输出**
   - 在构建日志窗口中，搜索 `[Firebase] Upload dSYM to Crashlytics`
   - 或者滚动到底部查看最新的执行结果

## 方法三：在构建过程中实时查看

### 步骤：

1. **开始构建**
   - 按 `⌘ + B` 开始构建

2. **查看活动窗口**
   - 构建时，Xcode 底部会自动显示活动窗口
   - 在活动窗口中可以看到当前执行的构建阶段
   - 找到 `[Firebase] Upload dSYM to Crashlytics` 阶段

3. **展开查看详情**
   - 点击该阶段左侧的三角形展开
   - 可以看到脚本的实时输出

## 成功标志

如果脚本执行成功，您会看到：

✅ **成功标志：**
- 脚本阶段显示为绿色 ✓
- 没有错误信息
- 可能看到类似 "Successfully uploaded dSYM" 的消息
- 构建完成且没有警告

❌ **失败标志：**
- 脚本阶段显示为红色 ✗
- 有错误信息（如 "dSYM file not found"、"Failed to upload" 等）
- 构建可能失败或显示警告

## 常见输出示例

### 成功输出示例：
```
PhaseScriptExecution [Firebase] Upload dSYM to Crashlytics
    cd /Users/.../Bunnyx
    /bin/sh -c "${PODS_ROOT}/FirebaseCrashlytics/upload-symbols" -gsp "${PROJECT_DIR}/Bunnyx/GoogleService-Info.plist" -p ios "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}"
    
    Successfully uploaded dSYM to Firebase Crashlytics
```

### 失败输出示例（dSYM 未找到）：
```
PhaseScriptExecution [Firebase] Upload dSYM to Crashlytics
    ...
    Error: dSYM file not found at path: ...
```

### 失败输出示例（配置文件未找到）：
```
PhaseScriptExecution [Firebase] Upload dSYM to Crashlytics
    ...
    Error: GoogleService-Info.plist not found
```

## 快速检查技巧

1. **使用搜索功能**
   - 在构建日志中按 `⌘ + F`（Command + F）
   - 搜索关键词：`Firebase`、`Crashlytics`、`dSYM`、`upload-symbols`

2. **查看构建时间**
   - 脚本执行通常需要几秒钟
   - 如果构建时间异常短，可能是脚本没有执行

3. **检查构建阶段顺序**
   - 脚本应该在 "Copy Bundle Resources" 之后执行
   - 在 Report Navigator 中可以看到所有构建阶段的顺序

## 如果看不到脚本输出

可能的原因和解决方法：

1. **脚本没有执行**
   - 检查 Build Phases 中是否包含该脚本
   - 确认脚本没有被禁用

2. **构建配置问题**
   - 尝试清理构建文件夹：`⌘ + Shift + K`
   - 重新构建：`⌘ + B`

3. **日志被过滤**
   - 在 Report Navigator 中，确保选择了 "All Messages"
   - 不要选择 "Errors Only" 或 "Warnings Only"

## 验证脚本是否真的执行了

### 方法：添加测试输出

如果担心脚本没有执行，可以在脚本中添加一个测试输出：

```bash
echo "🔥 Firebase Crashlytics dSYM upload script is running..."
"${PODS_ROOT}/FirebaseCrashlytics/upload-symbols" -gsp "${PROJECT_DIR}/Bunnyx/GoogleService-Info.plist" -p ios "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}"
echo "✅ Script execution completed"
```

这样在构建日志中就能明确看到脚本的执行痕迹。

