# Multi-Claw

分布式 OpenClaw 控制技能，实现"一控多"架构，让你可以从一个中心 OpenClaw 控制多台远程 OpenClaw 实例。

## 功能特性

- 🤖 **多机器管理** - 集中管理多台远程 OpenClaw 配置
- 🚀 **批量执行** - 同时向所有机器发送命令
- ⚡ **并行处理** - 异步执行，提高效率
- 📊 **报告生成** - 自动汇总结果生成 Markdown 报告
- 🔍 **健康检查** - 实时监控所有机器在线状态
- 🔒 **安全认证** - 使用 Bearer Token 进行身份验证

## 安装

### 通过 Skills CLI 安装（推荐）

```bash
npx skills add wangxin/multi-claw
```

### 手动安装

```bash
# 克隆到 OpenClaw skills 目录
git clone https://github.com/wangxin/multi-claw.git ~/.openclaw/skills/multi-claw

# 确保脚本可执行
chmod +x ~/.openclaw/skills/multi-claw/multi-claw.sh
```

## 快速开始

### 1. 添加远程机器

```bash
multi-claw add "web-01" "192.168.1.10" "your-token-here"
multi-claw add "db-01" "192.168.1.11" "your-token-here" 18789
```

### 2. 检查状态

```bash
multi-claw status
```

输出示例：
```
🔍 检查所有机器状态...

✅ web-01 (192.168.1.10) - 在线
✅ db-01 (192.168.1.11) - 在线

统计: 2/2 台机器在线
```

### 3. 批量执行命令

```bash
multi-claw run "查看系统负载"
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

# 检查内存使用情况
multi-claw run "free -h"
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

# 检查服务状态
multi-claw run "systemctl status nginx"
```

## 命令参考

| 命令 | 说明 | 示例 |
|------|------|------|
| `multi-claw status` | 检查所有机器健康状态 | `multi-claw status` |
| `multi-claw list` | 列出所有配置的机器 | `multi-claw list` |
| `multi-claw run '命令' [机器名]` | 执行命令 | `multi-claw run "df -h"` |
| `multi-claw add 名称 主机 token [端口]` | 添加机器 | `multi-claw add web-01 192.168.1.10 token123` |
| `multi-claw remove 名称` | 移除机器 | `multi-claw remove web-01` |

## 配置说明

配置文件位置：`~/.openclaw/skills/multi-claw/config.json`

```json
{
  "machines": [
    {
      "name": "web-01",
      "host": "192.168.1.10",
      "port": 18789,
      "token": "your-secret-token",
      "protocol": "http"
    },
    {
      "name": "db-01",
      "host": "192.168.1.11",
      "port": 18789,
      "token": "your-secret-token",
      "protocol": "https"
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
    port: 18789,
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

启动 Gateway：
```bash
openclaw gateway run
# 或
openclaw gateway start
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

## 报告示例

```markdown
# 🦞 Multi-Claw 执行报告

## 任务概览

| 项目 | 内容 |
|------|------|
| **任务ID** | multi-claw-1712654400 |
| **执行命令** | 查看系统负载 |
| **执行时间** | 2026-04-09T17:00:00+08:00 |
| **目标机器** | 2 台 |
| **成功** | 2 台 |
| **失败** | 0 台 |
| **成功率** | 100% |

## 详细结果

### web-01
```json
{
  "ok": true,
  "result": {
    // 执行结果...
  }
}
```

### db-01
```json
{
  "ok": true,
  "result": {
    // 执行结果...
  }
}
```

---
*报告生成时间: Thu Apr 09 2026 17:00:00 GMT+0800*
```

## 安全建议

1. **使用 HTTPS** - 生产环境建议使用 HTTPS 加密通信
2. **强 Token** - 使用随机生成的强密码作为 token
3. **防火墙限制** - 限制只有控制端 IP 可以访问被控端 Gateway 端口
4. **定期轮换 Token** - 定期更新认证令牌
5. **配合 VPN/Tailscale** - 在私有网络中部署，避免直接暴露公网

## 故障排查

### 连接失败

1. 检查被控端 Gateway 是否运行：
   ```bash
   openclaw gateway status
   ```

2. 检查网络连通性：
   ```bash
   ping <被控端IP>
   ```

3. 检查防火墙：
   ```bash
   # Ubuntu/Debian
   ufw status
   ufw allow 18789/tcp

   # CentOS/RHEL
   firewall-cmd --list-ports
   firewall-cmd --add-port=18789/tcp --permanent
   firewall-cmd --reload
   ```

### 认证失败

1. 确认 token 一致
2. 检查被控端 `gateway.auth.token` 配置
3. 检查请求中是否正确携带 `Authorization: Bearer <token>` 头

### 工具不可用

被控端需要在 `gateway.tools.allow` 中允许相应工具。注意：出于安全考虑，`exec`、`shell`、`sessions_spawn` 等工具默认被禁用。

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
0 * * * * /Users/wangxin/.openclaw/skills/multi-claw/multi-claw.sh status >> /var/log/multi-claw.log 2>&1
```

### 批量添加机器

```bash
# 从文件批量导入
while read name host token; do
  multi-claw add "$name" "$host" "$token"
done < machines.txt
```

## 开发计划

- [ ] WebSocket 支持 - 实时双向通信
- [ ] 文件传输 - 向多台机器分发文件
- [ ] 结果回调 - 异步任务完成后通知
- [ ] Web UI - 可视化管理和监控
- [ ] 任务队列 - 支持大规模批处理

## 贡献

欢迎提交 Issue 和 PR！

1. Fork 仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## License

MIT License - 详见 [LICENSE](LICENSE) 文件

## 作者

**wangxin** - [GitHub](https://github.com/wangxin)

## 致谢

感谢 OpenClaw 团队提供的优秀平台！
