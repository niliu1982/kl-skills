#!/usr/bin/env bash
# install.sh — KL Skills 一键安装脚本
# 用法: bash <(curl -s https://raw.githubusercontent.com/niliu1982/kl-skills/main/install.sh)

set -e

REPO_URL="https://github.com/niliu1982/kl-skills.git"
SKILLS_DIR="/root/.codebuddy/skills"
REPO_DIR="/root/.codebuddy/kl-skills-repo"

echo "==> KL Skills 安装脚本"

# 1. Clone 或更新仓库
if [ -d "$REPO_DIR" ]; then
  echo "==> 更新已有仓库: $REPO_DIR"
  cd "$REPO_DIR" && git pull
else
  echo "==> Clone 仓库到: $REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
fi

# 2. 复制所有 skills 到 codebuddy skills 目录
echo "==> 安装 skills 到: $SKILLS_DIR"
for skill in ekp-price-review ekp-order-prod-status loan-interest-calc ekp-add-config; do
  if [ -d "$REPO_DIR/$skill" ]; then
    cp -r "$REPO_DIR/$skill" "$SKILLS_DIR/"
    echo "    已安装: $skill"
  else
    echo "    警告: $skill 目录不存在，跳过"
  fi
done

echo "==> 安装完成！已安装的 skills:"
ls "$SKILLS_DIR/"
