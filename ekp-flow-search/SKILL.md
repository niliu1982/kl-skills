---
name: ekp-flow-search
description: |
  金龙客车 EKP 订单流程搜索（二期数据）。通过常用查询→订单搜索，查询订单各流程节点状态。
  触发词：流程节点、订单流程、flow、二期搜索、订单搜索。
  与 ekp-order-prod-status 的区别：本技能查询流程节点（审批/SAP/MES/入库等），
  后者查询车辆生产状态（投产/入库日期）。
agent_created: true
---

# EKP 订单流程搜索

## 与 ekp-order-prod-status 的区别

| | ekp-flow-search | ekp-order-prod-status |
|---|---|---|
| 入口 | 常用查询→订单搜索 | 订单周期搜索 |
| 查询内容 | 流��节点状态（审批/SAP/MES/入库） | 车辆生产状态（投产/入库日期） |
| 适合场景 | 快速了解订单整体流转状态 | 查看每台车具体投产计划 |

## 前提

- 已登录 EKP
- agent-browser 可用

## 工作流程

### 步骤 1：导航到订单搜索页

直接 URL 导航（推荐，绕过菜单点击）：

```
agent-browser open "https://ekp.king-long.com.cn/kl/gnorder/kl_gnorder_main/klGnordertwoMain_search.jsp?j_iframe=true&j_aside=false"
```

备选：通过菜单导航

```
1. 首页 → 点击"常用查询"展开
2. 点击"订单搜索"
```

### 步骤 2：清空日期 + 输入订单号 + 搜索

```bash
agent-browser eval "
(function() {
  var inputs = document.querySelectorAll('input[type=text]');
  // 1. 清空所有日期字段（格式 YYYY-MM-DD）
  for (var i = 0; i < inputs.length; i++) {
    if (inputs[i].value && inputs[i].value.match(/^\d{4}-\d{2}-\d{2}/)) {
      inputs[i].value = '';
      inputs[i].dispatchEvent(new Event('input',{bubbles:true}));
    }
  }
  // 2. 填入订单号
  for (var i = 0; i < inputs.length; i++) {
    var name = inputs[i].name || '';
    if (name.indexOf('OrderNo') >= 0 || inputs[i].placeholder.indexOf('订单号') >= 0) {
      inputs[i].value = '<订单号>';
      inputs[i].dispatchEvent(new Event('input',{bubbles:true}));
      break;
    }
  }
  // 如果订单号已在 textbox 中，直接修改
  for (var i = 0; i < inputs.length; i++) {
    if (inputs[i].value && inputs[i].value.indexOf('NL') === 0) {
      inputs[i].value = '<订单号>';
      inputs[i].dispatchEvent(new Event('input',{bubbles:true}));
      break;
    }
  }
  return 'Set';
})()
"
```

### 步骤 3：点击搜索

```bash
agent-browser snapshot -i | grep '搜索.*ref'  # 获取 ref
agent-browser click @<ref>
agent-browser wait 3000
```

### 步骤 4：提取结果

```bash
agent-browser snapshot
```

关键字段：
- 订单状态（准确定/确定）
- 价格审批阶段 + 特殊付款方式审批阶段
- 是否导入SAP
- 精排产状态
- 订单入库状态
- 时间节点：创建时间/有效意向时间/准确定时间/确定时间/技术完成时间
- 交车日期
- 当前处理 + 当前处理人
- 车号/数量/车型/客户

### 步骤 5：输出

精简输出关键流程节点，无结果时提示"订单未找到"。

## 批量查询

循环步骤2-4处理多个订单号，分开输出每条结果。

## 注意事项

- 必须清空日期字段，否则可能搜不到结果
- 页面顶部有"一期/二期"切换，确认选中"二期"
- 条目数显示"总台数：N"，用"="表示单条结果均只有一行
