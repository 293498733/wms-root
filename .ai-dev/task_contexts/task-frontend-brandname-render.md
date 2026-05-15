## Task: 前端：ItemQrGenerateDialog.vue 二维码合集渲染增加品牌名称

修改 renderQrSheet() 和 exportHtml() 方法，在二维码卡片显示'品牌名称 + 规格型号名称'，编码放第2行

### Implementation Context

修改 ItemQrGenerateDialog.vue 中的两处渲染逻辑（只改 renderQrSheet 和 exportHtml，不改 exportCsv 和 qrRecords 表格）：

A. renderQrSheet() 方法修改（Canvas 绘制）：

修改前：
```javascript
drawText(ctx, record.itemName || '', x + cellWidth / 2, y + 204, 220)
drawText(ctx, record.preCode || '', x + cellWidth / 2, y + 232, 230)
```

修改后：
```javascript
const brandItemName = [record.brandName, record.itemName].filter(Boolean).join(' ')
drawText(ctx, brandItemName || '', x + cellWidth / 2, y + 204, 220)
drawText(ctx, record.preCode || '', x + cellWidth / 2, y + 232, 230)
```

B. exportHtml() 方法修改（HTML 卡片）：

修改前：
```javascript
<strong>${escapeHtml(row.itemName || '')}</strong>
```

修改后：
```javascript
<strong>${escapeHtml([row.brandName, row.itemName].filter(Boolean).join(' '))}</strong>
```

关键约束：
- [record.brandName, record.itemName].filter(Boolean).join(' ') 可正确处理 brandName 为 null/undefined/空字符串的情况
- Canvas 的 drawText 已有截断逻辑，品牌名称+规格型号名称拼接后长度增加，截断机制保持不变
- 不改动 exportCsv() 方法（不改CSV列定义）
- 不改动生成后 qrRecords el-table 的列定义（需求要求不变）
- 不改动 downloadSingle()、handleGenerate()、resetDialog() 等业务逻辑
- 不改动 watch(visible) 初始化和 form 表单
- record.brandName 来自后端新增的字段，通过 generate API 返回，数据流为：
  前端调用 generateItemSkuQrPre → 后端返回 ItemSkuQrPreVo.brandName → 存入 qrRecords
- 注意 escapeHtml 函数已存在于 script 中，不需新增


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

#### ruo-yi-wms-vue-master/src/views/wms/basic/item/components/ItemQrGenerateDialog.vue
```
## File: ItemQrGenerateDialog.vue (382 lines, 11KB)

### Component Structure
- `<template>` (44 lines)
- `<template>` (44 lines)
- `<template>` (59 lines)
- `<template>` (60 lines)
- `<template>` (60 lines)
- `<template>` (66 lines)
- `<template>` (66 lines)
- `<style>` (0 lines)
- `<script>` (241 lines)
- `<style>` (36 lines)
```
