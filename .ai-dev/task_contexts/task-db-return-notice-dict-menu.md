## Task: 编写返回确认单字典和菜单 SQL 脚本

创建 return_notice_status 字典配置和返回确认单菜单注册的 SQL 迁移脚本（含回滚）

### Implementation Context

两个独立的 SQL 文件，分别注册字典和菜单。

SQL1：20260512_return_notice_dict.sql
字典类型：return_notice_status，描述"返回通知单状态"
字典数据：
- 0=草稿（info, is_default=Y）
- 2=已提交（warning, is_default=N）
- 3=已出库（success, is_default=N）
- 9=作废（danger, is_default=N）

使用 SELECT ... WHERE NOT EXISTS 方式防止重复执行。
菜单 dict_id 使用 2051910020000000001，dict_code 使用 2051910020000000010~2013。

SQL2：20260512_return_notice_menu.sql
顶级菜单（parent_id=0），order_num=65（紧跟返修通知单的 order_num=60）
menu_id 使用 1826000000000000001~1826000000000000008

菜单项：
- 菜单名"返回确认单"，path='returnNotice'，component='wms/order/returnNotice/index'
   perms='wms:returnNotice:list'，type='C'，icon='documentation'
- 按钮1：查询（perms=wms:returnNotice:list）
- 按钮2：新增（perms=wms:returnNotice:add）
- 按钮3：修改（perms=wms:returnNotice:edit）
- 按钮4：删除（perms=wms:returnNotice:remove）
- 按钮5：导出（perms=wms:returnNotice:export）
- 按钮6：详情（perms=wms:returnNotice:query）
- 按钮7：提交（perms=wms:returnNotice:edit，注意与修改共用同一权限）

所有菜单使用 SELECT ... WHERE NOT EXISTS 防重。
回滚 SQL 分别在各文件末尾注释块中。


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
