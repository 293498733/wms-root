## Task: 开发返回确认单 useReturnNotice.js 组合式函数

创建 useReturnNotice.js，封装列表查询、表单校验、保存/提交/确认出库/作废等页面交互逻辑

### Implementation Context

参照 useRepairNotice.js 的模式创建。
输出文件目录：ruo-yi-wms-vue-master/src/views/wms/order/returnNotice/
注意创建 useReturnNotice.js（与 index.vue 同级，非 components/ 目录下）。

核心状态：
- open (ref, 弹窗显隐), title (ref), loading (ref), buttonLoading (ref)
- showSearch (ref), total (ref), noticeList (ref)
- queryParams (reactive): { pageNum, pageSize, returnNoticeNo, repairNoticeId, status }
- form (reactive): 所有 Bo 字段
- rules: 校验规则

核心方法：
- getList()：调用 listReturnNotice(queryParams)
- handleQuery() / resetQuery() / handlePageChange()
- handleAdd()：重置 form，open=true，title="新增返回确认单"
- handleUpdate(row)：调用 getReturnNotice(id) 加载数据，open=true，title="编辑返回确认单"
- handleView(row)：类似 handleUpdate，title="查看返回确认单"
- handleDelete(row)：确认弹窗 → delReturnNotice(id)
- handleSubmit(row)：确认弹窗 → submitReturnNotice(data)
- handleConfirm(row)：确认弹窗 → confirmReturnNotice(id)
- handleVoid(row)：确认弹窗 → voidReturnNotice(id)
- cancel()：关闭弹窗，重置表单

状态判断辅助函数：
- isDraft(status): status === '0'
- isSubmitted(status): status === '2'
- isShipped(status): status === '3'
- isVoid(status): status === '9'

canEdit(row): isDraft(row.status) && 是创建人
canDelete(row): isDraft(row.status) && 是创建人
canSubmit(row): isDraft(row.status) && 是创建人
canConfirm(row): isSubmitted(row.status) && 是创建人
canVoid(row): isSubmitted(row.status) && 是创建人

注意：编辑页是路由驱动（edit.vue），所以 useReturnNotice.js 中的 handleAdd/handleUpdate/handleView
应通过 router.push 跳转到 edit.vue，而不是弹窗模式。

字典引用通过 proxy.useDict("return_notice_status") 获取


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

#### ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/useRepairNotice.js
```
## File: useRepairNotice.js (512 lines, 14KB)

**Imports**: 3 modules
**Exports**: 1 items

### Functions (32)
- `function normalizeFaultyDetail(detail = {}, index = 0) {`
- `function normalizeFaultyDetails(formData = {}) {`
- `function buildSubmitPayload(formData = {}) {`
- `function normalizePageParams(pageInfo = {}) {`
- `function getList() {`
- `function resetFormData() {`
- `function cancel() {`
- `function handleQuery(nextQuery = {}) {`
- `function handlePageChange(pageInfo = {}) {`
- `function resetQuery() {`
- `function handleAdd() {`
- `function handleUpdate(row) {`
- `function handleView(row) {`
- `function handleDelete(row) {`
- `function handleExport() {`
- `function isDraftStatus(status) {`
- `function isSubmittedStatus(status) {`
- `function isProcessingStatus(status) {`
- `function isFinishedStatus(status) {`
- `function isApplicant(row) {`
- `function isHandlerDeptUser(row) {`
- `function canEdit(row) {`
- `function canDelete(row) {`
- `function canSubmit(row) {`
- `function canStartProcess(row) {`
- `function validateForDraft(formRef, callback) {`
- `function validateForSubmit(formRef, callback) {`
- `function saveDraft({ formRef, formData }) {`
- `function submitProcess({ formRef, formData }) {`
- `function handleStartProcess(row) {`
```
