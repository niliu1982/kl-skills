---
name: ekp-add-config
description: |
  EKP价格评审页面 - 在选装配置明细（上表）中新增配置项。
  触发词：增加项目、新增配置、添加条目、补充配置项、加上、+号添加。
  在用户要求新增配置项目时调用此skill。
agent_created: true
---

# EKP 新增配置项

在 EKP 价格评审页面的 **选装配置明细**（上表）中添加新的配置行。

## 前提

- 已登录 EKP，价格评审页面处于编辑模式
- `agent-browser` 可用

## 关键规则

1. **使用上表 `TABLE_DocList_2`**，不是下表 `TABLE_DocList_1`
2. **只填配置信息、价格两列**，其他列留空（否则触发校验错误）
3. 新增行输入框索引：`[0]=序号, [1]=配置信息, [2]=价格, [3-5]=留空`

## 工作流程

### 步骤 1：添加空行

```javascript
agent-browser eval "
try { DocList_AddRow('TABLE_DocList_2'); } catch(e) {}
'Row added'
"
```

如果页面刷新导致 `DocList_AddRow` 不可用，使用图片点击：

```javascript
agent-browser eval "
(function() {
  var imgs = document.querySelectorAll('img');
  for (var i = 0; i < imgs.length; i++) {
    if ((imgs[i].src||'').indexOf('add.gif') >= 0) {
      var onclick = imgs[i].getAttribute('onclick') || '';
      if (onclick.indexOf('TABLE_DocList_2') >= 0) {
        imgs[i].click();
        return 'Clicked add button for DocList_2';
      }
    }
  }
  return 'Not found';
})()
"
```

### 步骤 2：找到新行并填入数据

新行在 `TABLE_DocList_2` 的最后一行。每个配置项传 `{info: "配置描述", price: "价格"}`。

```javascript
agent-browser eval '
(function() {
  var t = document.getElementById("TABLE_DocList_2");
  var rows = t.querySelectorAll("tr");
  var lastRow = rows[rows.length - 1];
  var inputs = lastRow.querySelectorAll("input[type=text]");
  // 只填 配置信息(input[1]) 和 价格(input[2])
  inputs[1].value = "<配置描述>";
  inputs[1].dispatchEvent(new Event("change",{bubbles:true}));
  inputs[2].value = "<价格>";
  inputs[2].dispatchEvent(new Event("change",{bubbles:true}));
  return "Filled: " + inputs[1].value + " = " + inputs[2].value;
})()
'
```

### 步骤 3：批量添加多条

多条时逐个执行步骤1+步骤2，或一次添加多行后批量填入。

```javascript
// 添加 N 行
agent-browser eval "
for (var i = 0; i < <N>; i++) { try { DocList_AddRow('TABLE_DocList_2'); } catch(e) {} }
'Added <N> rows'
"

// 批量填入（从倒数第N行开始）
agent-browser eval '
(function() {
  var t = document.getElementById("TABLE_DocList_2");
  var rows = t.querySelectorAll("tr");
  var items = [
    {info: "<配置1>", price: "<价格1>"},
    {info: "<配置2>", price: "<价格2>"}
  ];
  var startRow = rows.length - items.length;
  var results = [];
  for (var i = 0; i < items.length; i++) {
    var inputs = rows[startRow + i].querySelectorAll("input[type=text]");
    inputs[1].value = items[i].info;
    inputs[1].dispatchEvent(new Event("change",{bubbles:true}));
    inputs[2].value = items[i].price;
    inputs[2].dispatchEvent(new Event("change",{bubbles:true}));
    results.push(inputs[1].value + "=" + inputs[2].value);
  }
  return JSON.stringify(results);
})()
'
```

### 步骤 4：保存

```javascript
agent-browser eval "
(function() {
  var all = document.querySelectorAll('*');
  for (var i = 0; i < all.length; i++) {
    if (all[i].textContent.trim() === '保存') { all[i].click(); return 'Saved'; }
  }
  return 'Not found';
})()
"
```

等待结果：

```
agent-browser snapshot | grep '成功\|失败'
```

## 注意事项

- **绝不碰 `TABLE_DocList_1`**：那是下表（特殊选装配置明细）
- **只填 `inputs[1]` 和 `inputs[2]`**：填其他列会触发校验错误
- **新增行 input 数量可能为 6**（比已有行多），索引 `[1][2]` 不变
- 批量添加时从 `rows.length - N` 开始倒序填入

## 映射关系

| 表名 | 中文名 | 位置 | 用法 |
|------|--------|------|------|
| TABLE_DocList_2 | 选装配置明细 | 上方 | ✅ 新增配置项 |
| TABLE_DocList_1 | 特殊选装配置明细 | 下方 | ❌ 不要用 |
