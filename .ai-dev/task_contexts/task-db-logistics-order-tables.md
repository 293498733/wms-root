## Task: 编写物流单建表 SQL 迁移脚本

创建 repair_logistics_order 和 repair_logistics_order_detail 两张新表的 DDL 迁移脚本（含回滚）

### Implementation Context

全新模块，数据库中没有这两张表，需从头创建。

表1：repair_logistics_order（物流单主表）
- id: bigint(20) PK AUTO_INCREMENT
- order_no: varchar(64) UNIQUE NOT NULL (前缀 WLD)
- repair_notice_id: bigint(20) NOT NULL, INDEX
- status: varchar(2) NOT NULL DEFAULT '0' (0=草稿 1=已提交 2=已发运 9=作废)
- total_quantity: decimal(10,2) DEFAULT NULL
- logistics_company: varchar(100) DEFAULT NULL
- logistics_no: varchar(64) DEFAULT NULL（物流公司单号）
- remark: varchar(500) DEFAULT NULL
- del_flag: varchar(2) DEFAULT '0'
- create_by / create_time / update_by / update_time: 审计字段

表2：repair_logistics_order_detail（物流单明细表）
- id: bigint(20) PK AUTO_INCREMENT
- order_id: bigint(20) NOT NULL, INDEX（关联物流单主表ID）
- sku_id: bigint(20) NOT NULL, INDEX
- sku_name: varchar(200) DEFAULT NULL（冗余）
- quantity: decimal(10,2) NOT NULL
- remark: varchar(500) DEFAULT NULL

参照 03-plan.md 第3.3节的精确字段定义。
文件命名：20260512_repair_logistics_order_tables.sql

注意事项：
- 不修改 repair_notice 和 repair_notice_detail 表
- 不涉及库存相关表
- 引擎使用 InnoDB，字符集 utf8mb4
- 在注释块中提供回滚 SQL


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

#### requirement.md
```
返修通知单点击开始处理的核对明细页面UI调整，需要将物品按照规格型号进行汇总显示数量。只需要规格型号的预期数量与实际数量匹配即可。具体物品条码可以点击下拉展示。最后就是注意数据展示，当物品数量过多比如200个时，是否需要增加分页。
```
