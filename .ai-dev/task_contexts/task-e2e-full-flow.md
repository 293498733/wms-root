## Task: 端到端验证 — 核对明细完整业务流程

验证列表页->开始处理->弹窗->修改数量->核对通过/退回完整流程

### Implementation Context

6个测试场景：
1.正常核对：开始处理->弹窗分组展示->展开子表->修改数量->匹配状态更新->选择仓库->入库->状态变处理中
2.核对退回：退回原因输入框非空校验->退回->状态变待提交
3.仓库必填：不选仓库点入库->表单校验拦截
4.不匹配时入库二次确认：修改数量使不匹配->二次确认对话框->确认后后端校验拒绝
5.按钮互斥：入库请求中退回按钮disabled
6.空明细：无明细通知单显示el-empty


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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/service/RepairNoticeService.java
```
## File: RepairNoticeService.java (501 lines, 21KB)

**Package**: package com.ruoyi.wms.service;
**Imports**: 38 packages

### Classes/Interfaces (1)
- `public class RepairNoticeService {`

### Constants/Fields
private static final long MAX_CHECK_DETAIL_LIMIT = 5000L;
private static final Long REPAIR_RECEIPT_OPT_TYPE = 1L;

### Methods (33)
- `public RepairNoticeCheckDetailVo startProcess(Long id) {`
- `throw new ServiceException("只有已提交状态的单据才能开始处理");`
- `throw new ServiceException("只有处理机构所属部门才能开始处理该单据");`
- `throw new ServiceException("通知单明细不能为空");`
- `throw new ServiceException("通知单明细数量超过限制（最大" + MAX_CHECK_DETAIL_LIMIT + "条）");`
- `public Long confirmCheck(Long noticeId, RepairNoticeConfirmBo bo) {`
- `throw new ServiceException("只有已提交状态的单据才能核对通过");`
- `throw new ServiceException("只有处理机构所属部门才能核对该单据");`
- `throw new ServiceException("通知单明细不能为空");`
- `throw new ServiceException("入库物品不属于所选返修通知单");`
- `throw new ServiceException("存在规格型号实际数量与预期数量不一致，请核对后重新提交");`
- `public void rejectCheck(Long noticeId, RepairNoticeRejectBo bo) {`
- `throw new ServiceException("只有已提交状态的单据才能退回");`
- `throw new ServiceException("只有处理机构所属部门才能退回该单据");`
- `private List<CheckDetailItem> buildCheckDetailItems(List<RepairNoticeDetailVo> details) {`
- `private List<CheckDetailItem> buildSubmittedCheckItems(`
- `private List<GroupedCheckDetail> buildGroupedDetails(List<CheckDetailItem> items) {`
- `public RepairNoticeVo queryById(Long id) {`
- `public TableDataInfo<RepairNoticeVo> queryPageList(RepairNoticeBo bo, PageQuery pageQuery) {`
- `public List<RepairNoticeVo> queryList(RepairNoticeBo bo) {`
- `public TableDataInfo<RepairNoticeVo> queryReceiptSelectPage(String noticeNo, PageQuery pageQuery) {`
- `public void insertByBo(RepairNoticeBo bo) {`
- `public void updateByBo(RepairNoticeBo bo) {`
- `public void saveDraft(RepairNoticeBo bo) {`
- `public void submitNotice(RepairNoticeBo bo) {`
- `public RepairNoticeVo mobileSubmit(RepairNoticeMobileSubmitBo bo) {`
- `return queryById(notice.getId());`
- `public void deleteByIds(List<Long> ids) {`
- `throw new ServiceException("删除失败", HttpStatus.CONFLICT,`
- `private RepairNotice getByIdRequired(Long id) {`
- `throw new ServiceException("返修通知单不存在");`
- `private LambdaQueryWrapper<RepairNotice> buildQueryWrapper(RepairNoticeBo bo) {`
- `private String generateNoticeNo() {`
```

#### ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/components/RepairNoticeCheckDialog.vue
```
## File: RepairNoticeCheckDialog.vue (622 lines, 17KB)

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
