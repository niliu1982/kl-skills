---
name: ekp-price-review
description: |
  金龙客车 EKP 系统价格评审自动填写技能。当用户在 EKP 系统中打开价格评审页面，
  需要根据参考核价数据匹配并填写配置项价格时使用。触发词：价格评审、核价、EKP填写、
  配置价格、klPriceReview。依赖 agent-browser 进行浏览器自动化，
  依赖 ima-mcp 读取参考核价数据。
agent_created: true
---

# EKP 价格评审自动填写

## 概述

在金龙客车 EKP 系统中打开价格评审页面后，自动从 ima 知识库中搜索同车型参考核价数据，
匹配配置项并填写价格，最后保存。由于价格评审表单在 iframe 中加载，
浏览器自动化工具的常规选择器（ref、CSS）对 iframe 内容失效，
因此核心方案是使用 `agent-browser eval` 执行 JavaScript 直接操作 DOM。

**注意**：浏览器会话在任务间保持打开，避免重复登录开销。
执行前会自动检查登录状态，已登录则跳过登录步骤。
任务完成后浏览器保持开启，以便下一个任务直接复用。

## 前置条件

1. EKP 登录凭据存储在项目 `.workbuddy/memory/MEMORY.md` 中（用户名、密码、登录地址）
2. ima 知识库中已有同车型参考核价数据（Excel/网页）
3. `agent-browser` 可用

## 工作流程

### 步骤 1：检查登录状态并登录

登录流程优先复用已有会话，避免重复输入密码。

#### 1a. 检查当前状态

首先执行 snapshot 检查浏览器当前是否已在 EKP 系统中且处于登录状态：

```
agent-browser snapshot
```

**判断规则**：
- 页面内容包含"欢迎您" → ✅ 已登录，**直接跳到步骤 2**
- 页面显示的是登录页 → ❌ 未登录，执行 1b 登录流程
- 当前不在 EKP 站点（如空白页、其他网站） → 导航到门户页进一步检测：
  ```
  agent-browser open "https://ekp.king-long.com.cn/sys/portal/page.jsp"
  agent-browser wait --load networkidle
  agent-browser snapshot
  ```
  - 跳转到门户页且显示"欢迎您" → ✅ 已登录，跳到步骤 2
  - 被重定向到登录页 → ❌ 未登录，执行 1b 登录流程

#### 1b. 执行登录（仅在未登录时执行）

从项目 MEMORY.md 读取登录凭据，打开登录页面并填写：

```
agent-browser open "https://ekp.king-long.com.cn/login.jsp"
agent-browser wait --load networkidle
agent-browser type "input[placeholder='用户名']" "<username>"
agent-browser type "input[placeholder='密码']" "<password>"
agent-browser press "Enter"
agent-browser wait --load networkidle
```

登录后通过 snapshot 确认出现"欢迎您"文字。如遇验证码，截图发给用户手动输入。

### 步骤 2：导航到价格评审页面

```
agent-browser open "<价格评审页面URL>"
agent-browser wait --load networkidle
```

价格评审页面 URL 格式：
`https://ekp.king-long.com.cn/kl/price/kl_price_review/klPriceReview.do?method=view&fdId=<fdId>&fdTaskInstanceId=<taskInstanceId>`

### 步骤 3：提取配置列表

使用 `agent-browser eval` 提取页面上所有 `input[type=text]` 元素，
筛选配置项和配置信息。配置表结构为每行：
`[配置项] [配置信息] [价格(万)] [标配价格] [指定件价格] [周期]`

```javascript
// 提取所有文本输入框
agent-browser eval "
Array.from(document.querySelectorAll('input[type=text]')).map(function(i, idx) {
  return idx + ': ' + i.value;
}).join('\\n')
"
```

重点关注值为"0.0"的输入框——这些是待填写的价格字段，
其前一个 input 是该行的配置信息文本。

### 步骤 4：从 ima 获取参考核价数据

搜索 ima 知识库中同车型的核价 Excel：

```
ima-mcp__search_knowledge <knowledge_base_id> <车型关键词+核价>
```

读取匹配的 Excel 文件内容：
```
ima-mcp__fetch_media_content <excel_media_id>
```

同一车型可能有多个订单的核价数据，尽量合并参考。

### 步骤 5：匹配并填写价格

核心逻辑：遍历所有 `input[type=text]`，
将每个 input 的值与参考价格 Map 的 key（配置信息文本）做精确匹配。
匹配成功时，下一个 input（index+1）即为该配置的价格字段，写入参考价格。

构建价格映射表（单位：万元）：

```javascript
agent-browser eval "
(function() {
  var allInputs = Array.from(document.querySelectorAll('input[type=text]'));
  var priceMap = {
    '有AEBS': '0.35',
    '大为电涡流缓速器/TB17B/1700N.m': '0.02',
    '油箱仓贯通+加装前立面中间部位封板': '0.01',
    '佳通10R22.5真空胎': '0.03',
    '有(发动机和加热器的油路及滤芯加热)': '0.28',
    '整车流水槽': '0.065',
    '司机椅': '0.02',
    '双幅手动剪刀式前挡遮阳帘': '0.012',
    '南风380W外循环除霜机': '0.04',
    '有司机椅处散热器(电机两档)': '0.03',
    '有前门踏步散热器(电机两档)': '0.03',
    '电子蜗牛喇叭+气喇叭': '0.02',
    '有智能视频监控报警装置DSM': '0.06',
    '整车隔热降噪(标配件+乘客区下加棉)': '0.08',
    '乘客座椅靠背后刺绣\\"请系好安全带\\"': '0.08'
  };

  var results = [];
  for (var i = 0; i < allInputs.length; i++) {
    var val = allInputs[i].value;
    if (priceMap[val]) {
      var priceInput = allInputs[i + 1];
      if (priceInput) {
        priceInput.value = priceMap[val];
        priceInput.dispatchEvent(new Event('input', { bubbles: true }));
        priceInput.dispatchEvent(new Event('change', { bubbles: true }));
        results.push(val + ' -> ' + priceMap[val]);
      }
    }
  }
  return results;
})()
"
```

**重要提示**：
- 配置信息文本必须完全一致才能匹配（注意中文标点、换行符差异）
- 填写后触发 `input` 和 `change` 事件确保页面状态同步
- 未匹配的配置项不填，保持原值
- 不同订单的配置文本可能有细微差异，需要对比实际页面内容调整 priceMap

### 步骤 6：保存

```javascript
agent-browser eval "
(function() {
  var btns = document.querySelectorAll('.lui_widget_btn_txt');
  for (var i = 0; i < btns.length; i++) {
    if (btns[i].textContent.trim() === '保存') {
      btns[i].click();
      return 'Save button clicked!';
    }
  }
  return 'Save button not found';
})()
"
```

保存成功后等待 3 秒，然后 snapshot 检查是否有错误提示或成功提示。

### 步骤 7：记录操作

**保持浏览器打开，不要关闭。** 浏览器会话将留待下一个任务直接复用。

将本次操作记录到 `.workbuddy/memory/YYYY-MM-DD.md`：

- 订单编号
- 车型/数量/客户
- 已填写的配置项及价格
- 未匹配的配置项
- 保存结果

## 常见问题

### 登录出现验证码
多次登录失败后会触发验证码。用 `agent-browser screenshot` 截图发给用户，
让用户手动输入验证码后再继续。

### iframe 内元素选择器失效
agent-browser 的 ref 选择器和 CSS 选择器对 iframe 内的元素无效，
**必须使用 `agent-browser eval` 通过 JavaScript 直接操作**。

### 价格字段位置变化
不同 EKP 版本/页面布局下，价格 input 可能在配置信息 input 的 index+1 或 index+2。
用 eval 先打印 input 列表确认结构后再填写。

### 配置文本匹配失败
参考核价数据中的配置描述与实际页面上的文本可能有差异。
如果匹配结果少于预期，打印全部 input 值与参考价格 key 对比，手动调整 priceMap。

## 参考

- 详细的 DOM 结构分析和匹配策略见 `references/dom_and_matching.md`
- EKP 登录凭据：从项目 `.workbuddy/memory/MEMORY.md` 读取
