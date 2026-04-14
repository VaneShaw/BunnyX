# Firebase Crashlytics dSYM 上传配置完成 ✅

## 已完成的配置

### 1. ✅ 添加了 dSYM 上传脚本
已在 Xcode 项目中添加了 Firebase Crashlytics dSYM 上传脚本：

- **脚本名称**: `[Firebase] Upload dSYM to Crashlytics`
- **脚本位置**: Build Phases 的最后阶段（在 Copy Bundle Resources 之后）
- **脚本内容**: 
  ```bash
  "${PODS_ROOT}/FirebaseCrashlytics/upload-symbols" -gsp "${PROJECT_DIR}/Bunnyx/GoogleService-Info.plist" -p ios "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}"
  ```

### 2. ✅ 配置了 Input Files（支持用户脚本沙盒）
已配置以下输入文件路径：
- `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}`
- `${PROJECT_DIR}/Bunnyx/GoogleService-Info.plist`
- `${TARGET_BUILD_DIR}/${EXECUTABLE_PATH}`

### 3. ✅ 配置了 Output Files（支持用户脚本沙盒）
已配置输出文件路径：
- `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}`

## 需要手动检查的配置

### ⚠️ 重要：检查 Debug Information Format 设置

请在 Xcode 中验证以下设置：

1. 打开 Xcode 项目
2. 选择 **Bunnyx** target
3. 打开 **Build Settings** 标签页
4. 搜索 `debug information format` 或 `DEBUG_INFORMATION_FORMAT`
5. 确保所有构建配置（Debug、Release）都设置为：
   - **DWARF with dSYM File** ✅

如果设置为其他值（如 `dwarf`），dSYM 文件将不会生成，上传脚本也无法工作。

## 验证配置

### 1. 构建项目
在 Xcode 中构建项目（⌘+B），检查构建日志中是否有：
- `[Firebase] Upload dSYM to Crashlytics` 脚本的执行输出
- 如果没有错误，说明脚本配置正确

### 2. 检查 Firebase 控制台
1. 打开 [Firebase 控制台](https://console.firebase.google.com/)
2. 选择项目 `bunnyx-794e0`
3. 进入 **Crashlytics** > **dSYM** 标签页
4. 查看是否有上传的 dSYM 文件

**注意**: dSYM 文件上传后，Firebase 可能需要几分钟时间来处理。

## 故障排查

### 如果脚本执行失败：

1. **检查 upload-symbols 脚本是否存在**:
   ```bash
   ls -la "${PODS_ROOT}/FirebaseCrashlytics/upload-symbols"
   ```

2. **检查 GoogleService-Info.plist 路径是否正确**:
   确保文件位于 `${PROJECT_DIR}/Bunnyx/GoogleService-Info.plist`

3. **检查 dSYM 文件是否生成**:
   - 在 Xcode 中，打开 **Window** > **Organizer**
   - 查看归档中的 dSYM 文件

4. **查看构建日志**:
   - 在 Xcode 中打开构建日志（⌘+9）
   - 展开 `[Firebase] Upload dSYM to Crashlytics` 阶段
   - 查看详细的错误信息

### 如果 dSYM 文件未生成：

1. 确认 **Debug Information Format** 设置为 **DWARF with dSYM File**
2. 清理构建文件夹（⌘+Shift+K）
3. 重新构建项目

## 参考文档

- [Firebase Crashlytics iOS 文档](https://firebase.google.cn/docs/crashlytics/ios/get-deobfuscated-reports?hl=nl)
- 详细配置说明请查看 `FIREBASE_CRASHLYTICS_SETUP.md`

## 下一步

1. ✅ 在 Xcode 中验证 Debug Information Format 设置
2. ✅ 构建项目并检查脚本是否正常执行
3. ✅ 在 Firebase 控制台验证 dSYM 是否上传成功
4. ✅ 测试崩溃报告是否能正确显示去混淆的堆栈跟踪

配置完成后，Firebase Crashlytics 将能够显示去混淆的崩溃报告，帮助您更快地定位和修复问题！

