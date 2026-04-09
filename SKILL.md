---
name: multi-claw
description: 分布式 OpenClaw 控制技能，统一管理多台远程 OpenClaw 实例，批量执行命令并生成报告
metadata:
  openclaw:
    emoji: 🦞
---

# Multi-Claw Skill

分布式 OpenClaw 控制技能，实现"一控多"架构，让你可以从一个中心 OpenClaw 控制多台远程 OpenClaw 实例。

## 功能特性

- 🤖 **多机器管理** - 集中管理多台远程 OpenClaw 配置
- 🚀 **批量执行** - 同时向所有机器发送命令
- ⚡ **并行处理** - 异步执行，提高效率
- 📊 **报告生成** - 自动汇总结果生成 Markdown 报告
- 🔍 **健康检查** - 实时监控所有机器在线状态

## 安装

```bash
# Skill 已创建在 ~/.openclaw/skills/multi-claw/
# 确保脚本可执行
chmod +x ~/.openclaw/skills/multi-claw/multi-claw.sh
```

## 快速开始

### 1. 添加远程机器

```bash
~/.openclaw/skills/multi-claw/multi-claw.sh add \
  "web-01" \
  "10.1.108.23" \
  "clawx-490ef79de708c328cb47bd81fe08c258"
```

### 2. 检查状态

```bash
~/.openclaw/skills/multi-claw/multi-claw.sh status
```

### 3. 批量执行命令

```bash
~/.openclaw/skills/multi-claw/multi-claw.sh run "查看系统信息"
```

### 4. 查看报告

报告保存在 `~/.openclaw/reports/multi-claw/` 目录

## 使用场景

### 场景 1：服务器集群管理

```bash
# 检查所有服务器磁盘空间
multi-claw run "df -h"

# 查看所有服务器负载
multi-claw run "uptime"
```

### 场景 2：批量部署

```bash
# 在所有机器上执行部署脚本
multi-claw run "cd /app && git pull && npm install && pm2 restart"
```

### 场景 3：信息收集

```bash
# 收集所有机器的日志
multi-claw run "tail -100 /var/log/app.log"
```

## 架构说明

```
┌─────────────────────────────────────┐
│         你的 OpenClaw (控制端)        │
│         multi-claw skill            │
└─────────────────────────────────────┘
                   │
      ┌────────────┼────────────┐
      │            │            │
      ▼            ▼            ▼
┌─────────┐  ┌─────────┐  ┌─────────┐
│ 机器 A  │  │ 机器 B  │  │ 机器 C  │
│OpenClaw │  │OpenClaw │  │OpenClaw │
│Gateway  │  │Gateway  │  │Gateway  │
└─────────┘  └─────────┘  └─────────┘
      │            │            │
      └────────────┼────────────┘
                   ▼
          ┌─────────────────┐
          │   结果汇总报告    │
          └─────────────────┘
```

## 配置说明

配置文件位置：`~/.openclaw/skills/multi-claw/config.json`

```json
{
  "machines": [
    {
      "name": "web-01",
      "host": "10.1.108.23",
      "port": 18789,
      "token": "your-token",
      "protocol": "http"
    }
  ]
}
```

## 远程机器配置要求

被控端需要允许 HTTP API 调用：

```json5
// ~/.openclaw/openclaw.json5
{
  gateway: {
    bind: "0.0.0.0",  // 允许外部连接
    auth: {
      token: "your-secret-token"
    },
    tools: {
      // 允许通过 HTTP 调用的工具
      allow: ["web_search", "web_fetch", "sessions_list"]
    }
  }
}
```

## 命令参考

| 命令 | 说明 |
|------|------|
| `multi-claw status` | 检查所有机器健康状态 |
| `multi-claw list` | 列出所有配置的机器 |
| `multi-claw run '命令' [机器名]` | 执行命令 |
| `multi-claw add 名称 主机 token [端口]` | 添加机器 |
| `multi-claw remove 名称` | 移除机器 |

## 限制说明

由于 OpenClaw 安全机制，以下工具默认不能通过 HTTP API 调用：
- `exec` - 执行命令
- `shell` - shell 执行
- `sessions_spawn` - 创建子代理
- `cron` - 定时任务

**解决方案：**
1. 在被控端配置中允许这些工具（`gateway.tools.allow`）
2. 使用 WebSocket 连接替代 HTTP
3. 使用 SSH 直接在被控端执行 OpenClaw 命令

## 进阶用法

### 集成到 OpenClaw Session

你可以在自己的 OpenClaw 中使用这个 skill：

```
使用 multi_claw_run 工具检查所有机器的状态
```

### 定时任务

结合 cron 定期执行检查：

```bash
# 每小时检查一次机器状态
0 * * * * /Users/wangxin/.openclaw/skills/multi-claw/multi-claw.sh status >> /var/log/multi-claw.log
```

## 故障排查

### 连接失败

1. 检查被控端 Gateway 是否运行：`openclaw gateway status`
2. 检查网络连通性：`ping <被控端IP>`
3. 检查防火墙：`ufw status` 或 `firewall-cmd --list-ports`

### 认证失败

1. 确认 token 一致
2. 检查被控端 `gateway.auth.token` 配置

### 工具不可用

被控端需要在 `gateway.tools.allow` 中允许相应工具

## 贡献

欢迎提交 PR 改进这个 skill！

## License

MIT
