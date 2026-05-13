## Task: 新建返修通知单列表页 index.vue

创建repairNotice/index.vue整合RepairNoticeQuery/RepairNoticeTable/RepairNoticeCheckDialog/RepairNoticeDialog

### Implementation Context

新建repairNotice/index.vue（文件不存在）。Script Setup + 两个el-card模式(参考returnNotice/index.vue)。
模板结构：
el-card(RepairNoticeQuery @search @reset) 
-> el-card(RepairNoticeTable @add @edit @view @delete @export @start-process @queryTable @page-change @update:showSearch)
-> RepairNoticeDialog(@cancel @save-draft @submit-process)
-> RepairNoticeCheckDialog(@confirm @reject @update:visible)

Script逻辑：
const {proxy} = getCurrentInstance()
const {repair_notice_status, handover_status} = proxy.useDict("repair_notice_status", "handover_status")
const {open, title, loading, buttonLoading, showSearch, total, noticeList, queryParams, form, rules,
       getList, handleQuery, handlePageChange, resetQuery, handleAdd, handleUpdate, handleView,
       handleDelete, saveDraft, submitProcess, handleStartProcess, handleCheckConfirm,
       handleCheckReject, cancel, canEdit, canDelete, canSubmit, canStartProcess,
       checkDialogOpen, checkDetailData, handleExport} = useRepairNotice(proxy)

handleView覆盖为弹窗查看：
function handleView(row) { getNotice(row.id).then(res=>{form.value=res.data||{};open.value=true;title.value="查看返修通知单"}) }


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

#### ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/components/RepairNoticeQuery.vue
```
<template>
  <el-form
    :model="localQueryParams"
    ref="queryRef"
    :inline="true"
    v-show="showSearch"
    label-width="90px"
  >
    <el-form-item label="通知单号" prop="noticeNo">
      <el-input
        v-model="localQueryParams.noticeNo"
        placeholder="请输入返修通知单号"
        clearable
        style="width: 220px"
        @keyup.enter="emitSearch"
      />
    </el-form-item>

    <el-form-item label="项目包编码" prop="projectPackageCode">
      <el-input
        v-model="localQueryParams.projectPackageCode"
        placeholder="请输入项目包编码"
        clearable
        style="width: 220px"
        @keyup.enter="emitSearch"
      />
    </el-form-item>

    <el-form-item label="送修人" prop="applicantName">
      <el-input
        v-model="localQueryParams.applicantName"
        placeholder="请输入送修人姓名"
        clearable
        style="width: 200px"
        @keyup.enter="emitSearch"
      />
    </el-form-item>

    <el-form-item label="处理人" prop="handlerName">
      <el-input
        v-model="localQueryParams.handlerName"
        placeholder="请输入处理人姓名"
        clearable
        style="width: 200px"
        @keyup.enter="emitSearch"
      />
    </el-form-item>

    <el-form-item label="物流单号" prop="logisticsNo">
      <el-input
        v-model="localQueryParams.logisticsNo"
        placeholder="请输入物流单号"
        clearable
        style="width: 220px"
        @keyup.enter="emitSearch"
      />
    </el-form-item>

    <el-form-item label="交接状态" prop="handoverStatus">
      <el-select
        v-model="localQueryParams.handoverStatus"
        placeholder="请选择交接状态"
        clearable
        style="width: 100%"
      >
        <el-option
          v-for="dict in handover_status"
          :key="dict.value"
          :label="dict.label"
          :value="dict.value"
        />
      </el-select>
    </el-form-item>

    <el-form-item label="单据状态" prop="status">
      <el-select
        v-model="localQueryParams.status"
        placeholder="请选择单据状态"
        clearable
        style="width: 100%"
      >
        <el-option
          v-for="dict in repair_notice_status"
          :key="dict.value"
          :label="dict.label"
          :value="dict.value"
        />
      </el-select>
    </el-form-item>

    <el-form-item label="寄出日期" prop="shippedDate">
      <el-date-picker
        v-model="localQueryParams.shippedDate"
        type="date"
        value-format="YYYY-MM-DD"
        placeholder="请选择寄出日期"
        clearable
        style="width: 200px"
      />
    </el-form-item>

    <el-form-item>
      <el-button type="primary" icon="Search" @click="emitSearch">搜索</el-button>
      <el-button icon="Refresh" @click="handleReset">重置</el-button>
    </el-form-item>
  </el-form>
</template>

<script setup>
import {getCurrentInstance, ref, watch} from "vue";

const {proxy} = getCurrentInstance();
const {handover_status, repair_notice_status} = proxy.useDict(
  "handover_status",
  "repair_notice_status"
);
const props = defineProps({
  queryParams: {
    type: O
```

#### ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/components/RepairNoticeTable.vue
```
<template>
  <div class="repair-notice-table">
    <el-row :gutter="10" class="mb12">
      <el-col :span="1.5">
        <el-button type="primary" plain @click="$emit('add')">新增</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="warning" plain @click="$emit('export')">导出</el-button>
      </el-col>
      <right-toolbar v-model:showSearch="localShowSearch" @queryTable="$emit('queryTable')"/>
    </el-row>

    <el-table v-loading="loading" :data="noticeList" border>
      <el-table-column prop="noticeNo" label="返修通知单号" min-width="180" show-overflow-tooltip/>
      <el-table-column prop="projectPackageCode" label="项目包编码" min-width="140" show-overflow-tooltip/>
      <el-table-column prop="applicantName" label="送修人" min-width="100"/>
      <el-table-column label="送修日期" min-width="120" align="center">
        <template #default="{ row }">
          {{ parseTime(row.sendRepairDate, "{y}-{m}-{d}") || "-" }}
        </template>
      </el-table-column>
      <el-table-column label="物品数量" min-width="100" align="center">
        <template #default="{ row }">
          {{ row.repairQuantity ?? 0 }}
        </template>
      </el-table-column>
      <el-table-column prop="applicantDeptName" label="发起机构" min-width="140" show-overflow-tooltip/>
      <el-table-column prop="handlerDeptName" label="处理机构" min-width="140" show-overflow-tooltip/>
      <el-table-column prop="logisticsNo" label="物流单号" min-width="140" show-overflow-tooltip/>

      <el-table-column label="交接状态" width="120" align="center">
        <template #default="{ row }">
          <dict-tag :options="handover_status" :value="row.handoverStatus"/>
        </template>
      </el-table-column>

      <el-table-column label="单据状态" width="120" align="center">
        <template #default="{ row }">
          <dict-tag :options="repair_notice_status" :value="row.status"/>
        </template>
      </el-table-column>

      <el-table-column prop="createTime" label="创建时间" min-width="160" align="center"/>

      <el-table-column label="操作" width="340" fixed="right" align="center">
        <template #default="{ row }">
          <el-button
            v-if="canEdit(row)"
            link
            type="primary"
            @click="$emit('edit', row)"
          >
            编辑
          </el-button>

          <el-button
            v-else
            link
            type="primary"
            @click="$emit('view', row)"
          >
            查看
          </el-button>

          <el-button
            v-if="canSubmit(row)"
            link
            type="success"
            @click="$emit('edit', row)"
          >
            提交
          </el-button>

          <el-button
            v-if="canStartProcess(row)"
            link
            type="warning"
            @click="$emit('start-process', row)"
          >
            开始处理
          </el-button>

          <el-button
            v-if="canDelete(row)"
            link
            type="danger"
            @clic
```

#### ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/components/RepairNoticeDialog.vue
```
## File: RepairNoticeDialog.vue (671 lines, 20KB)

### Component Structure
- `<template>` (205 lines)
- `<template>` (206 lines)
- `<template>` (225 lines)
- `<template>` (225 lines)
- `<script>` (234 lines)
- `<style>` (63 lines)
```

#### ruo-yi-wms-vue-master/src/views/wms/order/returnNotice/index.vue
```
<template>
  <div class="app-container">
    <el-card>
      <ReturnNoticeQuery
        ref="queryComponentRef"
        v-model:queryParams="queryParams"
        :show-search="showSearch"
        :status-options="return_notice_status"
        @search="handleQuery"
        @reset="resetQuery"
      />
    </el-card>

    <el-card class="mt20">
      <ReturnNoticeTable
        :loading="loading"
        :notice-list="noticeList"
        :total="total"
        :query-params="queryParams"
        :show-search="showSearch"
        :status-options="return_notice_status"
        :can-edit="canEdit"
        :can-delete="canDelete"
        :can-submit="canSubmit"
        :can-confirm="canConfirm"
        :can-void="canVoid"
        @add="handleAdd"
        @edit="handleUpdate"
        @view="handleView"
        @delete="handleDelete"
        @export="handleExport"
        @submit="handleSubmit"
        @confirm="handleConfirm"
        @void="handleVoid"
        @queryTable="getList"
        @page-change="handlePageChange"
        @update:showSearch="showSearch = $event"
      />
    </el-card>

    <ReturnNoticeDialog
      v-model:open="open"
      :title="title"
      :form-data="dialogFormData"
    />
  </div>
</template>

<script setup name="ReturnNotice">
import { getCurrentInstance, ref } from "vue";
import ReturnNoticeQuery from "./components/ReturnNoticeQuery.vue";
import ReturnNoticeTable from "./components/ReturnNoticeTable.vue";
import ReturnNoticeDialog from "./components/ReturnNoticeDialog.vue";
import { getReturnNotice } from "@/api/wms/returnNotice";
import useReturnNotice from "./useReturnNotice";

const { proxy } = getCurrentInstance();

const { return_notice_status } = proxy.useDict("return_notice_status");

const dialogFormData = ref({});

const {
  open,
  title,
  loading,
  showSearch,
  total,
  noticeList,
  queryParams,
  getList,
  handleQuery,
  handlePageChange,
  resetQuery,
  handleAdd,
  handleUpdate,
  handleView: useHandleView,
  handleDelete,
  handleSubmit,
  handleConfirm,
  handleVoid,
  canEdit,
  canDelete,
  canSubmit,
  canConfirm,
  canVoid
} = useReturnNotice(proxy);

/**
 * 查看弹窗 - 加载详情数据
 * 覆盖 useReturnNotice.js 中的 handleView（路由跳转），改为弹窗展示
 */
function handleView(row) {
  const id = row?.id;
  if (!id) return;

  getReturnNotice(id).then((response) => {
    const data = response.data || {};
    dialogFormData.value = { ...data };
    title.value = `查看返回确认单【${data.returnNoticeNo || id}】`;
    open.value = true;
  });
}

/**
 * 导出
 */
function handleExport() {
  proxy.download(
    "wms/ReturnNotice/export",
    { ...queryParams.value },
    `返回确认单_${new Date().getTime()}.xlsx`
  );
}
</script>

<!--
## Key Decisions
- index.vue 使用 repairNotice/index.vue 的组件拆分模式：el-card(查询) + el-card(表格+按钮区域)
- 使用 ReturnNoticeQuery / ReturnNoticeTable / ReturnNoticeDialog 三个子组件
- 与 useReturnNotice.js 组合式函数集成，接收其返回的状态和操作方法
- 查看操作（handleView）在 index.vue 中实现，加载详情后传入 ReturnNoticeDialog 展示
  （因为 useReturnNotice.js 中的 handleView 走路由跳转，需要
```
