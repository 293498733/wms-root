## Task: 后端编译与单元测试验证

运行 Maven 编译和后端单元测试，验证所有后端修改的代码正确性

### Implementation Context

运行 Maven 编译和后端单元测试。

【步骤】
1. 进入项目根目录 D:\MyPrj\进销存
2. 运行 Maven 编译（跳过测试，检查代码编译是否通过）：
   ```
   cd /d D:\MyPrj\进销存
   mvn -DskipTests compile -f wms-ruoyi-master/pom.xml
   ```
3. 如果编译失败，根据错误信息修复
4. 编译通过后，运行单元测试：
   ```
   mvn test -f wms-ruoyi-master/pom.xml
   ```
5. 记录测试结果

【预期结果】
- BUILD SUCCESS（编译通过）
- 单元测试全部通过或跳过（UI 相关模块的测试可能不存在）

【错误处理】
如果编译失败：
1. 检查 Java 版本（需要 JDK 17+）
2. 检查 Maven 设置（settings.xml 中的镜像配置）
3. 查看具体错误信息并修复

【注意点】
如果 Maven 构建太慢或缺少依赖，可以只编译 ruoyi-admin-wms 模块：
```
mvn -DskipTests compile -f wms-ruoyi-master/ruoyi-admin-wms/pom.xml
```


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
