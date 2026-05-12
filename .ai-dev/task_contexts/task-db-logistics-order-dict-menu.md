## Task: 编写物流单字典和菜单 SQL 脚本

创建 repair_logistics_status 字典配置和物流单菜单注册的 SQL 迁移脚本（含回滚）

### Implementation Context

两个独立的 SQL 文件。

SQL1：20260512_repair_logistics_order_dict.sql
字典类型：repair_logistics_status，描述"物流单状态"
字典数据：
- 0=草稿（info, is_default=Y）
- 1=已提交（warning, is_default=N）
- 2=已发运（success, is_default=N）
- 9=作废（danger, is_default=N）

SQL2：20260512_repair_logistics_order_menu.sql
顶级菜单（parent_id=0），order_num=66（紧跟返回确认单 order_num=65）
menu_id 使用 1827000000000000001~1827000000000000007

菜单项：
- 菜单名"物流单"，path='repairLogisticsOrder'，component='wms/order/repairLogisticsOrder/index'
   perms='wms:repairLogisticsOrder:list'，type='C'，icon='logistics'
- 按钮1：查询（perms=wms:repairLogisticsOrder:list）
- 按钮2：新增（perms=wms:repairLogisticsOrder:add）
- 按钮3：修改（perms=wms:repairLogisticsOrder:edit）
- 按钮4：删除（perms=wms:repairLogisticsOrder:remove）
- 按钮5：导出（perms=wms:repairLogisticsOrder:export）
- 按钮6：详情（perms=wms:repairLogisticsOrder:query）

权限标识遵循细粒度模式，与 Controller 中的 @SaCheckPermission 注解保持一致。
所有菜单使用 SELECT ... WHERE NOT EXISTS 防重。


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

#### wms-ruoyi-master/script/sql/20260512_return_notice_menu.sql
```
-- ============================================================
-- 脚本名称：20260512_return_notice_menu.sql
-- 描述：新增返回确认单菜单目录、页面菜单和权限按钮
-- 升级日期：2026-05-12
-- 说明：
--   1. 返回确认单作为独立顶级菜单（与入库/出库/移库/盘库/返修通知单同级，order_num=65）
--   2. 包含 1 个 C 类型菜单 + 7 个 F 类型权限按钮 = 共 8 条记录
--   3. 使用 NOT EXISTS 条件判断防止重复执行
--   4. 注意：按钮"提交"与"修改"共用权限标识 wms:returnNotice:edit
-- ============================================================

-- 1. 插入顶级菜单：返回确认单（C 类型，页面菜单）
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `query_param`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`)
SELECT 1826000000000000001, '返回确认单', 0, 65, 'returnNotice', 'wms/order/returnNotice/index', NULL, 0, 0, 'C', '1', '1', 'wms:returnNotice:list', 'documentation', 'admin', NOW(), 'admin', NOW(), '返回确认单菜单'
WHERE NOT EXISTS (
    SELECT 1 FROM `sys_menu` WHERE `menu_id` = 1826000000000000001
);

-- 2. 插入权限按钮：查询（F 类型）
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `query_param`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`)
SELECT 1826000000000000002, '查询', 1826000000000000001, 1, '#', '', NULL, 0, 0, 'F', '1', '1', 'wms:returnNotice:list', '#', 'admin', NOW(), 'admin', NOW(), ''
WHERE NOT EXISTS (
    SELECT 1 FROM `sys_menu` WHERE `menu_id` = 1826000000000000002
);

-- 3. 插入权限按钮：新增（F 类型）
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `query_param`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`)
SELECT 1826000000000000003, '新增', 1826000000000000001, 2, '#', '', NULL, 0, 0, 'F', '1', '1', 'wms:returnNotice:add', '#', 'admin', NOW(), 'admin', NOW(), ''
WHERE NOT EXISTS (
    SELECT 1 FROM `sys_menu` WHERE `menu_id` = 1826000000000000003
);

-- 4. 插入权限按钮：修改（F 类型）
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `query_param`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`)
SELECT 1826000000000000004, '修改', 1826000000000000001, 3, '#', '', NULL, 0, 0, 'F', '1', '1', 'wms:returnNotice:edit', '#', 'admin', NOW(), 'admin', NOW(), ''
WHERE NOT EXISTS (
    SELECT 1 FROM `sys_menu` WHERE `menu_id` = 1826000000000000004
);

-- 5. 插入权限按钮：删除（F 类型）
INSERT INTO `sys_menu` (`menu_id`, `menu_name`, `parent_id`, `order_num`, `path`, `component`, `query_param`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`)
SELECT 1826000000000000005, '删除', 1826000000000000001, 4, '#', '', NULL, 0, 0, 'F', '1', '1', 'wms:returnNotice:remove', '#', 'admin', NOW(), 'admin', NOW(), ''
WHERE NOT EXISTS
```
