---
name: ekp-login
description: |
  EKP 系统自动登录。检查当前浏览器会话的 EKP 登录状态，
  未登录时使用存储的凭据自动登录，支持 agent-browser 和 playwright-cli 两种浏览器后端。
  触发词：登录、登陆、EKPLogin、ekp登录
agent_created: true
---

# EKP 自动登录

## 前提

- EKP 凭据已存储（首次使用时会引导配置）
- agent-browser 或 playwright-cli 可用

## 凭据管理

凭据优先级：环境变量 > 配置文件

```bash
# 环境变量（临时）
export EKP_USERNAME="wangqy"
export EKP_PASSWORD="xxx"

# 配置文件（持久，推荐）
echo "wangqy" > ~/.config/ekp/username
echo "xxx" > ~/.config/ekp/password
```

首次运行无凭据时会提示用户配置。

## 工作流程

### 选择浏览器后端

- **agent-browser**：性能更优，等待时间短，snapshot/eval 功能强
- **playwright-cli**：run-code 灵活，需自行管理 context（cert bypass 用 `newContext({ ignoreHTTPSErrors: true })`）

默认使用 agent-browser。如已在使用 playwright-cli，沿用当前后端。

### 步骤 1：读取凭据

```bash
EKP_USER="${EKP_USERNAME:-$(cat ~/.config/ekp/username 2>/dev/null)}"
EKP_PASS="${EKP_PASSWORD:-$(cat ~/.config/ekp/password 2>/dev/null)}"

if [ -z "$EKP_USER" ] || [ -z "$EKP_PASS" ]; then
  echo "请先配置 EKP 凭据：echo '用户名' > ~/.config/ekp/username && echo '密码' > ~/.config/ekp/password"
  exit 1
fi
```

### 步骤 2：检查登录状态

**agent-browser 方式：**

```bash
agent-browser open "https://ekp.king-long.com.cn/sys/portal/page.jsp" --ignore-https-errors
agent-browser wait --load networkidle
agent-browser snapshot
```

- 包含"欢迎您" → ✅ 已登录，跳过登录
- 显示登录页 → ❌ 执行步骤 3

**playwright-cli 方式（需在 run-code 内执行）：**

```javascript
await page.goto("https://ekp.king-long.com.cn/sys/portal/page.jsp", { waitUntil: "load" });
const body = await page.evaluate(() => document.body.innerText);
if (body.includes("欢迎您")) return "already_logged_in";
```

### 步骤 3：执行登录

**agent-browser 方式：**

```bash
agent-browser open "https://ekp.king-long.com.cn/login.jsp" --ignore-https-errors
agent-browser wait --load networkidle
agent-browser snapshot  # 确认在登录页

# 填写并提交
agent-browser type "input[placeholder='用户名']" "$EKP_USER"
agent-browser type "input[placeholder='密码']" "$EKP_PASS"
agent-browser press "Enter"
agent-browser wait --load networkidle
agent-browser snapshot  # 确认出现"欢迎您"
```

**playwright-cli 方式（run-code 内）：**

```javascript
const browser = page.context().browser();
const ctx = await browser.newContext({ ignoreHTTPSErrors: true });
const p = await ctx.newPage();
await p.goto("https://ekp.king-long.com.cn/login.jsp", { waitUntil: "load", timeout: 60000 });
await p.fill("input[placeholder='用户名']", USERNAME);
await p.fill("input[placeholder='密码']", PASSWORD);
await p.click("a:has-text('登录')");
await p.waitForTimeout(5000);
const body = await p.evaluate(() => document.body.innerText);
if (!body.includes("欢迎您")) return "login_failed";
return "login_ok";
```

### 步骤 4：验证

登录后 snapshot 检查页面是否包含"欢迎您"。如出现验证码，截图让用户手动输入。

## 常见问题

### 证书错误
- agent-browser：启动时加 `--ignore-https-errors` 或设 `AGENT_BROWSER_IGNORE_HTTPS_ERRORS=true`
- playwright-cli：`newContext({ ignoreHTTPSErrors: true })`

### 浏览器会话保持
登录后的 cookie 在浏览器会话中保持。同一个 agent-browser daemon 下所有后续请求共享登录状态。
daemon 重启后需重新登录。

### 验证码
多次登录失败后触发。截图发给用户手动输入：
```bash
agent-browser screenshot /tmp/ekp_captcha.png
# 展示截图，等用户输入验证码
```

## 与其它 skill 的协作

其他 EKP skill（ekp-price-review、ekp-order-prod-status、ekp-flow-search）在第一步骤都应先调用本 skill 的登录检查逻辑：

```
1. 尝试导航到 portal 页检查登录状态
2. 已登录 → 直接跳到业务步骤
3. 未登录 → 执行登录流程
```

这样避免每个 skill 重复实现登录逻辑。
