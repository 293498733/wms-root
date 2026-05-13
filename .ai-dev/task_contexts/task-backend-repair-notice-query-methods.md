## Task: 补充 RepairNoticeService CRUD方法

在新创建的Service中实现queryPageList/insertByBo/updateByBo/saveDraft/submitNotice/deleteByIds等全部CRUD方法

### Implementation Context

补充CRUD方法（对应Controller全部调用）：
queryPageList(RepairNoticeBo bo, PageQuery pageQuery) -> TableDataInfo<RepairNoticeVo>
queryReceiptSelectPage(String noticeNo, PageQuery pageQuery) -> TableDataInfo<RepairNoticeVo>
queryList(RepairNoticeBo bo) -> List<RepairNoticeVo>
queryById(Long id) -> RepairNoticeVo
insertByBo(RepairNoticeBo bo) -> void (@Transactional)
updateByBo(RepairNoticeBo bo) -> void (@Transactional)
saveDraft(RepairNoticeBo bo) -> void (status=0 handoverStatus=0)
submitNotice(RepairNoticeBo bo) -> void (status=2 handoverStatus=1)
deleteByIds(Collection<Long> ids) -> void
mobileSubmit(RepairNoticeMobileSubmitBo bo) -> RepairNoticeVo

使用MyBatis-Plus LambdaQueryWrapper + selectVoPage/selectVoList
使用MapstructUtils.convert BO->Entity
使用repairNoticeDetailService.replaceByNoticeId保存明细


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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/service/RepairNoticeService.java
```
## File: RepairNoticeService.java (501 lines, 21KB)

**Package**: package com.ruoyi.wms.service;
**Imports**: 38 packages

### Classes/Interfaces (1)
- `public class RepairNoticeService {`

### Constants/Fields
private static final long MAX_CHECK_DETAIL_LIMIT = 5000L;
private static final Long REPAIR_RECEIPT_OPT_TYPE = 1L;

### Methods (33)
- `public RepairNoticeCheckDetailVo startProcess(Long id) {`
- `throw new ServiceException("只有已提交状态的单据才能开始处理");`
- `throw new ServiceException("只有处理机构所属部门才能开始处理该单据");`
- `throw new ServiceException("通知单明细不能为空");`
- `throw new ServiceException("通知单明细数量超过限制（最大" + MAX_CHECK_DETAIL_LIMIT + "条）");`
- `public Long confirmCheck(Long noticeId, RepairNoticeConfirmBo bo) {`
- `throw new ServiceException("只有已提交状态的单据才能核对通过");`
- `throw new ServiceException("只有处理机构所属部门才能核对该单据");`
- `throw new ServiceException("通知单明细不能为空");`
- `throw new ServiceException("入库物品不属于所选返修通知单");`
- `throw new ServiceException("存在规格型号实际数量与预期数量不一致，请核对后重新提交");`
- `public void rejectCheck(Long noticeId, RepairNoticeRejectBo bo) {`
- `throw new ServiceException("只有已提交状态的单据才能退回");`
- `throw new ServiceException("只有处理机构所属部门才能退回该单据");`
- `private List<CheckDetailItem> buildCheckDetailItems(List<RepairNoticeDetailVo> details) {`
- `private List<CheckDetailItem> buildSubmittedCheckItems(`
- `private List<GroupedCheckDetail> buildGroupedDetails(List<CheckDetailItem> items) {`
- `public RepairNoticeVo queryById(Long id) {`
- `public TableDataInfo<RepairNoticeVo> queryPageList(RepairNoticeBo bo, PageQuery pageQuery) {`
- `public List<RepairNoticeVo> queryList(RepairNoticeBo bo) {`
- `public TableDataInfo<RepairNoticeVo> queryReceiptSelectPage(String noticeNo, PageQuery pageQuery) {`
- `public void insertByBo(RepairNoticeBo bo) {`
- `public void updateByBo(RepairNoticeBo bo) {`
- `public void saveDraft(RepairNoticeBo bo) {`
- `public void submitNotice(RepairNoticeBo bo) {`
- `public RepairNoticeVo mobileSubmit(RepairNoticeMobileSubmitBo bo) {`
- `return queryById(notice.getId());`
- `public void deleteByIds(List<Long> ids) {`
- `throw new ServiceException("删除失败", HttpStatus.CONFLICT,`
- `private RepairNotice getByIdRequired(Long id) {`
- `throw new ServiceException("返修通知单不存在");`
- `private LambdaQueryWrapper<RepairNotice> buildQueryWrapper(RepairNoticeBo bo) {`
- `private String generateNoticeNo() {`
```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/bo/RepairNoticeBo.java
```
package com.ruoyi.wms.domain.bo;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.ruoyi.common.core.validate.AddGroup;
import com.ruoyi.common.core.validate.EditGroup;
import com.ruoyi.common.mybatis.core.domain.BaseEntity;
import com.ruoyi.wms.domain.entity.RepairNotice;
import io.github.linpeilie.annotations.AutoMapper;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.EqualsAndHashCode;
import org.springframework.format.annotation.DateTimeFormat;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

/**
 * 返修通知单业务对象 repair_notice
 *
 * @author zcc
 * @date 2026-04-02
 */

@Data
@EqualsAndHashCode(callSuper = true)
@AutoMapper(target = RepairNotice.class, reverseConvertGenerate = false)
public class RepairNoticeBo extends BaseEntity {

    /**
     * 主键ID
     */
    @NotNull(message = "主键ID不能为空", groups = {EditGroup.class})
    private Long id;

    /**
     * 返修通知单号
     */
    private String noticeNo;

    /**
     * 送修人ID(sys_user.user_id)
     */
    @NotNull(message = "送修人ID(sys_user.user_id)不能为空", groups = {AddGroup.class, EditGroup.class})
    private Long applicantId;

    /**
     * 送修人姓名
     */
    @NotBlank(message = "送修人姓名不能为空", groups = {AddGroup.class, EditGroup.class})
    private String applicantName;

    /**
     * 发起机构ID
     */
    @NotNull(message = "发起机构ID不能为空", groups = {AddGroup.class, EditGroup.class})
    private Long applicantDeptId;

    /**
     * 发起机构名称
     */
    @NotBlank(message = "发起机构名称不能为空", groups = {AddGroup.class, EditGroup.class})
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
    @NotNull(message = "处理机构ID不能为空", groups = {AddGroup.class, EditGroup.class})
    private Long handlerDeptId;

    /**
     * 处理机构名称
     */
    @NotBlank(message = "处理机构名称不能为空", groups = {AddGroup.class, EditGroup.class})
    private String handlerDeptName;

    /**
     * 省编码
     */
    @NotBlank(message = "省编码不能为空", groups = {AddGroup.class, EditGroup.class})
    private String provinceCode;

    /**
     * 省名称
     */
    @NotBlank(message = "省名称不能为空", groups = {AddGroup.class, EditGroup.class})
    private String provinceName;

    /**
     * 市编码
     */
    @NotBlank(message = "市编码不能为空", groups = {AddGroup.class, EditGroup.class})
    private String cityCode;

    /**
     * 市名称
     */
    @NotBlank(message = "市名称不能为空", groups = {AddGroup.class, EditGroup.class})
    private String cityName;

    /**
     * 区县编码
     */
    @NotBlank(message = "区县编码不能为空", groups = {AddGroup.class, EditGroup.class})
    private String districtCode;

    /**
     * 区县名称
     */
    @NotBlank(message = "区县名称不能为空", groups = {AddGroup.class, EditGroup.class})
    private String districtName;

    /**
     * 设备来源
     
```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/vo/RepairNoticeVo.java
```
package com.ruoyi.wms.domain.vo;

import com.alibaba.excel.annotation.ExcelIgnoreUnannotated;
import com.alibaba.excel.annotation.ExcelProperty;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.ruoyi.common.excel.annotation.ExcelDictFormat;
import com.ruoyi.common.excel.convert.ExcelDictConvert;
import com.ruoyi.wms.domain.entity.RepairNotice;
import io.github.linpeilie.annotations.AutoMapper;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

/**
 * 返修通知单视图对象 repair_notice
 *
 * @author zcc
 * @date 2026-04-02
 */
@Data
@ExcelIgnoreUnannotated
@AutoMapper(target = RepairNotice.class)
public class RepairNoticeVo implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    @ExcelProperty(value = "主键ID")
    private Long id;

    /**
     * 返修通知单号
     */
    @ExcelProperty(value = "返修通知单号")
    private String noticeNo;

    /**
     * 送修人ID(sys_user.user_id)
     */
    @ExcelProperty(value = "送修人ID(sys_user.user_id)")
    private Long applicantId;

    /**
     * 送修人姓名
     */
    @ExcelProperty(value = "送修人姓名")
    private String applicantName;

    /**
     * 发起机构ID
     */
    @ExcelProperty(value = "发起机构ID")
    private Long applicantDeptId;

    /**
     * 发起机构名称
     */
    @ExcelProperty(value = "发起机构名称")
    private String applicantDeptName;

    /**
     * 处理人/对接人ID(sys_user.user_id)
     */
    @ExcelProperty(value = "处理人/对接人ID(sys_user.user_id)")
    private Long handlerId;

    /**
     * 处理人/对接人姓名
     */
    @ExcelProperty(value = "处理人/对接人姓名")
    private String handlerName;

    /**
     * 处理机构ID
     */
    @ExcelProperty(value = "处理机构ID")
    private Long handlerDeptId;

    /**
     * 处理机构名称
     */
    @ExcelProperty(value = "处理机构名称")
    private String handlerDeptName;

    /**
     * 省编码
     */
    @ExcelProperty(value = "省编码")
    private String provinceCode;

    /**
     * 省名称
     */
    @ExcelProperty(value = "省名称")
    private String provinceName;

    /**
     * 市编码
     */
    @ExcelProperty(value = "市编码")
    private String cityCode;

    /**
     * 市名称
     */
    @ExcelProperty(value = "市名称")
    private String cityName;

    /**
     * 区县编码
     */
    @ExcelProperty(value = "区县编码")
    private String districtCode;

    /**
     * 区县名称
     */
    @ExcelProperty(value = "区县名称")
    private String districtName;

    /**
     * 设备来源
     */
    @ExcelProperty(value = "设备来源")
    private String deviceSource;

    /**
     * 项目包编码
     */
    @ExcelProperty(value = "项目包编码")
    private String projectPackageCode;

    /**
     * 物流单位
     */
    @ExcelProperty(value = "物流单位")
    private String logisticsCompany;

    /**
     * 物流单号
     */
    @ExcelProperty(value = "物流单号")
    private String logisticsNo;

    /**
     * 运费
     */
    @ExcelProperty(value = "运费")
    private BigDecimal freight;

    /**
     * 回寄地址
     */
    @ExcelProperty(v
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
