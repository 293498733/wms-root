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
│                                                                     │
│  index.vue                                                          │
│    ├── 挂载 RepairNoticeCheckDialog.vue（核对明细弹窗组件）           │
│    ├── 挂载 useRepairNotice.js（业务逻辑组合函数）                    │
│    └── 传递事件: @confirm="handleCheckConfirm", @reject="handleCheckReject" │
│        └── useRepairNotice.js                                       │
│            ├── handleStartProcess()  → api.startProcessNotice(id)   │
│            ├── handleCheckConfirm()  → api.confirmCheck(id, data)   │
│            └── handleCheckReject()   → api.rejectCheck(id, data)    │
│                └── api/repairNotice.js（HTTP 请求封装）              │
│                                                                     │
│  store/modules/wms.js → 缓存 warehouseList（仓库下拉列表）           │
└──────────────────────┬──────────────────────────────────────────────┘
                       │  HTTP
                       ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    后端 (wms-ruoyi-master/ruoyi-admin-wms)          │
│                                                                     │
│  RepairNoticeController.java                                        │
│    ├── POST /startProcess/{id} → RepairNoticeService.startProcess() │
│    │                                ├── validate status=="2"        │
│    │                                ├── validate handlerDeptId      │
│    │                                └── buildCheckDetail()          │
│    │                                     ├── repairNoticeDetailSvc  │
│    │                                     ├── itemSkuService         │
│    │                                     └── buildGroupedDetails()  │
│    │                                        (按skuName分组聚合)      │
│    │                                                                │
│    ├── POST /confirmCheck/{id} → RepairNoticeService.confirmCheck() │
│    │                                ├── validate status             │
│    │                                ├── validate handlerDeptId      │
│    │                                ├── update notice status→3      │
│    │                                ├── validate allMatched         │
│    │                                ├── validate skuId belongs      │
│    │                                └── ReceiptOrderService.receive()│
│    │                                     ├── create receipt_order   │
│    │                                     ├── inventoryService.add() │
│    │                                     ├── inventoryHistorySvc    │
│    │                                     └── itemSkuService         │
│    │                                                                │
│    └── POST /rejectCheck/{id} → RepairNoticeService.rejectCheck()  │
│                                     ├── validate status            │
│                                     ├── validate handlerDeptId     │
│                                     └── update notice status→1     │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.3 数据流向

#### 1.3.1 开始处理 → 获取核对明细

```
[前端] 点击"开始处理"
  → confirm("是否确认开始处理？")
  → POST /wms/RepairNotice/startProcess/{id}
  → [后端] startProcess(id)
     ├── SELECT repair_notice WHERE id=? （校验status="2" + handlerDeptId）
     ├── SELECT repair_notice_detail WHERE notice_id=? （获取全部明细SKU）
     ├── SELECT wms_item_sku + wms_item （批量关联查询SKU/物品信息）
     ├── 构建 CheckDetailItem 扁平列表（expectedQuantity=1, actualQuantity=1）
     └── 按 skuName 分组聚合 → GroupedCheckDetail 列表
  → 返回 RepairNoticeCheckDetailVo（noticeNo, noticeStatus, groupedDetails[]）
  → [前端] 弹窗展示分组汇总表格 + 展开子表
```

#### 1.3.2 核对通过 → 入库

```
[前端] 点击"核对无误-入库"
  → 校验仓库必填（el-form validate）
  → 检查分组匹配状态（存在不匹配时 ElMessageBox.confirm 二次确认）
  → POST /wms/RepairNotice/confirmCheck/{noticeId}
     Body: { warehouseId, details: [{ skuId, quantity }] }
  → [后端] confirmCheck(noticeId, bo)
     ├── SELECT repair_notice （校验status + handlerDeptId）
     ├── UPDATE repair_notice SET status="3", handoverStatus="2"
     ├── SELECT repair_notice_detail （重建分组，校验 allMatched）
     ├── 校验 details 中 skuId 均属于本通知单
     └── ReceiptOrderService.receive()
          ├── INSERT receipt_order（opt_type=1返修入库, order_status=1已完成）
          ├── INSERT receipt_order_detail
          ├── inventoryService.add() → UPDATE wms_inventory
          ├── inventoryHistoryService.saveInventoryHistory()
          └── itemSkuService.batchUpdateRepairStatus(skuIds, 2)
  → 返回 receipt_order.id
  → [前端] 关闭弹窗，刷新列表，提示成功
```

#### 1.3.3 核对退回

```
[前端] 点击"核对有误-退回"
  → ElMessageBox.prompt("退回原因", textarea, 非空校验)
  → POST /wms/RepairNotice/rejectCheck/{noticeId}
     Body: { rejectReason: "..." }
  → [后端] rejectCheck(noticeId, bo)
     ├── SELECT repair_notice（校验status + handlerDeptId）
     └── UPDATE repair_notice SET status="1", handoverStatus="0", rejectReason=?
  → 返回 success
  → [前端] 关闭弹窗，刷新列表，提示"已退回"
```

### 1.4 是否引入新依赖

| 依赖项 | 状态 | 说明 |
|--------|------|------|
| 前端-新npm包 | ❌ 无需引入 | 使用的 `el-table`、`el-input-number`、`el-pagination`、`el-tag`、`ElMessageBox` 均为 Element Plus 已有组件 |
| 后端-新Maven依赖 | ❌ 无需引入 | MyBatis-Plus、Hutool、Lombok、MapStruct、Jakarta Validation 均为项目已有依赖 |
| 新数据库表 | ❌ 无需新增 | 复用 `repair_notice`、`repair_notice_detail`、`wms_item_sku`、`wms_item` 等已有表 |
| 新Redis Key | ❌ 无需新增 | 入库单号生成使用已有 `receipt_order:no:*` 模式 |

---

## 2. 接口定义（已有接口确认）

### 2.1 开始处理 — 获取核对明细

- **路径**：`POST /wms/RepairNotice/startProcess/{id}`（已有接口，未修改）
- **方法**：POST
- **权限**：`wms:notice:edit`
- **防重**：`@RepeatSubmit()`
- **请求参数**：

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| id | Path | Long | 是 | 返修通知单 ID |

- **响应** `R<RepairNoticeCheckDetailVo>`：

| 字段 | 类型 | 说明 |
|------|------|------|
| noticeNo | String | 返修通知单号 |
| noticeStatus | String | 单据状态（"2"=已提交） |
| groupedDetails | List\<GroupedCheckDetail\> | 按规格型号分组的明细列表 |

**GroupedCheckDetail**：

| 字段 | 类型 | 说明 |
|------|------|------|
| skuName | String | 规格型号（分组 key，null 归入"未知规格"） |
| itemName | String | 物品名称（取组内第一个非空值） |
| totalExpectedQuantity | Long | 该组预期数量汇总（=组内明细数） |
| totalActualQuantity | Long | 该组实际数量汇总（=组内 actualQuantity 之和） |
| matched | Boolean | 该分组是否一致（totalActualQuantity == totalExpectedQuantity） |
| items | List\<CheckDetailItem\> | 该组下的具体物品明细列表 |

**CheckDetailItem**：

| 字段 | 类型 | 说明 |
|------|------|------|
| skuId | Long | SKU ID |
| skuName | String | 规格型号 |
| itemName | String | 物品名称 |
| barcode | String | 物品条码 |
| expectedQuantity | Long | 预期数量（固定为 1） |
| actualQuantity | Long | 实际数量（默认 1） |
| matched | Boolean | 是否一致（actualQuantity == expectedQuantity） |

### 2.2 核对通过 — 入库

- **路径**：`POST /wms/RepairNotice/confirmCheck/{noticeId}`（已有接口，未修改）
- **方法**：POST
- **权限**：`wms:notice:edit`
- **防重**：`@RepeatSubmit()`
- **请求参数**：

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| noticeId | Path | Long | 是 | 返修通知单 ID |
| warehouseId | Body | Long | 是 | 入库仓库 ID（`@NotNull` 校验） |
| details | Body | List\<ConfirmDetail\> | 是 | 核对后的物品明细列表（`@NotEmpty` 校验） |

**ConfirmDetail**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| skuId | Long | 是 | SKU ID（`@NotNull`） |
| quantity | BigDecimal | 是 | 实际入库数量（`@NotNull`，后端 use `longValue()`） |

- **响应**：`R<Long>`（入库单 ID）

- **后端校验**：
  - 通知单状态必须为 "2"（已提交）
  - 操作人部门必须等于 `handlerDeptId`
  - 提交的 `details` 中的 `skuId` 必须属于本通知单
  - 用提交的实际数量重建分组，必须 `allMatched == true`（全部一致才可入库）
  - 不匹配时抛出 `ServiceException("存在规格型号实际数量与预期数量不一致，请核对后重新提交")`

### 2.3 核对退回

- **路径**：`POST /wms/RepairNotice/rejectCheck/{noticeId}`（已有接口，未修改）
- **方法**：POST
- **权限**：`wms:notice:edit`
- **防重**：`@RepeatSubmit()`
- **请求参数**：

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| noticeId | Path | Long | 是 | 返修通知单 ID |
| rejectReason | Body | String | 是 | 退回原因（`@NotBlank` 校验） |

- **响应**：`R<Void>`

- **后端校验**：
  - 通知单状态必须为 "2"（已提交）
  - 操作人部门必须等于 `handlerDeptId`

### 2.4 错误码对照

| 错误场景 | 错误信息 | 抛出位置 |
|---------|---------|---------|
| 通知单不存在 | `返修通知单不存在` | `RepairNoticeService.getByIdRequired()` |
| 状态非"已提交" | `只有已提交状态的单据才能开始处理` | `startProcess()` |
| 状态非"已提交" | `只有已提交状态的单据才能核对通过` | `confirmCheck()` |
| 状态非"已提交" | `只有已提交状态的单据才能退回` | `rejectCheck()` |
| 权限-非处理机构 | `只有处理机构所属部门才能开始处理该单据` | `startProcess()` |
| 权限-非处理机构 | `只有处理机构所属部门才能核对该单据` | `confirmCheck()` |
| 权限-非处理机构 | `只有处理机构所属部门才能退回该单据` | `rejectCheck()` |
| 分组不匹配 | `存在规格型号实际数量与预期数量不一致，请核对后重新提交` | `confirmCheck()` |
| SKU不属于通知单 | `入库物品不属于所选返修通知单` | `confirmCheck()` |
| 明细为空 | `核对明细不能为空` | Jakarta Validation |
| 退回原因为空 | `退回原因不能为空` | Jakarta Validation |
| 仓库为空 | `仓库不能为空` | Jakarta Validation |
| 入库单号用尽 | `当天入库单号生成次数过多，请稍后重试` | `generateReceiptOrderNo()` |

---

## 3. 数据模型

### 3.1 表结构确认

**本次不涉及数据库变更。** 以下为涉及到的已有表结构确认：

#### repair_notice（返修通知单主表）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | bigint | PK, AUTO_INCREMENT | 主键 |
| notice_no | varchar(64) | UNIQUE, NOT NULL | 通知单号 |
| status | char(1) | NOT NULL, DEFAULT '0' | 状态：0=草稿, 1=待提交, 2=已提交, 3=处理中, 4=待返回, 5=已完成, 9=已关闭 |
| handover_status | char(1) | NOT NULL, DEFAULT '0' | 交接状态：0=未交接, 1=已提交, 2=已入库, 3=处理中, 4=已返回, 5=已完成 |
| handler_dept_id | bigint |  | 处理机构部门ID |
| handler_dept_name | varchar(100) |  | 处理机构部门名称 |
| reject_reason | varchar(500) |  | 退回原因 |
| ...（其他业务字段省略） |  |  |  |

#### repair_notice_detail（返修通知单明细表）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | bigint | PK, AUTO_INCREMENT | 主键 |
| notice_id | bigint | FK→repair_notice.id, NOT NULL | 通知单ID |
| sku_id | bigint | FK→wms_item_sku.id, NOT NULL | SKU ID |
| UNIQUE(notice_id, sku_id) |  |  | 联合唯一约束 |

#### wms_item_sku（物品SKU表）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | bigint | PK, AUTO_INCREMENT | 主键 |
| sku_name | varchar(200) |  | 规格型号 |
| sku_code | varchar(100) |  | SKU编码 |
| barcode | varchar(100) |  | 条码 |
| item_id | bigint | FK→wms_item.id | 所属物品ID |
| repair_status | tinyint | DEFAULT 0 | 维修状态：0=正常, 1=已送修, 2=维修中, 3=已返回 |

#### wms_item（物品表）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | bigint | PK, AUTO_INCREMENT | 主键 |
| item_name | varchar(200) |  | 物品名称 |

### 3.2 字典数据确认

| dict_type | dict_value | dict_label | 说明 |
|-----------|-----------|-----------|------|
| repair_notice_status | 0 | 草稿 |  |
| repair_notice_status | 1 | 待提交 |  |
| repair_notice_status | 2 | 已提交 |  |
| repair_notice_status | 3 | 处理中 |  |
| repair_notice_status | 4 | 待返回 |  |
| repair_notice_status | 5 | 已完成 |  |
| repair_notice_status | 9 | 已关闭 |  |
| handover_status | 0 | 未交接 |  |
| handover_status | 1 | 已提交 |  |
| handover_status | 2 | 已入库 |  |
| handover_status | 3 | 处理中 |  |
| handover_status | 4 | 已返回 |  |
| handover_status | 5 | 已完成 |  |

### 3.3 SQL 确认

本次无需执行任何 DDL 或 DML 变更。

---

## 4. 代码变更

### 4.1 核心结论

**根据完整代码审计，所有需求功能已在代码中实现，无需修改源代码文件（.java/.vue/.js/.xml等）。**

以下列出**代码与需求文档的逐项对照确认**，以及**可选优化项**（非必须）。

### 4.2 前端代码逐项确认

| 需求项 | 代码实现位置 | 确认状态 |
|--------|-------------|---------|
| 分组汇总表格 | `RepairNoticeCheckDialog.vue` L33-L95（el-table with type="expand"） | ✅ **已实现** |
| 规格型号分组 | `RepairNoticeCheckDialog.vue` L163-L165（computed `groupedDetails`） | ✅ **已实现** |
| 展开子表 | `RepairNoticeCheckDialog.vue` L34-L78（expand slot 含子表） | ✅ **已实现** |
| 实际数量编辑 | `RepairNoticeCheckDialog.vue` L49-L56（el-input-number no-controls, 90px） | ✅ **已实现** |
| 匹配状态实时更新 | `RepairNoticeCheckDialog.vue` L199-L211（`onQuantityChange()`） | ✅ **已实现** |
| 子表分页(>200, 50条/页) | `RepairNoticeCheckDialog.vue` L67-L76 + L153-L186（`pageMap`, `paginatedItems()`） | ✅ **已实现** |
| 分组独立页码 | `RepairNoticeCheckDialog.vue` L158（`pageMap: Map<skuName, currentPage>`） | ✅ **已实现** |
| 匹配标签 | `RepairNoticeCheckDialog.vue` L60-L63 + L90-L93（el-tag success/danger） | ✅ **已实现** |
| 仓库选择+必填校验 | `RepairNoticeCheckDialog.vue` L19-L30（el-form rules） | ✅ **已实现** |
| 退回原因弹窗+非空校验 | `RepairNoticeCheckDialog.vue` L268-L284（`ElMessageBox.prompt`） | ✅ **已实现** |
| 按钮互斥禁用+loading | `RepairNoticeCheckDialog.vue` L100-L115（confirmLoading/rejectLoading 互斥） | ✅ **已实现** |
| 提示说明文字 | `RepairNoticeCheckDialog.vue` L10-L12（div.dialog-tip） | ✅ **已实现** |
| 取消按钮关闭弹窗 | `RepairNoticeCheckDialog.vue` L213-L215（`handleCancel()`） | ✅ **已实现** |
| 入库二次确认(不匹配时) | `RepairNoticeCheckDialog.vue` L240-L252（`ElMessageBox.confirm`） | ✅ **已实现** |

### 4.3 后端代码逐项确认

| 需求项 | 代码实现位置 | 确认状态 |
|--------|-------------|---------|
| 开始处理接口 | `RepairNoticeController.java` L116-L119 → `RepairNoticeService.startProcess()` L341-L354 | ✅ **已实现** |
| 校验status="2" | `startProcess()` L344-L346 | ✅ **已实现** |
| 校验handlerDeptId | `startProcess()` L348-L350 | ✅ **已实现** |
| 构建核对明细 | `buildCheckDetail()` L359-L377 | ✅ **已实现** |
| 批量查询SKU/物品信息 | `buildCheckDetailItems()` L382-L411（`itemSkuService.queryItemSkuMapVosByIds()`） | ✅ **已实现** |
| 按skuName分组聚合 | `buildGroupedDetails()` L416-L447（`Collectors.groupingBy`） | ✅ **已实现** |
| 核对通过接口 | `RepairNoticeController.java` L124-L128 → `RepairNoticeService.confirmCheck()` L452-L528 | ✅ **已实现** |
| 校验分组匹配性 | `confirmCheck()` L493-L497 | ✅ **已实现** |
| 校验SKU归属 | `confirmCheck()` L498-L502 | ✅ **已实现** |
| 状态变更status=3,handoverStatus=2 | `confirmCheck()` L463-L467 | ✅ **已实现** |
| 自动创建入库单 | `confirmCheck()` L505-L526 → `ReceiptOrderService.receive()` | ✅ **已实现** |
| 核对退回接口 | `RepairNoticeController.java` L133-L138 → `RepairNoticeService.rejectCheck()` L533-L549 | ✅ **已实现** |
| 退回状态变更status=1,handoverStatus=0 | `rejectCheck()` L543-L548 | ✅ **已实现** |

### 4.4 可选优化清单（非必须，建议但不强制）

以下为分析报告中指出的优化建议，按重要性排序：

#### 🟡 P2级优化建议

| # | 优化项 | 说明 | 改动文件 | 建议实施 |
|---|--------|------|---------|---------|
| 1 | **消除后端重复SKU查询** | `RepairNoticeDetailService.fillSkuAndItemInfo()` 已填充 `itemSku` / `item` 到 `RepairNoticeDetailVo`，但 `buildCheckDetailItems()` 中通过 `itemSkuService.queryItemSkuMapVosByIds()` 又查了一遍。可复用 `RepairNoticeDetailVo` 中已填充的数据。 | `RepairNoticeService.java` — `buildCheckDetailItems()` 方法 | ✅ **推荐修复**（性能优化，代码简洁） |
| 2 | **修复字典 key 前缀** | 前端 `index.vue` L76 使用 `proxy.useDict("wms_repair_notice_status", "wms_repair_handover_status")`，但 SQL 中字典 `dict_type` 值为 `repair_notice_status` 和 `handover_status`（无 `wms_` 前缀）。可能导致字典数据加载为空。 | `index.vue` L76 — 修改 key | ✅ **推荐修复**（功能正确性） |
| 3 | **空明细状态提示** | 当通知单无可核对物品时，弹窗展示空表格，无提示信息。增加空状态文字提示。 | `RepairNoticeCheckDialog.vue` 增加 `v-if` 空状态显示 | 🟢 **推荐增强**（用户体验） |
| 4 | **确认 handoverStatus 覆盖逻辑** | `confirmCheck()` 设 `handoverStatus=2`（已入库）→ `receive()` → `autoFinishRepairNoticeIfComplete()` 又覆盖为 `3`（处理中）。需确认这是否为预期行为。 | 无需代码改动，需产品确认 | ⚠️ **需确认** |

#### 🟢 P3级建议（低优）

| # | 优化项 | 说明 |
|---|--------|------|
| 5 | 后端增加最大明细数限制 | 当 `repair_notice_detail` 记录达到数万条时，`buildCheckDetail()` 全量加载可能 OOM。建议加限制（如5000条）。 |
| 6 | actualQuantity=0 处理 | 用户将实际数量改为0时，传0到后端 `confirmCheck()` 会导致入库校验问题。当前 `quantity` 被 `longValue()` 使用，0表示缺失。需确认业务含义。 |
| 7 | 日志增强 | 当前 Controller 层已有 `@Log` 注解，核对通过和退回有操作日志，无需额外改动。 |

### 4.5 需要修改/新增/删除的文件清单

#### 必须修改的文件

| 文件路径 | 修改内容摘要 | 优先级 |
|---------|-------------|--------|
| **无** | 核心功能已全部实现，无需修改源代码 | — |

#### 建议修改的文件（可选优化#1 — 消除重复查询）

| 文件路径 | 修改内容摘要 | 影响范围 |
|---------|-------------|---------|
| `wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/service/RepairNoticeService.java` | `buildCheckDetailItems()` 中复用 `RepairNoticeDetailVo` 的 `itemSku`/`item` 属性，去掉 `itemSkuService.queryItemSkuMapVosByIds(skuIds)` 的重复调用 | 仅此方法，不影响其他功能 |

#### 建议修改的文件（可选优化#2 — 字典前缀）

| 文件路径 | 修改内容摘要 | 影响范围 |
|---------|-------------|---------|
| `ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/index.vue` | L76: `proxy.useDict("repair_notice_status", "handover_status")` 去掉 `wms_` 前缀 | 仅字典数据加载，不影响其他 |

#### 建议修改的文件（可选优化#3 — 空明细提示）

| 文件路径 | 修改内容摘要 | 影响范围 |
|---------|-------------|---------|
| `ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/components/RepairNoticeCheckDialog.vue` | `checkDetail` 存在但 `groupedDetails` 为空时，增加 el-empty 或文字提示 | 仅视图层 |

#### 需要新增的文件

| 文件路径 | 说明 |
|---------|------|
| **无** | 无需新增任何文件 |

#### 需要删除的文件

| 文件路径 | 说明 |
|---------|------|
| **无** | 无需删除任何文件 |

### 4.6 配置变更

| 配置项 | 变更说明 | 状态 |
|--------|---------|------|
| `application.yml` | 无需变更 | ✅ |
| `application-*.yml` | 无需变更 | ✅ |
| `bootstrap.yml` | 无需变更 | ✅ |
| 前端 `vue.config.js` / `.env.*` | 无需变更 | ✅ |
| 字典数据 `sys_dict_type` / `sys_dict_data` | 无需变更（已有数据） | ✅ |

---

## 5. 测试方案

### 5.1 现有测试确认

项目已有单元测试文件：

| 文件 | 现有用例数 | 测试范围 | 状态 |
|------|-----------|---------|------|
| `RepairNoticeServiceTest.java` | 7 | `buildGroupedDetails()` 私有方法（反射调用）：分组正确性、匹配逻辑、空列表、null skuName、混合匹配、itemName 取值 | ✅ **全部通过**（7/7） |

### 5.2 单元测试范围（可选增强）

如果实施可选优化#1（消除重复查询），建议补充单元测试：

| 测试类 | 新增用例 | 说明 |
|--------|---------|------|
| `RepairNoticeServiceTest.java` | `testBuildCheckDetailItems_withDuplicatedSkuQuery()` | 验证 `buildCheckDetailItems()` 是否正确复用已有 SKU 数据 |
| `RepairNoticeServiceTest.java` | `testStartProcess_withInvalidStatus()` | 验证非"2"状态时抛异常 |
| `RepairNoticeServiceTest.java` | `testConfirmCheck_withAllMatchedStatus()` | 验证全部匹配时入库成功 |
| `RepairNoticeServiceTest.java` | `testConfirmCheck_withMismatchStatus_shouldThrow()` | 验证不匹配时拒绝入库 |

### 5.3 集成测试范围

| 测试项 | 测试方法 | 前置条件 |
|--------|---------|---------|
| 开始处理-分组正确性 | 调用 `POST /wms/RepairNotice/startProcess/{id}`，验证返回的 `groupedDetails` 结构正确 | 需在DB中准备一条status="2"的通知单及若干明细 |
| 核对通过-入库全流程 | 调用 `POST /wms/RepairNotice/confirmCheck/{id}`，验证通知单状态变更、入库单创建、库存增加 | 需准备完整数据（仓库、SKU等） |
| 核对退回-状态回退 | 调用 `POST /wms/RepairNotice/rejectCheck/{id}`，验证status→1, handoverStatus→0 | 需准备status="2"的通知单 |
| 权限校验 | 使用非处理机构用户调用三个接口，验证均被拒绝 | 需准备不同机构用户 |

### 5.4 手动测试步骤

#### 测试场景1：正常核对流程

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| 1.1 | 登录系统，进入"返修通知单"页面 | 列表显示返修通知单 |
| 1.2 | 找到一条**已提交**(status=2)且当前机构是处理机构的通知单，点击"开始处理" | 弹出确认对话框 |
| 1.3 | 确认"开始处理" | 弹窗"核对明细"显示，顶部有提示文字，表格按规格型号分组展示 |
| 1.4 | 查看分组汇总行：物品名称、规格型号、预期数量、实际数量、匹配状态（绿色"一致"标签） | 数据正确，默认全部一致 |
| 1.5 | 点击行首展开箭头 | 展开子表，显示该组下的具体物品条码 |
| 1.6 | 修改某条明细的"实际数量"（如改为0） | 该行匹配变为"不一致"（红色标签），所属分组的实际数量汇总同步更新，分组匹配状态变为"不一致" |
| 1.7 | 将实际数量改回1 | 匹配状态恢复为"一致" |
| 1.8 | 选择入库仓库 | 下拉列表加载仓库数据 |
| 1.9 | 点击"核对无误-入库" | 调用核对通过接口，返回成功提示，弹窗关闭，列表刷新 |
| 1.10 | 查看该通知单状态 | status变为"处理中"(3)，handoverStatus变为"已入库"(2) |

#### 测试场景2：核对退回

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| 2.1 | 点击"开始处理"打开核对明细弹窗 | — |
| 2.2 | 点击"核对有误-退回" | 弹出退回原因输入框 |
| 2.3 | 不输入原因直接确认 | 提示"退回原因不能为空" |
| 2.4 | 输入退回原因后确认 | 调用核对退回接口，关闭弹窗，刷新列表 |
| 2.5 | 查看该通知单状态 | status变为"待提交"(1)，handoverStatus变为"未交接"(0) |

#### 测试场景3：分组不匹配时入库二次确认

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| 3.1 | 打开核对明细弹窗后，修改某分组下实际数量（使分组不匹配） | 分组匹配状态变为"不一致"（红色） |
| 3.2 | 点击"核对无误-入库" | 弹出确认提示"存在数量不一致的物品，确认仍要入库吗？" |
| 3.3 | 点击"取消" | 不操作，弹窗保持 |
| 3.4 | 再次点击"核对无误-入库"，点击"确认入库" | 后端校验不匹配，返回错误提示"存在规格型号实际数量与预期数量不一致，请核对后重新提交" |

#### 测试场景4：仓库必填校验

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| 4.1 | 打开核对明细弹窗，不选择仓库 | — |
| 4.2 | 点击"核对无误-入库" | 表单校验提示"请选择入库仓库" |

#### 测试场景5：子表分页

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| 5.1 | 准备一条有200+条明细（同一skuName）的通知单 | — |
| 5.2 | 打开核对明细弹窗，展开该分组子表 | 子表下方显示分页组件，每页50条 |
| 5.3 | 点击分页的下一页/上一页 | 子表内容随页码更新 |
| 5.4 | 切换到另一个分组展开 | 该分组显示第1页数据，两个分组页码独立 |

#### 测试场景6：按钮互斥

| 步骤 | 操作 | 预期结果 |
|------|------|---------|
| 6.1 | 点击"核对无误-入库" | "核对有误-退回"按钮被 disabled（反之亦然） |
| 6.2 | 等待接口返回后 | 按钮恢复正常 |

---

## 附录A：已确认的悬而未决项处理

以下为需求分析和检查点中标识的不确定项，在本方案中已明确处理：

| 不确定项 | 处理结论 | 方案中的处理 |
|---------|---------|-------------|
| 分组粒度：同skuName不同itemName时 | **维持现有仅按skuName分组**。代码中 `buildGroupedDetails()` 取组内第一个非空itemName作为分组名称 | 已在 1.3 数据流和 2.1 接口定义中明确 |
| expectedQuantity 固定为1 | **维持现状**（每条 repair_notice_detail 代表1件物品） | 已在 2.1 接口定义和3.1 表结构中确认 |
| 分页阈值200/50是否可配置 | **维持硬编码**（`pageItemThreshold=200`, `pageItemSize=50`） | 已在代码分析和前端确认 |
| 字典 key 前缀不一致 | **建议修复**：前端 `wms_repair_notice_status` → `repair_notice_status` | 已在 4.4 可选优化#2中记录 |
| handoverStatus 被 autoFinish 覆盖 | **需产品确认**：`confirmCheck` 设 handoverStatus=2，但 `autoFinishRepairNoticeIfComplete()` 可能覆盖为3 | 已在 4.4 可选优化#4中记录 |
| actualQuantity=0 的场景 | **需产品确认**：0表示缺失时，后端入库校验可能拒绝 | 已在 4.4 可选优化#6中记录 |
| 后端重复SKU查询 | **建议修复**：`buildCheckDetailItems()` 中复用 `RepairNoticeDetailVo` 的已填充数据 | 已在 4.4 可选优化#1中记录 |
| 空明细时空白展示 | **建议增强**：增加空状态提示 | 已在 4.4 可选优化#3中记录 |
| 性能：最大明细数限制 | **建议加限制**（如5000条） | 已在 4.4 可选优化#5中记录 |

## 附录B：代码仓库差异记录

| 差异项 | 需求文档描述 | 代码实际实现 | 处理方式 |
|--------|------------|------------|---------|
| 分组聚合 | 按 skuName 分组 | 按 skuName 分组，null 归入"未知规格" | **以代码为准**，不影响功能 |
| 入库单号格式 | 未描述 | `RK + yyyyMMddHHmmss + 4位自增` | **以代码为准**，无需修正 |
| 状态值 | 核过后status=3, handoverStatus=2 | 代码同需求描述 | ✅ 一致 |
| 退回状态 | status=1, handoverStatus=0 | 代码同需求描述 | ✅ 一致 |
