# 发布到 ClawHub 指南

## 步骤 1：创建 GitHub 仓库

1. 访问 https://github.com/new
2. 创建名为 `multi-claw` 的仓库
3. 设置为 Public
4. 不要初始化（我们已经准备好了文件）

## 步骤 2：推送代码到 GitHub

```bash
# 进入 skill 目录
cd ~/.openclaw/skills/multi-claw

# 初始化 git 仓库
git init

# 添加所有文件
git add .

# 提交
git commit -m "Initial release: multi-claw v1.0.0"

# 添加远程仓库（替换为你的用户名）
git remote add origin https://github.com/wangxin/multi-claw.git

# 推送
git push -u origin main
```

## 步骤 3：创建 Release

```bash
# 创建标签
git tag v1.0.0

# 推送标签
git push origin v1.0.0
```

或者通过 GitHub Web 界面：
1. 进入仓库页面
2. 点击 "Releases" → "Create a new release"
3. 选择标签 "v1.0.0"
4. 填写发布说明
5. 点击 "Publish release"

## 步骤 4：提交到 ClawHub

ClawHub 会自动从 GitHub 同步带有 `skill.json` 的仓库。

如果 24 小时内没有自动同步，可以手动提交：

1. 访问 https://clawhub.ai
2. 使用 GitHub 账号登录
3. 点击 "Submit Skill"
4. 填写仓库地址：`https://github.com/wangxin/multi-claw`
5. 提交审核

## 步骤 5：验证发布

发布后，用户可以通过以下方式安装：

```bash
# 通过 skills CLI
npx skills add wangxin/multi-claw

# 或通过 ClawHub 网站
# https://clawhub.ai/skills/wangxin/multi-claw
```

## 发布检查清单

- [ ] GitHub 仓库已创建
- [ ] 代码已推送到 GitHub
- [ ] Release 已创建
- [ ] skill.json 格式正确
- [ ] README.md 完整
- [ ] LICENSE 文件存在
- [ ] 在 ClawHub 上可见

## 后续更新

发布新版本时：

```bash
# 更新版本号
vim skill.json  # 修改 version

# 提交更改
git add .
git commit -m "Bump version to v1.1.0"
git push

# 创建新标签
git tag v1.1.0
git push origin v1.1.0
```

ClawHub 会自动检测新版本。

## 注意事项

1. **skill.json 必须存在** - 这是 ClawHub 识别 skill 的关键
2. **README.md 建议完整** - 帮助用户了解如何使用
3. **使用语义化版本** - v1.0.0, v1.1.0, v2.0.0 等
4. **保持向后兼容** - 大版本更新时说明 breaking changes

## 获取帮助

- ClawHub 文档: https://docs.clawhub.ai
- OpenClaw 文档: https://docs.openclaw.ai
- 社区 Discord: https://discord.gg/clawd
