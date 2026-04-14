# Bunnyx（iOS）

Objective-C / UIKit 客户端工程，涵盖首页与素材流、登录与账号、订阅与内购、充值与钱包、国际化与多环境调试等模块。

> **本 README 的侧重点**：记录本人在本项目中 **以 Cursor 为主力工具、重度结合 AI 辅助编程** 的开发方式与心得，而非强调 App 自身的业务是否属于「AI 应用」。

---

## AI 辅助开发实践（Cursor）

本项目从搭建网络层与模型、迭代 UI、对齐多端接口到补充工程文档，**大量工作流在 Cursor 内完成**。对我而言，「AI 开发能力」主要体现在：能否把 AI 当成可靠的 **结对开发者**——在明确约束下快速产出可维护代码，而不是堆不可读的生成物。

| 实践方向 | 具体做法（摘要） |
|----------|------------------|
| **需求拆解与上下文** | 用自然语言描述模块目标、文件路径、与 Android/后端约定；让 AI 在**已有工程风格**（Masonry、宏、Manager 分工）下增量修改。 |
| **重复劳动自动化** | Model 字段、`NetworkMacros` 端点、样板 VC 结构等，由对话驱动生成后再人工收口命名与边界情况。 |
| **跨文件修改** | 利用工作区级理解一次性改网络层 + Model + 调用方，减少「改漏一处」的回归成本。 |
| **文档与排障** | Crashlytics、构建说明等仓库内 Markdown 由 AI 辅助起草，再按真实环境校对。 |
| **质量约束** | 通过 **Cursor Rules / Skills**（或团队规范）约束内存、架构偏好（如新功能 MVVM-C）、国际化与约束写法，避免生成代码与项目习惯冲突。 |

若你也在用 Cursor 做原生客户端：**把「规则写清楚」比「提示词堆很长」更重要**——规则越贴近仓库真实约定，AI 越能稳定当生产力放大器。

---

## 技术栈（节选）

- **语言**：Objective-C（UIKit）
- **布局**：Masonry
- **网络**：`NetworkManager` + `HostEnvironmentManager`（多环境）
- **国际化**：`BXLocalization` / `LanguageManager`
- **统计与广告**：Adjust、Google AdMob（以工程配置为准）
- **崩溃监控**：Firebase Crashlytics（参见 `FIREBASE_CRASHLYTICS_SETUP.md`）

**系统要求**：iOS **15.6+**（以 Xcode 工程 `IPHONEOS_DEPLOYMENT_TARGET` 为准）

---

## 仓库结构（节选）

```
仓库根目录/
├── README.md                  # GitHub 首页默认展示
├── Bunnyx.xcodeproj
├── Bunnyx/                    # 业务源码（AppDelegate、Network、Model…）
├── Podfile
└── …
```

---

## 本地构建

1. 使用 **Xcode** 打开 **`Bunnyx.xcodeproj`**（与 `Podfile` 同级）。
2. 选择目标设备或模拟器，编译运行。
3. Crashlytics / 广告等能力请按 `FIREBASE_CRASHLYTICS_SETUP.md` 等文档配置，**勿将密钥提交到公开仓库**。

---

## 多端与协作

- 可与 **Android** 版对照接口与行为（如 OSS 上传、业务 API 路径）。
- 调试期可通过应用内 **Host / 环境切换**（以当前版本为准）。

---

## 声明

- 请勿将本仓库用于未授权用途；公开前请自行脱敏配置与隐私信息。
- 若 README 与当前分支不一致，以代码与 App Store 说明为准。

---

## License

如需开源，请在此补充协议并与合规确认。
