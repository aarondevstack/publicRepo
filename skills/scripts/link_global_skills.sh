#!/bin/bash

# 初始化变量
CENTRAL_SKILLS_DIR=""
SKILLS_TO_SYNC=()

# 1. 解析命令行参数
while getopts "p:s:" opt; do
  case $opt in
    p) CENTRAL_SKILLS_DIR="$OPTARG" ;;
    s) IFS=',' read -r -a SKILLS_TO_SYNC <<< "$OPTARG" ;;
    *) echo "用法: $0 -p <GitHub仓库路径> [-s 技能1,技能2,...]"; exit 1 ;;
  esac
done

# --- 强制校验 -p 参数 ---
if [ -z "$CENTRAL_SKILLS_DIR" ]; then
    echo "错误: 必须使用 -p 参数指定 GitHub 仓库路径。"
    exit 1
fi

# --- 路径标准化 ---
if [ -d "$CENTRAL_SKILLS_DIR" ]; then
    CENTRAL_SKILLS_DIR=$(cd "$CENTRAL_SKILLS_DIR"; pwd)
else
    echo "错误: 路径 $CENTRAL_SKILLS_DIR 不存在。"
    exit 1
fi

# --- 修正：交互式确认全量同步 ---
if [ ${#SKILLS_TO_SYNC[@]} -eq 0 ]; then
    echo "提示: 未指定特定的技能名称 (-s)。"
    read -p "是否要软链接路径 [$CENTRAL_SKILLS_DIR] 下的全部技能？(y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "操作已取消。"
        exit 0
    fi
fi

# 2. 定义各Agent全局目标路径
AGENT_PATHS=(
    "$HOME/.gemini/antigravity/global_skills"
    "$HOME/.codex/skills"
    "$HOME/.config/opencode/skills"
    # "$HOME/.claude/skills"
    # "$HOME/.cursor/skills"
)

# 3. 确定最终要处理的文件夹
FINAL_SKILLS=()
if [ ${#SKILLS_TO_SYNC[@]} -eq 0 ]; then
    for dir in "$CENTRAL_SKILLS_DIR"/*; do
        [ -d "$dir" ] && FINAL_SKILLS+=("$(basename "$dir")")
    done
else
    FINAL_SKILLS=("${SKILLS_TO_SYNC[@]}")
fi

echo "--- 开始同步过程 ---"

# 4. 执行符号链接逻辑
for skill_name in "${FINAL_SKILLS[@]}"; do
    skill_source="$CENTRAL_SKILLS_DIR/$skill_name"

    if [ ! -d "$skill_source" ]; then
        echo "警告: 技能目录不存在，跳过 [$skill_name]"
        continue
    fi

    echo "正在处理: $skill_name"
    
    for agent_dir in "${AGENT_PATHS[@]}"; do
        mkdir -p "$agent_dir"
        target_link="$agent_dir/$skill_name"

        if [ -L "$target_link" ] || [ -e "$target_link" ]; then
            echo "  - 已存在: $agent_dir"
        else
            ln -s "$skill_source" "$target_link"
            echo "  - 已链接: $agent_dir"
        fi
    done
done

echo "--- 同步完成 ---"