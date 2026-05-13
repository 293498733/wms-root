## Task: 新建 RepairNoticeService 业务服务层

创建RepairNoticeService.java实现startProcess/confirmCheck/rejectCheck三个核心方法

### Implementation Context

新建RepairNoticeService.java（文件不存在）。包com.ruoyi.wms.service。
使用@RequiredArgsConstructor+@Service，与ReceiptOrderService风格一致（无接口层直接@Service在主类）。
注入：RepairNoticeMapper, RepairNoticeDetailService, ReceiptOrderService, ItemSkuService。

startProcess(Long id) -> RepairNoticeCheckDetailVo：
校验通知单存在 -> status=="2" -> handlerDeptId==LoginHelper.getDeptId()
-> repairNoticeDetailService.queryByNoticeId(id) 查明细
-> 检查数量不超过MAX_CHECK_DETAIL_LIMIT=5000
-> buildCheckDetailItems(details) -> buildGroupedDetails(items) -> 返回VO

confirmCheck(Long noticeId, RepairNoticeConfirmBo bo) -> Long：
校验状态和权限 -> 校验提交的skuId均属于本通知单 -> 用提交数量重建分组校验allMatched
-> 更新status=3/handoverStatus=2
-> 构建ReceiptOrderBo -> receiptOrderService.receive() 创建入库单
-> 返回入库单ID

rejectCheck(Long noticeId, RepairNoticeRejectBo bo) -> void：
校验 -> 更新status=1/handoverStatus=0/rejectReason

buildCheckDetailItems：从RepairNoticeDetailVo的getItemSku()/getItem()读取，不重复查数据库
buildGroupedDetails：按skuName分组，null归入"未知规格"，取第一个非空itemName


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

### Relevant Input Files

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/controller/RepairNoticeController.java
```
package com.ruoyi.wms.controller;

import cn.dev33.satoken.annotation.SaCheckPermission;
import com.ruoyi.common.core.domain.R;
import com.ruoyi.common.core.validate.AddGroup;
import com.ruoyi.common.core.validate.EditGroup;
import com.ruoyi.common.excel.utils.ExcelUtil;
import com.ruoyi.common.idempotent.annotation.RepeatSubmit;
import com.ruoyi.common.log.annotation.Log;
import com.ruoyi.common.log.enums.BusinessType;
import com.ruoyi.common.mybatis.core.page.PageQuery;
import com.ruoyi.common.mybatis.core.page.TableDataInfo;
import com.ruoyi.common.web.core.BaseController;
import com.ruoyi.wms.domain.bo.RepairNoticeBo;
import com.ruoyi.wms.domain.bo.RepairNoticeConfirmBo;
import com.ruoyi.wms.domain.bo.RepairNoticeMobileSubmitBo;
import com.ruoyi.wms.domain.bo.RepairNoticeRejectBo;
import com.ruoyi.wms.domain.vo.RepairNoticeCheckDetailVo;
import com.ruoyi.wms.domain.vo.RepairNoticeVo;
import com.ruoyi.wms.service.RepairNoticeService;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Validated
@RequiredArgsConstructor
@RestController
@RequestMapping("/wms/RepairNotice")
public class RepairNoticeController extends BaseController {

    private final RepairNoticeService repairNoticeService;

    @SaCheckPermission("wms:notice:list")
    @GetMapping("/list")
    public TableDataInfo<RepairNoticeVo> list(RepairNoticeBo bo, PageQuery pageQuery) {
        return repairNoticeService.queryPageList(bo, pageQuery);
    }

    /**
     * 入库单选择返修通知单专用列表：
     * 仅返回当前登录人机构下已提交(status=2)的通知单
     */
    @SaCheckPermission("wms:notice:list")
    @GetMapping("/receiptSelectList")
    public TableDataInfo<RepairNoticeVo> receiptSelectList(@RequestParam(required = false) String noticeNo, PageQuery pageQuery) {
        return repairNoticeService.queryReceiptSelectPage(noticeNo, pageQuery);
    }

    @SaCheckPermission("wms:notice:export")
    @Log(title = "返修通知单", businessType = BusinessType.EXPORT)
    @PostMapping("/export")
    public void export(RepairNoticeBo bo, HttpServletResponse response) {
        List<RepairNoticeVo> list = repairNoticeService.queryList(bo);
        ExcelUtil.exportExcel(list, "返修通知单", RepairNoticeVo.class, response);
    }

    @SaCheckPermission("wms:notice:query")
    @GetMapping("/{id}")
    public R<RepairNoticeVo> getInfo(@NotNull(message = "主键不能为空") @PathVariable Long id) {
        return R.ok(repairNoticeService.queryById(id));
    }

    @SaCheckPermission("wms:notice:add")
    @Log(title = "返修通知单", businessType = BusinessType.INSERT)
    @RepeatSubmit()
    @PostMapping()
    public R<Void> add(@Validated(AddGroup.class) @RequestBody RepairNoticeBo bo) {
        repairNoticeService.insertByBo(bo);
        return R.ok();
    }

 
```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/vo/RepairNoticeCheckDetailVo.java
```
package com.ruoyi.wms.domain.vo;

import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.util.List;

/**
 * 返修通知单核对明细视图
 */
@Data
public class RepairNoticeCheckDetailVo implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    private String noticeNo;
    private String noticeStatus;

    /**
     * 按规格型号分组后的明细列表
     */
    private List<GroupedCheckDetail> groupedDetails;

    @Data
    public static class CheckDetailItem {
        private Long skuId;
        private String skuName;
        private String itemName;
        private String barcode;
        private Long expectedQuantity;
        private Long actualQuantity;
        private Boolean matched;
    }

    @Data
    public static class GroupedCheckDetail {
        /** 规格型号（分组 key） */
        private String skuName;
        /** 物品名称 */
        private String itemName;
        /** 该规格型号下的预期数量汇总 */
        private Long totalExpectedQuantity;
        /** 该规格型号下的实际数量汇总 */
        private Long totalActualQuantity;
        /** 该分组是否一致（totalActualQuantity === totalExpectedQuantity） */
        private Boolean matched;
        /** 该分组下的明细列表 */
        private List<CheckDetailItem> items;
    }
}

```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/vo/RepairNoticeDetailVo.java
```
package com.ruoyi.wms.domain.vo;

import com.alibaba.excel.annotation.ExcelIgnoreUnannotated;
import com.ruoyi.wms.domain.entity.RepairNoticeDetail;
import io.github.linpeilie.annotations.AutoMapper;
import lombok.Data;

/**
 * ??????????????????
 */
@Data
@ExcelIgnoreUnannotated
@AutoMapper(target = RepairNoticeDetail.class)
public class RepairNoticeDetailVo {

    private Long id;

    private Long noticeId;

    private Long skuId;

    private ItemSkuVo itemSku;

    private ItemVo item;
}

```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/vo/ItemSkuVo.java
```
package com.ruoyi.wms.domain.vo;

import com.alibaba.excel.annotation.ExcelIgnoreUnannotated;
import com.alibaba.excel.annotation.ExcelProperty;
import com.ruoyi.wms.domain.entity.ItemSku;
import io.github.linpeilie.annotations.AutoMapper;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

@Data
@ExcelIgnoreUnannotated
@AutoMapper(target = ItemSku.class)
public class ItemSkuVo implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @ExcelProperty(value = "")
    private Long id;

    /**
     * 商品名称
     */
    @ExcelProperty(value = "商品名称")
    private String skuName;

    private Long itemId;

    /**
     * 条码
     */
    @ExcelProperty(value = "条码")
    private String barcode;

    /**
     * 编号（与条码一致）
     */
    @ExcelProperty(value = "编号")
    private String skuCode;

    @ExcelProperty(value = "长(cm)")
    private BigDecimal length;

    @ExcelProperty(value = "宽(cm)")
    private BigDecimal width;

    @ExcelProperty(value = "高(cm)")
    private BigDecimal height;

    @ExcelProperty(value = "毛重(kg)")
    private BigDecimal grossWeight;

    @ExcelProperty(value = "净重(kg)")
    private BigDecimal netWeight;

    /**
     * 原字段保留不使用
     */
    private BigDecimal costPrice;
    private BigDecimal sellingPrice;

    /**
     * 维修状态
     */
    @ExcelProperty(value = "维修状态")
    private Integer repairStatus;

    /**
     * 故障类型
     */
    @ExcelProperty(value = "故障类型")
    private String faultType;

    /**
     * 故障描述
     */
    @ExcelProperty(value = "故障描述")
    private String faultDesc;

    /**
     * 维修单位
     */
    @ExcelProperty(value = "维修单位")
    private String repairVendor;

    /**
     * 送修时间
     */
    @ExcelProperty(value = "送修时间")
    private Date sendRepairTime;

    /**
     * 维修完成时间
     */
    @ExcelProperty(value = "维修完成时间")
    private Date repairFinishTime;

    /**
     * 回寄时间
     */
    @ExcelProperty(value = "回寄时间")
    private Date returnTime;

    /**
     * 维修备注
     */
    @ExcelProperty(value = "维修备注")
    private String repairRemark;
}

```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/vo/ItemVo.java
```
package com.ruoyi.wms.domain.vo;

import com.alibaba.excel.annotation.ExcelIgnoreUnannotated;
import com.alibaba.excel.annotation.ExcelProperty;
import com.ruoyi.wms.domain.entity.Item;
import io.github.linpeilie.annotations.AutoMapper;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;

@Data
@ExcelIgnoreUnannotated
@AutoMapper(target = Item.class)
public class ItemVo implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @ExcelProperty(value = "")
    private Long id;

    @ExcelProperty(value = "编号")
    private String itemCode;

    @ExcelProperty(value = "名称")
    private String itemName;

    @ExcelProperty(value = "分类")
    private String itemCategory;

    @ExcelProperty(value = "单位类别")
    private String unit;

    @ExcelProperty(value = "品牌")
    private Long itemBrand;

    @ExcelProperty(value = "备注")
    private String remark;

    /**
     * 分类信息
     */
    private ItemCategoryVo itemCategoryInfo;

    /**
     * 商品数量
     */
    private Long goodsCount;
}

```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/bo/RepairNoticeConfirmBo.java
```
package com.ruoyi.wms.domain.bo;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.List;

/**
 * 返修通知单核对通过请求
 */
@Data
public class RepairNoticeConfirmBo implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @NotNull(message = "仓库不能为空")
    private Long warehouseId;

    @NotEmpty(message = "核对明细不能为空")
    private List<ConfirmDetail> details;

    @Data
    public static class ConfirmDetail {
        @NotNull(message = "SKU不能为空")
        private Long skuId;

        @NotNull(message = "数量不能为空")
        private BigDecimal quantity;
    }
}

```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/bo/RepairNoticeRejectBo.java
```
package com.ruoyi.wms.domain.bo;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;

/**
 * 返修通知单核对退回请求
 */
@Data
public class RepairNoticeRejectBo implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    @NotBlank(message = "退回原因不能为空")
    private String rejectReason;
}

```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/entity/RepairNotice.java
```
package com.ruoyi.wms.domain.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.ruoyi.common.mybatis.core.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.io.Serial;
import java.math.BigDecimal;
import java.util.Date;

/**
 * 返修通知单对象 repair_notice
 *
 * @author zcc
 * @date 2026-04-02
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("repair_notice")
public class RepairNotice extends BaseEntity {

    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    @TableId(value = "id")
    private Long id;
    /**
     * 返修通知单号
     */
    private String noticeNo;
    /**
     * 送修人ID(sys_user.user_id)
     */
    private Long applicantId;
    /**
     * 送修人姓名
     */
    private String applicantName;
    /**
     * 发起机构ID
     */
    private Long applicantDeptId;
    /**
     * 发起机构名称
     */
    private String applicantDeptName;
    /**
     * 处理人/对接人ID(sys_user.user_id)
     */
    private Long handlerId;
    /**
     * 处理人/对接人姓名
     */
    private String handlerName;
    /**
     * 处理机构ID
     */
    private Long handlerDeptId;
    /**
     * 处理机构名称
     */
    private String handlerDeptName;
    /**
     * 省编码
     */
    private String provinceCode;
    /**
     * 省名称
     */
    private String provinceName;
    /**
     * 市编码
     */
    private String cityCode;
    /**
     * 市名称
     */
    private String cityName;
    /**
     * 区县编码
     */
    private String districtCode;
    /**
     * 区县名称
     */
    private String districtName;
    /**
     * 设备来源
     */
    private String deviceSource;
    /**
     * 项目包编码
     */
    private String projectPackageCode;
    /**
     * 物流单位
     */
    private String logisticsCompany;
    /**
     * 物流单号
     */
    private String logisticsNo;
    /**
     * 运费
     */
    private BigDecimal freight;
    /**
     * 回寄地址
     */
    private String returnAddress;
    /**
     * 回寄联系人ID
     */
    private Long returnContactId;
    /**
     * 回寄联系人姓名
     */
    private String returnContactName;
    /**
     * 回寄联系人电话
     */
    private String returnContactPhone;
    /**
     * 寄修地址
     */
    private String repairAddress;
    /**
     * 寄修联系人ID
     */
    private Long repairContactId;
    /**
     * 寄修联系人姓名
     */
    private String repairContactName;
    /**
     * 寄修联系人电话
     */
    private String repairContactPhone;
    /**
     * 故障件类型
     */
    private String faultyDeviceType;
    /**
     * 故障件名称
     */
    private String faultyDeviceName;
    /**
     * 故障件品牌
     */
    private String faultyDeviceBrand;
    /**
     * 故障件型号
     */
    private String faultyDeviceModel;
    /**
     * 送修数量
     */
    private Long repairQuantity;
    /**
     * 送修日期
     */
    @JsonFormat(pattern = "yyyy-MM-dd", timezone = "GMT+8")
    private Date sendRepairDate;
    /**
     * 寄出日期
     */
    @Json
```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/mapper/RepairNoticeMapper.java
```
package com.ruoyi.wms.mapper;

import com.ruoyi.wms.domain.entity.RepairNotice;
import com.ruoyi.wms.domain.vo.RepairNoticeVo;
import com.ruoyi.common.mybatis.core.mapper.BaseMapperPlus;

/**
 * 返修通知单Mapper接口
 *
 * @author zcc
 * @date 2026-04-02
 */
public interface RepairNoticeMapper extends BaseMapperPlus<RepairNotice, RepairNoticeVo> {

}

```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/service/RepairNoticeDetailService.java
```
package com.ruoyi.wms.service;

import cn.hutool.core.collection.CollUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.ruoyi.common.core.exception.ServiceException;
import com.ruoyi.wms.domain.bo.RepairNoticeDetailBo;
import com.ruoyi.wms.domain.entity.RepairNoticeDetail;
import com.ruoyi.wms.domain.vo.ItemSkuMapVo;
import com.ruoyi.wms.domain.vo.RepairNoticeDetailVo;
import com.ruoyi.wms.mapper.RepairNoticeDetailMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@RequiredArgsConstructor
@Service
public class RepairNoticeDetailService extends ServiceImpl<RepairNoticeDetailMapper, RepairNoticeDetail> {

    private final RepairNoticeDetailMapper repairNoticeDetailMapper;
    private final ItemSkuService itemSkuService;

    public List<RepairNoticeDetailVo> queryByNoticeId(Long noticeId) {
        LambdaQueryWrapper<RepairNoticeDetail> lqw = Wrappers.lambdaQuery();
        lqw.eq(RepairNoticeDetail::getNoticeId, noticeId);
        List<RepairNoticeDetailVo> list = repairNoticeDetailMapper.selectVoList(lqw);
        if (CollUtil.isEmpty(list)) {
            return Collections.emptyList();
        }
        fillSkuAndItemInfo(list);
        return list;
    }

    @Transactional
    public void replaceByNoticeId(Long noticeId, List<RepairNoticeDetailBo> detailBos) {
        deleteByNoticeId(noticeId);
        if (CollUtil.isEmpty(detailBos)) {
            return;
        }
        validateDetailBos(detailBos);
        List<RepairNoticeDetail> details = detailBos.stream().map(bo -> {
            RepairNoticeDetail detail = new RepairNoticeDetail();
            detail.setId(bo.getId());
            detail.setSkuId(bo.getSkuId());
            detail.setNoticeId(noticeId);
            return detail;
        }).collect(Collectors.toList());
        saveBatch(details);
    }

    public void deleteByNoticeId(Long noticeId) {
        LambdaQueryWrapper<RepairNoticeDetail> lqw = Wrappers.lambdaQuery();
        lqw.eq(RepairNoticeDetail::getNoticeId, noticeId);
        remove(lqw);
    }

    public long countByNoticeId(Long noticeId) {
        LambdaQueryWrapper<RepairNoticeDetail> lqw = Wrappers.lambdaQuery();
        lqw.eq(RepairNoticeDetail::getNoticeId, noticeId);
        return count(lqw);
    }

    public Set<Long> querySkuIdSetByNoticeId(Long noticeId) {
        LambdaQueryWrapper<RepairNoticeDetail> lqw = Wrappers.lambdaQuery();
        lqw.select(RepairNoticeDetail::getSkuId);
        lqw.eq(RepairNoticeDetail::getNoticeId, noticeId);
        List<RepairNoticeDetail> details = repairNoticeDetailMapper.selectList(lqw);
        if (CollUtil.isEmpty(details)) {
            return Collections.emptySet();
        }
        retu
```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/service/ReceiptOrderService.java
```
## File: ReceiptOrderService.java (328 lines, 13KB)

**Package**: package com.ruoyi.wms.service;
**Imports**: 32 packages

### Classes/Interfaces (1)
- `public class ReceiptOrderService {`

### Constants/Fields
private static final Long REPAIR_RECEIPT_OPT_TYPE = 1L;

### Methods (29)
- `public ReceiptOrderVo queryById(Long id){`
- `public Long queryIdByOrderNo(String orderNo){`
- `public TableDataInfo<ReceiptOrderVo> queryPageList(ReceiptOrderBo bo, PageQuery pageQuery) {`
- `public List<ReceiptOrderVo> queryList(ReceiptOrderBo bo) {`
- `private LambdaQueryWrapper<ReceiptOrder> buildQueryWrapper(ReceiptOrderBo bo) {`
- `public Long insertByBo(ReceiptOrderBo bo) {`
- `public void receive(ReceiptOrderBo bo) {`
- `private void validateBeforeReceive(ReceiptOrderBo bo) {`
- `throw new BaseException("商品明细不能为空");`
- `public void updateByBo(ReceiptOrderBo bo) {`
- `public void editToInvalid(Long id) {`
- `public void deleteById(Long id) {`
- `private void validateIdBeforeDelete(Long id) {`
- `throw new ServiceException("删除失败", HttpStatus.CONFLICT,"入库单【" + receiptOrderVo.getOrderNo() + "】已入库，无法删除！");`
- `public void deleteByIds(Collection<Long> ids) {`
- `public void validateReceiptOrderNo(String receiptOrderNo) {`
- `private boolean isRepairReceipt(ReceiptOrderBo bo) {`
- `private void validateDuplicateSkuInDetails(List<ReceiptOrderDetailBo> details) {`
- `throw new ServiceException("商品明细必须包含skuId");`
- `throw new ServiceException("同一单据不允许重复选择同一物品");`
- `private void validateRepairReceiptDetails(ReceiptOrderBo bo) {`
- `throw new ServiceException("返修入库必须选择返修通知单");`
- `throw new ServiceException("返修通知单不存在");`
- `throw new ServiceException("仅已提交或处理中状态的返修通知单可用于返修入库");`
- `throw new ServiceException("该返修通知单不属于当前机构，无法用于返修入库");`
- `throw new ServiceException("返修通知单未关联可入库物品");`
- `throw new ServiceException("入库物品不属于所选返修通知单");`
- `throw new ServiceException("返修入库物品数量必须大于0");`
- `private void autoFinishRepairNoticeIfComplete(ReceiptOrderBo bo) {`
```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/service/ItemSkuService.java
```
## File: ItemSkuService.java (361 lines, 12KB)

**Package**: package com.ruoyi.wms.service;
**Imports**: 28 packages

### Classes/Interfaces (1)
- `public class ItemSkuService extends ServiceImpl<ItemSkuMapper, ItemSku> {`

### Methods (30)
- `public ItemSkuMapVo queryItemSkuMapVo(Long id) {`
- `public ItemSkuVo queryById(Long id) {`
- `public TableDataInfo<ItemSkuMapVo> queryPageList(ItemSkuBo bo, PageQuery pageQuery) {`
- `public List<ItemSkuVo> queryList(ItemSkuBo bo) {`
- `public List<ItemPageWithSkuVo> queryItemWithSkuList(ItemSkuBo bo) {`
- `private LambdaQueryWrapper<ItemSku> buildQueryWrapper(ItemSkuBo bo) {`
- `public Boolean insertByBo(ItemSkuBo bo) {`
- `public Boolean updateByBo(ItemSkuBo bo) {`
- `private void normalizeBeforeSave(ItemSkuBo bo) {`
- `private void validateSkuCodeUnique(ItemSkuBo bo) {`
- `throw new ServiceException("保存失败", HttpStatus.CONFLICT, "编码不能为空！");`
- `throw new ServiceException("保存失败", HttpStatus.CONFLICT, "编码已存在，不能重复！");`
- `public void deleteById(Long id) {`
- `private void validateIdBeforeDelete(Long id) {`
- `throw new ServiceException("删除失败", HttpStatus.CONFLICT, "至少包含一个商品规格！");`
- `throw new ServiceException("删除失败", HttpStatus.CONFLICT, "该规格已有业务关联，无法删除！");`
- `private void validateSkuIdsBeforeDelete(Collection<Long> skuIds) {`
- `throw new ServiceException("删除失败", HttpStatus.CONFLICT, "该商品已有业务关联，无法删除！");`
- `public void deleteByIds(Collection<Long> ids) {`
- `public void saveOrUpdateBatchByBo(List<ItemSkuBo> sku) {`
- `public void setItemId(List<ItemSkuBo> itemSkuList, Long itemId) {`
- `public List<ItemSkuVo> queryByItemId(Long id) {`
- `public Map<Long, ItemSkuMapVo> queryItemSkuMapVosByIds(Set<Long> skuIds) {`
- `public void setItemSkuMap(List<? extends BaseOrderDetailVo> details) {`
- `public Map<Long, Long> countByItemIds(List<Long> itemIds) {`
- `public TableDataInfo<ItemSkuVo> queryPageByItemId(ItemSkuBo bo, PageQuery pageQuery) {`
- `throw new ServiceException("itemId不能为空");`
- `public TableDataInfo<ItemSkuVo> queryPageByItemIdForRepairNotice(ItemSkuBo bo, PageQuery pageQuery) {`
- `throw new ServiceException("itemId不能为空");`
- `public void batchUpdateRepairStatus(Collection<Long> skuIds, Integer repairStatus) {`
```
