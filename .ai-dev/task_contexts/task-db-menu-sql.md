## Task: 新增返修通知单菜单与权限按钮SQL脚本

创建可重复执行的SQL脚本，为返修通知单模块新增一个C类型菜单和6个F类型权限按钮

### Implementation Context

创建返修通知单菜单和权限按钮的SQL迁移脚本。
技术说明：MySQL表sys_menu。菜单ID 1825000000000000001~1825000000000000007。
所有INSERT使用NOT EXISTS防重。路径repairNotice，组件wms/order/repairNotice/index。
顶级菜单(C)：返修通知单parent_id=0 order_num=60 perms=wms:notice:list。
权限按钮(F)：查询(wms:notice:list)/新增(wms:notice:add)/修改(wms:notice:edit)/删除(wms:notice:remove)/导出(wms:notice:export)/详情(wms:notice:query)


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

#### wms-ruoyi-master/script/sql/wms.sql
```
## File: wms.sql (1118 lines, 105KB)

### SQL Statements
- DROP TABLE IF EXISTS `GEN_TABLE`;
- CREATE TABLE `GEN_TABLE`  (
- DROP TABLE IF EXISTS `GEN_TABLE_COLUMN`;
- CREATE TABLE `GEN_TABLE_COLUMN`  (
- DROP TABLE IF EXISTS `SYS_CONFIG`;
- CREATE TABLE `SYS_CONFIG`  (
- INSERT INTO `SYS_CONFIG` VALUES (1, '主框架页-默认皮肤样式名称', 'SYS.INDEX.SKINNAME', 'SKIN-BLUE', 'Y', 'ADMIN', '2024-06-13 16:06:
- INSERT INTO `SYS_CONFIG` VALUES (2, '用户管理-账号初始密码', 'SYS.USER.INITPASSWORD', '123456', 'Y', 'ADMIN', '2024-06-13 16:06:37
- INSERT INTO `SYS_CONFIG` VALUES (3, '主框架页-侧边栏主题', 'SYS.INDEX.SIDETHEME', 'THEME-LIGHT', 'Y', 'ADMIN', '2024-06-13 16:06:
- INSERT INTO `SYS_CONFIG` VALUES (4, '账号自助-验证码开关', 'SYS.ACCOUNT.CAPTCHAENABLED', 'TRUE', 'Y', 'ADMIN', '2024-06-13 16:06:
- INSERT INTO `SYS_CONFIG` VALUES (5, '账号自助-是否开启用户注册功能', 'SYS.ACCOUNT.REGISTERUSER', 'FALSE', 'Y', 'ADMIN', '2024-06-13 16
- INSERT INTO `SYS_CONFIG` VALUES (11, 'OSS预览列表资源开关', 'SYS.OSS.PREVIEWLISTRESOURCE', 'TRUE', 'Y', 'ADMIN', '2024-06-13 16:
- DROP TABLE IF EXISTS `SYS_DEPT`;
- CREATE TABLE `SYS_DEPT`  (
- INSERT INTO `SYS_DEPT` VALUES (100, 0, '0', '若依科技', 0, '若依', '15888888888', 'RY@QQ.COM', '1', '0', 'ADMIN', '2024-06-13 
- INSERT INTO `SYS_DEPT` VALUES (101, 100, '0,100', '深圳总公司', 1, '若依', '15888888888', 'RY@QQ.COM', '1', '0', 'ADMIN', '2024
- INSERT INTO `SYS_DEPT` VALUES (102, 100, '0,100', '长沙分公司', 2, '若依', '15888888888', 'RY@QQ.COM', '1', '0', 'ADMIN', '2024
- INSERT INTO `SYS_DEPT` VALUES (103, 101, '0,100,101', '研发部门', 1, '若依', '15888888888', 'RY@QQ.COM', '1', '0', 'ADMIN', '2
- INSERT INTO `SYS_DEPT` VALUES (104, 101, '0,100,101', '市场部门', 2, '若依', '15888888888', 'RY@QQ.COM', '1', '0', 'ADMIN', '2
- INSERT INTO `SYS_DEPT` VALUES (105, 101, '0,100,101', '测试部门', 3, '若依', '15888888888', 'RY@QQ.COM', '1', '0', 'ADMIN', '2
  ... and 353 more
```
