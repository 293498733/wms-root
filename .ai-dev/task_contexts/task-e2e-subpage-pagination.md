## Task: 端到端验证 — 子表分页与分组独立页码

验证单组明细超过200条时子表自动分页（每页50条）、不同分组独立页码互不影响

### Implementation Context

验证子表分页与分组独立页码。

分页逻辑（前端 RepairNoticeCheckDialog.vue）：
- pageItemThreshold = 200（硬编码，不配置化）
- pageItemSize = 50（每页50条）
- pageMap: Map<skuName, currentPage>（每个 skuName 分组维护独立页码）
- paginatedItems(group) 根据当前页码做数组切片

测试准备：
1. 准备一条通知单，其中一组 skuName="规格A" 有 220 条明细
2. 另一组 skuName="规格B" 有 5 条明细

测试步骤（手动）：
1. 打开核对明细弹窗，展开"规格A"分组
   - 验证子表下方显示分页组件（el-pagination, small）
   - 分页显示：总数 220，当前第 1 页，每页 50 条
   - 子表内容为 1-50 条
2. 点击第 2 页
   - 子表内容变为 51-100 条
3. 切换到"规格B"分组展开
   - 该分组无分页组件（5条 < 200 阈值）
   - 显示全部 5 条
4. 回到"规格A"分组展开
   - 页码应保持在第2页（独立维护）
5. 关闭弹窗重新打开
   - 所有页码重置为第1页（watch open → pageMap = new Map()）

验收标准（requirement.md 验收标准 5, 6）：
5. ✓ 单组 >200 条时子表显示分页，每页50条
6. ✓ 不同分组独立分页，切换互不影响

输出测试报告到 .ai-dev/outputs/06-e2e-subpage-pagination.md


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

### Relevant Input Files

#### ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/components/RepairNoticeCheckDialog.vue
```
## File: RepairNoticeCheckDialog.vue (624 lines, 17KB)

### Component Structure
- `<template>` (25 lines)
- `<template>` (43 lines)
- `<template>` (44 lines)
- `<template>` (52 lines)
- `<template>` (59 lines)
- `<template>` (59 lines)
- `<template>` (60 lines)
- `<template>` (61 lines)
- `<template>` (62 lines)
- `<template>` (69 lines)
- `<template>` (78 lines)
- `<template>` (78 lines)
- `<template>` (102 lines)
- `<template>` (102 lines)
- `<script>` (293 lines)
- `<style>` (79 lines)
```
