## Task: 前端：ItemQrGenerateDialog.vue 生成前表格新增物品分类列

在预生成二维码弹窗的生成前表格中，'规格型号名称'列之后新增'物品分类'列，数据来自 itemCategoryInfo?.categoryName

### Implementation Context

在 ItemQrGenerateDialog.vue 的生成前 el-table（:data="generateLines"）中新增一列"物品分类"。

修改位置：在 current 表格模板中，"规格型号名称"列（`<el-table-column label="规格型号名称" prop="itemName" ...>`）之后，
"编号"列（`<el-table-column label="编号" prop="itemCode" ...>`）之前。

新增列定义：
```html
<el-table-column label="物品分类" min-width="140" show-overflow-tooltip>
  <template #default="{ row }">
    {{ row.itemCategoryInfo?.categoryName || '-' }}
  </template>
</el-table-column>
```

关键约束：
- 列位置：紧跟在"规格型号名称"之后，作为第2列
- 数据源：row.itemCategoryInfo?.categoryName（通过 generateLines 中 ...item 展开保留的 ItemVo.itemCategoryInfo）
- 空值显示：使用 `|| '-'`（与 ItemTable.vue 中分类列统一为短横线），不显示 undefined/null
- 长文本处理：使用 show-overflow-tooltip 属性
- 列宽：min-width="140"
- 不改动生成后视图（v-else 模板中 qrRecords el-table）的任何列定义
- 不改动 exportCsv()、renderQrSheet()、exportHtml()、downloadSingle() 等方法
- 不改动 handleGenerate()、resetDialog()、watch(visible) 等业务逻辑
- 不修改后端代码，也不修改 API 调用
- ItemVo.itemCategoryInfo 由后端 ItemService.fillItemCategoryInfo() 填充，listItemPage API 返回的数据中已包含


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
