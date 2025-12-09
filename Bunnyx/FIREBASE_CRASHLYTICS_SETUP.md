# Firebase Crashlytics dSYM 上传配置说明

根据 [Firebase Crashlytics 文档](https://firebase.google.cn/docs/crashlytics/ios/get-deobfuscated-reports?hl=nl)，需要配置以下内容以确保能看到去混淆的崩溃报告。

## 当前状态

✅ 已集成 Firebase/Crashlytics Pod  
✅ 已初始化 Firebase (`[FIRApp configure]`)  
❌ **缺少 dSYM 上传脚本**  
❌ **需要检查 Debug Information Format 设置**

## 需要配置的步骤

### 1. 检查 Debug Information Format 设置

在 Xcode 中：
1. 选择项目文件
2. 选择 **Bunnyx** target
3. 打开 **Build Settings** 标签页
4. 搜索 `debug information format`
5. 确保所有构建配置（Debug、Release）都设置为 **DWARF with dSYM File**

### 2. 添加 Crashlytics dSYM 上传脚本

在 Xcode 中：
1. 选择 **Bunnyx** target
2. 打开 **Build Phases** 标签页
3. 点击左上角的 **+** 按钮，选择 **New Run Script Phase**
4. 将新脚本阶段拖到 **"Copy Bundle Resources"** 阶段**之后**
5. 展开脚本阶段，设置以下内容：

**脚本内容：**
```bash
"${PODS_ROOT}/FirebaseCrashlytics/upload-symbols" -gsp "${PROJECT_DIR}/Bunnyx/GoogleService-Info.plist" -p ios "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}"
```

**Input Files（如果启用了用户脚本沙盒）：**
```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}
${PROJECT_DIR}/Bunnyx/GoogleService-Info.plist
${TARGET_BUILD_DIR}/${EXECUTABLE_PATH}
```

**Output Files（如果启用了用户脚本沙盒）：**
```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}
```

**注意：** 如果项目设置了 `ENABLE_USER_SCRIPT_SANDBOXING=YES`，必须配置 Input Files 和 Output Files。

### 3. 验证配置

构建项目后，检查：
1. 构建日志中是否有 Crashlytics 上传相关的输出
2. Firebase 控制台 > Crashlytics > dSYM 标签页，查看是否有上传的 dSYM 文件

## 手动上传 dSYM（如果自动上传失败）

如果自动上传失败，可以手动上传：

### 方法 1：通过 Firebase 控制台
1. 打开 Firebase 控制台
2. 进入 **Crashlytics** > **dSYM** 标签页
3. 拖放包含 dSYM 文件的 zip 文件

### 方法 2：使用命令行脚本
```bash
find dSYM_DIRECTORY -name "*.dSYM" | xargs -I {} ${PODS_ROOT}/FirebaseCrashlytics/upload-symbols -gsp ${PROJECT_DIR}/Bunnyx/GoogleService-Info.plist -p ios {}
```

## 查找 dSYM 文件位置

### 在 Xcode Organizer 中查找
1. 在 Xcode 中，打开 **Window** > **Organizer**
2. 选择应用，查看归档列表
3. 右键点击归档，选择 **Show in Finder**
4. 在 `.xcarchive` 中找到 `dSYMs` 目录

### 使用命令行查找
```bash
mdfind -name .dSYM | while read -r line; do dwarfdump -u "$line"; done
```

## 注意事项

1. **Debug Information Format** 必须设置为 **DWARF with dSYM File**，否则不会生成 dSYM 文件
2. 脚本必须在 **"Copy Bundle Resources"** 阶段**之后**执行
3. 如果启用了用户脚本沙盒，必须配置 Input Files 和 Output Files
4. dSYM 文件上传后，Firebase 控制台可能需要几分钟才能处理完成

## 参考文档

- [Firebase Crashlytics iOS 文档](https://firebase.google.cn/docs/crashlytics/ios/get-deobfuscated-reports?hl=nl)

