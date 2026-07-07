# KL Skills

金龙客车（King Long）WorkBuddy 技能集合，用于 EKP 系统自动化操作与金融计算。

## 技能列表

### ekp-order-prod-status

EKP 订单投产状态查询。输入订单号，自动查询并解析订单流转信息与车辆生产状态（计划投产日期、投产日期、入库日期等）。

**触发词**：投产、生产状态、订单进度、查询订单、订单流转、prodStatus

### ekp-price-review

EKP 价格评审自动填写。在价格评审页面中，根据 ima 知识库中的参考核价数据，自动匹配配置项并填写价格，完成后保存。

**触发词**：价格评审、核价、EKP填写、配置价格、klPriceReview

### loan-interest-calc

贷款利息计算器，支持四种计算场景：
- 等额本息分期贷款
- 短期资金占用利息（首付/延期支付）
- 承兑汇票贴现利息
- 车款综合计算（首付 + 分期 + 承兑）

利率依据中国人民银行贷款基准利率自动匹配。

**触发词**：贷款利息、按揭计算、月供、承兑贴现、分期付款

## 依赖

- `agent-browser`：浏览器自动化（ekp-order-prod-status、ekp-price-review）
- `ima-mcp`：知识库搜索（ekp-price-review）

## 安装

**一句话安装（推荐）：**
```bash
bash <(curl -s https://raw.githubusercontent.com/niliu1982/kl-skills/main/install.sh)
```

**或手动安装：**
```bash
git clone https://github.com/niliu1982/kl-skills.git /root/.codebuddy/kl-skills-repo
cp -r /root/.codebuddy/kl-skills-repo/ekp-price-review /root/.codebuddy/skills/
cp -r /root/.codebuddy/kl-skills-repo/ekp-order-prod-status /root/.codebuddy/skills/
cp -r /root/.codebuddy/kl-skills-repo/loan-interest-calc /root/.codebuddy/skills/
```
