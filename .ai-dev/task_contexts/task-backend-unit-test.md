## Task: 补充 RepairNoticeService 单元测试

为后端新增/修改的方法补充单元测试，包括优化后的 buildCheckDetailItems、最大明细数限制、状态校验等场景

### Implementation Context

补充单元测试。

现有测试已有 7 个测试用例（RepairNoticeServiceTest.java），覆盖了 buildGroupedDetails 的分组正确性、
匹配逻辑、空列表、null skuName、混合匹配、itemName 取值。

需要新增的测试用例（基于本次变更）：

1. testBuildCheckDetailItems_usesRepairNoticeDetailVoData()
   - 验证优化后的 buildCheckDetailItems 正确从 RepairNoticeDetailVo 的 itemSku/item 字段读取数据
   - 不再依赖 ItemSkuMapVo，需要用 Mock 或模拟数据验证

2. testStartProcess_withInvalidStatus_shouldThrow()
   - 验证状态非 "2" 时抛出 ServiceException("只有已提交状态的单据才能开始处理")
   - 需要 Mock RepairNoticeMapper.selectById() 返回 status="0" 或 "1"
   - 验证异常消息

3. testConfirmCheck_withAllMatchedStatus_shouldSuccess()
   - 验证全部匹配时 confirmCheck 成功返回入库单 ID
   - 需要 Mock 多个依赖服务

4. testConfirmCheck_withMismatchStatus_shouldThrow()
   - 验证不匹配时抛出 ServiceException
   - 需要 Mock 明细数据并模拟实际数量不一致

5. testBuildCheckDetail_exceedsLimit_shouldThrow()
   - 验证明细超过 5000 条时抛出 ServiceException
   - 需要 Mock repairNoticeDetailService.queryByNoticeId() 返回大列表

因为 RepairNoticeService 使用了 @RequiredArgsConstructor 构造器注入，
测试中可以通过 new RepairNoticeService(mapper, detailService, skuService, receiptService, ...) 
注入 Mock 对象。

测试框架：JUnit 5 (org.junit.jupiter) + 无 Mockito 依赖？请检查 pom.xml 中是否有 spring-boot-starter-test。
如果无 Mockito，用纯数据构造测试（不 Mock）——现有测试就是这么做的。

技术约束：
- 使用 JUnit 5 + 纯数据构造方式（不引入 Mockito）
- 对于需要 Mock Mapper 的测试，可以构造 RepariNoticeService 并直接传 null（如现有测试），
  然后测试逻辑方法（buildGroupedDetails, buildCheckDetailItems）而非集成流程方法
- 新增方法如 buildCheckDetailItems 也需要反射调用（私有方法）
- 标注 @Tag("dev") 和 @DisplayName


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

### Relevant Input Files

#### wms-ruoyi-master/ruoyi-admin-wms/src/test/java/com/ruoyi/wms/service/RepairNoticeServiceTest.java
```
package com.ruoyi.wms.service;

import com.ruoyi.wms.domain.vo.RepairNoticeCheckDetailVo.CheckDetailItem;
import com.ruoyi.wms.domain.vo.RepairNoticeCheckDetailVo.GroupedCheckDetail;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 返修通知单服务 - 分组构建与匹配逻辑单元测试
 * <p>
 * 测试 {@link RepairNoticeService} 中的分组构建和匹配校验方法。
 * 由于 buildGroupedDetails 为私有方法，通过反射调用。
 */
@Tag("dev")
@DisplayName("RepairNoticeService - 分组构建与匹配测试")
class RepairNoticeServiceTest {

    /**
     * 通过反射调用 RepairNoticeService.buildGroupedDetails 私有方法
     */
    @SuppressWarnings("unchecked")
    private List<GroupedCheckDetail> invokeBuildGroupedDetails(List<CheckDetailItem> items) throws Exception {
        RepairNoticeService service = new RepairNoticeService(null, null, null, null, null, null, null, null);
        Method method = RepairNoticeService.class.getDeclaredMethod("buildGroupedDetails", List.class);
        method.setAccessible(true);
        return (List<GroupedCheckDetail>) method.invoke(service, items);
    }

    // ==================== 分组正确性测试 ====================

    @Test
    @DisplayName("按规格型号分组 - 5条明细分为3+2两个分组")
    void testBuildGroupedDetails_withMultipleSkuNames_shouldGroupCorrectly() throws Exception {
        List<CheckDetailItem> items = new ArrayList<>();

        // 3条规格A
        items.add(createItem(1L, "规格A", "物品1", "BC001"));
        items.add(createItem(2L, "规格A", "物品2", "BC002"));
        items.add(createItem(3L, "规格A", "物品3", "BC003"));
        // 2条规格B
        items.add(createItem(4L, "规格B", "物品4", "BC004"));
        items.add(createItem(5L, "规格B", "物品5", "BC005"));

        List<GroupedCheckDetail> result = invokeBuildGroupedDetails(items);

        assertEquals(2, result.size(), "应返回2个分组");

        GroupedCheckDetail groupA = result.stream()
            .filter(g -> "规格A".equals(g.getSkuName()))
            .findFirst().orElse(null);
        GroupedCheckDetail groupB = result.stream()
            .filter(g -> "规格B".equals(g.getSkuName()))
            .findFirst().orElse(null);

        assertNotNull(groupA, "规格A分组应存在");
        assertNotNull(groupB, "规格B分组应存在");

        assertEquals(3L, groupA.getTotalExpectedQuantity(), "规格A预期数量应为3");
        assertEquals(3L, groupA.getTotalActualQuantity(), "规格A实际数量应为3（默认=预期）");
        assertTrue(groupA.getMatched(), "规格A应匹配");

        assertEquals(2L, groupB.getTotalExpectedQuantity(), "规格B预期数量应为2");
        assertEquals(2L, groupB.getTotalActualQuantity(), "规格B实际数量应为2（默认=预期）");
        assertTrue(groupB.getMatched(), "规格B应匹配");

        assertEquals(3, groupA.getItems().size(), "规格A应有3条明细");
        assertEquals(2, groupB.getItems().size(), "规格B应有2条明细");
    }

    // ==================== 匹配逻辑测试 ====================

    @Test
    @DisplayName("分组匹配
```

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
