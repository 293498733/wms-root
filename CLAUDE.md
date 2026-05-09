# CLAUDE.md

## 项目概述

本项目是基于 **RuoYi-Vue-Fast** 框架改造的 **WMS 进销存管理系统**，支持多仓库、多商户的入库/出库/移库/盘点/维修全流程管理。

- **后端**：`wms-ruoyi-master/` — Spring Boot 3.2.6 + MyBatis-Plus 3.5.6，JDK 17，Maven 多模块
- **前端**：`ruo-yi-wms-vue-master/` — Vue 3.2 + Vite 3 + Element Plus 2.2 + Pinia
- **数据库**：MySQL，库名 `ry-vue`
- **版本控制**：SVN（非 Git）
- JDK本地地址：D:\zulu17.54.21-ca-jdk17.0.13-win_x64\bin
### 项目背景

本项目是从其他进销存系统改造而来，存在一些历史遗留的命名不一致问题。**后续修改应尽量纠正不适配的命名和设计，不要被旧代码误导。** 典型问题包括：

- `wms_item_sku` 在实际业务中充当的是**物品/商品主表**的角色（库存、订单明细、维修通知单全部引用 sku_id），而非传统电商语境下的"规格变体"。`wms_item` 更接近于物品分组/模板
- 部分模块的字段命名和表关系沿用了原系统的设计，可能与当前业务语义不符

---

## 核心模块结构

```
wms-ruoyi-master/
├── ruoyi-admin-wms/          # 应用入口，WMS 业务代码（controller/service/mapper/domain）
│   └── src/main/java/com/ruoyi/wms/
│       ├── controller/       # 接口层
│       ├── service/          # 业务逻辑层（每个 service 对应一个业务模块）
│       ├── mapper/           # MyBatis-Plus 映射器接口
│       ├── domain/
│       │   ├── entity/       # 数据库实体（映射表结构）
│       │   ├── bo/           # 业务对象（请求参数封装）
│       │   └── vo/           # 视图对象（响应数据封装）
│       └── utils/            # WMS 专用工具
│   └── src/main/resources/
│       ├── application.yml           # 主配置
│       ├── application-dev.yml       # 开发环境
│       └── mapper/wms/               # MyBatis XML 映射文件
├── ruoyi-common/             # 通用模块（core/web/security/redis/excel/oss/sms 等）
├── ruoyi-modules/
│   ├── ruoyi-system/         # 系统管理（用户/角色/菜单/部门/字典/日志）
│   └── ruoyi-generator/      # 代码生成器
└── script/sql/               # SQL 迁移脚本（按日期命名 YYYYMMDD_xxx.sql）
```

前端视图目录：`ruo-yi-wms-vue-master/src/views/wms/`，按模块分为 `basic/`（基础数据）、`order/`（单据）、`inventory/`（库存）。

---

## 技术约定

### 认证授权
- 使用 **Sa-Token**（JWT 模式），非 Spring Security
- 权限注解：`@SaCheckPermission("wms:notice:edit")`
- 角色注解：`@SaCheckRole("admin")`

### 分层架构
- Controller 负责参数校验、权限、调用 Service
- Service 包含所有业务逻辑，标注 `@Transactional` 管理事务
- Mapper 继承 MyBatis-Plus BaseMapper，复杂查询写在 XML 中
- 领域对象分三类：**Entity**（表映射）、**BO**（入参）、**VO**（出参）

### 基类继承
- 业务单据实体继承 `BaseOrder`（含 id/orderNo/totalQuantity/totalAmount/orderStatus/remark）
- 单据明细实体继承 `BaseOrderDetail`（含 id/orderId/skuId/quantity/amount/remark）

### 命名规范
- Controller 方法：RESTful 风格，`/wms/模块名/动作`
- Service 方法：`getXxxById()`、`queryXxxList()`、`insertXxx()`、`updateXxx()`、`deleteXxx()`
- 权限标识：`wms:模块名:动作`（如 `wms:notice:edit`）

### 主键策略
- MyBatis-Plus `ASSIGN_ID`（雪花算法），Long 类型

---

## 数据库

### 关键业务表

| 表名 | 用途 | 备注 |
|------|------|------|
| `wms_item_sku` | **物品主表** | 实际充当物品/商品主表角色，库存/订单/维修全部引用 sku_id；含 repair_status 等维修字段 |
| `wms_item` | 物品分组/模板 | 对 SKU 进行分组归类（名称、品牌、分类），不直接参与库存和订单 |
| `wms_item_category` | 物品分类 | 树形结构 |
| `wms_receipt_order` | 入库单 | opt_type 区分入库类型，具体映射见 `wms_receipt_type` 字典 |
| `wms_receipt_order_detail` | 入库单明细 | 含 sku_id/quantity/warehouse_id |
| `wms_shipment_order` | 出库单 | 含出库类型 |
| `wms_shipment_order_detail` | 出库单明细 | |
| `wms_movement_order` | 移库单 | 含移库类型 |
| `wms_check_order` | 盘点单 | |
| `wms_inventory` | 库存 | 按 sku_id + warehouse_id 维度 |
| `wms_inventory_history` | 库存流水 | 记录每次出入库操作 |
| `repair_notice` | 返修通知单 | status/handover_status 双状态字段 |
| `repair_notice_detail` | 返修通知单明细 | 仅 notice_id + sku_id（唯一约束 uk_notice_sku） |

### SQL 变更规则
- 新增迁移脚本放在 `script/sql/`，命名格式 `YYYYMMDD_描述.sql`
- 涉及表结构变更时，**必须先输出 SQL + 回滚 SQL + 影响范围**

---

## 码值管理（核心约定）

**所有业务状态码值统一由数据库字典表管理**，这是项目的核心约定。字典数据是码值的唯一权威来源，代码中不应硬编码状态常量。

### 字典表结构

- **`sys_dict_type`** — 字典类型定义（`dict_type` 为唯一标识，如 `repair_status`、`wms_receipt_type`）
- **`sys_dict_data`** — 字典数据项（`dict_type` + `dict_value` + `dict_label`，如 `repair_status` / `"0"` / `"待送修"`）

### 字典解析方式

- `DictService` 接口（`ruoyi-common-core`）提供 `getDictLabel()`、`getDictValue()`、`getAllDictByDictType()`
- `SysDictTypeService` 实现 `DictService`，启动时加载所有字典到 Redis 缓存 `sys_dict`
- VO 导出时通过 `@ExcelDictFormat(dictType = "xxx")` 注解自动转换码值为标签

### 已有字典类型

| dict_type | 用途 |
|-----------|------|
| `repair_status` | 物品维修状态（0待送修~6报废） |
| `wms_receipt_status` | 入库单状态（-1作废/0未入库/1已入库） |
| `wms_receipt_type` | 入库类型（1生产/2采购/3退货/4归还） |
| `wms_shipment_status` | 出库单状态 |
| `wms_shipment_type` | 出库类型（1退货/2销售/3生产） |
| `wms_inventory_history_type` | 库存流水类型（1入库/2出库/3移库/4盘点） |
| `wms_movement_status` | 移库单状态 |
| `wms_check_status` | 盘点单状态 |
| `merchant_type` | 客户类型（客户/供应商/两者） |

### 注意

- 返修通知单的 `status`（单据状态）和 `handoverStatus`（交接状态）**尚未纳入字典表**，后续应补充对应的 dict_type
- 新增业务状态时，**必须先创建对应的字典类型和数据**，再在代码中引用，不允许在代码中直接硬编码状态值

---

## 开发注意事项

1. **不要删除已有业务逻辑**，只能扩展或修改
2. **不要修改已有接口路径**（除非需求明确要求）
3. **不要全局重构**，改动范围控制在需求涉及的模块内
4. 数据库变更前必须输出完整 SQL 方案
5. 实现前先输出工程方案
6. 前端开发时 Vite 代理 `/dev-api` → `http://192.168.2.24:8080`
7. **新增业务状态码值必须通过字典表管理**（`sys_dict_type` + `sys_dict_data`），禁止在代码中硬编码
8. **注意项目的历史遗留命名**，`wms_item_sku` 实际是物品主表，修改代码时优先纠正不适配的命名和设计

---

## 常用服务定位

| 功能 | 文件路径 |
|------|---------|
| 入库单业务 | `ruoyi-admin-wms/.../service/ReceiptOrderService.java` |
| 返修通知单业务 | `ruoyi-admin-wms/.../service/RepairNoticeService.java` |
| 库存操作 | `ruoyi-admin-wms/.../service/InventoryService.java` |
| 库存流水 | `ruoyi-admin-wms/.../service/InventoryHistoryService.java` |
| 物品主表（ItemSku） | `ruoyi-admin-wms/.../service/ItemSkuService.java` |
| 字典服务接口 | `ruoyi-common/ruoyi-common-core/.../service/DictService.java` |
| 字典服务实现 | `ruoyi-modules/ruoyi-system/.../service/SysDictTypeService.java` |
| 状态常量 | `ruoyi-common/ruoyi-common-core/.../constant/ServiceConstants.java` |
| 通知单号工具 | `ruoyi-common/ruoyi-common-redis/.../utils/RepairNoticeNoUtils.java` |
