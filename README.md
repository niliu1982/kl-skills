# KL Skills

金龙客车（King Long）WorkBuddy 技能集合，用于 EKP 系统自动化操作与金融计算。

## 技能列表

### ekp-login
EKP 系统自动登录。检查当前浏览器会话的登录状态，未登录时自动使用存储凭据登录。支持 agent-browser 和 playwright-cli 双后端。

**触发词**：登录、登陆、EKPLogin、ekp登录

### ekp-order-prod-status
EKP 订单投产状态查询。输入订单号，自动查询并解析订单流转信息与车辆生产状态（计划投产日期、投产日期、入库日期等）。

**触发词**：投产、生产状态、订单进度、查询订单、订单流转、prodStatus

### ekp-price-review
EKP 价格评审自动填写。在价格评审页面中，根据 ima 知识库中的参考核价数据，自动匹配配置项并填写价格，完成后保存。

**触发词**：价格评审、核价、EKP填写、配置价格、klPriceReview

### ekp-flow-search
EKP 订单流程搜索（二期数据）。通过常用查询 → 订单搜索入口，快速查询订单整体流转状态，包括审批阶段、SAP导入、精排产、入库等节点。

**触发词**：流程搜索、订单搜索、flowSearch

### ekp-add-config
EKP 价格评审页面 - 在选装配置明细（上表）中新增配置项行。用于添加参考订单有但目标页面缺失的配置项。

**触发词**：添加配置、新增配置项、addConfig

### loan-interest-calc
贷款利息计算器，支持四种计算场景：
- 等额本息分期贷款
- 短期资金占用利息（首付/延期支付）
- 承兑汇票贴现利息
- 车款综合计算（首付 + 分期 + 承兑）

利率依据中国人民银行贷款基准利率自动匹配。

**触发词**：贷款利息、按揭计算、月供、承兑贴现、分期付款

### pdf-text-replace
PDF 表格/表单内文本替换（排版保真）。用于修改已生成 PDF 中的指定文字，保持原有字体、字号、行距、表格线完整。适用于金龙客车配置更改单等固定版式表单。

**触发词**：PDF替换、PDF修改文字、PDF编辑、改PDF内容

## 依赖

- `agent-browser`：浏览器自动化（ekp-* 系列）
- `playwright-cli`：备选浏览器后端（支持 cert bypass）
- `ima-skill`：知识库搜索（ekp-price-review）

## 安装

**一句话安装（推荐）：**
```bash
bash <(curl -s https://raw.githubusercontent.com/niliu1982/kl-skills/main/install.sh)
```

**首次使用需配置 EKP 凭据：**
```bash
echo "用户名" > ~/.config/ekp/username
echo "密码" > ~/.config/ekp/password
```
