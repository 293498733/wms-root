## Task: 子表分页阈值参数调整

根据业务实际量级评估子表分页阈值 pageItemThreshold(200) 和 每页条数 pageItemSize(50) 是否合理，如需调整则修改 index.vue 中传入的 prop 值。


### Implementation Context

【问题描述】
当前 RepairNoticeCheckDialog 通过 props 接收 pageItemThreshold（默认200）和
pageItemSize（默认50），但 index.vue 在使用 RepairNoticeCheckDialog 时
没有显式传入这两个 prop，因此使用的都是默认值。

【确认需求】
<RepairNoticeCheckDialog
  v-model:open="checkDialogOpen"
  :check-detail="checkDetailData"
  @confirm="handleCheckConfirm"
  @reject="handleCheckReject"
/>
当前没有传入 :pageItemThreshold 和 :pageItemSize，因此使用了 dialog 组件内的默认值。

【推荐方案】
如果业务上单次返修量级通常不超过 200 件/组，可考虑提升阈值或保持现状。
如需调整，在 index.vue 中添加 prop 传入：
<RepairNoticeCheckDialog
  v-model:open="checkDialogOpen"
  :check-detail="checkDetailData"
  :page-item-threshold="200"
  :page-item-size="50"
  @confirm="handleCheckConfirm"
  @reject="handleCheckReject"
/>

注意 prop 命名：Vue 3 中 camelCase prop 在 template 中需转为 kebab-case。

【约束】
- 不改动 RepairNoticeCheckDialog.vue 内部的默认值逻辑
- 不改动任何后端代码
- 修改后需要验证：
  a) 分组内 >200 条时显示分页组件
  b) 分组内 <=200 条时不显示分页组件
  c) 不同分组分页独立互不干扰


### Reference Documents

#### 03-plan.md
```
# 工程方案：返修通知单.核对明细页面UI优化

> 编制日期：2026-05-11
> 依据文档：`requirement.md`（精炼需求）、`02-analysis.md`（需求分析）
> 项目代码：`wms-ruoyi-master`（后端）、`ruo-yi-wms-vue-master`（前端）

---

## 版本记录

| 版本 | 日期 | 变更人 | 变更说明 |
|------|------|--------|---------|
| v1.0 | 2026-05-11 | AI Agent | 初始版本，基于代码审计确认现状 |

---

## 总体结论

**经完整代码审计确认：本需求的核心功能已在代码仓库中完整实现。** 需求文档是对现有实现的规范化精炼，并非新开发任务。工程方案以**"验证现有实现与需求的一致性"**为基调，列出已有功能的确认状态，并指出可选的优化方向。

---

## 1. 架构设计

### 1.1 涉及的模块

| 模块 | 层级 | 已有文件 | 状态 |
|------|------|---------|------|
| 前端-核对明细弹窗 | 视图层 | `ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/components/RepairNoticeCheckDialog.vue` | ✅ 已完整实现 |
| 前端-业务逻辑组合 | 逻辑层 | `ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/useRepairNotice.js` | ✅ 已完整实现 |
| 前端-页面入口 | 视图层 | `ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/index.vue` | ✅ 已实现 |
| 前端-API层 | 通信层 | `ruo-yi-wms-vue-master/src/api/wms/repairNotice.js` | ✅ 已实现 |
| 前端-仓库Store | 状态层 | `ruo-yi-wms-vue-master/src/store/modules/wms.js` | ✅ 已实现 |
| 后端-Controller | 控制层 | `wms-ruoyi-master/ruoyi-admin-wms/.../controller/RepairNoticeController.java` | ✅ 已完整实现 |
| 后端-Service | 业务层 | `wms-ruoyi-master/ruoyi-admin-wms/.../service/RepairNoticeService.java` | ✅ 已完整实现 |
| 后端-明细Service | 业务层 | `wms-ruoyi-master/ruoyi-admin-wms/.../service/RepairNoticeDetailService.java` | ✅ 已实现 |
| 后端-SKU查询Service | 业务层 | `wms-ruoyi-master/ruoyi-admin-wms/.../service/ItemSkuService.java` | ✅ 已实现 |
| 后端-入库单Service | 业务层 | `wms-ruoyi-master/ruoyi-admin-wms/.../service/ReceiptOrderService.java` | ✅ 已实现 |
| 后端-VO/BO | 模型层 | `RepairNoticeCheckDetailVo.java` / `RepairNoticeConfirmBo.java` / `RepairNoticeRejectBo.java` | ✅ 已完整实现 |
| 后端-Entity/Mapper | 持久层 | `RepairNotice.java` / `RepairNoticeDetail.java` / `RepairNoticeMapper.java` / `RepairNoticeDetailMapper.java` | ✅ 已实现 |

### 1.2 模块间调用关系

```
┌─────────────────────────────────────────────────────────────────────┐
│                       前端 (ruo-yi-wms-vue-master)                   │
│                                   
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

#### ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/components/RepairNoticeCheckDialog.vue
```
<template>
  <el-dialog
    title="核对明细"
    v-model="localOpen"
    width="1000px"
    append-to-body
    destroy-on-close
  >
    <!-- 说明文字 -->
    <div class="dialog-tip" style="font-size: 13px; color: #909399; padding: 0 4px 12px;">
      💡 提示：物品已按规格型号自动分组汇总，仅需核对各规格的预期数量与实际数量是否一致。点击行首 ▶ 可展开查看具体条码明细。
    </div>
    <div v-if="checkDetail" class="check-detail-wrapper">
      <el-descriptions :column="2" border size="small" class="mb16">
        <el-descriptions-item label="返修通知单号">{{ checkDetail.noticeNo }}</el-descriptions-item>
        <el-descriptions-item label="状态">处理中</el-descriptions-item>
      </el-descriptions>

      <el-form ref="checkFzormRef" :model="checkForm" label-width="80px">
        <el-form-item label="入库仓库" prop="warehouseId" :rules="[{ required: true, message: '请选择入库仓库', trigger: 'change' }]">
          <el-select v-model="checkForm.warehouseId" placeholder="请选择入库仓库" filterable style="width: 300px">
            <el-option
              v-for="item in warehouseList"
              :key="item.id"
              :label="item.warehouseName"
              :value="item.id"
            />
          </el-select>
        </el-form-item>
      </el-form>

      <!-- 空状态提示：无可核对的物品明细 -->
      <el-empty v-if="groupedDetails.length === 0" description="该通知单无可核对的物品明细">
        <el-text type="info" size="small">请联系管理员检查通知单是否已关联 SKU</el-text>
      </el-empty>
      
      <!-- 按规格型号分组的汇总表格 -->
      <template v-else>
      <el-table :data="groupedDetails" border size="small" row-key="skuName" :row-class-name="groupRowClass">
        <el-table-column type="expand" width="50">
          <template #default="{ row }">
            <div class="detail-sub-table-wrapper">
              <el-table
                :data="paginatedItems(row)"
                border
                size="small"
                :show-header="true"
                style="width: 100%"
                :row-class-name="detailRowClass"
              >
                <el-table-column label="序号" type="index" width="60" align="center"/>
                <el-table-column prop="barcode" label="条码" min-width="160"/>
                <el-table-column prop="expectedQuantity" label="预期数量" width="90" align="center"/>
                <el-table-column label="实际数量" width="130" align="center">
                  <template #default="{ row: item }">
                    <el-input-number
                      v-model="item.actualQuantity"
                      :min="0"
                      :controls="false"
                      size="small"
                      style="width: 90px"
                      @change="onQuantityChange(item, row)"
                    />
                  </template>
                </el-table-column>
                <el-table-column label="匹配" width="80" align="center">
                  <template #default="{ row: item }">
                    <el-tag v-if="item.matched" type="success" size="small">一致</el-tag>
                    <el-tag v-else type="danger" size="sm
```
