## Task: 开发物流单实体/BO/VO 数据对象

创建 RepairLogisticsOrder 和 RepairLogisticsOrderDetail 的 Entity、Bo、Vo 共6个类

### Implementation Context

参照 ReturnNotice / ReturnNoticeDetail 的现有模式开发6个数据对象类。

Entity（实体）：
- RepairLogisticsOrder：@TableName("repair_logistics_order")，继承 BaseEntity（含 del_flag, create_by, create_time 等审计字段）
  字段：id(Long, @TableId), orderNo(String), repairNoticeId(Long), status(String, default "0"), 
        totalQuantity(BigDecimal), logisticsCompany(String), logisticsNo(String), remark(String), delFlag(String)
- RepairLogisticsOrderDetail：@TableName("repair_logistics_order_detail")，不继承 BaseEntity
  字段：id(Long, @TableId), orderId(Long), skuId(Long), skuName(String), quantity(BigDecimal), remark(String)

BO（业务对象）：
- RepairLogisticsOrderBo：继承 BaseEntity，使用 @AutoMapper(target = RepairLogisticsOrder.class, reverseConvertGenerate = false)
  验证注解：@NotNull(id for EditGroup), @NotNull(repairNoticeId for AddGroup/EditGroup), @NotEmpty(details)
  字段与 Entity 对应，但 details 字段为 List<RepairLogisticsOrderDetailBo>
- RepairLogisticsOrderDetailBo：plain POJO
  字段：skuId(Long, 必填), skuName(String), quantity(BigDecimal, 必填), remark(String)

VO（视图对象）：
- RepairLogisticsOrderVo：@AutoMapper(target = RepairLogisticsOrder.class)，实现 Serializable
  字段与 Entity 对应，额外加上 repairNoticeNo(String，关联展示)，details(List<RepairLogisticsOrderDetailVo>)
- RepairLogisticsOrderDetailVo：plain POJO，含所有字段

包路径：com.ruoyi.wms.domain.entity / .bo / .vo
使用 Lombok @Data @EqualsAndHashCode(callSuper=true)


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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/bo/ReturnNoticeBo.java
```
package com.ruoyi.wms.domain.bo;

import com.ruoyi.common.core.validate.AddGroup;
import com.ruoyi.common.core.validate.EditGroup;
import com.ruoyi.common.mybatis.core.domain.BaseEntity;
import com.ruoyi.wms.domain.entity.ReturnNotice;
import io.github.linpeilie.annotations.AutoMapper;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.util.List;

/**
 * 返回通知单业务对象 return_notice
 *
 * @author zcc
 * @date 2026-05-11
 */
@Data
@EqualsAndHashCode(callSuper = true)
@AutoMapper(target = ReturnNotice.class, reverseConvertGenerate = false)
public class ReturnNoticeBo extends BaseEntity {

    /**
     * 主键ID
     */
    @NotNull(message = "主键ID不能为空", groups = {EditGroup.class})
    private Long id;

    /**
     * 返回通知单号
     */
    private String returnNoticeNo;

    /**
     * 关联返修通知单ID
     */
    @NotNull(message = "关联返修通知单不能为空", groups = {AddGroup.class, EditGroup.class})
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
     * 返回明细列表
     */
    @NotEmpty(message = "明细不能为空", groups = {AddGroup.class, EditGroup.class})
    private List<ReturnNoticeDetailBo> details;

}

```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/vo/ReturnNoticeVo.java
```
package com.ruoyi.wms.domain.vo;

import com.alibaba.excel.annotation.ExcelIgnoreUnannotated;
import com.alibaba.excel.annotation.ExcelProperty;
import com.ruoyi.common.excel.annotation.ExcelDictFormat;
import com.ruoyi.common.excel.convert.ExcelDictConvert;
import com.ruoyi.wms.domain.entity.ReturnNotice;
import io.github.linpeilie.annotations.AutoMapper;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

/**
 * 返回通知单视图对象 return_notice
 *
 * @author zcc
 * @date 2026-05-11
 */
@Data
@ExcelIgnoreUnannotated
@AutoMapper(target = ReturnNotice.class)
public class ReturnNoticeVo implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    @ExcelProperty(value = "主键ID")
    private Long id;

    /**
     * 返回通知单号
     */
    @ExcelProperty(value = "返回通知单号")
    private String returnNoticeNo;

    /**
     * 关联返修通知单ID
     */
    @ExcelProperty(value = "关联返修通知单ID")
    private Long repairNoticeId;

    /**
     * 关联返修通知单号（冗余展示）
     */
    @ExcelProperty(value = "关联返修通知单号")
    private String repairNoticeNo;

    /**
     * 状态
     */
    @ExcelProperty(value = "状态", converter = ExcelDictConvert.class)
    @ExcelDictFormat(dictType = "return_notice_status")
    private String status;

    /**
     * 出库仓库ID
     */
    @ExcelProperty(value = "出库仓库ID")
    private Long warehouseId;

    /**
     * 出库仓库名称
     */
    @ExcelProperty(value = "出库仓库名称")
    private String warehouseName;

    /**
     * 总返回数量
     */
    @ExcelProperty(value = "总返回数量")
    private BigDecimal totalQuantity;

    /**
     * 物流公司
     */
    @ExcelProperty(value = "物流公司")
    private String logisticsCompany;

    /**
     * 物流单号
     */
    @ExcelProperty(value = "物流单号")
    private String logisticsNo;

    /**
     * 处理人ID
     */
    @ExcelProperty(value = "处理人ID")
    private Long handlerId;

    /**
     * 处理人名称
     */
    @ExcelProperty(value = "处理人名称")
    private String handlerName;

    /**
     * 备注
     */
    @ExcelProperty(value = "备注")
    private String remark;

    /**
     * 创建人
     */
    @ExcelProperty(value = "创建人")
    private String createBy;

    /**
     * 创建时间
     */
    @ExcelProperty(value = "创建时间")
    private Date createTime;

    /**
     * 更新人
     */
    @ExcelProperty(value = "更新人")
    private String updateBy;

    /**
     * 更新时间
     */
    @ExcelProperty(value = "更新时间")
    private Date updateTime;

    /**
     * 明细列表
     */
    private List<ReturnNoticeDetailVo> details;

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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/bo/ReturnNoticeDetailBo.java
```
package com.ruoyi.wms.domain.bo;

import com.ruoyi.common.core.validate.AddGroup;
import com.ruoyi.common.core.validate.EditGroup;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 返回通知单明细业务对象 return_notice_detail
 *
 * @author zcc
 * @date 2026-05-11
 */
@Data
public class ReturnNoticeDetailBo {

    /**
     * 主键
     */
    private Long id;

    /**
     * 关联返回通知单ID
     */
    private Long returnId;

    /**
     * SKU ID
     */
    @NotNull(message = "SKU不能为空", groups = {AddGroup.class, EditGroup.class})
    private Long skuId;

    /**
     * 规格型号/名称（冗余）
     */
    private String skuName;

    /**
     * 本次返回数量
     */
    @NotNull(message = "返回数量不能为空", groups = {AddGroup.class, EditGroup.class})
    @DecimalMin(value = "0.01", message = "返回数量必须大于0", groups = {AddGroup.class, EditGroup.class})
    private BigDecimal quantity;

    /**
     * 备注
     */
    private String remark;

}

```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/vo/ReturnNoticeDetailVo.java
```
package com.ruoyi.wms.domain.vo;

import com.alibaba.excel.annotation.ExcelIgnoreUnannotated;
import com.ruoyi.wms.domain.entity.ReturnNoticeDetail;
import io.github.linpeilie.annotations.AutoMapper;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;

/**
 * 返回通知单明细视图对象 return_notice_detail
 *
 * @author zcc
 * @date 2026-05-11
 */
@Data
@ExcelIgnoreUnannotated
@AutoMapper(target = ReturnNoticeDetail.class)
public class ReturnNoticeDetailVo implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
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
