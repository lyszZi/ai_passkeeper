## Why

当前AI PassKeeper仅支持单一语言，无法满足不同地区用户的使用需求。同时，用户需要一个集中的入口来管理应用设置，包括语言偏好和密码重置功能。

## What Changes

1. **新增多语言(i18n)支持**
   - 实现简体中文和English两种语言支持
   - 建立本地化字符串管理体系
   - 所有UI文本支持语言切换

2. **新增"设置"功能入口**
   - 在主界面添加"设置"Tab或入口按钮
   - 实现语言切换功能（简体中文/English）
   - 实现重置登录密码功能（需验证当前密码）

## Capabilities

### New Capabilities
- `i18n`: 多语言支持能力，包含语言检测、切换和本地化字符串管理
- `settings`: 设置中心能力，包含语言切换和密码重置功能
- `password-reset`: 重置登录密码能力，包含当前密码验证和新密码设置

### Modified Capabilities
- 无（现有功能需求无变化）

## Impact

- **新增文件**:
  - 本地化字符串文件 (`zh-Hans.lproj/`, `en.lproj/`)
  - 国际化服务 (`I18nService`)
  - 设置视图 (`SettingsView`)
  - 密码重置相关ViewModel
- **修改文件**:
  - 主界面添加设置入口
  - 应用启动时检测系统语言