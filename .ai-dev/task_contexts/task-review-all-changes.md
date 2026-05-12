## Task: 代码变更审查与文档更新

审查所有代码变更，更新 .ai-dev/outputs/ 中的文档，确认修改符合项目规范

### Implementation Context

审查所有代码变更，更新设计文档。

【审查清单】
1. 后端代码：
   - RepairNoticeService.java：确认 confirmCheck 数量修复正确
   - ReceiptOrderService.java：确认数量校验放开正确
   - 确认没有引入新的编译错误或警告
   - 确认代码风格符合项目规范（Lombok、MapStruct 等用法一致）

2. 数据库脚本：
   - 确认 20260512_repair_notice_menu.sql 语法正确
   - 确认 NOT EXISTS 条件能防止重复执行
   - 确认菜单 ID 不与已有 ID 冲突

3. 前端代码：
   - 确认行高亮 CSS 不影响其他表格样式
   - 确认分页 props 兼容性
   - 确认空状态逻辑无误

【文档更新】
1. 更新 02-analysis.md：
   - 在"需修改的模块"部分补充本次实际修改的文件列表
   - 更新问题清单状态（问题1已修复，问题2已修复）

2. 更新 03-plan.md：
   - 在 4.2 节"需要修改的文件列表"中补充实际修改的文件
   - 更新 4.3 节问题的解决状态
   - 补充代码变更详情

【项目规范检查】
- profile.yml 中的 codingRules 是否被遵守
- 没有使用 allowGlobalRefactor 禁用的全局重构
- 没有删除已有逻辑（allowDeleteExistingLogic: false）
- SQL 迁移脚本命名符合 yyyyMMdd_descriptive_name.sql 规范
- 所有修改有明确的设计依据


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

    /**
     * 核对明细最大数量限制，防止全量加载导致 OOM
     */
    private static final int MAX_CHECK_DETAIL_LIMIT = 5000;

    /**
    
```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/service/ReceiptOrderService.java
```
package com.ruoyi.wms.service;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.collection.CollectionUtil;
import cn.hutool.core.lang.Assert;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.ruoyi.common.core.constant.HttpStatus;
import com.ruoyi.common.core.constant.ServiceConstants;
import com.ruoyi.common.core.exception.ServiceException;
import com.ruoyi.common.core.exception.base.BaseException;
import com.ruoyi.common.core.utils.MapstructUtils;
import com.ruoyi.common.core.utils.StringUtils;
import com.ruoyi.common.mybatis.core.domain.BaseEntity;
import com.ruoyi.common.mybatis.core.page.PageQuery;
import com.ruoyi.common.mybatis.core.page.TableDataInfo;
import com.ruoyi.common.satoken.utils.LoginHelper;
import com.ruoyi.wms.domain.bo.ReceiptOrderBo;
import com.ruoyi.wms.domain.bo.ReceiptOrderDetailBo;
import com.ruoyi.wms.domain.entity.ReceiptOrder;
import com.ruoyi.wms.domain.entity.ReceiptOrderDetail;
import com.ruoyi.wms.domain.entity.RepairNotice;
import com.ruoyi.wms.domain.vo.ReceiptOrderDetailVo;
import com.ruoyi.wms.domain.vo.ReceiptOrderVo;
import com.ruoyi.wms.mapper.ReceiptOrderMapper;
import com.ruoyi.wms.mapper.RepairNoticeMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 入库单Service业务层处理
 *
 * @author zcc
 * @date 2024-07-19
 */
@RequiredArgsConstructor
@Service
public class ReceiptOrderService {

    private final ReceiptOrderMapper receiptOrderMapper;
    private final ReceiptOrderDetailService receiptOrderDetailService;
    private final InventoryService inventoryService;
    private final InventoryHistoryService inventoryHistoryService;
    private final ItemSkuService itemSkuService;
    private final RepairNoticeMapper repairNoticeMapper;
    private final RepairNoticeDetailService repairNoticeDetailService;
    private static final Long REPAIR_RECEIPT_OPT_TYPE = 1L;

    /**
     * 查询入库单
     */
    public ReceiptOrderVo queryById(Long id){
        ReceiptOrderVo receiptOrderVo = receiptOrderMapper.selectVoById(id);
        Assert.notNull(receiptOrderVo, "入库单不存在");
        receiptOrderVo.setDetails(receiptOrderDetailService.queryByReceiptOrderId(id));
        return receiptOrderVo;
    }

    public Long queryIdByOrderNo(String orderNo){
        ReceiptOrderVo receiptOrderVo = receiptOrderMapper.selectVoOne(new QueryWrapper<ReceiptOrder>().eq("order_no",orderNo));
        return receiptOrderVo != null ? receiptOrderVo.getId() : null;
    }

    /**
     * 查询入库单列表
     */
    public TableDataInfo<ReceiptOrderVo> queryPageList(ReceiptOrderB
```

#### wms-ruoyi-master/script/sql/20260512_repair_notice_menu.sql
```
-- ============================================================
-- 脚本名称：20260512_repair_notice_menu.sql
-- 描述：新增返修通知单菜单目录、页面菜单和权限按钮
-- 升级日期：2026-05-12
-- 说明：
--   1. 返修通知单作为独立顶级菜单（与入库/出库/移库/盘库同级，order_num=60）
--   2. 包含 1 个 C 类型菜单 + 6 个 F 类型权限按钮 = 共 7 条记录
--   3. 使用 NOT EXISTS 条件判断防止重复执行
-- ============================================================

-- 1. 插入顶级菜单：返修通知单（C 类型，页面菜单）
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `query_param`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`)
SELECT 1825000000000000001, '返修通知单', 0, 60, 'repairNotice', 'wms/order/repairNotice/index', NULL, 0, 0, 'C', '1', '1', 'wms:notice:list', 'bug', 'admin', NOW(), 'admin', NOW(), '返修通知单菜单'
WHERE NOT EXISTS (
    SELECT 1 FROM `sys_menu` WHERE `menu_id` = 1825000000000000001
);

-- 2. 插入权限按钮：查询（F 类型）
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `query_param`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`)
SELECT 1825000000000000002, '查询', 1825000000000000001, 1, '#', '', NULL, 0, 0, 'F', '1', '1', 'wms:notice:list', '#', 'admin', NOW(), 'admin', NOW(), ''
WHERE NOT EXISTS (
    SELECT 1 FROM `sys_menu` WHERE `menu_id` = 1825000000000000002
);

-- 3. 插入权限按钮：新增（F 类型）
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `query_param`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`)
SELECT 1825000000000000003, '新增', 1825000000000000001, 2, '#', '', NULL, 0, 0, 'F', '1', '1', 'wms:notice:add', '#', 'admin', NOW(), 'admin', NOW(), ''
WHERE NOT EXISTS (
    SELECT 1 FROM `sys_menu` WHERE `menu_id` = 1825000000000000003
);

-- 4. 插入权限按钮：修改（F 类型）
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `query_param`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`)
SELECT 1825000000000000004, '修改', 1825000000000000001, 3, '#', '', NULL, 0, 0, 'F', '1', '1', 'wms:notice:edit', '#', 'admin', NOW(), 'admin', NOW(), ''
WHERE NOT EXISTS (
    SELECT 1 FROM `sys_menu` WHERE `menu_id` = 1825000000000000004
);

-- 5. 插入权限按钮：删除（F 类型）
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `query_param`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`)
SELECT 1825000000000000005, '删除', 1825000000000000001, 4, '#', '', NULL, 0, 0, 'F', '1', '1', 'wms:notice:remove', '#', 'admin', NOW(), 'admin', NOW(), ''
WHERE NOT EXISTS (
    SELECT 1 FROM `sys_menu` WHERE `menu_id` = 1825000000000000005
);

-- 6. 插入权限按钮：导出（F 类型）
I
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
                    <el-tag v-else type="danger" size="small">不一
```
