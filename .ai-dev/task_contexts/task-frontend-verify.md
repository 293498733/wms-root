## Task: 前端核对弹窗功能回归验证

对 RepairNoticeCheckDialog.vue 的所有交互功能进行手动回归验证， 包括：分组展示、展开/收起、分页、数量修改联动、匹配高亮、仓库校验、 核对通过/退回流程，确保 UI 文案优化不影响原有功能。


### Implementation Context

【验证目标】
在完成所有前端修改后，对核对弹窗的 10 个测试用例进行手动回归验证。

【验证环境准备】
1. 确保数据库中有至少 1 条 status="2"（已提交）且 handlerDeptId 等于当前登录用户部门 ID 的返修通知单
2. 该通知单至少关联 2 个不同的 SKU（分属不同规格型号），每个 SKU 有至少 2 条明细
3. 如果可能，准备一个带>200条明细的分组（或降低 pageItemThreshold prop 到 5 来模拟分页场景）

【验证用例】

TC-01 核对弹窗基本展示
- 登录系统，进入「返修通知单管理」页面
- 找到一条 status="已提交" 且当前部门可处理的单据，点击"开始处理"按钮
- 验证弹出"核对明细"弹窗
- 验证弹窗包含：提示文字、返修单号+状态、仓库选择、分组汇总表格、底部三个按钮
- 验证提示文字为更新后的文案
- 验证分组表格显示：序号、物品名称、规格型号、预期数量、实际数量、匹配标签

TC-02 分组展开功能
- 点击某分组行首的 ▶ 展开箭头
- 验证展开后显示子表（序号、条码、预期数量、实际数量可编辑、匹配标签）
- 展开其他分组，验证各分组独立展开/收起互不影响

TC-03 子表分页
- 展开物品>200条（或 > 调整后的阈值）的分组
- 验证子表底部显示分页组件（el-pagination）
- 点击页码切换，验证子表数据正确切换
- 验证不同分组的分页独立

TC-04 修改实际数量联动汇总
- 展开一个分组，找到一条明细
- 修改 el-input-number 中的实际数量（如从1改为2）
- 验证该明细行的"匹配"标签即时刷新
- 验证该分组汇总行的实际数量和匹配标签同步更新
- 修改为一致的值后，验证红色高亮消失
- 修改为不一致的值后，验证红色高亮出现

TC-05 核对通过-入库
- 选择入库仓库
- 不选仓库直接点"核对无误-入库"，验证表单校验提示
- 选择仓库，所有分组均为"一致"状态，点击"核对无误-入库"
- 验证直接提交成功，弹窗关闭，列表刷新

TC-06 核对通过-存在不一致
- 确保有分组为"不一致"状态
- 点击"核对无误-入库"，验证弹出二次确认框"存在数量不一致的物品，确认仍要入库吗？"
- 点击"取消"，验证弹窗不关闭
- 再次点击确认，验证执行入库

TC-07 核对退回
- 点击"核对有误-退回"
- 不输入原因直接确认，验证"退回原因不能为空"提示
- 输入原因，确认退回，验证弹窗关闭，状态回退

TC-08 空状态处理
- 找到一条无明细的通知单（或 mock 返回空 groupedDetails）
- 点击"开始处理"，验证显示 el-empty 空状态提示
- 验证底部两个按钮置灰禁用

TC-09 权限控制
- 验证非处理机构用户看不到"开始处理"按钮
- 验证已处理（status="3"）的通知单看不到"开始处理"按钮

TC-10 异常/边界场景
- 验证明细超过5000条时后端返回异常提示
- 验证快速双击"核对无误-入库"不被重复提交（@RepeatSubmit）

【验证记录】
对于每个测试用例，记录：
- 测试结果（通过/失败）
- 如失败：描述失败现象、截图、浏览器控制台错误
- 如通过：标记确认

【约束】
- 不改动任何代码（纯验证任务）
- 如发现 bug，记录到 .ai-dev/bug-report.md
- 如全部通过，输出 "所有 10 个测试用例全部通过"


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
