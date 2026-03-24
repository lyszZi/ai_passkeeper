## 1. 国际化(i18n)基础设施

- [x] 1.1 创建 `zh-Hans.lproj/Localizable.strings` 文件（简体中文翻译）
- [x] 1.2 创建 `en.lproj/Localizable.strings` 文件（英文翻译）
- [x] 1.3 创建 `I18nService` 服务类，管理语言偏好存储和加载
- [x] 1.4 在 `App` 入口初始化时检测并加载语言设置

## 2. 添加设置入口

- [x] 2.1 创建 `SettingsView` 设置界面视图
- [x] 2.2 在主界面添加设置入口导航（修改 MainView）
- [x] 2.3 创建 `SettingsViewModel` 处理设置逻辑

## 3. 语言切换功能

- [x] 3.1 在 SettingsView 中添加语言选择器
- [x] 3.2 实现语言切换逻辑（保存到 UserDefaults）
- [x] 3.3 确保语言切换后 UI 立即刷新

## 4. 重置登录密码功能

- [x] 4.1 创建密码重置相关的数据模型和验证逻辑
- [x] 4.2 实现当前密码验证功能
- [x] 4.3 实现新密码设置和确认功能
- [x] 4.4 创建密码重置成功/失败的提示反馈