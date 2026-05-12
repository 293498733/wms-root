## Task: 新增返修通知单菜单和权限按钮的 SQL 迁移脚本

创建 20260512_repair_notice_menu.sql 迁移脚本，为 sys_menu 表新增返修通知单菜单目录、页面菜单和 7 个权限按钮

### Implementation Context

创建 SQL 迁移脚本，在 sys_menu 表中新增返修通知单相关菜单和权限按钮。

【背景】
RepairNoticeController 已使用 @SaCheckPermission 注解定义了 7 个权限标识：
- wms:notice:list（列表查询 + receiptSelectList）
- wms:notice:query（详情查询）
- wms:notice:add（新增）
- wms:notice:edit（编辑、草稿、提交、mobileSubmit、开始处理、核对通过、核对退回）
- wms:notice:remove（删除）
- wms:notice:export（导出）

但 wms.sql 中并没有对应的 sys_menu 记录，导致管理员无法通过角色管理界面分配权限。

【已知父菜单 ID】
从 wms.sql 已知的菜单 ID：
- 父菜单「基础资料」menu_id = 1808758090157985794（order_num=100）
- 入库单菜单 menu_id = 1818466281474822145（order_num=20，顶级 C 类型）
- 出库单菜单 menu_id = 1818854933803638785（order_num=30，顶级 C 类型）
- 移库单菜单 menu_id = 1822820194307051521（order_num=40，顶级 C 类型）
- 盘库单菜单 menu_id = 1823187248797270018（order_num=50，顶级 C 类型）

【设计决策】
返修通知单应该放在哪个菜单下？
方案 A：放在「基础资料」作为子菜单（与商品管理、仓库管理等并列）
方案 B：作为独立顶级菜单（与入库/出库/移库/盘库并列，order_num=60）

→ 选择方案 B，因为返修通知单是业务流程单据，与入库/出库/移库/盘库属于同一层级。

【SQL 脚本要求】
1. 文件名：20260512_repair_notice_menu.sql
2. 使用 NOT EXISTS 条件判断防止重复执行
3. 菜单 ID 使用雪花算法风格（参考已有菜单的 18 开头的 19 位数字）
4. 新增记录：
   
   顶级菜单（C 类型）：
   - menu_name='返修通知单', parent_id=0, order_num=60
   - path='repairNotice', component='wms/order/repairNotice/index'
   - permission='wms:notice:list', icon='bug'（参考需求分析中的图标建议）
   - visible=1, status=1

   权限按钮（F 类型，parent_id=上面菜单的 ID）：
   - 查询：permission='wms:notice:list', order_num=1
   - 新增：permission='wms:notice:add', order_num=2
   - 修改：permission='wms:notice:edit', order_num=3
   - 删除：permission='wms:notice:remove', order_num=4
   - 导出：permission='wms:notice:export', order_num=5
   - 详情：permission='wms:notice:query', order_num=6

5. 遵循 profile.yml 中的 migrationNaming 规范：yyyyMMdd_descriptive_name.sql
6. SQL 放置在 wms-ruoyi-master/script/sql/ 目录下

【验证】
检查 SQL 语法无错误，确保 NOT EXISTS 条件能正确防止重复插入。


### Reference Documents

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

#### wms-ruoyi-master/script/sql/wms.sql
```
# File: wms.sql (1118 lines, 105KB)

## Structure (classes, functions, top-level declarations)

... (1118 total lines — request specific sections if needed)
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
