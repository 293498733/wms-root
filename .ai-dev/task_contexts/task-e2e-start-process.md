## Task: 端到端验证 — 开始处理/获取核对明细流程

验证点击开始处理→弹窗展示分组汇总表格→展开子表→实际数量编辑→匹配状态实时更新的完整前端交互流程

### Implementation Context

验证开始处理→获取核对明细的完整端到端流程。

测试场景（对应 03-plan.md 5.4 手动测试步骤 场景1）：

测试准备：
1. 在数据库中准备一条 status="2"（已提交）的 repair_notice 记录
2. handler_dept_id 设置为当前登录用户的部门ID
3. 在 repair_notice_detail 中准备若干条明细记录（至少2个不同 skuName）
4. 确保 wms_item_sku 和 wms_item 表中有对应的 SKU/物品数据

测试步骤与验收（手动+接口）：

1. POST /wms/RepairNotice/startProcess/{id}
   验证响应 JSON 结构：
   - noticeNo: String ✓
   - noticeStatus: "2" ✓
   - groupedDetails: List ✓（按 skuName 分组）
   - 每个 GroupedCheckDetail 包含：skuName, itemName, totalExpectedQuantity, totalActualQuantity, matched, items[]
   - 每个 CheckDetailItem 包含：skuId, skuName, itemName, barcode, expectedQuantity=1, actualQuantity=1, matched=true

2. 前端弹窗展示：
   - 顶部提示文字显示："提示：物品按规格型号分组汇总..."
   - 通知单号 + 状态显示正确
   - 仓库下拉列表加载正常
   - 主表按 skuName 分组，每行显示：序号、物品名称、规格型号、预期数量、实际数量、匹配标签
   - 匹配标签：全部一致时显示绿色"一致"
   - 点击展开箭头，展开子表显示具体物品条码
   - 展开的子表包含：序号、条码、预期数量、实际数量(InputNumber 无加减按钮, 宽度90px)、匹配标签

3. 修改实际数量：
   - 将某条明细的实际数量改为 0
   - 该行匹配状态立即变为红色"不一致"
   - 所属分组的 totalActualQuantity 汇总同步减少
   - 所属分组的 matched 变为 false
   - 分组行的匹配标签变为红色"不一致"
   - 改回 1 后状态恢复

4. 空明细场景：
   - 如果 groupedDetails 为空，显示 el-empty 或文字提示"该通知单无可核对的物品明细"

输出测试报告到 .ai-dev/outputs/04-e2e-start-process.md


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

#### ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/index.vue
```
<template>
  <div class="app-container">
    <el-card>
      <RepairNoticeQuery
        v-model:queryParams="queryParams"
        :show-search="showSearch"
        :status-options="repair_notice_status"
        :handover-status-options="handover_status"
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
        :status-options="repair_notice_status"
        :handover-status-options="handover_status"
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
      v-model:open="open"
      :title="title"
      :form="form"
      :rules="rules"
      :button-loading="buttonLoading"
      @cancel="cancel"
      @save-draft="saveDraft"
      @submit-process="submitProcess"
    />

    <RepairNoticeCheckDialog
      ref="checkDialogRef"
      v-model:visible="checkDialogOpen"
      :check-detail="checkDetailData"
      @confirm="handleCheckConfirm"
      @reject="handleCheckReject"
    />
  </div>
</template>

<script setup name="RepairNotice">
import { getCurrentInstance, ref } from "vue";
import RepairNoticeQuery from "./components/RepairNoticeQuery.vue";
import RepairNoticeTable from "./components/RepairNoticeTable.vue";
import RepairNoticeDialog from "./components/RepairNoticeDialog.vue";
import RepairNoticeCheckDialog from "./components/RepairNoticeCheckDialog.vue";
import { getNotice } from "@/api/wms/repairNotice";
import useRepairNotice from "./useRepairNotice";

const { proxy } = getCurrentInstance();

const { repair_notice_status, handover_status } = proxy.useDict(
  "repair_notice_status",
  "handover_status"
);

/** 核对弹窗组件引用 */
const checkDialogRef = ref(null);

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
  handleView: useHandleView,
  handleDelete,
  saveDraft,
  submitProcess,
  handleStartProcess,
  handleCheckConfirm: useHandleCheckConfirm,
  handleCheckReject: useHandleCheckReject,
  cancel,
  canEdit,
  canDelete,
  canSubmit,
  canStartProcess,
  checkDialogOpen,
  checkDetailData
} = useRepairNotice(proxy);

/**
 * 查看弹窗 - 加载详情数据
 * 覆盖 useRepairNotice.js 中的 handleView（路由跳转），改为弹窗展示
 */
function handleView(row) {
  const id = row?.id;
  if (!id) return;

  getNotice(id).then((response) => {
    const data = respo
```

#### ruo-yi-wms-vue-master/src/api/wms/repairNotice.js
```
import request from "@/utils/request";

// 查询列表
export function listNotice(query) {
  return request({
    url: "/wms/RepairNotice/list",
    method: "get",
    params: query
  });
}

// 入库单选择返修通知单（仅当前机构且已提交）
export function listReceiptSelectableNotice(query) {
  return request({
    url: "/wms/RepairNotice/receiptSelectList",
    method: "get",
    params: query
  });
}

// 查询详情
export function getNotice(id) {
  return request({
    url: `/wms/RepairNotice/${id}`,
    method: "get"
  });
}

// 新增
export function addNotice(data) {
  return request({
    url: "/wms/RepairNotice",
    method: "post",
    data
  });
}

// 修改
export function updateNotice(data) {
  return request({
    url: "/wms/RepairNotice",
    method: "put",
    data
  });
}

// 删除
export function delNotice(id) {
  return request({
    url: `/wms/RepairNotice/${id}`,
    method: "delete"
  });
}

// 暂存
export function saveDraftNotice(data) {
  return request({
    url: "/wms/RepairNotice/draft",
    method: "post",
    data
  });
}

// 提交处理
export function submitRepairNotice(data) {
  return request({
    url: "/wms/RepairNotice/submit",
    method: "post",
    data
  });
}

// 移动端轻量提交
export function submitRepairNoticeMobile(data) {
  return request({
    url: "/wms/RepairNotice/mobileSubmit",
    method: "post",
    data
  });
}

// 开始处理
export function startProcessNotice(id) {
  return request({
    url: `/wms/RepairNotice/startProcess/${id}`,
    method: "post"
  });
}

// 核对通过-自动创建入库单草稿
export function confirmCheck(noticeId, data) {
  return request({
    url: `/wms/RepairNotice/confirmCheck/${noticeId}`,
    method: "post",
    data
  });
}

// 核对退回
export function rejectCheck(noticeId, data) {
  return request({
    url: `/wms/RepairNotice/rejectCheck/${noticeId}`,
    method: "post",
    data
  });
}

```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/service/RepairNoticeService.java
```
## File: RepairNoticeService.java (501 lines, 21KB)

**Package**: package com.ruoyi.wms.service;
**Imports**: 38 packages

### Classes/Interfaces (1)
- `public class RepairNoticeService {`

### Constants/Fields
private static final int MAX_CHECK_DETAIL_LIMIT = 5000;
private static final Long REPAIR_RECEIPT_OPT_TYPE = 1L;

### Methods (33)
- `public RepairNoticeCheckDetailVo startProcess(Long id) {`
- `throw new ServiceException("只有已提交状态的单据才能开始处理");`
- `throw new ServiceException("只有处理机构所属部门才能开始处理该单据");`
- `throw new ServiceException("通知单明细不能为空");`
- `throw new ServiceException("该通知单物品明细数量超过上限（最大" + MAX_CHECK_DETAIL_LIMIT + "条），当前" + details.size() + "条，请分批处理");`
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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/controller/RepairNoticeController.java
```
package com.ruoyi.wms.controller;

import cn.dev33.satoken.annotation.SaCheckPermission;
import com.ruoyi.common.core.domain.R;
import com.ruoyi.common.core.validate.AddGroup;
import com.ruoyi.common.core.validate.EditGroup;
import com.ruoyi.common.excel.utils.ExcelUtil;
import com.ruoyi.common.idempotent.annotation.RepeatSubmit;
import com.ruoyi.common.log.annotation.Log;
import com.ruoyi.common.log.enums.BusinessType;
import com.ruoyi.common.mybatis.core.page.PageQuery;
import com.ruoyi.common.mybatis.core.page.TableDataInfo;
import com.ruoyi.common.web.core.BaseController;
import com.ruoyi.wms.domain.bo.RepairNoticeBo;
import com.ruoyi.wms.domain.bo.RepairNoticeConfirmBo;
import com.ruoyi.wms.domain.bo.RepairNoticeMobileSubmitBo;
import com.ruoyi.wms.domain.bo.RepairNoticeRejectBo;
import com.ruoyi.wms.domain.vo.RepairNoticeCheckDetailVo;
import com.ruoyi.wms.domain.vo.RepairNoticeVo;
import com.ruoyi.wms.service.RepairNoticeService;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Validated
@RequiredArgsConstructor
@RestController
@RequestMapping("/wms/RepairNotice")
public class RepairNoticeController extends BaseController {

    private final RepairNoticeService repairNoticeService;

    @SaCheckPermission("wms:notice:list")
    @GetMapping("/list")
    public TableDataInfo<RepairNoticeVo> list(RepairNoticeBo bo, PageQuery pageQuery) {
        return repairNoticeService.queryPageList(bo, pageQuery);
    }

    /**
     * 入库单选择返修通知单专用列表：
     * 仅返回当前登录人机构下已提交(status=2)的通知单
     */
    @SaCheckPermission("wms:notice:list")
    @GetMapping("/receiptSelectList")
    public TableDataInfo<RepairNoticeVo> receiptSelectList(@RequestParam(required = false) String noticeNo, PageQuery pageQuery) {
        return repairNoticeService.queryReceiptSelectPage(noticeNo, pageQuery);
    }

    @SaCheckPermission("wms:notice:export")
    @Log(title = "返修通知单", businessType = BusinessType.EXPORT)
    @PostMapping("/export")
    public void export(RepairNoticeBo bo, HttpServletResponse response) {
        List<RepairNoticeVo> list = repairNoticeService.queryList(bo);
        ExcelUtil.exportExcel(list, "返修通知单", RepairNoticeVo.class, response);
    }

    @SaCheckPermission("wms:notice:query")
    @GetMapping("/{id}")
    public R<RepairNoticeVo> getInfo(@NotNull(message = "主键不能为空") @PathVariable Long id) {
        return R.ok(repairNoticeService.queryById(id));
    }

    @SaCheckPermission("wms:notice:add")
    @Log(title = "返修通知单", businessType = BusinessType.INSERT)
    @RepeatSubmit()
    @PostMapping()
    public R<Void> add(@Validated(AddGroup.class) @RequestBody RepairNoticeBo bo) {
        repairNoticeService.insertByBo(bo);
        return R.ok();
    }

 
```
