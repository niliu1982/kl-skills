---
name: pdf-text-replace
description: |
  PDF 表格/表单内文本替换（排版保真）。用于修改已生成 PDF 中的指定文字，
  保持原有字体、字号、行距、表格线完整，替换后无遮挡、无残留旧文本。
  触发词：PDF替换、PDF修改文字、PDF编辑、改PDF内容、replacePdfText。
  适用于金龙客车配置更改单等固定版式表单。
agent_created: true
---

# PDF 文本替换（排版保真）

## 核心原则

1. **不用覆盖层**（白块+新文字的 overlay 方案）：旧文本仍留在文字层，提取时新旧混杂
2. **必须 redaction 清除旧文本** 后再插入新文本
3. **必须保留表格线**：`apply_redactions(graphics=fitz.PDF_REDACT_LINE_ART_NONE)`，
   默认参数会把被红action区域碰到的表格线一并删除
4. **字体必须匹配原文**：先查原文 span 的 font/size，嵌入系统同款字体文件，
   不要用 PyMuPDF 内置 `china-s`（名字对不上，视觉也有差）

## 工作流程

### 步骤 1：分析原文

```python
import fitz
doc = fitz.open(src)
page = doc[0]
# 查字体、字号、颜色、基线
d = page.get_text("rawdict")
# span: font, size, color, bbox; char: origin (基线坐标)
# 查表格竖线边界（防止文字写进邻列）
for dr in page.get_drawings():
    for item in dr["items"]:
        if item[0] == "l":  # 竖线: abs(p1.x-p2.x)<1
            ...
```

### 步骤 2：红action 旧文本

```python
# 区域只圈目标列，别碰表格线
page.add_redact_annot(fitz.Rect(x0, y0, x1, y1), fill=(1,1,1))
page.apply_redactions(graphics=fitz.PDF_REDACT_LINE_ART_NONE)  # 关键参数！
```

### 步骤 3：插入新文本（匹配原字体）

```python
# 中文用系统 TTF/TTC，fontname 起与原文相同的名字
page.insert_text(
    fitz.Point(x, baseline_y),   # 用原文 char origin 的 y（基线），不是 bbox top
    text,
    fontname="SimSun",
    fontfile="C:/Windows/Fonts/simsun.ttc",
    fontsize=12,                  # 与原文 span size 一致
    color=(0, 0, 0),
)
```

### 步骤 4：折行计算（表格内）

- 列宽 = 右边界竖线 x − 文本起始 x
- 中文每字宽 ≈ fontsize（SimSun 12pt ≈ 12pt/字），数字/字母半角约一半
- 首行缩进 x=96.6（带"1、"编号），续行 x=72.6（金龙表单的版式习惯）
- 行距沿用原文（如 23.4pt）

### 步骤 5：验证（必做）

```python
# 1. 全文提取确认旧文本无残留、新文本正确
# 2. 每个 span 的 font 与原文一致（注意文档可能合法存在第二种字体，
#    如 SegoePrint 手写体用于编号/车型填写，属例外）
# 3. 新文本 bbox 不越过列边界竖线
# 4. 表格竖线/横线数量与原文一致（get_drawings 对比）
# 5. 渲染页面局部 PNG 肉眼确认无遮挡
page.get_pixmap(matrix=fitz.Matrix(2,2), clip=fitz.Rect(...)).save("preview.png")
```

## 常见坑

| 坑 | 解决 |
|---|---|
| `apply_redactions()` 误删表格线 | 传 `graphics=fitz.PDF_REDACT_LINE_ART_NONE` |
| pypdf `merge_page` 白块盖不住旧文字层 | 放弃 pypdf overlay，换 PyMuPDF redaction |
| 内置 `china-s` 字体名与原文不符 | `fontfile` 嵌入系统 simsun.ttc/msyh.ttc |
| insert_text 的 y 用 bbox top 导致错位 | 用 rawdict 里 char 的 `origin[1]`（基线） |
| .ttc 多字重 | simsun.ttc 第 0 个 face 即 SimSun，直接用 |
| 文字溢出到邻列 | 先查 `get_drawings()` 竖线 x 坐标，按列宽折行 |

## 环境

```bash
# Windows venv pip 路径（不是 bin/pip，是 Scripts/pip）
C:/Users/niliu/.workbuddy/binaries/python/envs/default/Scripts/pip install PyMuPDF
C:/Users/niliu/.workbuddy/binaries/python/envs/default/Scripts/python script.py
```
