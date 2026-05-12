## Task: 分组表格序号列展示方案确认与优化

分析分组表格和子表的序号列（type="index"）的连续性行为， 确认是否保持不变，或改为全局连续序号（手动计算累计索引）。


### Implementation Context

【问题描述】
分组汇总表格目前使用 <el-table-column type="index" width="60" align="center"/> 作为序号列。
Element Plus 的 type="index" 在 el-table 中每行从 1 开始递增，但不同分页或不同数据源之间
该索引是从 1 重新开始的。当前 groupedDetails 是分组后的数组（每个分组一行），
因此序号在分组间是连续的（只要 groupedDetails 是一个数组）。但在展开子表中，
每个分组独立使用 type="index"，当分组内数据跨页时，每页也从 1 开始。

【确认需求】
需要确认验收方是否要求：
a) 分组汇总表的序号全局连续（当前 type="index" on groupedDetails 数组本身即连续，无需修改）
b) 子表展开后的明细序号是否要求跨页连续（当前每页从 1 重新开始）
c) 或者各组之间的序号是否要求跨组连续（当前各组独立从 1 开始）

【推荐方案】
维持现状（各分组独立序号、子表每页独立序号），因为：
- 验收标准未明确要求跨组/跨页序号连续性
- 展开子表每页显示 50 条，用户焦点在单个分组内，跨页连续意义不大
- 如果验收方坚持全局连续，需要移除 type="index" 改用 #default 模板手动计算索引
  （计算方式：分组序号 = 前序分组 items 累加 + 当前分组索引 + 1）

【修改方式（如需全局连续）】
template 中分组表格的 <el-table-column label="序号" type="index" ...> 替换为：
<el-table-column label="序号" width="60" align="center">
  <template #default="{ $index }">
    {{ $index + 1 }}
  </template>
</el-table-column>
注意：$index 在 el-table 中是从 0 开始的当前页/数组索引，对于 groupedDetails 数组本身就是全局连续。

子表的序号如果要跨页连续，需要在 paginatedItems 中计算：
在 template 中：
<el-table-column label="序号" width="60" align="center">
  <template #default="{ $index }">
    {{ (getPageNum(row.skuName) - 1) * pageItemSize + $index + 1 }}
  </template>
</el-table-column>

【约束】
- 不改动后端 VO 结构
- 不改动 script 中除序号计算外的业务逻辑
- 修改完成后需测试分组展开/收起/分页切换后序号正确性


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

#### 02-analysis.md
```
# 需求分析报告：返修通知单核对明细页面UI调整

> 分析日期：2026-05-09
> 分析人：Goose AI Agent
> 前置文档：[requirement.md](../requirement.md) | [profile.yml](../profile.yml)
> 代码仓库：`D:\MyPrj\进销存`

---

## 1. 功能拆分

### P0（核心功能，本次必须实现）

| # | 功能名称 | 涉及模块 | 关联数据表 | 优先级 |
|---|---------|---------|-----------|-------|
| 1 | **核对明细按规格型号汇总展示** | `ruo-yi-wms-vue-master` 前端 | —（纯UI展示层变更） | P0 |
| | | views: `RepairNoticeCheckDialog.vue` | | |
| | | 后端返回VO: `RepairNoticeCheckDetailVo.java` | | |
| 2 | **汇总行数量匹配逻辑** | 前端 `RepairNoticeCheckDialog.vue` | —（前端计算逻辑） | P0 |
| | 按规格型号（skuName）分组统计预期数量与实际数量，对比匹配 | | | |
| 3 | **条码明细下拉展开** | 前端 `RepairNoticeCheckDialog.vue` | —（纯UI交互变更） | P0 |
| | 点击展开/收起该规格型号下的所有条码明细 | | | |

### P1（重要，建议本次实现）

| # | 功能名称 | 涉及模块 | 关联数据表 | 优先级 |
|---|---------|---------|-----------|-------|
| 4 | **核对明细分页支持** | 前端 `RepairNoticeCheckDialog.vue` | —（UI分页组件） | P1 |
| | 当条码明细行数较多时（>200条），启用分页展示 | | | |
| 5 | **数据接口适配** | `RepairNoticeService.java` | —（后端VO调整） | P1 |
| | `startProcess` 接口返回的 `CheckDetailItem` 需要携带 `itemId` 用于前端分组 | | | |
| | VO: `RepairNoticeCheckDetailVo.java` | | | |

### P2（后续迭代）

| # | 功能名称 | 涉及模块 | 关联数据表 | 优先级 |
|---|---------|---------|-----------|-------|
| 6 | **批量实际数量修改** | 前端 `RepairNoticeCheckDialog.vue` | — | P2 |
| | 在汇总行上直接修改实际数量，同步更新至明细行 | | | |
| 7 | **分组统计角标/徽标** | 前端 `RepairNoticeCheckDialog.vue` | — | P2 |
| | 在规格型号行展示该分组下的明细条数 | | | |

---

## 2. 数据流

### 2.1 数据来源

```
用户操作：返修通知单列表 → 点击 "开始处理" 按钮
     ↓
前端调用 POST /wms/RepairNotice/startProcess/{id}
     ↓
后端 RepairsNoticeService.startProcess() 处理
     ↓
    ├── 校验：状态必须为 "已提交"(status=2)
    ├── 校验：当前用户机构必须等于 handlerDeptId
    ├── 查询 RepairNoticeDetail（notice_id → sku_id 列表）
    ├── 批量查询 ItemSkuMapVo（sku_id → skuName, barcode, itemId）
    └── 返回 RepairNoticeCheckDetailVo
```

### 2.2 数据流转（当前逻辑）

```
数据库表：
  repair_notice (主表) 
    ├── id, notice_no, status, handler_dept_id, ...
    └── repair_notice_detail (明细)
          └── id, notice_id (FK→repair_notice.id), sku_id (FK→wms_item_sku.id)

数据库表：
  wms_ite
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
