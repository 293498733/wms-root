## Task: 集成编译与回归验证

执行 Maven 编译验证后端无报错，检查前端页面渲染无误，确认三个功能的修改不产生竞合冲突

### Implementation Context

集成验证分3步执行：

第1步：后端编译验证
```bash
cd /d D:\MyPrj\进销存\wms-ruoyi-master
mvn -DskipTests compile -pl ruoyi-admin-wms -am
```
验证点：
- 编译无错误
- ItemSkuQrPreService 中 ItemBrandMapper 注入无循环依赖
- MapStruct Plus 自动映射编译通过（brandName 在 VO 有、Entity 没有，自动忽略）
- import 无遗漏

第2步：前端代码审查
验证 ReturnNoticeDialog.vue、ItemQrGenerateDialog.vue 三处修改文件：
- 语法无误（template 中 el-table-column 标签闭合）
- scoped style 不影响全局
- 无重复的 el-table-column 定义
- renderQrSheet 和 exportHtml 修改无语法错误

第3步：功能竞合检查
- ItemQrGenerateDialog.vue 同时包含功能二和功能三的修改，确认两处修改不冲突
- ReturnNoticeDialog.vue 的弹窗宽度 → 栅格布局 → 表格列宽修改在同一文件，确认递进关系正确
- 后端只修改了 ItemSkuQrPreVo.java 和 ItemSkuQrPreService.java，无冲突

如果编译失败，根据错误信息回滚并修复。


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

#### wms-ruoyi-master/pom.xml
```
## File: pom.xml (467 lines, 17KB)

**Elements**: activation, activeByDefault, alibaba, annotationProcessorPaths, arg, argLine, artifactId, aws, bouncycastle, build, compilerArgs, configuration, dependencies, dependency, dependencyManagement, description, directory, dynamic, easyexcel, enabled, encoding, excludedGroups, exclusion, exclusions, execution, executions, filtering, flatten, flattenMode, goal
```

#### wms-ruoyi-master/ruoyi-admin-wms/pom.xml
```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <artifactId>ruoyi-wms</artifactId>
        <groupId>com.ruoyi</groupId>
        <version>${revision}</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>
    <packaging>jar</packaging>
    <artifactId>ruoyi-admin-wms</artifactId>

    <description>
        web服务入口
    </description>

    <dependencies>

        <!-- spring-boot-devtools -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-devtools</artifactId>
            <optional>true</optional> <!-- 表示依赖不会传递 -->
        </dependency>

        <!-- Mysql驱动包 -->
        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-j</artifactId>
        </dependency>

        <dependency>
            <groupId>com.ruoyi</groupId>
            <artifactId>ruoyi-system</artifactId>
        </dependency>

        <dependency>
            <groupId>com.ruoyi</groupId>
            <artifactId>ruoyi-common-oss</artifactId>
        </dependency>

        <dependency>
            <groupId>com.ruoyi</groupId>
            <artifactId>ruoyi-common-mail</artifactId>
        </dependency>

        <dependency>
            <groupId>com.ruoyi</groupId>
            <artifactId>ruoyi-common-ratelimiter</artifactId>
        </dependency>

        <!-- 代码生成-->
        <dependency>
            <groupId>com.ruoyi</groupId>
            <artifactId>ruoyi-generator</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>

        <!-- skywalking 整合 logback -->
<!--        <dependency>-->
<!--            <groupId>org.apache.skywalking</groupId>-->
<!--            <artifactId>apm-toolkit-logback-1.x</artifactId>-->
<!--            <version>${与你的agent探针版本保持一致}</version>-->
<!--        </dependency>-->
<!--        <dependency>-->
<!--            <groupId>org.apache.skywalking</groupId>-->
<!--            <artifactId>apm-toolkit-trace</artifactId>-->
<!--            <version>${与你的agent探针版本保持一致}</version>-->
<!--        </dependency>-->

    </dependencies>

    <build>
        <finalName>${project.artifactId}</finalName>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <version>${spring-boot.version}</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>repackage</goal>
                        </goals>
                    </execution>
                </executions>
 
```
