#!/bin/bash
set -e
echo "==> KL Skills 安装脚本"
echo "==> Clone 仓库到: ~/.codebuddy/kl-skills-repo"
echo "==> 安装 skills 到: ~/.codebuddy/skills"

SKILLS_DIR="$HOME/.codebuddy/skills"
REPO_DIR="$HOME/.codebuddy/kl-skills-repo"

mkdir -p "$SKILLS_DIR"

cd "$(dirname "$0")"
REPO_SRC="$(pwd)"

cp -r "$REPO_SRC/ekp-price-review" "$SKILLS_DIR/" && echo "    已安装: ekp-price-review"
cp -r "$REPO_SRC/ekp-order-prod-status" "$SKILLS_DIR/" && echo "    已安装: ekp-order-prod-status"
cp -r "$REPO_SRC/loan-interest-calc" "$SKILLS_DIR/" && echo "    已安装: loan-interest-calc"
cp -r "$REPO_SRC/ekp-add-config" "$SKILLS_DIR/" && echo "    已安装: ekp-add-config"
cp -r "$REPO_SRC/ekp-flow-search" "$SKILLS_DIR/" && echo "    已安装: ekp-flow-search"
cp -r "$REPO_SRC/pdf-text-replace" "$SKILLS_DIR/" && echo "    已安装: pdf-text-replace"
cp -r "$REPO_SRC/ekp-login" "$SKILLS_DIR/" && echo "    已安装: ekp-login"

echo "==> 安装完成！已安装的 skills:"
ls "$SKILLS_DIR" | grep -v README
