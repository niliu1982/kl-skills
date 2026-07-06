# EKP 价格评审页面 DOM 结构与匹配策略

## 页面结构

价格评审页面 URL 格式：
```
https://ekp.king-long.com.cn/kl/price/kl_price_review/klPriceReview.do?method=view&fdId=<fdId>&fdTaskInstanceId=<taskInstanceId>
```

### 页面布局

页面分为上下两部分：

1. **基本信息区**：订单编号、车型、数量、营销部、客户等（textbox 输入框）
2. **选装配置明细区**：在 iframe 内加载，包含完整的配置表格

### iframe

配置表格在 iframe 中渲染，src 通常为 `/kl/price/kl_price_review/...` 路径。
iframe 导致 agent-browser 的 ref 选择器和 CSS 选择器无法定位到表单元素，
必须使用 JavaScript DOM 操作。

### 配置表格结构

配置表格每一行包含以下 input 字段（type=text）：

| 位置 | 字段 | 说明 |
|------|------|------|
| index | 配置项名称 | 如"AEBS"、"缓速器"等 |
| index+1 | 配置信息/规格 | 如"有AEBS"、"大为电涡流缓速器/TB17B/1700N.m" |
| index+2 | 价格(万) | **待填写的目标字段**，默认值"0.0" |
| index+3 | 标配价格 | 参考值 |
| index+4 | 指定件价格 | 参考值 |
| index+5 | 周期 | 参考值 |

> **注意**：不同 EKP 版本/页面配置下，价格字段可能从 index+2 变为 index+1。
> 使用 eval 打印所有 input 值确认结构后再操作。

### 页面模式

价格评审页面有两种视图模式：
- **编辑模式**：价格 input 可编辑（value 初始为"0.0"）
- **查看模式**：价格 input 不可编辑（已填写或只读）

只有编辑模式下才需要填写价格。

## DOM 操作方式

### 唯一有效方案：agent-browser eval

```bash
agent-browser eval "<javascript_code>"
```

JavaScript 代码运行在页面全局上下文中，可以访问 iframe 内的 DOM。

### 查找所有输入框

```javascript
Array.from(document.querySelectorAll('input[type=text]'))
```

### 匹配配置项

配置信息文本是唯一的匹配 key。遍历所有 input，
将每个 input 的 value 与参考价格 Map 的 key 做**精确字符串匹配**。

匹配规则：
- 必须完全一致（包括标点符号、空格、括号类型）
- 中文标点与英文标点不互通，必须使用相同编码

### 填写价格

```javascript
allInputs[i + 1].value = priceMap[configText];
allInputs[i + 1].dispatchEvent(new Event('input', { bubbles: true }));
allInputs[i + 1].dispatchEvent(new Event('change', { bubbles: true }));
```

**必须触发 input 和 change 事件**，否则前端框架无法感知值变化，
保存时提交的仍然是旧值。

### 保存按钮

保存按钮位于页面右上方，DOM 特征：
- class: `lui_widget_btn_txt`
- 文本: "保存"

```javascript
document.querySelectorAll('.lui_widget_btn_txt') 中 textContent.trim() === '保存' 的元素
```

点击保存后，系统弹出"您的操作已成功！"提示。

## 价格参考数据源

### ima 知识库

- 知识库：厄尔尼诺的知识库（ID: 001a8a0de00015b3）
- 核价数据文件夹：按订单编号命名（如 NL26060067、NL26040199）
- 文件格式：Excel (.xlsx)

### 搜索策略

1. 先按当前订单编号搜索专属核价表
2. 如无专属数据，按车型关键词搜索同车型其他订单
3. 合并多个同车型订单的核价数据作为参考

### 常见配置项与参考价格（XMQ6905AYD6C 车型）

| 配置信息（精确匹配文本） | 价格(万) |
|---|---|
| 有AEBS | 0.35 |
| 大为电涡流缓速器/TB17B/1700N.m | 0.02 |
| 油箱仓贯通+加装前立面中间部位封板 | 0.01 |
| 佳通10R22.5真空胎 | 0.03 |
| 有(发动机和加热器的油路及滤芯加热) | 0.28 |
| 整车流水槽 | 0.065 |
| 司机椅 | 0.02 |
| 双幅手动剪刀式前挡遮阳帘 | 0.012 |
| 南风380W外循环除霜机 | 0.04 |
| 有司机椅处散热器(电机两档) | 0.03 |
| 有前门踏步散热器(电机两档) | 0.03 |
| 电子蜗牛喇叭+气喇叭 | 0.02 |
| 有智能视频监控报警装置DSM | 0.06 |
| 整车隔热降噪(标配件+乘客区下加棉) | 0.08 |
| 乘客座椅靠背后刺绣"请系好安全带" | 0.08 |

> 以上为典型参考价格，不同订单可能有差异，以 ima 中最新核价数据为准。
