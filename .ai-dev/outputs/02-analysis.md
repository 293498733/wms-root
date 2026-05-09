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
  wms_item_sku (SKU表)
    ├── id, sku_name (规格型号名称), sku_code, barcode, item_id (FK→wms_item.id)
    └── wms_item (物料/物品表)
          └── id, item_code, item_name (物品名称), unit, ...

后端构建 CheckDetailItem（当前逻辑）：
  每条 repair_notice_detail 记录 → 1条 CheckDetailItem
    ├── skuId = detail.skuId
    ├── skuName = ItemSku.skuName        ← "规格型号"名称
    ├── itemName = Item.itemName          ← 物品名称
    ├── barcode = ItemSku.barcode
    ├── expectedQuantity = 1 (硬编码)      ← 当前需求要汇总此字段
    ├── actualQuantity = 1 (默认值)        ← 用户可修改
    └── matched = true (由 actualQuantity === expectedQuantity 决定)
```

### 2.3 数据最终存储

核对通过后数据流：
```
修复单 → confirmCheck({warehouseId, details[{skuId, quantity}]})
    │
    ├── 1. 更新 repair_notice.status = "3"(处理中)
    │                         .handoverStatus = "2"(处理中)
    │
    ├── 2. 构建 ReceiptOrder（入库单）
    │      ├── receipt_order 表（order_no, biz_order_no=noticeNo, ...）
    │      └── receipt_order_detail 表（sku_id, quantity, warehouse_id, ...）
    │
    └── 3. receiptOrderService.receive() 
           ├── 增加 inventory 表库存
           ├── 记录 inventory_history 表
           └── 更新 item_sku.repair_status
```

核对退回后数据流：
```
rejectCheck({rejectReason})
    │
    └── 更新 repair_notice.status = "1"(待提交)
                         .handoverStatus = "0"(待交接)
                         .rejectReason = 退回原因
```

### 2.4 本次变更后的数据流

```
startProcess 接口返回值变更（RepairNoticeCheckDetailVo）：
  
  当前返回：扁平 list，每条 1 条明细
  变更后：按 skuName 分组的嵌套结构

  {
    "noticeNo": "FXTZD...",
    "noticeStatus": "2",
    "groupedDetails": [                          ← 新增上层分组
      {
        "skuName": "规格型号A",                   ← 分组key
        "itemName": "物品名称",
        "totalExpectedQuantity": 5,              ← 汇总预期数量
        "totalActualQuantity": 5,                ← 汇总实际数量
        "matched": true,                         ← 汇总匹配状态
        "items": [                               ← 明细列表（默认收起）
          { skuId, barcode, expectedQuantity:1, actualQuantity:1, matched:true },
          { skuId, barcode, expectedQuantity:1, actualQuantity:1, matched:true },
          ...
        ]
      },
      ...
    ]
  }
```

---

## 3. 界面逻辑

### 3.1 涉及页面

| 页面/组件 | 文件路径 | 变更类型 |
|-----------|---------|---------|
| 核对明细弹窗 | `ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/components/RepairNoticeCheckDialog.vue` | **核心变更** |
| 返修通知单列表 | `.../repairNotice/index.vue` | 无需变更 |
| 列表逻辑 | `.../repairNotice/useRepairNotice.js` | 无需变更 |
| 后端VO | `wms-ruoyi-master/.../domain/vo/RepairNoticeCheckDetailVo.java` | **需扩展** |
| 后端Service | `.../service/RepairNoticeService.java` | **需扩展**（buildCheckDetail方法） |

### 3.2 交互流程

#### 当前交互（现状）
```
1. 列表页 → 点击 "开始处理" 按钮
2. 弹窗打开 "核对明细"（RepairNoticeCheckDialog）
3. 弹窗内容：
   ├── 通知单信息头（noticeNo + 状态）
   ├── 入库仓库下拉选择（必填）
   └── 明细表格
        ├── 序号 | 物品名称 | 规格型号 | 条码 | 预期数量 | 实际数量(input) | 匹配
        └── 逐行展示每条 repair_notice_detail + sku 信息
4. 底部按钮：取消 | 核对有误-退回 | 核对无误-入库
```

#### 变更后交互（本次需求）
```
1. 列表页 → 点击 "开始处理" 按钮
2. 弹窗打开 "核对明细"（RepairNoticeCheckDialog）
3. 弹窗内容：
   ├── 通知单信息头（noticeNo + 状态）
   ├── 入库仓库下拉选择（必填）
   └── 汇总表格（按规格型号 skuName 分组）
        ├── 序号 | 物品名称 | 规格型号 | 预期数量 | 实际数量 | 匹配 | 操作
        ├── [行1] 物品A | 规格型号X | 预期5 | 实际5[input] | ✓一致 | ▶展开↓
        │     └── (展开后子表)
        │          ├── 条码001 | 预期1 | 实际1[input] | ✓
        │          ├── 条码002 | 预期1 | 实际1[input] | ✓
        │          ├── 条码003 | 预期1 | 实际1[input] | ✓
        │          ├── 条码004 | 预期1 | 实际1[input] | ✓
        │          └── 条码005 | 预期1 | 实际1[input] | ✓
        ├── [行2] 物品B | 规格型号Y | 预期3 | 实际2[input] | ✗不一致 | ▶展开↓
        ...
4. 底部按钮：取消 | 核对有误-退回 | 核对无误-入库
```

### 3.3 输入验证

| 验证项 | 规则 | 说明 |
|-------|------|------|
| 入库仓库 | 必填 | `el-select` + 非空校验（现有逻辑） |
| 汇总行实际数量 | 必须 >= 0 | `el-input-number` min=0（现有逻辑复用） |
| 明细行实际数量 | 必须 >= 0 | 汇总行修改后需同步到明细行 |
| 汇总匹配 | 所有明细行匹配才为一致 | 前端计算 `totalActual === totalExpected` |
| 提交时全不一致 | 弹窗二次确认 | 复用现有 `ElMessageBox.confirm` 逻辑 |

### 3.4 分页逻辑

```
当 groupedDetails 下的 items 数量 > 200 时：
  └── 子表启用 el-pagination 分页，每页建议 50 条
```

---

## 4. 不确定项（最关键的部分）

### 4.1 业务规则不确定项

- [ ] **预期数量的取值规则** | 当前后端 `buildCheckDetail()` 中 `expectedQuantity` 硬编码为 `1L`，因为 `repair_notice_detail` 表只有 `(notice_id, sku_id)` 关系，没有数量字段。需求要求"按规格型号汇总预期数量"，但一个规格型号下的多条明细当前每条预期数量都是1，汇总后就是明细条数。请确认：① 每个SKU的预期数量是否永远为1？② 是否需要在 `repair_notice_detail` 表增加 `quantity` 字段以支持非1的数量？ | 产品经理/业务方

- [ ] **实际数量修改的联动规则** | 当前每条明细都有一个 `el-input-number` 可独立修改实际数量。改为分组汇总后：① 是否允许在汇总行上批量修改实际数量（汇总行修改后按比例/均匀分配到明细行）？② 还是保留逐条修改后自动汇总？③ 两种模式都支持？ | 产品经理

- [ ] **规格型号完全一致但物品名称不同的情况** | 当前数据模型中 `skuName`（规格型号）与 `itemName`（物品名称）是多对一关系（多个SKU可对应同一物品）。如果出现相同 `skuName` 但不同 `itemName`，应当合并还是分开成组？建议按 `skuName` 合并，因为需求明确说"按照规格型号进行汇总"。 | 产品经理/技术负责人

- [ ] **"匹配"状态的计算粒度** | 汇总行的"一致/不一致"是取所有明细行的逻辑与（全部一致才一致），还是按汇总数量判断（汇总actual=汇总expected即一致）？建议按汇总数量判断，更符合汇总的目的。 | 产品经理/技术负责人

### 4.2 技术不确定项

- [ ] **后端是否需要增加分组返回的接口字段** | 目前 `RepairNoticeCheckDetailVo` 返回扁平的 `List<CheckDetailItem>`，按规格型号分组可以在前端完成（前端按 skuName 做 groupBy），也可以后端返回分组结构。推荐**后端直接返回分组结构**以减少前端计算量，但需要扩展 VO。当前 VO 中 `CheckDetailItem` 没有 `itemId` 字段，分组时需要确认 skiName 作为唯一分组 key 是否足够。 | 技术负责人

- [ ] **分页阈值配置化** | 是否需要将"200条启用分页"做成可配置项（如通过系统参数表 `sys_config` 配置），还是硬编码在代码中？建议本次硬编码，后续迭代可配置。 | 技术负责人

- [ ] **移动端适配** | 当前移动端有 `mobileSubmit` 接口和 `views/mobile/repairNotice/` 目录（空）。本次变更是否要考虑移动端「开始处理」后核对弹窗的一致性？ | 技术负责人

- [ ] **大规模数据性能** | 如果一个返修通知单包含数百甚至上千条 SKU 明细（`repair_notice_detail` 记录），`startProcess` 接口返回后前端一次性渲染所有展开子表是否会卡顿？建议后端只返回汇总层数据，明细条码通过懒加载按需获取，或前端按需展开渲染。 | 技术负责人

### 4.3 现有代码中未找到对应实现的问题

- [ ] **后端 `startProcess` 接口不返回 `itemId` 字段** | 当前 `CheckDetailItem` 类没有 `itemId`，只有 `skuId`（SKU级）。按规格型号分组需要 `skuName`，但同名的 `skuName` 在不同物品下可能重复，建议增加 `itemId` 字段以确保分组的精确性。 | 后端开发

- [ ] **`repair_notice_detail` 表没有数量字段** | 当前表结构只有 `(id, notice_id, sku_id)`，每条记录隐含数量=1。如果未来需要支持同一SKU多条（数量>1），需要表结构变更。当前需求下不需要变更数据库。 | 技术负责人

### 4.4 兼容性不确定项

- [ ] **核对通过后入库单创建逻辑是否需要调整** | 当前 `confirmCheck` 将每条 `detail` 转为 `ReceiptOrderDetailBo`，`quantity=BigDecimal.ONE`。如果改为汇总模式，入参传递的是汇总数量还是逐条明细？建议保持入参为逐条SKU明细（`skuId + quantity`），后端按SKU聚合后创建入库单明细。 | 技术负责人

- [ ] **现有已处理的返修通知单数据兼容性** | 已有数据库中状态为"3(处理中)"的单据不受本次UI变更影响，但如果有用户在变更窗口期内打开核对弹窗，前端需要同时兼容新旧两种数据格式（或通过版本号判断）。建议后端 VO 增加 `version` 字段或通过 `details` 是否包含 `groupedDetails` 区分。 | 技术负责人

---

## 5. 影响范围

### 5.1 需要修改的文件

#### 后端（Java）

| 文件 | 修改内容 | 变更类型 |
|------|---------|---------|
| `wms-ruoyi-master/.../domain/vo/RepairNoticeCheckDetailVo.java` | 新增 `GroupedCheckDetail` 内部类，扩展分组嵌套结构 | 新增类/修改 |
| `wms-ruoyi-master/.../service/RepairNoticeService.java` | 修改 `buildCheckDetail()` 方法，按 `skuName` 分组返回 | 方法修改 |
| | 确认 `CheckDetailItem` 是否增加 `itemId` 字段 | 可选字段增加 |

#### 前端（Vue）

| 文件 | 修改内容 | 变更类型 |
|------|---------|---------|
| `.../repairNotice/components/RepairNoticeCheckDialog.vue` | **核心变更**：表格改为分组-子表结构，增加展开/收起、分页逻辑 | 重写表格部分 |
| | 汇总行实际数量联动明细行逻辑 | 新增计算逻辑 |
| | 汇总匹配状态计算逻辑 | 新增计算属性 |
| `.../api/wms/repairNotice.js` | 无需变更（接口路径和参数不变） | — |

### 5.2 数据库变更

| 变更 | 说明 |
|------|------|
| **无数据库变更** | 本次需求为纯UI展示层调整 + 后端VO结构调整，不涉及新增表/字段/索引 |

### 5.3 配置变更

| 配置项 | 说明 |
|-------|------|
| **无配置变更** | 不涉及 `application.yml` 等配置文件修改 |

### 5.4 接口兼容性

| 接口 | 影响 | 说明 |
|------|------|------|
| `POST /wms/RepairNotice/startProcess/{id}` | **向前兼容破坏** | 返回值从扁平 `List<CheckDetailItem>` 变为分组嵌套结构。如果前端同时部署（蓝绿部署），旧版前端无法解析新格式 |
| | | **建议方案**：后端在VO中同时保留平铺的 `details` 字段（标记 `@JsonInclude(Include.NON_NULL)`），新版前端读分组字段，旧版前端读平铺字段。过渡期后移除。 |
| `POST /wms/RepairNotice/confirmCheck/{noticeId}` | **不变** | 入参仍然是 `{warehouseId, details[{skuId, quantity}]}`，前端在提交前将汇总数量拆回逐条 |
| `POST /wms/RepairNotice/rejectCheck/{noticeId}` | **不变** | 入参仍然是 `{rejectReason}` |

### 5.5 回归影响

| 影响范围 | 说明 |
|---------|------|
| **后端逻辑不变** | `confirmCheck`/`rejectCheck`/`startProcess` 的状态校验逻辑不变 |
| **入库单创建逻辑不变** | `receiptOrderService.receive()` 调用不变 |
| **列表页不变** | `index.vue`、`useRepairNotice.js`、`RepairNoticeQuery.vue`、`RepairNoticeTable.vue` 均不变 |
| **编辑/新增弹窗不变** | `RepairNoticeDialog.vue`、`FaultyItemSelector` 均不受影响 |

---

## 附录：关键代码位置索引

| 功能点 | 文件 | 行数参考 |
|-------|------|---------|
| 核对弹窗模板 | `RepairNoticeCheckDialog.vue` | 全文件约170行 |
| 核对弹窗JS逻辑 | `RepairNoticeCheckDialog.vue <script>` | ~130行 |
| 开始处理触发 | `useRepairNotice.js` → `handleStartProcess()` | ~150行 |
| 核对通过提交 | `useRepairNotice.js` → `handleCheckConfirm()` | ~162行 |
| 核对退回提交 | `useRepairNotice.js` → `handleCheckReject()` | ~173行 |
| 后端构建核对明细 | `RepairNoticeService.java` → `buildCheckDetail()` | ~223行 |
| 后端核对通过 | `RepairNoticeService.java` → `confirmCheck()` | ~267行 |
| 后端核对退回 | `RepairNoticeService.java` → `rejectCheck()` | ~307行 |
| 核对明细VO | `RepairNoticeCheckDetailVo.java` | 全文件 |
| 通知单明细表DDL | `ry-vue_...sql` → `repair_notice_detail` | `(id, notice_id, sku_id)` |
| SKU表DDL | `ry-vue_...sql` → `wms_item_sku` | `id, sku_name(规格), item_id, barcode` |
| 物品表DDL | `ry-vue_...sql` → `wms_item` | `id, item_code, item_name(物品名称)` |
