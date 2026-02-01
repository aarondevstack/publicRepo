#!/bin/bash

# 需要删除的技能数组
SKILLS_TO_UNLINK=()

# 1. 解析命令行参数
while getopts "s:" opt; do
  case $opt in
    s) IFS=',' read -r -a SKILLS_TO_UNLINK <<< "$OPTARG" ;;
    *) echo "用法: $0 [-s 技能1,技能2,...]"; exit 1 ;;
  esac
done

# 2. 定义各 Agent 目标路径
AGENT_PATHS=(
    "$HOME/.gemini/antigravity/global_skills"
    "$HOME/.codex/skills"
    "$HOME/.config/opencode/skills"
    # "$HOME/.claude/skills"
)

echo "--- 开始清理过程 ---"

# 3. 执行删除逻辑
for agent_dir in "${AGENT_PATHS[@]}"; do
    if [ ! -d "$agent_dir" ]; then
        echo "跳过不存在的目录: $agent_dir"
        continue
    fi

    echo "正在检查目录: $agent_dir"

    if [ ${#SKILLS_TO_UNLINK[@]} -eq 0 ]; then
        # 场景 A：未指定参数，清理该目录下所有的符号链接
        echo "  - 未指定技能，正在清理所有符号链接..."
        find "$agent_dir" -type l -delete
        echo "  - $agent_dir 内的符号链接已全部移除。"
    else
        # 场景 B：删除指定的技能链接
        for skill_name in "${SKILLS_TO_UNLINK[@]}"; do
            target_link="$agent_dir/$skill_name"
            if [ -L "$target_link" ]; then
                rm "$target_link"
                echo "  - 已删除链接: $skill_name"
            elif [ -e "$target_link" ] && [ ! -L "$target_link" ]; then
                echo "  - 警告: $skill_name 是真实文件/目录而非链接，已跳过以防误删。"
            fi
        done
    fi
done

echo "--- 清理完成 ---"