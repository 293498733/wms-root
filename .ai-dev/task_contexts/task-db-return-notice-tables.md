## Task: 编写返回确认单建表 SQL 迁移脚本

创建 return_notice 和 return_notice_detail 两张业务表的 DDL 迁移脚本（含回滚）

### Implementation Context

后端代码已有 ReturnNotice 和 ReturnNoticeDetail 实体类（com.ruoyi.wms.domain.entity），
但它们对应的数据库表在当前数据库导出和迁移脚本中均不存在。

必须基于实体类的 @TableName 和字段定义，反向生成建表 DDL。

表1：return_notice（根据 ReturnNotice.java + BaseEntity）
- id: bigint(20) PK AUTO_INCREMENT
- return_notice_no: varchar(64) UNIQUE NOT NULL
- repair_notice_id: bigint(20) NOT NULL, INDEX
- status: varchar(2) NOT NULL DEFAULT '0' (0=草稿 2=已提交 3=已出库 9=作废)
- warehouse_id: bigint(20) DEFAULT NULL
- warehouse_name: varchar(100) DEFAULT NULL
- total_quantity: decimal(10,2) DEFAULT NULL
- logistics_company: varchar(100) DEFAULT NULL
- logistics_no: varchar(64) DEFAULT NULL
- handler_id: bigint(20) DEFAULT NULL
- handler_name: varchar(64) DEFAULT NULL
- remark: varchar(500) DEFAULT NULL
- del_flag: varchar(2) DEFAULT '0'
- create_by: varchar(64) DEFAULT NULL
- create_time: datetime(3) DEFAULT NULL
- update_by: varchar(64) DEFAULT NULL
- update_time: datetime(3) DEFAULT NULL

表2：return_notice_detail（根据 ReturnNoticeDetail.java）
- id: bigint(20) PK AUTO_INCREMENT
- return_id: bigint(20) NOT NULL, INDEX
- sku_id: bigint(20) NOT NULL, INDEX
- sku_name: varchar(200) DEFAULT NULL
- quantity: decimal(10,2) NOT NULL
- remark: varchar(500) DEFAULT NULL

文件命名：20260512_return_notice_tables.sql
迁移脚本目录：wms-ruoyi-master/script/sql/

脚本必须包含：
1. DROP TABLE IF EXISTS 前置检查
2. CREATE TABLE DDL（含主键、索引、UNIQUE、NOT NULL、DEFAULT、ENGINE=InnoDB、CHARSET=utf8mb4）
3. 注释 -- ============================================================
4. 回滚 SQL 注释块

回滚：
DROP TABLE IF EXISTS return_notice_detail;
DROP TABLE IF EXISTS return_notice;


### Reference Documents

#### 02-analysis.md
```
## File: 02-analysis.md (348 lines, 20KB)

### Document Structure
# 需求分析报告：返修通知单核对明细页面UI调整
## 1. 功能拆分
### P0（核心功能，本次必须实现）
### P1（重要，建议本次实现）
### P2（后续迭代）
## 2. 数据流
### 2.1 数据来源
### 2.2 数据流转（当前逻辑）
### 2.3 数据最终存储
### 2.4 本次变更后的数据流
## 3. 界面逻辑
### 3.1 涉及页面
### 3.2 交互流程
#### 当前交互（现状）
#### 变更后交互（本次需求）
### 3.3 输入验证
### 3.4 分页逻辑
## 4. 不确定项（最关键的部分）
### 4.1 业务规则不确定项
### 4.2 技术不确定项
### 4.3 现有代码中未找到对应实现的问题
### 4.4 兼容性不确定项
## 5. 影响范围
### 5.1 需要修改的文件
#### 后端（Java）
#### 前端（Vue）
#### SQL 脚本（新增）
### 5.2 数据库变更
### 5.3 配置变更
### 5.4 接口兼容性
### 5.5 回归影响
## 附录：本次实际修改的文件清单
### 后端文件（wms-ruoyi-master）
### 前端文件（ruo-yi-wms-vue-master）
## 附录：关键代码位置索引
```

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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/entity/ReturnNotice.java
```
package com.ruoyi.wms.domain.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.ruoyi.common.mybatis.core.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.io.Serial;
import java.math.BigDecimal;

/**
 * 返回通知单对象 return_notice
 *
 * @author zcc
 * @date 2026-05-11
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("return_notice")
public class ReturnNotice extends BaseEntity {

    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    @TableId(value = "id")
    private Long id;

    /**
     * 返回通知单号
     */
    private String returnNoticeNo;

    /**
     * 关联返修通知单ID
     */
    private Long repairNoticeId;

    /**
     * 状态：0草稿 2已提交 3已出库 9作废
     */
    private String status;

    /**
     * 出库仓库ID
     */
    private Long warehouseId;

    /**
     * 总返回数量
     */
    private BigDecimal totalQuantity;

    /**
     * 物流公司
     */
    private String logisticsCompany;

    /**
     * 物流单号
     */
    private String logisticsNo;

    /**
     * 处理人ID
     */
    private Long handlerId;

    /**
     * 处理人名称
     */
    private String handlerName;

    /**
     * 备注
     */
    private String remark;

    /**
     * 删除标志(0正常 2已删除)
     */
    private String delFlag;

}

```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/entity/ReturnNoticeDetail.java
```
package com.ruoyi.wms.domain.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.io.Serial;
import java.math.BigDecimal;

/**
 * 返回通知单明细对象 return_notice_detail
 *
 * @author zcc
 * @date 2026-05-11
 */
@Data
@EqualsAndHashCode(callSuper = false)
@TableName("return_notice_detail")
public class ReturnNoticeDetail {

    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id")
    private Long id;

    /**
     * 关联返回通知单ID
     */
    private Long returnId;

    /**
     * SKU ID
     */
    private Long skuId;

    /**
     * 规格型号/名称（冗余）
     */
    private String skuName;

    /**
     * 本次返回数量
     */
    private BigDecimal quantity;

    /**
     * 备注
     */
    private String remark;

}

```
