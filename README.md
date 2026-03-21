# PassKeeper

macOS 密码管理应用 - 纯本地、高安全性的密码保险库

## 核心特性

- **本地存储**：所有数据存储在本地设备，不上传云端
- **端到端加密**：AES-256-GCM + PBKDF2 (600,000 次迭代)
- **生物认证**：支持 Touch ID / Face ID 解锁
- **安全剪贴板**：复制密码后 10 秒自动清除
- **强密码生成**：可配置长度的随机安全密码

## 技术架构

| 组件 | 技术 |
|------|------|
| 框架 | SwiftUI |
| 架构 | MVVM |
| 加密 | AES-256-GCM + PBKDF2 |
| 存储 | SQLite (SQLite.swift) |
| 密钥管理 | Keychain Services |

## 安全特性

- 主密码哈希存储在 Keychain（永不存储明文）
- 会话密钥内存管理
- 恒定时间比较防止时序攻击
- 应用锁定/解锁机制
- 自动剪贴板清理

## 构建要求

- Xcode 15.0+
- macOS 13.0+
- Swift 5.9+

## 依赖

- [SQLite.swift](https://github.com/stephencelis/SQLite.swift) - SQLite 数据库封装

## 使用说明

### 首次启动

1. 运行应用，显示 "Welcome to PassKeeper" 界面
2. 创建主密码（至少 8 个字符）
3. 点击 "Create Vault" 创建密码库

### 日常使用

1. 输入主密码或使用 Touch ID 解锁
2. 添加、查看、编辑密码条目
3. 使用分类和搜索功能管理密码

### 添加密码

1. 点击工具栏 "+" 按钮 或按 `Cmd+N`
2. 填写标题、用户名、密码
3. 选择分类
4. 可使用内置密码生成器

## 项目结构

```
PasswordManager/
├── Sources/
│   ├── App/              # 应用入口
│   ├── Models/           # 数据模型
│   ├── ViewModels/       # 视图模型
│   ├── Views/            # SwiftUI 视图
│   ├── Services/
│   │   ├── Security/     # 加密/密钥服务
│   │   └── Storage/      # 数据库服务
│   └── Utilities/        # 工具类
├── Resources/
│   ├── Assets.xcassets   # 应用图标
│   ├── Info.plist
│   └── PassKeeper.entitlements
└── project.yml           # XcodeGen 配置
```

## 许可证

MIT License