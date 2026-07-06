---
name: ekp-order-prod-status
description: |
  金龙客车 EKP 系统订单投产状态查询。根据订单号查询订单流转信息和车辆生产状态
  （计划投产日期、投产日期、入库日期等）。触发词：投产、生产状态、订单进度、
  查询订单、订单流转、prodStatus。依赖 agent-browser 进行浏览器自动化。
agent_created: true
---

# EKP 订单投产状态查询

## 概述

在 EKP 系统中输入订单号，查询该订单的流转信息和车辆生产状态，
包括各时间节点和计划投产/实际投产/入库等信息。

**前提**：已登录 EKP，浏览器会话保持打开。

## 工作流程

### 步骤 1：导航到订单周期搜索页

```
agent-browser open "https://ekp.king-long.com.cn/kl/gnorder/#j_path=%2Fkl_gnorder_main_cycle_search"
agent-browser wait --load networkidle
```

### 步骤 2：在 iframe 中搜索订单

搜索表单在 iframe 内，需用 `agent-browser eval` 操作 DOM。

```javascript
agent-browser eval "
(function() {
  var iframe = document.querySelector('iframe');
  var doc = iframe.contentDocument || iframe.contentWindow.document;
  var inputs = doc.querySelectorAll('input[type=text]');
  for (var i = 0; i < inputs.length; i++) {
    if (inputs[i].name === 'fdOrderNo') {
      inputs[i].value = '<订单号>';
      break;
    }
  }
  var links = doc.querySelectorAll('a');
  for (var i = 0; i < links.length; i++) {
    if (links[i].textContent.trim() === '查询') {
      links[i].click();
      return 'Search submitted';
    }
  }
  return 'Search button not found';
})()
"
```

等待结果加载：

```
agent-browser wait --load networkidle
```

### 步骤 3：提取投产详情 URL

搜索结果每行是一个 `<tr>`，带有 `kmss_href` 属性指向投产状态页面：

```javascript
agent-browser eval "
(function() {
  var iframe = document.querySelector('iframe');
  var doc = iframe.contentDocument || iframe.contentWindow.document;
  var cells = doc.querySelectorAll('td');
  for (var i = 0; i < cells.length; i++) {
    if (cells[i].innerHTML.trim() === '<订单号>') {
      var tr = cells[i].closest('tr');
      var href = tr.getAttribute('kmss_href');
      return href ? href : 'No kmss_href found';
    }
  }
  return 'Order not found in results';
})()
"
```

### 步骤 4：打开投产状态页面

```
agent-browser open "https://ekp.king-long.com.cn<步骤3返回的kmss_href路径>"
agent-browser wait --load networkidle
agent-browser snapshot
```

### 步骤 5：解析投产信息

Snapshot 包含两部分：

1. **订单流转信息**：订单号、合同号、车型、车号、订单状态、流转状态，以及各时间节点（转准确定时间、转确定时间、技术完成时间、导入 SAP 时间）

2. **车辆生产状态表**：
   - 生产状态（计划投产/投产/入库等）
   - 计划投产日期
   - 投产日期
   - 入库日期
   - 提车/送车时间

## 注意事项

- 搜索结果仅有一行时，可直接取 `kmss_href` 导航；多行时需匹配对应车号
- `kmss_href` 属性是 EKP 框架自定义属性，标准 click 不会触发，需直接导航到其值
- 浏览器会话保持，查询完成后无需关闭
