# 进销存 WMS 项目架构地图

> 基于 RuoYi-Vue-Plus v5.2.0 构建 | Spring Boot 3.2.6 + Vue 3.2.45 + Element Plus 2.2.27
> 生成时间: 2026-05-12 | 作者: goose 自动分析

---

## 一、模块结构图

```
进销存/
├── wms-ruoyi-master/                    # 后端项目
│   ├── pom.xml                          # 根 POM (聚合模块)
│   ├── ruoyi-admin-wms/                 # [Web入口] 含 WMS 业务代码
│   │   ├── pom.xml
│   │   └── src/main/
│   │       ├── java/com/ruoyi/
│   │       │   ├── RuoYiApplication.java
│   │       │   ├── RuoYiServletInitializer.java
│   │       │   └── wms/
│   │       │       ├── controller/      # 19个 REST Controller
│   │       │       ├── service/         # 业务接口
│   │       │       ├── service/impl/    # 业务实现
│   │       │       ├── mapper/          # MyBatis-Plus Mapper
│   │       │       ├── domain/
│   │       │       │   ├── entity/      # 实体类
│   │       │       │   ├── bo/          # 业务对象
│   │       │       │   └── vo/          # 视图对象
│   │       │       └── ...
│   │       └── resources/
│   │           ├── application.yml      # 主配置
│   │           ├── mapper/wms/          # 19个 XML Mapper
│   │           ├── i18n/               # 国际化
│   │           └── ...
│   │       └── test/                    # 单元测试
│   ├── ruoyi-common/                    # [公共模块，聚合18个子模块]
│   │   ├── ruoyi-common-bom/            # 依赖版本管理
│   │   ├── ruoyi-common-core/           # 核心工具
│   │   ├── ruoyi-common-web/            # Web 通用配置
│   │   ├── ruoyi-common-mybatis/        # MyBatis-Plus 封装
│   │   ├── ruoyi-common-redis/          # Redis/Redisson
│   │   ├── ruoyi-common-satoken/        # 权限集成
│   │   ├── ruoyi-common-security/       # 安全配置
│   │   ├── ruoyi-common-log/            # 操作日志
│   │   ├── ruoyi-common-excel/          # Excel
│   │   ├── ruoyi-common-oss/            # 对象存储
│   │   ├── ruoyi-common-sms/            # 短信
│   │   ├── ruoyi-common-mail/           # 邮件
│   │   ├── ruoyi-common-json/           # JSON
│   │   ├── ruoyi-common-encrypt/        # 加密
│   │   ├── ruoyi-common-sensitive/      # 脱敏
│   │   ├── ruoyi-common-translation/    # 数据翻译
│   │   ├── ruoyi-common-ratelimiter/    # 限流
│   │   ├── ruoyi-common-idempotent/     # 幂等
│   │   └── ruoyi-common-doc/            # 文档
│   ├── ruoyi-modules/                   # [业务模块，聚合3个子模块]
│   │   ├── ruoyi-system/                # 系统管理
│   │   ├── ruoyi-generator/             # 代码生成器
│   │   └── ruoyi-demo/                  # 演示模块
│   └── script/sql/                      # SQL 迁移脚本
│       ├── wms.sql                      # 完整建表 + 初始化数据
│       ├── 20260421_repair_notice_detail.sql
│       ├── 20260422_instance_tracking_constraints.sql
│       ├── 20260506_item_sku_qr_pre.sql
│       ├── 20260506_repair_notice_contact_fields.sql
│       ├── 20260507_repair_notice_send_repair_date.sql
│       ├── 20260507_repair_status_dict.sql
│       └── 20260508_repair_notice_reject_reason.sql
│
├── ruo-yi-wms-vue-master/               # 前端项目
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   └── src/
│       ├── api/                         # API 封装
│       │   ├── login.js                 # 登录 API
│       │   ├── menu.js                  # 获取路由菜单
│       │   ├── system/                  # 系统管理 API
│       │   ├── monitor/                 # 监控 API
│       │   ├── tool/                    # 代码生成 API
│       │   └── wms/                     # [WMS 业务 API - 16个文件]
│       ├── views/                       # 页面
│       │   ├── wms/                     # [WMS 业务页面]
│       │   │   ├── basic/               # 基础资料（商品/品牌/商户/仓库）
│       │   │   ├── inventory/           # 库存统计/库存记录
│       │   │   └── order/               # 单据（入库/出库/移库/盘点/返修）
│       │   ├── system/                  # 系统管理页面
│       │   ├── monitor/                 # 系统监控页面
│       │   ├── tool/                    # 工具页面
│       │   ├── mobile/                  # 移动端页面
│       │   └── ...
│       ├── router/index.js              # 路由配置
│       ├── store/modules/               # Pinia 状态管理
│       │   ├── permission.js            # [动态路由加载核心]
│       │   ├── user.js
│       │   ├── app.js
│       │   ├── settings.js
│       │   ├── dict.js
│       │   ├── tagsView.js
│       │   └── wms.js
│       ├── utils/request.js             # Axios 封装
│       └── components/                  # 公共组件
│
└── .ai-dev/                             # [AI 辅助开发配置]
    ├── profile.yml                      # 项目画像
    └── project-map.md                   # 本文件
```

---

## 二、关键目录说明

### 后端

| 目录 | 说明 |
|------|------|
| `ruoyi-admin-wms/src/main/java/com/ruoyi/wms/controller/` | WMS 业务 REST Controller (19个) |
| `ruoyi-admin-wms/src/main/java/com/ruoyi/wms/service/` | 业务接口 |
| `ruoyi-admin-wms/src/main/java/com/ruoyi/wms/service/impl/` | 业务实现 |
| `ruoyi-admin-wms/src/main/java/com/ruoyi/wms/mapper/` | MyBatis-Plus Mapper 接口 |
| `ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/entity/` | 实体类 (JPA 注解 + @TableName) |
| `ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/bo/` | 业务对象 (配合 @Xss 校验) |
| `ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/vo/` | 视图对象 (配合 MapStruct 转换) |
| `ruoyi-admin-wms/src/main/resources/mapper/wms/` | MyBatis XML 映射文件 (19个) |
| `ruoyi-system/src/main/java/com/ruoyi/system/` | 系统管理 (用户/角色/菜单/部门/字典/配置等) |
| `script/sql/` | SQL 迁移脚本目录 |

### 前端

| 目录 | 说明 |
|------|------|
| `src/views/wms/basic/` | 基础资料页面 (商品/品牌/商户/仓库) |
| `src/views/wms/inventory/` | 库存统计 + 库存记录 |
| `src/views/wms/order/` | 订单单据页面 (入库/出库/移库/盘点/返修) |
| `src/views/mobile/` | 移动端页面 (扫码入库/创建物品/扫码录入返修) |
| `src/views/system/` | 系统管理页面 |
| `src/api/wms/` | WMS 业务 API 封装 (16个文件) |
| `src/store/modules/permission.js` | 动态路由加载核心 |
| `src/utils/request.js` | Axios 请求封装 |
| `src/components/` | 公共组件 (DictTag/FileUpload/ImageUpload/TreeSelect等) |

---

## 三、数据库表清单

### 系统表 (RuoYi 标准)

| 表名 | 说明 |
|------|------|
| `sys_user` | 用户表 |
| `sys_role` | 角色表 |
| `sys_role_menu` | 角色-菜单关联 |
| `sys_role_dept` | 角色-部门关联 |
| `sys_menu` | 菜单表 (含权限标识 perms) |
| `sys_dept` | 部门表 |
| `sys_post` | 岗位表 |
| `sys_user_post` | 用户-岗位关联 |
| `sys_user_role` | 用户-角色关联 |
| `sys_dict_type` | 字典类型 |
| `sys_dict_data` | 字典数据 |
| `sys_config` | 参数配置 |
| `sys_notice` | 通知公告 |
| `sys_oper_log` | 操作日志 |
| `sys_logininfor` | 登录日志 |
| `sys_oss` | OSS 文件存储 |
| `sys_oss_config` | OSS 配置 |
| `gen_table` | 代码生成 - 表配置 |
| `gen_table_column` | 代码生成 - 列配置 |

### WMS 业务表

| 表名 | 说明 | 关键字段 |
|------|------|----------|
| `wms_item` | 商品 (物料) | name, spec, unit, category_id |
| `wms_item_sku` | 商品规格/SKU | sku_name, barcode, sku_code, item_id, repair_status★ |
| `wms_item_sku_qr_pre` | SKU 二维码预生成 | sku_id, qr_code |
| `wms_item_brand` | 品牌 | brand_name, order_num |
| `wms_item_category` | 物料分类 (树形) | category_name, parent_id, order_num |
| `wms_merchant` | 往来单位/商户 | merchant_name, contact, phone, address |
| `wms_warehouse` | 仓库 | warehouse_code, warehouse_name, order_num |
| `wms_receipt_order` | 入库单 | order_no, order_status, supplier_id, warehouse_id |
| `wms_receipt_order_detail` | 入库单详情 | order_id, sku_id, quantity, warehouse_id |
| `wms_shipment_order` | 出库单 | order_no, order_status, customer_id, warehouse_id |
| `wms_shipment_order_detail` | 出库单详情 | order_id, sku_id, quantity, amount, warehouse_id |
| `wms_movement_order` | 移库单 | order_no, order_status, source_warehouse_id, target_warehouse_id |
| `wms_movement_order_detail` | 移库单详情 | order_id, sku_id, quantity |
| `wms_check_order` | 盘点单 | order_no, order_status, warehouse_id |
| `wms_check_order_detail` | 盘点单详情 | order_id, sku_id, expected_qty, actual_qty, difference |
| `wms_inventory` | 库存 | sku_id, warehouse_id, quantity, locked_quantity |
| `wms_inventory_history` | 库存变更记录 | sku_id, warehouse_id, before_quantity, change_quantity, after_quantity, change_type |

> ★ `wms_item_sku.repair_status` 为维修业务扩展字段，关联字典 `repair_status`

---

## 四、菜单和权限体系

### 顶部菜单结构 (从 sys_menu 数据提取)

```
基础资料 (M, 排序100)
  ├── 往来单位 (C, perms: wms:merchant:list)
  ├── 仓库管理 (C, perms: wms:warehouse:list)
  ├── 品牌管理 (C, perms: wms:itemBrand:list)
  └── 商品管理 (C, perms: wms:item:list)

入库 (C, 排序20, perms: wms:receipt:all)
出库 (C, 排序30, perms: wms:shipment:all)
移库 (C, 排序40, perms: wms:movement:all)
盘库 (C, 排序50, perms: wms:check:all)
库存统计 (C, 排序0, perms: wms:inventory:all)
库存记录 (C, 排序3, perms: wms:inventoryHistory:all)
系统管理 (M, 排序110) - RuoYi 标准
系统监控 (M, 排序120) - RuoYi 标准
代码生成 (C, 排序130) - RuoYi 标准
日志管理 (M, 排序140) - RuoYi 标准
```

### 权限标注体系

后端使用 `@SaCheckPermission` 注解，权限字符串格式为 `wms:{module}:{action}`：

| 权限标识 | 说明 |
|----------|------|
| `wms:item:list` | 商品查看/查询 |
| `wms:item:edit` | 商品新增/修改/删除 |
| `wms:receipt:all` | 入库全部权限 |
| `wms:shipment:all` | 出库全部权限 |
| `wms:movement:all` | 移库全部权限 |
| `wms:check:all` | 盘点全部权限 |
| `wms:inventory:all` | 库存全部权限 |
| `wms:inventoryHistory:all` | 库存记录全部权限 |
| `wms:merchant:list` | 商户查看 |
| `wms:merchant:edit` | 商户编辑 |
| `wms:warehouse:list` | 仓库查看 |
| `wms:warehouse:edit` | 仓库编辑 |
| `wms:itemBrand:list` | 品牌查看 |
| `wms:itemBrand:edit` | 品牌编辑 |

### 权限层级

```
M (目录) → C (菜单) → F (按钮/功能)
例:
  基础资料(M) → 商品管理(C, wms:item:list) → 商品查询(F, wms:item:list)
                                              → 商品编辑(F, wms:item:edit)
```

---

## 五、页面和路由对应关系

### 静态路由 (constantRoutes)

| 路径 | 页面 | 说明 |
|------|------|------|
| `/login` | `views/login.vue` | 登录页 |
| `/register` | `views/register.vue` | 注册页 |
| `/index` | `views/dashboard/charts.vue` | 首页 |
| `/dashboard` | `views/dashboard/dashboard.vue` | 数据大屏 |
| `/user/profile` | `views/system/user/profile/index.vue` | 个人中心 |
| `/m/**` | `views/mobile/**` | 移动端页面组 |

### 动态路由 (dynamicRoutes - 硬编码)

| 路径 | 页面 | 权限 |
|------|------|------|
| `/system/user-auth/role/:userId` | `views/system/user/authRole.vue` | system:user:edit |
| `/system/role-auth/user/:roleId` | `views/system/role/authUser.vue` | system:role:edit |
| `/system/dict-data/index/:dictId` | `views/system/dict/data.vue` | system:dict:list |
| `/system/oss-config/index` | `views/system/oss/config.vue` | system:oss:list |
| `/tool/gen-edit/index/:tableId` | `views/tool/gen/editTable.vue` | tool:gen:edit |

### 服务端动态路由 (从 `/getRouters` API 加载)

| 路径前缀 | 对应页面目录 |
|----------|-------------|
| `wms/basic/merchant/` | `views/wms/basic/merchant/` |
| `wms/basic/warehouse/` | `views/wms/basic/warehouse/` |
| `wms/basic/itemBrand/` | `views/wms/basic/itemBrand/` |
| `wms/basic/item/` | `views/wms/basic/item/` |
| `wms/order/receipt/` | `views/wms/order/receipt/` |
| `wms/order/shipment/` | `views/wms/order/shipment/` |
| `wms/order/movement/` | `views/wms/order/movement/` |
| `wms/order/check/` | `views/wms/order/check/` |
| `wms/order/repairNotice/` | `views/wms/order/repairNotice/` |
| `wms/inventory/statistic` | `views/wms/inventory/statistic.vue` |
| `wms/inventory/history` | `views/wms/inventory/history.vue` |

---

## 六、开发约定

### 代码模式

#### Controller 标准模式

```java
@Validated
@RequiredArgsConstructor
@RestController
@RequestMapping("/wms/{moduleName}")  // lowerCamelCase
public class XxxController extends BaseController {

    private final XxxService xxxService;

    // 列表查询
    @SaCheckPermission("wms:{module}:{action}")
    @GetMapping("/list")
    public TableDataInfo<XxxVo> list(XxxBo bo, PageQuery pageQuery) { ... }

    // 导出
    @SaCheckPermission("wms:{module}:{action}")
    @PostMapping("/export")
    public void export(XxxBo bo, HttpServletResponse response) { ... }

    // 详情
    @SaCheckPermission("wms:{module}:{action}")
    @GetMapping("/{id}")
    public R<XxxVo> getInfo(@PathVariable Long id) { ... }

    // 新增
    @SaCheckPermission("wms:{module}:{action}")
    @Log(title = "...", businessType = BusinessType.INSERT)
    @RepeatSubmit()
    @PostMapping()
    public R<Void> add(@Validated(AddGroup.class) @RequestBody XxxBo bo) { ... }

    // 修改
    @SaCheckPermission("wms:{module}:{action}")
    @Log(title = "...", businessType = BusinessType.UPDATE)
    @RepeatSubmit()
    @PutMapping()
    public R<Void> edit(@Validated(EditGroup.class) @RequestBody XxxBo bo) { ... }

    // 删除
    @SaCheckPermission("wms:{module}:{action}")
    @Log(title = "...", businessType = BusinessType.DELETE)
    @DeleteMapping("/{id}")
    public R<Void> remove(@PathVariable Long id) { ... }
}
```

#### 前端页面标准模式

```
views/wms/{module}/
├── index.vue           # 列表页（含查询表单 + 表格 + 新增/编辑/删除操作）
├── edit.vue            # 编辑/详情页（部分模块有）
└── components/         # 拆分子组件（Dialog / Drawer / Query / Table 等）
```

对于复杂页面，使用 `use{Module}.js` 抽离业务逻辑：
```
views/wms/basic/item/
├── index.vue
├── useItemPage.js      # 业务逻辑抽离
└── components/
    ├── ItemDrawer.vue
    ├── ItemTable.vue
    ├── ItemQuery.vue
    └── ItemGoodsDialog.vue
```

#### 前端 API 标准模式

```javascript
// api/wms/{module}.js
import request from '@/utils/request'

export function listXxxPage(query) { return request({ url: '/wms/{module}/list', method: 'get', params: query }) }
export function listXxx(query)      { return request({ url: '/wms/{module}/listNoPage', method: 'get', params: query }) }
export function getXxx(id)         { return request({ url: '/wms/{module}/' + id, method: 'get' }) }
export function addXxx(data)       { return request({ url: '/wms/{module}', method: 'post', data }) }
export function updateXxx(data)    { return request({ url: '/wms/{module}', method: 'put', data }) }
export function delXxx(id)         { return request({ url: '/wms/{module}/' + id, method: 'delete' }) }
```

### 命名规范

| 层面 | 规范 | 示例 |
|------|------|------|
| Java 类名 | PascalCase | `ReceiptOrderController` |
| Java 包名 | 全小写 | `com.ruoyi.wms.controller` |
| URL 路径 | lowerCamelCase | `/wms/receiptOrder` |
| 数据库表 | snake_case + wms_前缀 | `wms_receipt_order` |
| 数据库列 | snake_case | `order_status`, `sku_id` |
| MyBatis XML | {Entity}Mapper.xml | `ReceiptOrderMapper.xml` |
| Vue 页面 | kebab-case 目录 + index.vue | `wms/order/receipt/index.vue` |
| API JS 文件 | camelCase.js | `receiptOrder.js` |
| 权限标识 | `{模块}:{资源}:{操作}` | `wms:receipt:all` |

### 关键技术配置

| 配置项 | 值 |
|--------|-----|
| JDK | 17 |
| Spring Boot | 3.2.6 |
| MySQL | 驱动 mysql-connector-j |
| MyBatis-Plus | 3.5.6, idType=ASSIGN_ID |
| Sa-Token | 1.37.0, JWT 模式, token 过期 86400s |
| Redis | Redisson 3.29.0 |
| 文件上传 | 最大 10MB/个，20MB/总 |
| 接口文档 | SpringDoc (默认关闭) |
| 验证码 | 数学计算 + 圆圈干扰 |
| 密码策略 | 最大错误5次，锁定10分钟 |

---

## 附录：Controller 完整列表

| 类名 | URL 前缀 | 权限 | 说明 |
|------|----------|------|------|
| `CheckOrderController` | `/wms/checkOrder` | `wms:check:all` | 盘点单 CRUD + 盘库结束 |
| `CheckOrderDetailController` | `/wms/checkOrderDetail` | `wms:check:all` | 盘点详情 |
| `InventoryController` | `/wms/inventory` | `wms:inventory:all` | 库存查询（商品维度/仓库维度） |
| `InventoryHistoryController` | `/wms/inventoryHistory` | `wms:inventoryHistory:all` | 库存记录 |
| `ItemBrandController` | `/wms/itemBrand` | `wms:itemBrand:list/edit` | 品牌管理 |
| `ItemCategoryController` | `/wms/itemCategory` | `wms:item:list/edit` | 物料分类（含树形下拉） |
| `ItemController` | `/wms/item` | `wms:item:list/edit` | 商品管理 |
| `ItemSkuController` | `/wms/itemSku` | `wms:item:list/edit` | SKU 管理 |
| `ItemSkuQrPreController` | `/wms/itemSkuQrPre` | - | SKU 二维码预生成 |
| `MerchantController` | `/wms/merchant` | `wms:merchant:list/edit` | 往来单位 |
| `MovementOrderController` | `/wms/movementOrder` | `wms:movement:all` | 移库单 |
| `MovementOrderDetailController` | `/wms/movementOrderDetail` | `wms:movement:all` | 移库详情 |
| `ReceiptOrderController` | `/wms/receiptOrder` | `wms:receipt:all` | 入库单（含入库操作） |
| `ReceiptOrderDetailController` | `/wms/receiptOrderDetail` | `wms:receipt:all` | 入库详情 |
| `RepairNoticeController` | `/wms/repairNotice` | - | 返修通知（含移动端提交） |
| `ReturnNoticeController` | `/wms/returnNotice` | - | 退货通知 |
| `ShipmentOrderController` | `/wms/shipmentOrder` | `wms:shipment:all` | 出库单 |
| `ShipmentOrderDetailController` | `/wms/shipmentOrderDetail` | `wms:shipment:all` | 出库详情 |
| `WarehouseController` | `/wms/warehouse` | `wms:warehouse:list/edit` | 仓库管理 |
