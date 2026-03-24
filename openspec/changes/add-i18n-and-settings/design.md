## Context

AI PassKeeper是一款iOS密码管理器应用，当前版本仅支持单一语言（系统默认语言）。用户反馈需要中文界面，同时需要一个集中的设置入口来管理应用偏好和安全设置。

当前应用架构：
- 使用SwiftUI进行UI开发
- MVVM架构模式
- 本地数据存储使用SQLite
- 安全认证使用Face ID/Touch ID和密码

## Goals / Non-Goals

**Goals:**
- 实现简体中文和English两种语言支持
- 建立可扩展的本地化字符串管理体系，后续可轻松添加更多语言
- 在主界面添加设置入口
- 实现语言切换功能（立即生效，无需重启）
- 实现重置登录密码功能（需验证当前密码）

**Non-Goals:**
- 不支持运行时语言切换时保存到服务器（仅本地存储）
- 不支持第三方翻译服务集成
- 不修改现有的密码存储和加密机制

## Decisions

### 1. 本地化方案选择
**决定**: 使用Swift原生`String.localizationWithPlatform` + `.lproj`目录方式

**备选方案考虑**:
- `.strings`文件方式（传统iOS方案）✓ 采用
- 第三方库（如SwiftGen）
- 自定义JSON配置

**理由**: 使用Apple原生方案，无需引入额外依赖，与SwiftUI无缝集成。

### 2. 语言存储方案
**决定**: 使用UserDefaults存储用户选择的语言偏好

**理由**: 轻量级配置存储，简单高效，符合Apple推荐实践。

### 3. 重置密码验证方式
**决定**: 需要验证当前登录密码后才能重置

**理由**: 安全考虑，防止他人直接重置用户密码。

### 4. 设置入口位置
**决定**: 在MainView中添加导航到Settings的入口

**理由**: 与现有NavigationStack架构兼容，保持UI一致性。

## Risks / Trade-offs

- [Risk] 用户首次打开应用时语言检测可能不准确
  - → Mitigation: 优先使用UserDefaults存储的语言设置，其次检测系统语言，最后默认English

- [Risk] 语言切换后部分动态内容未更新
  - → Mitigation: 使用`@Observable`或`@State`确保视图响应语言变化

- [Risk] 密码重置后数据安全问题
  - → Mitigation: 重置仅影响登录密码，不影响已存储的密码数据