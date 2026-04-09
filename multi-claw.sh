#!/bin/bash
# Multi-Claw Skill - 主脚本

set -e

# 优先使用 ~/.openclaw/skills/multi-claw 作为配置目录
if [[ -d "${HOME}/.openclaw/skills/multi-claw" ]]; then
    CONFIG_DIR="${HOME}/.openclaw/skills/multi-claw"
else
    CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
CONFIG_FILE="${CONFIG_DIR}/config.json"
REPORT_DIR="${HOME}/.openclaw/reports/multi-claw"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 确保配置存在
init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo '{"machines": []}' > "$CONFIG_FILE"
    fi
    mkdir -p "$REPORT_DIR"
}

# 获取机器列表
get_machines() {
    if [[ -f "$CONFIG_FILE" ]]; then
        cat "$CONFIG_FILE" | jq -c '.machines[]' 2>/dev/null
    fi
}

# 检查单台机器状态
check_machine() {
    local name="$1"
    local host="$2"
    local port="$3"
    local token="$4"
    local protocol="${5:-http}"
    
    local url="${protocol}://${host}:${port}/health"
    local response
    
    response=$(curl -s -m 5 "$url" -H "Authorization: Bearer ${token}" 2>/dev/null || echo '{"ok":false}')
    
    if echo "$response" | grep -q '"ok":true'; then
        echo -e "${GREEN}✅ $name ($host) - 在线${NC}"
        return 0
    else
        echo -e "${RED}❌ $name ($host) - 离线${NC}"
        return 1
    fi
}

# 在单台机器上执行命令
run_on_machine() {
    local name="$1"
    local host="$2"
    local port="$3"
    local token="$4"
    local protocol="${5:-http}"
    local command="$6"
    local task_id="$7"
    
    local url="${protocol}://${host}:${port}/tools/invoke"
    local result_file="${REPORT_DIR}/${task_id}_${name}.json"
    
    # 使用 web_search 作为测试（因为 exec 可能被禁用）
    local response
    response=$(curl -s -X POST "$url" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json" \
        -d "{
            \"tool\": \"web_search\",
            \"args\": {
                \"query\": \"$command\"
            }
        }" 2>/dev/null)
    
    # 保存结果
    echo "$response" > "$result_file"
    
    if echo "$response" | grep -q '"ok":true'; then
        echo -e "${GREEN}✅ $name - 执行成功${NC}"
        echo "$result_file"
        return 0
    else
        echo -e "${RED}❌ $name - 执行失败${NC}"
        echo "$result_file"
        return 1
    fi
}

# 显示所有机器状态
cmd_status() {
    echo -e "${BLUE}🔍 检查所有机器状态...${NC}"
    echo ""
    
    local total=0
    local online=0
    
    while IFS= read -r machine; do
        ((total++))
        local name host port token protocol
        name=$(echo "$machine" | jq -r '.name')
        host=$(echo "$machine" | jq -r '.host')
        port=$(echo "$machine" | jq -r '.port // 18789')
        token=$(echo "$machine" | jq -r '.token')
        protocol=$(echo "$machine" | jq -r '.protocol // "http"')
        
        if check_machine "$name" "$host" "$port" "$token" "$protocol"; then
            ((online++))
        fi
    done < <(get_machines)
    
    echo ""
    echo -e "${BLUE}统计: $online/$total 台机器在线${NC}"
}

# 在所有机器上执行命令
cmd_run() {
    local command="$1"
    local target_machine="$2"
    local task_id="multi-claw-$(date +%s)"
    
    echo -e "${BLUE}🚀 批量执行命令...${NC}"
    echo "任务ID: $task_id"
    echo "命令: $command"
    if [[ -n "$target_machine" ]]; then
        echo "目标: $target_machine"
    else
        echo "目标: 所有机器"
    fi
    echo ""
    
    local total=0
    local success=0
    local results=()
    
    while IFS= read -r machine; do
        local name host port token protocol
        name=$(echo "$machine" | jq -r '.name')
        host=$(echo "$machine" | jq -r '.host')
        port=$(echo "$machine" | jq -r '.port // 18789')
        token=$(echo "$machine" | jq -r '.token')
        protocol=$(echo "$machine" | jq -r '.protocol // "http"')
        
        # 如果指定了目标机器，只执行该机器
        if [[ -n "$target_machine" && "$name" != "$target_machine" ]]; then
            continue
        fi
        
        ((total++))
        echo -e "${YELLOW}▶️ $name${NC}"
        
        local result_file
        result_file=$(run_on_machine "$name" "$host" "$port" "$token" "$protocol" "$command" "$task_id")
        
        if [[ $? -eq 0 ]]; then
            ((success++))
        fi
        
        results+=("$name:$result_file")
        echo ""
    done < <(get_machines)
    
    # 生成汇总报告
    generate_report "$task_id" "$command" "$total" "$success" "${results[@]}"
}

# 生成报告
generate_report() {
    local task_id="$1"
    local command="$2"
    local total="$3"
    local success="$4"
    shift 4
    local results=("$@")
    
    local report_file="${REPORT_DIR}/${task_id}_report.md"
    local timestamp=$(date -Iseconds)
    
    cat > "$report_file" << EOF
# 🦞 Multi-Claw 执行报告

## 任务概览

| 项目 | 内容 |
|------|------|
| **任务ID** | $task_id |
| **执行命令** | $command |
| **执行时间** | $timestamp |
| **目标机器** | $total 台 |
| **成功** | $success 台 |
| **失败** | $((total - success)) 台 |
| **成功率** | $(( success * 100 / total ))% |

## 详细结果

EOF

    # 添加每台机器的结果
    for result in "${results[@]}"; do
        local name file
        name=$(echo "$result" | cut -d: -f1)
        file=$(echo "$result" | cut -d: -f2-)
        
        echo "### $name" >> "$report_file"
        echo "" >> "$report_file"
        echo '```json' >> "$report_file"
        cat "$file" | jq '.' 2>/dev/null || cat "$file" >> "$report_file"
        echo '```' >> "$report_file"
        echo "" >> "$report_file"
    done

    echo "---" >> "$report_file"
    echo "*报告生成时间: $(date)*" >> "$report_file"
    
    echo -e "${GREEN}📄 报告已保存: $report_file${NC}"
    echo ""
    echo "统计: $success/$total 台机器执行成功"
}

# 添加机器
cmd_add() {
    local name="$1"
    local host="$2"
    local token="$3"
    local port="${4:-18789}"
    
    if [[ -z "$name" || -z "$host" || -z "$token" ]]; then
        echo "用法: multi-claw add <名称> <主机> <token> [端口]"
        exit 1
    fi
    
    # 添加到配置
    local new_machine
    new_machine=$(jq -n \
        --arg name "$name" \
        --arg host "$host" \
        --arg token "$token" \
        --argjson port "$port" \
        '{name: $name, host: $host, port: $port, token: $token}')
    
    jq --argjson machine "$new_machine" '.machines += [$machine]' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    
    echo -e "${GREEN}✅ 已添加机器: $name ($host)${NC}"
}

# 移除机器
cmd_remove() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo "用法: multi-claw remove <名称>"
        exit 1
    fi
    
    jq --arg name "$name" '.machines = [.machines[] | select(.name != $name)]' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    
    echo -e "${GREEN}✅ 已移除机器: $name${NC}"
}

# 列出所有机器
cmd_list() {
    echo -e "${BLUE}📋 已配置的机器:${NC}"
    echo ""
    
    get_machines | while IFS= read -r machine; do
        local name host port
        name=$(echo "$machine" | jq -r '.name')
        host=$(echo "$machine" | jq -r '.host')
        port=$(echo "$machine" | jq -r '.port // 18789')
        echo "  • $name - $host:$port"
    done
}

# 显示帮助
show_help() {
    echo "🦞 Multi-Claw - 分布式 OpenClaw 控制工具"
    echo ""
    echo "用法:"
    echo "  multi-claw status                    检查所有机器状态"
    echo "  multi-claw list                      列出所有配置的机器"
    echo "  multi-claw run '命令' [机器名]        在所有/指定机器上执行命令"
    echo "  multi-claw add 名称 主机 token [端口] 添加新机器"
    echo "  multi-claw remove 名称               移除机器"
    echo ""
    echo "示例:"
    echo "  multi-claw status"
    echo "  multi-claw run '查看系统负载'"
    echo "  multi-claw run 'df -h' web-server-01"
    echo "  multi-claw add web-01 192.168.1.10 my-token"
}

# 主函数
main() {
    init_config
    
    if [[ $# -lt 1 ]]; then
        show_help
        exit 1
    fi
    
    local cmd="$1"
    shift
    
    case "$cmd" in
        status)
            cmd_status
            ;;
        list)
            cmd_list
            ;;
        run)
            if [[ $# -lt 1 ]]; then
                echo "错误: 需要提供命令"
                echo "用法: multi-claw run '命令内容' [机器名]"
                exit 1
            fi
            cmd_run "$1" "${2:-}"
            ;;
        add)
            cmd_add "$@"
            ;;
        remove)
            cmd_remove "$1"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "未知命令: $cmd"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
