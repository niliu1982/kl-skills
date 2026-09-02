#!/bin/bash
set -e

REPO_URL="https://github.com/niliu1982/kl-skills.git"
SKILLS_DIR="$HOME/.codebuddy/skills"
REPO_DIR="$HOME/.codebuddy/kl-skills-repo"
SKILLS=(ekp-price-review ekp-order-prod-status loan-interest-calc ekp-add-config ekp-flow-search pdf-text-replace ekp-login)

echo "==> KL Skills 安装脚本"
echo "==> 安装 skills 到: $SKILLS_DIR"

# 定位仓库源：脚本若在仓库目录内运行则直接使用，否则 clone/更新
SRC_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)"
if [ -f "$SRC_DIR/install.sh" ] && [ -d "$SRC_DIR/${SKILLS[0]}" ]; then
    echo "==> 检测到本地仓库: $SRC_DIR"
else
    if [ -d "$REPO_DIR/.git" ]; then
        echo "==> 本地仓库已存在，尝试更新: $REPO_DIR"
        git -C "$REPO_DIR" pull --ff-only 2>/dev/null || echo "    更新失败，使用现有版本"
    else
        echo "==> Clone 仓库到: $REPO_DIR"
        rm -rf "$REPO_DIR"
        git clone --depth 1 "$REPO_URL" "$REPO_DIR"
    fi
    SRC_DIR="$REPO_DIR"
fi

mkdir -p "$SKILLS_DIR"

INSTALLED=()
for s in "${SKILLS[@]}"; do
    if [ -d "$SRC_DIR/$s" ]; then
        rm -rf "$SKILLS_DIR/$s"
        cp -r "$SRC_DIR/$s" "$SKILLS_DIR/" && INSTALLED+=("$s") && echo "    已安装: $s"
    else
        echo "    [跳过] 仓库中不存在: $s"
    fi
done

echo "==> 安装完成！本次共安装 ${#INSTALLED[@]} 个 skills:"
printf '    - %s\n' "${INSTALLED[@]}"
