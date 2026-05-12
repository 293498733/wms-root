# 需求拆分 — 最小粒度任务清单

> 基于 `requirement.md` 拆分，结合当前项目代码现状分析。

---

## 一、Bug修复：核对明细"核对无误"按钮无反应

### 问题定位
`RepairNoticeCheckDialog.vue` 第 19 行模板 ref 写为 `ref="checkFzormRef"`（多一个字母 `z`），而 script 中变量名为 `checkFormRef`。ref 名称不匹配导致 `checkFormRef.value` 始终为 `null`，`handleConfirm()` 第 244 行直接 return，按钮点击无任何响应。

### 任务清单

| 编号 | 模块 | 描述 | 依赖 |
|------|------|------|------|
| **1.1** | [前端] | 修复 `RepairNoticeCheckDialog.vue` 第 19 行 ref 拼写：`checkFzormRef` → `checkFormRef` | 无 |
| **1.2** | [前端] | 本地启动前端，验证核对明细弹窗点击"核对无误-入库"按钮正常触发校验和提交 | 1.1 |

---

## 二、返回确认单功能完善

### 现状分析
- 后端已存在：`ReturnNotice` 实体、`ReturnNoticeDetail` 实体、`ReturnNoticeService`/`ReturnNoticeServiceImpl`、`ReturnNoticeController`
- **前端完全缺失**：无页面、无 API 模块、无路由、无菜单

### 任务清单

| 编号 | 模块 | 描述 | 依赖 |
|------|------|------|------|
| **2.1** | [数据库] | 确认 `return_notice` / `return_notice_detail` 表是否已创建；若未创建则输出建表 SQL 迁移脚本 | 无 |
| **2.2** | [数据库] | 添加返回确认单状态字典类型 `return_notice_status`（0草稿/2已提交/3已出库/9作废）及数据项 | 无 |
| **2.3** | [数据库] | 添加返回确认单菜单记录到 `sys_menu` 表（位置：单据管理 → 返回确认单） | 2.1 |
| **2.4** | [前端] | 创建 API 模块 `src/api/wms/returnNotice.js`，封装 CRUD + 提交/出库等接口调用 | 无 |
| **2.5** | [前端] | 创建返回确认单列表页 `views/wms/order/returnNotice/index.vue`（含查询条件、表格、分页） | 2.4 |
| **2.6** | [前端] | 创建返回确认单编辑/新建页 `views/wms/order/returnNotice/edit.vue` | 2.4 |
| **2.7** | [前端] | 创建返回确认单查询组件 `components/ReturnNoticeQuery.vue` | 无 |
| **2.8** | [前端] | 创建返回确认单表格组件 `components/ReturnNoticeTable.vue`（含操作按钮：编辑/提交/删除等） | 无 |
| **2.9** | [前端] | 创建返回确认单弹窗组件 `components/ReturnNoticeDialog.vue` | 无 |
| **2.10** | [前端] | 在 `router/index.js` 中添加返回确认单路由（含权限标识） | 2.5 |
| **2.11** | [后端] | 确认后端 Controller 接口路径与前端 API 调用一致，必要时微调 | 无 |
| **2.12** | [全栈] | 端到端验证：新建返回确认单 → 提交 → 出库 → 状态变更全流程 | 2.1~2.11 |

---

## 三、返修通知单下挂物流单功能

### 业务说明
- 一个**返修通知单**对应多个**物流单**
- 每个物流单下挂物品明细（关联 SKU）
- 物流单明细数量必须等于返修通知单对应明细数量
- 当所有物流单明细数量合计 = 返修通知单总数量时，返修通知单状态变更为"已完成"

### 任务清单

#### 阶段 A：数据库设计

| 编号 | 模块 | 描述 | 依赖 |
|------|------|------|------|
| **3.1** | [数据库] | 设计 `repair_logistics_order` 物流单主表：id、order_no、repair_notice_id、status、total_quantity、logistics_company、logistics_no、remark、create_time 等 | 无 |
| **3.2** | [数据库] | 设计 `repair_logistics_order_detail` 物流单明细表：id、order_id、sku_id、quantity、remark 等 | 3.1 |
| **3.3** | [数据库] | 输出建表 SQL 迁移脚本（含回滚 SQL） | 3.1, 3.2 |
| **3.4** | [数据库] | 添加物流单状态字典类型 `repair_logistics_status`（如 0草稿/1已提交/2已发运/9作废）及数据项 | 无 |

#### 阶段 B：后端实体与映射

| 编号 | 模块 | 描述 | 依赖 |
|------|------|------|------|
| **3.5** | [后端] | 创建 `RepairLogisticsOrder` 实体类（继承 BaseEntity） | 3.1 |
| **3.6** | [后端] | 创建 `RepairLogisticsOrderDetail` 实体类 | 3.2 |
| **3.7** | [后端] | 创建 `RepairLogisticsOrderMapper` 接口 + XML 映射文件 | 3.5 |
| **3.8** | [后端] | 创建 `RepairLogisticsOrderDetailMapper` 接口 + XML 映射文件 | 3.6 |
| **3.9** | [后端] | 创建 `RepairLogisticsOrderBo`（入参）、`RepairLogisticsOrderVo`（出参） | 3.5 |
| **3.10** | [后端] | 创建 `RepairLogisticsOrderDetailBo`、`RepairLogisticsOrderDetailVo` | 3.6 |

#### 阶段 C：后端业务逻辑

| 编号 | 模块 | 描述 | 依赖 |
|------|------|------|------|
| **3.11** | [后端] | 创建 `RepairLogisticsOrderService`：基础 CRUD（分页查询、按ID查询、新增、编辑、删除） | 3.7, 3.8 |
| **3.12** | [后端] | 实现物流单创建时的校验——明细 SKU 必须属于关联的返修通知单；物流单明细数量必须等于返修通知单对应明细数量 | 3.11 |
| **3.13** | [后端] | 实现汇总判定逻辑——查询该返修通知单下所有物流单，汇总各 SKU 明细数量，若全部 SKU 的物流总量 >= 返修通知单明细数量，则将返修通知单状态更新为"已完成" | 3.11 |
| **3.14** | [后端] | 在物流单提交/确认时触发汇总判定（回调 3.13 的逻辑） | 3.12, 3.13 |
| **3.15** | [后端] | 创建 `RepairLogisticsOrderController`：list、getInfo、add、edit、delete、submit 等接口，添加 SaToken 权限注解 | 3.11 |
| **3.16** | [后端] | 生成物流单号工具方法（类似 `RepairNoticeNoUtils`） | 无 |

#### 阶段 D：前端页面

| 编号 | 模块 | 描述 | 依赖 |
|------|------|------|------|
| **3.17** | [前端] | 创建 API 模块 `src/api/wms/repairLogisticsOrder.js` | 3.15 |
| **3.18** | [前端] | 创建物流单列表页 `views/wms/order/repairLogisticsOrder/index.vue` | 3.17 |
| **3.19** | [前端] | 创建物流单编辑/新建页（含返修通知单选择 + 明细录入） | 3.17 |
| **3.20** | [前端] | 创建物流单查询组件 `components/RepairLogisticsOrderQuery.vue` | 无 |
| **3.21** | [前端] | 创建物流单表格组件 `components/RepairLogisticsOrderTable.vue` | 无 |
| **3.22** | [前端] | 创建物流单弹窗组件 `components/RepairLogisticsOrderDialog.vue` | 无 |
| **3.23** | [前端] | 在 `router/index.js` 中添加物流单路由 | 3.18 |
| **3.24** | [数据库] | 添加物流单菜单记录到 `sys_menu` 表 | 3.23 |

#### 阶段 E：端到端验证

| 编号 | 模块 | 描述 | 依赖 |
|------|------|------|------|
| **3.25** | [全栈] | 验证：创建返修通知单（含 N 个 SKU）→ 创建物流单 A（部分明细）→ 创建物流单 B（剩余明细）→ 状态自动变更为"已完成" | 3.1~3.24 |
| **3.26** | [全栈] | 验证异常场景：物流单明细 SKU 不在通知单范围内时拒绝提交 | 3.25 |
| **3.27** | [全栈] | 验证异常场景：物流单明细数量超过通知单明细数量时拒绝提交 | 3.25 |

---

## 执行优先建议

1. **最先执行 1.1~1.2**（Bug 修复，改动最小，风险最低）
2. **其次执行需求二**（返回确认单前端开发，后端已有基础）
3. **最后执行需求三**（物流单为全新功能，前后端均需从零构建）
