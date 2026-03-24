# AI PassKeeper - Claude Code 配置

## 项目概述
- **项目类型**: 密码管理器 iOS 应用
- **主要功能**: 安全存储和管理用户密码
- **技术栈**: Swift, SwiftUI, iOS

## 常用 Skills 配置

### 测试辅助 (/test)
```
当用户请求运行测试时，使用 xcodebuild 进行测试:
- 找出可用的测试目标: xcodebuild -list -project *.xcodeproj
- 运行测试: xcodebuild test -scheme <scheme> -destination 'platform=iOS Simulator'
```

### Git 提交 (/commit)
```
分析未暂存的更改，自动生成符合项目风格的提交信息:
- 使用 conventional commits 格式
- 包含变更类型: feat, fix, refactor, docs, test, chore
- 建议提交前先运行 lint 检查
```

### Git Rebase (/rebase)
```
辅助执行 git rebase 操作:
- 提供交互式 rebase 指导
- 解决冲突时提供上下文帮助
- 支持 squash、reword、drop 等操作
```

### 部署辅助 (/deploy)
```
处理应用部署相关任务:
- 构建发布版本: xcodebuild -configuration Release
- 验证构建成功
- 辅助 App Store Connect 上传（如果需要）
```

### 文档生成 (/docs)
```
为代码生成文档:
- Swift 代码使用 SwiftDoc 格式
- 为 public 方法和类型生成注释
- 生成 API 文档概要
```

### 代码迁移 (/migrate)
```
辅助代码迁移任务:
- 框架升级迁移
- API 兼容性问题处理
- 批量重命名支持
- 迁移前创建备份分支
```

### 代码重构 (/refactor)
```
辅助代码重构:
- 提取重复代码为函数
- 简化复杂逻辑
- 应用设计模式
- 重构前确保有测试覆盖
```

### 代码检查 (/lint)
```
代码质量检查:
- 使用 SwiftLint 进行静态分析
- 检查代码风格违规
- 提供修复建议
- 可以在提交前自动运行
```

### 代码解释 (/explain)
```
详细解释代码功能:
- 分析代码逻辑和意图
- 说明关键算法的原理
- 解释复杂的 Swift 语法
- 提供学习参考资料
```

### 依赖管理 (/dependency)
```
项目依赖管理:
- 检查 CocoaPods/Swift Package 依赖
- 查找可更新的依赖版本
- 验证依赖兼容性
- 更新前提醒备份
```

## 项目特定配置

### iOS 开发规范
- 使用 SwiftUI 进行 UI 开发
- 遵循 Apple Human Interface Guidelines
- 使用 MVVM 架构模式

### 安全要求
- 不在代码中硬编码敏感信息
- 使用 Keychain 存储密码
- 遵循 OWASP 安全最佳实践

### 构建命令
```bash
# 运行测试
xcodebuild test -scheme AIPassKeeper -destination 'platform=iOS Simulator,name=iPhone 16'

# 构建 Release
xcodebuild -scheme AIPassKeeper -configuration Release

# SwiftLint 检查
swiftlint
```