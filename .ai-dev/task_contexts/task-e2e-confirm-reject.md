## Task: 端到端验证 — 核对通过/核对退回全流程

验证核对通过→入库（含仓库校验、匹配校验、状态变更、入库单创建）和核对退回（退回原因、状态回退）的完整流程

### Implementation Context

验证核对通过→入库和核对退回的全流程。

测试场景一：核对通过→入库（03-plan.md 5.4 场景1 的 1.8-1.10）

接口：POST /wms/RepairNotice/confirmCheck/{noticeId}
Body: { warehouseId: Long, details: [{ skuId: Long, quantity: BigDecimal }] }

后端校验链：
1. ✓ status == "2" — 否则抛 ServiceException
2. ✓ handlerDeptId == 当前登录部门 — 否则抛 ServiceException
3. ✓ 状态变更为 status="3", handoverStatus="2"
4. ✓ 重建分组校验 allMatched — 不匹配抛 ServiceException
5. ✓ 校验 details.skuId 均属于本通知单 — 否则抛 ServiceException
6. ✓ 调用 ReceiptOrderService.receive()→入库单创建→库存增加→SKU维修状态更新→库存历史记录

验收标准（对应 requirement.md 验收标准 7-11）：
7. ✓ 仓库必填校验（@NotNull）
8. ✓ 不匹配时拒绝入库（后端校验，前端二次确认）
9. ✓ 成功后 status→3, handoverStatus→2，自动创建入库单
10. ✓ 返回 R<Long>（入库单 ID）

测试场景二：核对退回（03-plan.md 5.4 场景2）

接口：POST /wms/RepairNotice/rejectCheck/{noticeId}
Body: { rejectReason: String }

后端校验链：
1. ✓ status == "2" — 否则抛 ServiceException
2. ✓ handlerDeptId == 当前登录部门 — 否则抛 ServiceException
3. ✓ 状态变更为 status="1", handoverStatus="0"
4. ✓ 写入 rejectReason

验收标准（对应 requirement.md 验收标准 8, 10）：
8. ✓ 退回原因非空前端校验 + 后端 @NotBlank 校验
10. ✓ status→1（待提交）, handoverStatus→0（未交接）

测试场景三：按钮互斥与 Loading（03-plan.md 5.4 场景6）
1. 点击入库按钮时，退回按钮 disabled（confirmLoading=true）
2. 点击退回按钮时，入库按钮 disabled（rejectLoading=true）
3. 接口返回后按钮恢复正常

需准备的数据：
- 一条 status="2" 的通知单（含多条明细，不同 skuName）
- 一个有效的仓库（wms_warehouse 表中存在记录）
- 当前登录用户的部门 = handler_dept_id

输出测试报告到 .ai-dev/outputs/05-e2e-confirm-reject.md


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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/service/ReceiptOrderService.java
```
## File: ReceiptOrderService.java (328 lines, 13KB)

**Package**: package com.ruoyi.wms.service;
**Imports**: 32 packages

### Classes/Interfaces (1)
- `public class ReceiptOrderService {`

### Constants/Fields
private static final Long REPAIR_RECEIPT_OPT_TYPE = 1L;

### Methods (29)
- `public ReceiptOrderVo queryById(Long id){`
- `public Long queryIdByOrderNo(String orderNo){`
- `public TableDataInfo<ReceiptOrderVo> queryPageList(ReceiptOrderBo bo, PageQuery pageQuery) {`
- `public List<ReceiptOrderVo> queryList(ReceiptOrderBo bo) {`
- `private LambdaQueryWrapper<ReceiptOrder> buildQueryWrapper(ReceiptOrderBo bo) {`
- `public Long insertByBo(ReceiptOrderBo bo) {`
- `public void receive(ReceiptOrderBo bo) {`
- `private void validateBeforeReceive(ReceiptOrderBo bo) {`
- `throw new BaseException("商品明细不能为空");`
- `public void updateByBo(ReceiptOrderBo bo) {`
- `public void editToInvalid(Long id) {`
- `public void deleteById(Long id) {`
- `private void validateIdBeforeDelete(Long id) {`
- `throw new ServiceException("删除失败", HttpStatus.CONFLICT,"入库单【" + receiptOrderVo.getOrderNo() + "】已入库，无法删除！");`
- `public void deleteByIds(Collection<Long> ids) {`
- `public void validateReceiptOrderNo(String receiptOrderNo) {`
- `private boolean isRepairReceipt(ReceiptOrderBo bo) {`
- `private void validateDuplicateSkuInDetails(List<ReceiptOrderDetailBo> details) {`
- `throw new ServiceException("商品明细必须包含skuId");`
- `throw new ServiceException("同一单据不允许重复选择同一物品");`
- `private void validateRepairReceiptDetails(ReceiptOrderBo bo) {`
- `throw new ServiceException("返修入库必须选择返修通知单");`
- `throw new ServiceException("返修通知单不存在");`
- `throw new ServiceException("仅已提交或处理中状态的返修通知单可用于返修入库");`
- `throw new ServiceException("该返修通知单不属于当前机构，无法用于返修入库");`
- `throw new ServiceException("返修通知单未关联可入库物品");`
- `throw new ServiceException("入库物品不属于所选返修通知单");`
- `throw new ServiceException("返修入库物品数量必须大于0");`
- `private void autoFinishRepairNoticeIfComplete(ReceiptOrderBo bo) {`
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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/bo/RepairNoticeConfirmBo.java
```
package com.ruoyi.wms.domain.bo;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.List;

/**
 * 返修通知单核对通过请求
 */
@Data
public class RepairNoticeConfirmBo implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @NotNull(message = "仓库不能为空")
    private Long warehouseId;

    @NotEmpty(message = "核对明细不能为空")
    private List<ConfirmDetail> details;

    @Data
    public static class ConfirmDetail {
        @NotNull(message = "SKU不能为空")
        private Long skuId;

        @NotNull(message = "数量不能为空")
        private BigDecimal quantity;
    }
}

```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/bo/RepairNoticeRejectBo.java
```
package com.ruoyi.wms.domain.bo;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;

/**
 * 返修通知单核对退回请求
 */
@Data
public class RepairNoticeRejectBo implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @NotBlank(message = "退回原因不能为空")
    private String rejectReason;
}

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
