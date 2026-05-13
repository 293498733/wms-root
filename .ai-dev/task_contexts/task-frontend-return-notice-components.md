## Task: 开发返回确认单前端页面（Index/Query/Table/Dialog + edit.vue）

创建返回确认单的列表页(index.vue)、编辑页(edit.vue)及查询/表格/弹窗组件共6个前端文件

### Implementation Context

参照 repairNotice 的组件拆分模式创建6个前端文件。

整体架构：
index.vue ← 使用 useReturnNotice.js（组合式函数） + 4个子组件
edit.vue ← 路由驱动的新建/编辑页（独立路由，非弹窗）

index.vue（列表页主页面）：
- 模板结构：el-card(查询) + el-card(表格+按钮区域)
- 引入 ReturnNoticeQuery / ReturnNoticeTable / ReturnNoticeDialog 3个子组件
- script setup name="ReturnNotice"
- 字典：const { return_notice_status } = proxy.useDict("return_notice_status")
- 按钮权限：v-hasPermi="['wms:returnNotice:xxx']"

ReturnNoticeQuery.vue（查询条件组件）：
- el-form inline 布局
- 查询条件：返回单号(returnNoticeNo, 模糊)、返修通知单号(repairNoticeId 精确)、状态(status 下拉)、创建时间(dateRange)
- props: showSearch, queryParams, statusOptions
- emits: search, reset
- 参照 RepairNoticeQuery.vue 风格

ReturnNoticeTable.vue（表格组件）：
- 顶部按钮行：新增(+ 权限)、导出(+ 权限)
- el-table 列：返回单号 | 返修通知单号 | 状态(字典标签) | 总数量 | 物流公司 | 物流单号 | 创建时间 | 操作
- 操作列按钮：
  - 查看(v-hasPermi="wms:returnNotice:query")
  - 编辑(仅草稿 + 权限)
  - 删除(仅草稿 + 权限)
  - 提交(仅草稿 + 权限)
  - 确认出库(仅已提交 + 权限)
  - 作废(仅已提交 + 权限)
- 分页：pagination 组件
- props: loading, returnNoticeList, total, queryParams, showSearch, statusOptions
- emits: add, edit, view, delete, export, submit, confirm, void
- 状态标签使用 el-tag：草稿(info)、已提交(warning)、已出库(success)、作废(danger)

ReturnNoticeDialog.vue（弹窗组件——用于简单查看场景）：
- el-dialog：标题动态绑定，width="800px"
- el-descriptions 展示只读详情
- 明细表格展示 SKU 明细列表
- 如果使用编辑/新建场景，则交给 edit.vue 路由处理

edit.vue（路由驱动的新建/编辑页）：
- 参照 receipt/edit.vue 风格（不是弹窗，是页面）
- 路由：新建 → /wms/order/returnNotice/edit，编辑 → /wms/order/returnNotice/edit?id=xxx
- 页面结构：
  1. 基本信息区域（el-form）：返回单号(自动生成只读) | 关联返修通知单(选择器 + 搜索弹窗) | 出库仓库(选) | 物流公司 | 物流单号 | 备注
  2. 选择返修通知单弹窗（内嵌或独立组件）：
     - 只能选择 status=3(处理中) 的通知单
     - 选择后自动调用 listReturnableSkus(repairNoticeId) 加载 SKU 列表
  3. 明细表格区域：SKU | SKU名称(只读) | 可返回数量(只读) | 本次返回数量(输入)
  4. 底部操作栏：保存(存草稿) | 提交(草稿→已提交)
- 使用 onMounted 判断 route.query.id 是否存在来决定是新增还是编辑
- 编辑时调用 getReturnNotice(id) 加载数据
- 提交时调用 submitReturnNotice(), 保存调用 addReturnNotice()/updateReturnNotice()
- 注意：确认出库和作废在列表页操作列中触发，不在 edit.vue 中

细节注意：
- 所有组件使用 <script setup> 语法
- 使用 Element Plus 组件库
- 与 repairNotice 风格保持一致，组件拆分模式
- 目录结构：
  views/wms/order/returnNotice/
    ├── index.vue
    ├── edit.vue
    ├── useReturnNotice.js
    └── components/
        ├── ReturnNoticeQuery.vue
        ├── ReturnNoticeTable.vue
        └── ReturnNoticeDialog.vue


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

#### ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/index.vue
```
<template>
  <div class="app-container">
    <el-card>
      <RepairNoticeQuery
        ref="queryComponentRef"
        v-model:queryParams="queryParams"
        :show-search="showSearch"
        :status-options="wms_repair_notice_status"
        :handover-status-options="wms_repair_handover_status"
        @search="handleQuery"
        @reset="resetQuery"
      />
    </el-card>

    <el-card class="mt20">
      <RepairNoticeTable
        :loading="loading"
        :notice-list="noticeList"
        :total="total"
        :query-params="queryParams"
        :show-search="showSearch"
        :status-options="wms_repair_notice_status"
        :handover-status-options="wms_repair_handover_status"
        :can-edit="canEdit"
        :can-delete="canDelete"
        :can-submit="canSubmit"
        :can-start-process="canStartProcess"
        @add="handleAdd"
        @edit="handleUpdate"
        @view="handleView"
        @delete="handleDelete"
        @export="handleExport"
        @start-process="handleStartProcess"
        @queryTable="getList"
        @page-change="handlePageChange"
        @update:showSearch="showSearch = $event"
      />
    </el-card>

    <RepairNoticeDialog
      ref="dialogRef"
      v-model:open="open"
      :title="title"
      :form="form"
      :rules="rules"
      :button-loading="buttonLoading"
      :status-options="wms_repair_notice_status"
      :handover-status-options="wms_repair_handover_status"
      @save-draft="saveDraft"
      @submit-process="submitProcess"
      @cancel="cancel"
    />

    <RepairNoticeCheckDialog
      v-model:open="checkDialogOpen"
      :check-detail="checkDetailData"
      :page-item-threshold="200"
      :page-item-size="50"
      @confirm="handleCheckConfirm"
      @reject="handleCheckReject"
    />
  </div>
</template>

<script setup name="RepairNotice">
import { getCurrentInstance } from "vue";
import RepairNoticeQuery from "./components/RepairNoticeQuery.vue";
import RepairNoticeTable from "./components/RepairNoticeTable.vue";
import RepairNoticeDialog from "./components/RepairNoticeDialog.vue";
import RepairNoticeCheckDialog from "./components/RepairNoticeCheckDialog.vue";
import useRepairNotice from "./useRepairNotice";

const { proxy } = getCurrentInstance();

const {
  wms_repair_notice_status,
  wms_repair_handover_status
} = proxy.useDict("repair_notice_status", "handover_status");

const {
  open,
  title,
  loading,
  buttonLoading,
  showSearch,
  total,
  noticeList,
  queryParams,
  form,
  rules,
  getList,
  handleQuery,
  handlePageChange,
  resetQuery,
  handleAdd,
  handleUpdate,
  handleView,
  handleDelete,
  handleExport,
  saveDraft,
  submitProcess,
  handleStartProcess,
  cancel,
  canEdit,
  canDelete,
  canSubmit,
  canStartProcess,
  checkDialogOpen,
  checkDetailData,
  handleCheckConfirm,
  handleCheckReject
} = useRepairNotice(proxy);
</script>

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

#### ruo-yi-wms-vue-master/src/views/wms/order/receipt/edit.vue
```
## File: edit.vue (549 lines, 16KB)

### Component Structure
- `<template>` (52 lines)
- `<template>` (53 lines)
- `<template>` (54 lines)
- `<template>` (55 lines)
- `<template>` (56 lines)
- `<template>` (57 lines)
- `<template>` (58 lines)
- `<template>` (59 lines)
- `<template>` (59 lines)
- `<script>` (354 lines)
- `<style>` (15 lines)
```
