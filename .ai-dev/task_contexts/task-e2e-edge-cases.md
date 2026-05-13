## Task: 端到端验证 — 边界场景测试

验证空明细、权限拒绝、重复提交防御、字典数据显示等边界场景

### Implementation Context

验证边界场景。

测试用例列表：

1. 权限拒绝场景（对应 03-plan.md 2.4 错误码对照表）：
   a. 使用非处理机构用户调用 startProcess → 抛出"只有处理机构所属部门才能开始处理该单据"
   b. 使用非处理机构用户调用 confirmCheck → 抛出"只有处理机构所属部门才能核对该单据"
   c. 使用非处理机构用户调用 rejectCheck → 抛出"只有处理机构所属部门才能退回该单据"
   d. 通知单不存在 → 抛出"返修通知单不存在"

2. 状态校验场景：
   a. status="0" 的通知单调用 startProcess → "只有已提交状态的单据才能开始处理"
   b. status="0" 的通知单调用 confirmCheck → "只有已提交状态的单据才能核对通过"
   c. status="2" 但 handlerDeptId 不是当前机构 → 权限拒绝

3. 字典数据显示（fix 后验证）：
   a. 前端表格中 status 列应正确显示"已提交"、"处理中"等字典标签
   b. handoverStatus 列应正确显示"未交接"、"已入库"等字典标签
   c. 确认字典 key 修复后数据加载正常

4. 重复提交防御：
   a. Controller 层面有 @RepeatSubmit() 注解（基于 Redis）
   b. 前端 confirmLoading/rejectLoading 互斥
   c. 快速点击按钮时，只有第一次请求生效
   d. 验证 @RepeatSubmit 是否确实生效（Redis 防重）

5. 空数据场景（优化#3 验证）：
   a. 没有明细的通知单点击开始处理
   b. groupedDetails 为空时显示 el-empty 或文字提示
   c. groupedDetails 为空时点击入库 → details 为空数组，前端应阻止提交

6. 前端校验场景：
   a. 仓库选择器未选仓库 → 表单校验提示"请选择入库仓库"
   b. 退回原因为空 → ElMessageBox prompt 的非空校验拦截
   c. 修改实际数量为负数 → el-input-number :min="0" 阻止

输出测试报告到 .ai-dev/outputs/07-e2e-edge-cases.md


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
