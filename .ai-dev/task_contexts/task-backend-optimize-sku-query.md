## Task: 消除后端 buildCheckDetailItems 中重复的 SKU 数据库查询

RepairNoticeService.buildCheckDetailItems() 中重复调用 itemSkuService.queryItemSkuMapVosByIds()，应复用 RepairNoticeDetailVo 中已填充的 SKU/物品数据

### Implementation Context

消除重复 SKU 查询的性能优化。

当前问题（02-analysis.md 4.3 节指出）：
RepairNoticeDetailService.queryByNoticeId() 返回的 RepairNoticeDetailVo 已经通过 fillSkuAndItemInfo() 
填充了 itemSku 和 item 关联对象，但 buildCheckDetailItems() 方法中又重新调用
itemSkuService.queryItemSkuMapVosByIds(skuIds) 查询了一遍同样的数据，导致不必要的数据库查询。

修改方案：
1. 修改 RepairNoticeService.buildCheckDetailItems() 方法的签名或内部逻辑
2. 参数从 List<RepairNoticeDetailVo> details 传入，直接读取 detail.getItemSku() 和 detail.getItem() 
   来获取 skuName、barcode、itemName，而不是从 skuMap 中获取
3. 去掉 itemSkuService.queryItemSkuMapVosByIds(skuIds) 调用
4. 注意 RepairNoticeDetailVo 中的 itemSku 和 item 字段类型：确认字段名称为 itemSku 和 item（通过 getter/setter）
5. ItemSkuMapVo 包含 getItemSku() 返回 WmsItemSku 实体（含 skuName、barcode），getItem() 返回 WmsItem 实体（含 itemName、id）
   RepairNoticeDetailVo 中同样有 getItemSku() 返回 WmsItemSku，getItem() 返回 WmsItem
6. 确保不影响 confirmCheck() 方法中调用的 buildCheckDetailItems()，因为 confirmCheck 也调用了此方法

技术约束：
- 只修改 RepairNoticeService.java 中的 buildCheckDetailItems() 方法
- 不可修改其他 Service、Controller、Mapper、Entity 类
- 保持 confirmCheck() 中调用 buildCheckDetailItems() 的逻辑不变
- 保持 buildGroupedDetails() 方法不变
- 保持 public 方法签名不变


### Reference Documents

#### 03-plan.md
```
# 工程方案：返修通知单.核对明细页面UI优化

> 编制日期：2026-05-11
> 依据文档：`requirement.md`（精炼需求）、`02-analysis.md`（需求分析）
> 项目代码：`wms-ruoyi-master`（后端）、`ruo-yi-wms-vue-master`（前端）

---

## 版本记录

| 版本 | 日期 | 变更人 | 变更说明 |
|------|------|--------|---------|
| v1.0 | 2026-05-11 | AI Agent | 初始版本，基于代码审计确认现状 |

---

## 总体结论

**经完整代码审计确认：本需求的核心功能已在代码仓库中完整实现。** 需求文档是对现有实现的规范化精炼，并非新开发任务。工程方案以**"验证现有实现与需求的一致性"**为基调，列出已有功能的确认状态，并指出可选的优化方向。

---

## 1. 架构设计

### 1.1 涉及的模块

| 模块 | 层级 | 已有文件 | 状态 |
|------|------|---------|------|
| 前端-核对明细弹窗 | 视图层 | `ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/components/RepairNoticeCheckDialog.vue` | ✅ 已完整实现 |
| 前端-业务逻辑组合 | 逻辑层 | `ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/useRepairNotice.js` | ✅ 已完整实现 |
| 前端-页面入口 | 视图层 | `ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/index.vue` | ✅ 已实现 |
| 前端-API层 | 通信层 | `ruo-yi-wms-vue-master/src/api/wms/repairNotice.js` | ✅ 已实现 |
| 前端-仓库Store | 状态层 | `ruo-yi-wms-vue-master/src/store/modules/wms.js` | ✅ 已实现 |
| 后端-Controller | 控制层 | `wms-ruoyi-master/ruoyi-admin-wms/.../controller/RepairNoticeController.java` | ✅ 已完整实现 |
| 后端-Service | 业务层 | `wms-ruoyi-master/ruoyi-admin-wms/.../service/RepairNoticeService.java` | ✅ 已完整实现 |
| 后端-明细Service | 业务层 | `wms-ruoyi-master/ruoyi-admin-wms/.../service/RepairNoticeDetailService.java` | ✅ 已实现 |
| 后端-SKU查询Service | 业务层 | `wms-ruoyi-master/ruoyi-admin-wms/.../service/ItemSkuService.java` | ✅ 已实现 |
| 后端-入库单Service | 业务层 | `wms-ruoyi-master/ruoyi-admin-wms/.../service/ReceiptOrderService.java` | ✅ 已实现 |
| 后端-VO/BO | 模型层 | `RepairNoticeCheckDetailVo.java` / `RepairNoticeConfirmBo.java` / `RepairNoticeRejectBo.java` | ✅ 已完整实现 |
| 后端-Entity/Mapper | 持久层 | `RepairNotice.java` / `RepairNoticeDetail.java` / `RepairNoticeMapper.java` / `RepairNoticeDetailMapper.java` | ✅ 已实现 |

### 1.2 模块间调用关系

```
┌─────────────────────────────────────────────────────────────────────┐
│                       前端 (ruo-yi-wms-vue-master)                   │
│                                   
```

#### 02-analysis.md
```
# 需求分析报告：返修通知单核对明细页面UI调整

> 分析日期：2026-05-09
> 分析人：Goose AI Agent
> 前置文档：[requirement.md](../requirement.md) | [profile.yml](../profile.yml)
> 代码仓库：`D:\MyPrj\进销存`

---

## 1. 功能拆分

### P0（核心功能，本次必须实现）

| # | 功能名称 | 涉及模块 | 关联数据表 | 优先级 |
|---|---------|---------|-----------|-------|
| 1 | **核对明细按规格型号汇总展示** | `ruo-yi-wms-vue-master` 前端 | —（纯UI展示层变更） | P0 |
| | | views: `RepairNoticeCheckDialog.vue` | | |
| | | 后端返回VO: `RepairNoticeCheckDetailVo.java` | | |
| 2 | **汇总行数量匹配逻辑** | 前端 `RepairNoticeCheckDialog.vue` | —（前端计算逻辑） | P0 |
| | 按规格型号（skuName）分组统计预期数量与实际数量，对比匹配 | | | |
| 3 | **条码明细下拉展开** | 前端 `RepairNoticeCheckDialog.vue` | —（纯UI交互变更） | P0 |
| | 点击展开/收起该规格型号下的所有条码明细 | | | |

### P1（重要，建议本次实现）

| # | 功能名称 | 涉及模块 | 关联数据表 | 优先级 |
|---|---------|---------|-----------|-------|
| 4 | **核对明细分页支持** | 前端 `RepairNoticeCheckDialog.vue` | —（UI分页组件） | P1 |
| | 当条码明细行数较多时（>200条），启用分页展示 | | | |
| 5 | **数据接口适配** | `RepairNoticeService.java` | —（后端VO调整） | P1 |
| | `startProcess` 接口返回的 `CheckDetailItem` 需要携带 `itemId` 用于前端分组 | | | |
| | VO: `RepairNoticeCheckDetailVo.java` | | | |

### P2（后续迭代）

| # | 功能名称 | 涉及模块 | 关联数据表 | 优先级 |
|---|---------|---------|-----------|-------|
| 6 | **批量实际数量修改** | 前端 `RepairNoticeCheckDialog.vue` | — | P2 |
| | 在汇总行上直接修改实际数量，同步更新至明细行 | | | |
| 7 | **分组统计角标/徽标** | 前端 `RepairNoticeCheckDialog.vue` | — | P2 |
| | 在规格型号行展示该分组下的明细条数 | | | |

---

## 2. 数据流

### 2.1 数据来源

```
用户操作：返修通知单列表 → 点击 "开始处理" 按钮
     ↓
前端调用 POST /wms/RepairNotice/startProcess/{id}
     ↓
后端 RepairsNoticeService.startProcess() 处理
     ↓
    ├── 校验：状态必须为 "已提交"(status=2)
    ├── 校验：当前用户机构必须等于 handlerDeptId
    ├── 查询 RepairNoticeDetail（notice_id → sku_id 列表）
    ├── 批量查询 ItemSkuMapVo（sku_id → skuName, barcode, itemId）
    └── 返回 RepairNoticeCheckDetailVo
```

### 2.2 数据流转（当前逻辑）

```
数据库表：
  repair_notice (主表) 
    ├── id, notice_no, status, handler_dept_id, ...
    └── repair_notice_detail (明细)
          └── id, notice_id (FK→repair_notice.id), sku_id (FK→wms_item_sku.id)

数据库表：
  wms_ite
```

### Relevant Input Files

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/service/RepairNoticeService.java
```
package com.ruoyi.wms.service;

import cn.hutool.core.collection.CollUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.ruoyi.common.core.exception.ServiceException;
import com.ruoyi.common.core.utils.MapstructUtils;
import com.ruoyi.common.core.utils.StringUtils;
import com.ruoyi.common.mybatis.core.page.PageQuery;
import com.ruoyi.common.mybatis.core.page.TableDataInfo;
import com.ruoyi.common.redis.utils.RedisUtils;
import com.ruoyi.common.redis.utils.RepairNoticeNoUtils;
import com.ruoyi.common.satoken.utils.LoginHelper;
import com.ruoyi.wms.domain.bo.RepairNoticeBo;
import com.ruoyi.wms.domain.bo.RepairNoticeConfirmBo;
import com.ruoyi.wms.domain.bo.RepairNoticeDetailBo;
import com.ruoyi.wms.domain.bo.RepairNoticeMobileSubmitBo;
import com.ruoyi.wms.domain.bo.RepairNoticeRejectBo;
import com.ruoyi.wms.domain.bo.ReceiptOrderBo;
import com.ruoyi.wms.domain.bo.ReceiptOrderDetailBo;
import com.ruoyi.wms.domain.entity.RepairNotice;
import com.ruoyi.wms.domain.vo.ItemSkuMapVo;
import com.ruoyi.wms.domain.vo.RepairNoticeCheckDetailVo;
import com.ruoyi.wms.domain.vo.RepairNoticeCheckDetailVo.CheckDetailItem;
import com.ruoyi.wms.domain.vo.RepairNoticeCheckDetailVo.GroupedCheckDetail;
import com.ruoyi.wms.domain.vo.RepairNoticeDetailVo;
import com.ruoyi.wms.domain.vo.RepairNoticeVo;
import com.ruoyi.wms.domain.vo.ReturnableSkuVo;
import com.ruoyi.wms.mapper.RepairNoticeMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

@RequiredArgsConstructor
@Service
public class RepairNoticeService {

    private final RepairNoticeMapper repairNoticeMapper;
    private final RepairNoticeDetailService repairNoticeDetailService;
    private final ItemSkuService itemSkuService;
    private final ReceiptOrderService receiptOrderService;
    private final com.ruoyi.wms.mapper.ReceiptOrderMapper receiptOrderMapper;
    private final com.ruoyi.wms.mapper.ReceiptOrderDetailMapper receiptOrderDetailMapper;
    private final com.ruoyi.wms.mapper.ReturnNoticeMapper returnNoticeMapper;
    private final com.ruoyi.wms.mapper.ReturnNoticeDetailMapper returnNoticeDetailMapper;

    public RepairNoticeVo queryById(Long id) {
        RepairNoticeVo vo = repairNoticeMapper.selectVoById(id);
        
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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/vo/ItemSkuMapVo.java
```
package com.ruoyi.wms.domain.vo;

import lombok.Data;

import java.io.Serial;
import java.io.Serializable;

@Data
public class ItemSkuMapVo implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    private Long skuId;
    private ItemVo item;
    private ItemSkuVo itemSku;
}

```
