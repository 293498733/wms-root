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
      提示：物品按规格型号分组汇总，点击行首箭头可展开查看具体物品条码。核对规格型号的预期数量与实际数量是否一致。
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

      <!-- 按规格型号分组的汇总表格 -->
      <el-table :data="groupedDetails" border size="small" row-key="skuName">
        <el-table-column type="expand" width="50">
          <template #default="{ row }">
            <div class="detail-sub-table-wrapper">
              <el-table
                :data="paginatedItems(row)"
                border
                size="small"
                :show-header="true"
                style="width: 100%"
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
                    <el-tag v-else type="danger" size="small">不一致</el-tag>
                  </template>
                </el-table-column>
              </el-table>
              <!-- 分页：子表明细超过 200 条时启用 -->
              <div v-if="row.items" class="detail-pagination">
                <el-pagination
                  :current-page="getPageNum(row.skuName)"
                  
```

#### ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/useRepairNotice.js
```
import { reactive, ref, toRefs } from "vue";
import {
  listNotice,
  getNotice,
  delNotice,
  saveDraftNotice,
  submitRepairNotice,
  startProcessNotice,
  confirmCheck,
  rejectCheck
} from "@/api/wms/repairNotice";

import useUserStore from "@/store/modules/user";

const userStore = useUserStore();

function normalizeFaultyDetail(detail = {}, index = 0) {
  const itemInfo = detail.item || {};
  const skuInfo = detail.itemSku || {};
  const itemId = detail.itemId ?? detail.id ?? itemInfo.id ?? null;
  const itemCode = detail.itemCode ?? itemInfo.itemCode ?? "";
  const itemName = detail.itemName ?? itemInfo.itemName ?? "";
  const itemCategory = detail.itemCategory ?? itemInfo.itemCategory ?? null;
  const itemCategoryName = detail.itemCategoryName ?? detail.faultyDeviceTypeName ?? "";
  const itemBrand = detail.itemBrand ?? itemInfo.itemBrand ?? null;
  const itemBrandName = detail.itemBrandName ?? "";
  const skuId = detail.skuId ?? skuInfo.id ?? detail.id ?? null;
  const skuName = detail.skuName ?? skuInfo.skuName ?? "";
  const skuCode = detail.skuCode ?? skuInfo.skuCode ?? "";
  const barcode = detail.barcode ?? skuInfo.barcode ?? "";

  return {
    itemId,
    itemCode,
    itemName,
    itemCategory,
    itemCategoryName,
    itemBrand,
    itemBrandName,
    skuId,
    skuName,
    skuCode,
    barcode,
    _detailKey: String(skuId ?? itemId ?? skuCode ?? itemCode ?? `${index}`)
  };
}

function normalizeFaultyDetails(formData = {}) {
  const rawList = Array.isArray(formData.faultyDeviceDetailList)
    ? formData.faultyDeviceDetailList
    : [];

  if (rawList.length) {
    return rawList.map((detail, index) => normalizeFaultyDetail(detail, index));
  }

  return [];
}

function buildSubmitPayload(formData = {}) {
  const details = normalizeFaultyDetails(formData);
  const relationDetails = details
    .map((detail) => ({ skuId: detail.skuId ?? null }))
    .filter((detail) => detail.skuId);

  return {
    ...formData,
    repairContactId: null,
    returnContactId: null,
    faultyDeviceDetailList: relationDetails
  };
}

export default function useRepairNotice(proxy) {
  const open = ref(false);
  const title = ref("");
  const loading = ref(false);
  const buttonLoading = ref(false);
  const showSearch = ref(true);
  const total = ref(0);
  const noticeList = ref([]);
  const listRequestSeq = ref(0);
  const checkDialogOpen = ref(false);
  const checkDetailData = ref(null);
  const currentNoticeId = ref(null);

  const data = reactive({
    queryParams: {
      pageNum: 1,
      pageSize: 10,
      noticeNo: undefined,
      projectPackageCode: undefined,
      applicantName: undefined,
      logisticsNo: undefined,
      sendRepairDate: undefined,
      shippedDate: undefined,
      handoverStatus: undefined,
      status: undefined
    },
    form: {},
    rules: {
      deviceSource: [{ required: true, message: "设备来源不能为空", trigger: "change" }],
      applicantId: [{ required: true, message: "送修人ID不能为空", trigger: "blur" }],
  
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
} = proxy.useDict("wms_repair_notice_status", "wms_repair_handover_status");

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
package com.ruoyi.wms.service;

import cn.hutool.core.collection.CollUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.ruoyi.common.core.exception.ServiceException;
import com.ruoyi.common.core.utils.MapstructUtils;
import com.ruoyi.common.core.utils.StringUtils;
import com.ruoyi.common.mybatis.core.page.PageQuery;
import com.ruoyi.common.mybatis.core.page.TableDataInfo;
import com.ruoyi.common.redis.utils.RedisUtils;
import com.ruoyi.common.redis.utils.RepairNoticeNoUtils;
import com.ruoyi.common.satoken.utils.LoginHelper;
import com.ruoyi.wms.domain.bo.RepairNoticeBo;
import com.ruoyi.wms.domain.bo.RepairNoticeConfirmBo;
import com.ruoyi.wms.domain.bo.RepairNoticeDetailBo;
import com.ruoyi.wms.domain.bo.RepairNoticeMobileSubmitBo;
import com.ruoyi.wms.domain.bo.RepairNoticeRejectBo;
import com.ruoyi.wms.domain.bo.ReceiptOrderBo;
import com.ruoyi.wms.domain.bo.ReceiptOrderDetailBo;
import com.ruoyi.wms.domain.entity.RepairNotice;
import com.ruoyi.wms.domain.vo.ItemSkuMapVo;
import com.ruoyi.wms.domain.vo.RepairNoticeCheckDetailVo;
import com.ruoyi.wms.domain.vo.RepairNoticeCheckDetailVo.CheckDetailItem;
import com.ruoyi.wms.domain.vo.RepairNoticeCheckDetailVo.GroupedCheckDetail;
import com.ruoyi.wms.domain.vo.RepairNoticeDetailVo;
import com.ruoyi.wms.domain.vo.RepairNoticeVo;
import com.ruoyi.wms.domain.vo.ReturnableSkuVo;
import com.ruoyi.wms.mapper.RepairNoticeMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

@RequiredArgsConstructor
@Service
public class RepairNoticeService {

    private final RepairNoticeMapper repairNoticeMapper;
    private final RepairNoticeDetailService repairNoticeDetailService;
    private final ItemSkuService itemSkuService;
    private final ReceiptOrderService receiptOrderService;
    private final com.ruoyi.wms.mapper.ReceiptOrderMapper receiptOrderMapper;
    private final com.ruoyi.wms.mapper.ReceiptOrderDetailMapper receiptOrderDetailMapper;
    private final com.ruoyi.wms.mapper.ReturnNoticeMapper returnNoticeMapper;
    private final com.ruoyi.wms.mapper.ReturnNoticeDetailMapper returnNoticeDetailMapper;

    public RepairNoticeVo queryById(Long id) {
        RepairNoticeVo vo = repairNoticeMapper.selectVoById(id);
        
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
