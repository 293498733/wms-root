## Task: 后端分组构建逻辑单元测试验证

运行并验证 RepairNoticeServiceTest 中 10 个单元测试全部通过， 确认后端 buildGroupedDetails/buildCheckDetailItems 逻辑的稳定性和正确性。


### Implementation Context

【目标】
运行 RepairNoticeServiceTest 的单元测试，验证所有测试用例通过。

【测试类路径】
wms-ruoyi-master/ruoyi-admin-wms/src/test/java/com/ruoyi/wms/service/RepairNoticeServiceTest.java

【测试用例清单】（共11个）
1. testBuildGroupedDetails_withMultipleSkuNames_shouldGroupCorrectly
   - 5条明细（3条规格A+2条规格B），验证分2组、预期数量、匹配状态
2. testBuildGroupedDetails_whenActualEqualsExpected_shouldBeMatched
   - 实际=预期时 matched=true
3. testBuildGroupedDetails_whenActualNotEqualsExpected_shouldNotBeMatched
   - 实际≠预期时 matched=false（1+0=1≠2）
4. testBuildGroupedDetails_withEmptyList_shouldReturnEmptyList
   - 空列表返回空集合
5. testBuildGroupedDetails_withNullSkuName_shouldGroupToUnknown
   - null skuName 归入"未知规格"
6. testBuildGroupedDetails_mixedMatchStatus_shouldBeIndependent
   - 多分组独立匹配（一组匹配、一组不匹配）
7. testBuildGroupedDetails_itemName_shouldPickFirstNonNull
   - 分组 itemName 取第一个非空
8. testBuildCheckDetailItems_usesRepairNoticeDetailVoData
   - 从 itemSku/item 字段读取数据正确
9. testBuildCheckDetailItems_withNullItemSku_shouldHandleGracefully
   - itemSku=null 时容错
10. testBuildCheckDetailItems_withNullItem_shouldHandleGracefully
    - item=null 时容错
11. testBuildCheckDetailItems_withNullItemSkuAndNullItem_shouldHandleGracefully
    - 两者都为 null 时容错

【运行命令】
cd D:\MyPrj\进销存\wms-ruoyi-master
mvn test -pl ruoyi-admin-wms -Dtest=RepairNoticeServiceTest -Dgroups=dev

【注意事项】
- 测试使用反射调用私有方法，需确保 JDK 17+ 的模块访问限制不影响反射
- 测试不依赖数据库（纯业务逻辑测试，通过 new RepairNoticeService(null,...) 构造）
- 测试 tagged with @Tag("dev")，需用 -Dgroups=dev 指定
- 如果测试失败，需记录具体失败原因和堆栈，但不修改测试代码（本次不涉及后端逻辑变更）

【输出】
- 在控制台输出测试结果
- 如果全部通过：输出 "所有 11 个测试用例全部通过"
- 如果有失败：输出失败列表和原因分析

【约束】
- 不改动任何后端源代码（RepairNoticeService.java / VO / BO / Controller 等）
- 不改动测试代码本身
- 如遇编译错误，仅检查 pom.xml 依赖是否正确


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

import com.ruoyi.common.core.exception.ServiceException;
import com.ruoyi.wms.domain.vo.ItemSkuVo;
import com.ruoyi.wms.domain.vo.ItemVo;
import com.ruoyi.wms.domain.vo.RepairNoticeCheckDetailVo.CheckDetailItem;
import com.ruoyi.wms.domain.vo.RepairNoticeCheckDetailVo.GroupedCheckDetail;
import com.ruoyi.wms.domain.vo.RepairNoticeDetailVo;
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
 * 由于 buildGroupedDetails 和 buildCheckDetailItems 均为私有方法，通过反射调用。
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

    /**
     * 通过反射调用 RepairNoticeService.buildCheckDetailItems 私有方法
     */
    @SuppressWarnings("unchecked")
    private List<CheckDetailItem> invokeBuildCheckDetailItems(List<RepairNoticeDetailVo> details) throws Exception {
        RepairNoticeService service = new RepairNoticeService(null, null, null, null, null, null, null, null);
        Method method = RepairNoticeService.class.getDeclaredMethod("buildCheckDetailItems", List.class);
        method.setAccessible(true);
        return (List<CheckDetailItem>) method.invoke(service, details);
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
            .filter(g -> "规格B".equals(g.get
```

#### wms-ruoyi-master/pom.xml
```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.ruoyi</groupId>
    <artifactId>ruoyi-wms</artifactId>
    <version>${revision}</version>

    <name>ruoyi-wms</name>
    <url>https://gitee.com/zccbbg/wms-ruoyi</url>
    <description>ruoyi-wms后台管理系统</description>

    <properties>
        <revision>5.2.0</revision>
        <spring-boot.version>3.2.6</spring-boot.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
        <java.version>17</java.version>
        <mybatis.version>3.5.16</mybatis.version>
        <mybatis-plus.version>3.5.6</mybatis-plus.version>
        <springdoc.version>2.5.0</springdoc.version>
        <therapi-javadoc.version>0.15.0</therapi-javadoc.version>
        <poi.version>5.2.3</poi.version>
        <easyexcel.version>3.3.4</easyexcel.version>
        <velocity.version>2.3</velocity.version>
        <satoken.version>1.37.0</satoken.version>
        <p6spy.version>3.9.1</p6spy.version>
        <hutool.version>5.8.27</hutool.version>
        <okhttp.version>4.10.0</okhttp.version>
        <spring-boot-admin.version>3.2.3</spring-boot-admin.version>
        <redisson.version>3.29.0</redisson.version>
        <lock4j.version>2.2.7</lock4j.version>
        <dynamic-ds.version>4.3.0</dynamic-ds.version>
        <alibaba-ttl.version>2.14.2</alibaba-ttl.version>
        <mapstruct-plus.version>1.3.6</mapstruct-plus.version>
        <mapstruct-plus.lombok.version>0.2.0</mapstruct-plus.lombok.version>
        <lombok.version>1.18.32</lombok.version>
        <lombok.version>1.18.30</lombok.version>
        <bouncycastle.version>1.72</bouncycastle.version>
        <!-- 离线IP地址定位库 -->
        <ip2region.version>2.7.0</ip2region.version>

        <!-- OSS 配置 -->
        <aws-java-sdk-s3.version>1.12.540</aws-java-sdk-s3.version>
        <!-- SMS 配置 -->
        <sms4j.version>2.2.0</sms4j.version>

        <!-- 插件版本 -->
        <maven-jar-plugin.version>3.2.2</maven-jar-plugin.version>
        <maven-war-plugin.version>3.2.2</maven-war-plugin.version>
        <maven-compiler-plugin.verison>3.11.0</maven-compiler-plugin.verison>
        <maven-surefire-plugin.version>3.1.2</maven-surefire-plugin.version>
        <flatten-maven-plugin.version>1.3.0</flatten-maven-plugin.version>
    </properties>

    <profiles>
        <profile>
            <id>local</id>
            <properties>
                <!-- 环境标识，需要与配置文件的名称相对应 -->
                <profiles.active>local</profiles.active>
                <logging.level>info</logging.level>
            </properties>
        </profile>
        <profile>
            <id>dev</id>
            <properties>
                <!--
```
