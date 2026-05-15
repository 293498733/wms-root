## Task: 前端：ReturnNoticeDialog.vue 明细表格列宽调整

调整返回物品明细表格中的 SKU编码、SKU名称、可返回数量、本次返回数量列宽

### Implementation Context

在 ReturnNoticeDialog.vue 的明细 el-table 中调整列宽，适应 960px 弹窗宽度。

具体修改：
- SKU编码列：`min-width="140"` → `min-width="120"`
- SKU名称列：`min-width="180"` → `min-width="150"`
- 可返回数量列：`width="120"` → `width="100"`
- 本次返回数量列：`width="180"` → `width="140"`

关键约束：
- 只修改 el-table-column 的 min-width 和 width 属性值
- 保留 show-overflow-tooltip 属性（如原有）
- 保持列顺序不变（#、SKU编码、SKU名称、可返回数量、本次返回数量）
- 不修改 template 内部的内容（#default 插槽）
- el-input-number 的 style="width: 140px" 保持不变
- 不修改 edit.vue 中的表格列宽（不同步调整）
- 验证调整后表格在 960px 弹窗中不出现水平滚动条（或仅内容超长时溢出）


### Relevant Past Decisions
### [task-frontend-returnnotice-dialog-width] 前端：ReturnNoticeDialog.vue 弹窗宽度调整为 960px
**Category**: frontend | **Time**: 2026-05-15 10:21

*From `ruo-yi-wms-vue-master/src/views/wms/order/returnNotice/components/ReturnNoticeDialog.vue`:*
- - 弹窗宽度从 1100px 改为 960px，与 ItemQrGenerateDialog 弹窗宽度一致，统一视觉风格
- - 960px 在 1366px 分辨率下（减去侧边栏约 220px 后剩余 1140px）居中展示，两侧各有约 90px 边距
- - 仅修改 `<el-dialog>` 的 width 属性，其他属性（append-to-body、destroy-on-close、class）及所有业务逻辑保持不变
---
### [task-frontend-qr-category-column] 前端：ItemQrGenerateDialog.vue 生成前表格新增物品分类列
**Category**: frontend | **Time**: 2026-05-15 10:21

*From `ruo-yi-wms-vue-master/src/views/wms/basic/item/components/ItemQrGenerateDialog.vue`:*
- - renderQrSheet(): 拼接 brandName + itemName 作为第一行文本（品牌名称+规格型号名称），preCode 保持第二行。
- - exportHtml(): 同理拼接 brandName + itemName 作为卡片标题，编码在第二行 span 展示。
- - 使用 [record.brandName, record.itemName].filter(Boolean).join(' ') 模式，可安全处理 brandName 为 null/undefined/空字符串的情况。
- - 未改动 exportCsv() 的 CSV 列定义；未改动 qrRecords 表格的列定义；未改动其他业务逻辑。
- - record.brandName 由后端 generateItemSkuQrPre API 返回的 ItemSkuQrPreVo.brandName 字段提供。
- - 在"规格型号名称"列之后、"编号"列之前插入"物品分类"列，保持与 ItemTable.vue 中分类列一致的显示逻辑（row.itemCategoryInfo?.categoryName || '-'）
- - 使用 show-overflow-tooltip 处理长文本溢出，min-width="140" 与"编号"列宽度一致
- - 未改动生成后视图（v-else 模板中 qrRecords 表格）、未改动导出/打印/下载方法、未改动业务逻辑
- - 数据通过 generateLines 的 ...item 展开保留，由后端 ItemService.fillItemCategoryInfo() 填充

### Reference Documents

#### 03-plan.md
```
## File: 03-plan.md (574 lines, 31KB)

### Document Structure
# 工程方案：返修通知单.核对明细页面UI优化
## 版本记录
## 总体结论
## 1. 架构设计
### 1.1 涉及的模块
### 1.2 模块间调用关系
### 1.3 数据流向
#### 1.3.1 开始处理 → 获取核对明细
#### 1.3.2 核对通过 → 入库
#### 1.3.3 核对退回
### 1.4 是否引入新依赖
## 2. 接口定义（已有接口确认）
### 2.1 开始处理 — 获取核对明细
### 2.2 核对通过 — 入库
### 2.3 核对退回
### 2.4 错误码对照
## 3. 数据模型
### 3.1 表结构确认
#### repair_notice（返修通知单主表）
#### repair_notice_detail（返修通知单明细表）
#### wms_item_sku（物品SKU表）
#### wms_item（物品表）
### 3.2 字典数据确认
### 3.3 SQL 确认
## 4. 代码变更
### 4.1 核心结论
### 4.2 前端代码逐项确认
### 4.3 后端代码逐项确认
### 4.4 可选优化清单（非必须，建议但不强制）
#### 🟡 P2级优化建议
#### 🟢 P3级建议（低优）
### 4.5 需要修改/新增/删除的文件清单
#### 必须修改的文件
#### 建议修改的文件（可选优化#1 — 消除重复查询）
#### 建议修改的文件（可选优化#2 — 字典前缀）
#### 建议修改的文件（可选优化#3 — 空明细提示）
#### 需要新增的文件
#### 需要删除的文件
### 4.6 配置变更
## 5. 测试方案
  ... and 12 more headings
```

#### 02-analysis.md
```
## File: 02-analysis.md (348 lines, 20KB)

### Document Structure
# 需求分析报告：返修通知单核对明细页面UI调整
## 1. 功能拆分
### P0（核心功能，本次必须实现）
### P1（重要，建议本次实现）
### P2（后续迭代）
## 2. 数据流
### 2.1 数据来源
### 2.2 数据流转（当前逻辑）
### 2.3 数据最终存储
### 2.4 本次变更后的数据流
## 3. 界面逻辑
### 3.1 涉及页面
### 3.2 交互流程
#### 当前交互（现状）
#### 变更后交互（本次需求）
### 3.3 输入验证
### 3.4 分页逻辑
## 4. 不确定项（最关键的部分）
### 4.1 业务规则不确定项
### 4.2 技术不确定项
### 4.3 现有代码中未找到对应实现的问题
### 4.4 兼容性不确定项
## 5. 影响范围
### 5.1 需要修改的文件
#### 后端（Java）
#### 前端（Vue）
#### SQL 脚本（新增）
### 5.2 数据库变更
### 5.3 配置变更
### 5.4 接口兼容性
### 5.5 回归影响
## 附录：本次实际修改的文件清单
### 后端文件（wms-ruoyi-master）
### 前端文件（ruo-yi-wms-vue-master）
## 附录：关键代码位置索引
```

### Relevant Input Files

#### ruo-yi-wms-vue-master/src/views/wms/order/returnNotice/components/ReturnNoticeDialog.vue
```
## File: ReturnNoticeDialog.vue (550 lines, 16KB)

### Component Structure
- `<template>` (60 lines)
- `<template>` (61 lines)
- `<template>` (62 lines)
- `<template>` (63 lines)
- `<template>` (73 lines)
- `<template>` (74 lines)
- `<template>` (77 lines)
- `<template>` (87 lines)
- `<template>` (87 lines)
- `<script>` (255 lines)
- `<style>` (48 lines)
```
