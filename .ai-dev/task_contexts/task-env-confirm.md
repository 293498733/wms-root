## Task: 项目技术栈与环境确认

确认后端和前端的技术栈版本、依赖是否完整，确保构建和运行环境就绪

### Implementation Context

确认技术栈就绪，不修改任何源代码。只需读取配置文件并输出检查清单。

技术栈：
- 后端：Spring Boot 3.2.6 + JDK 17 + MyBatis-Plus 3.5.6 + MapStruct Plus 1.3.6 + Lombok 1.18.32 + Hutool 5.8.27 + Sa-Token 1.37.0
- 前端：Vue 3.2.45 + Element Plus 2.2.27 + Vite + Pinia
- 数据库：MySQL（通过 MyBatis-Plus 操作）
- 缓存：Redis（用于入库单号自增 + @RepeatSubmit 防重）

检查要点：
1. pom.xml 中所有依赖是否可解析（确认版本号已定）
2. package.json 中 npm 依赖是否完整（element-plus, vue-router, pinia, axios 等）
3. 确认 JDK 17、Node.js 版本要求
4. 确认 application.yml 中数据库、Redis 配置项
5. 确保 MapStruct Plus 注解处理器已配置（annotationProcessorPaths）
6. 输出 checklist-env.md 作为后续任务的环境参考


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

#### ruo-yi-wms-vue-master/package.json
```
{
  "name": "ruoyi-wms",
  "version": "4.8.2",
  "description": "ruoyi-wms后台管理系统",
  "author": "ZCC",
  "license": "MIT",
  "scripts": {
    "dev": "vite",
    "build:prod": "vite build",
    "preview": "vite preview"
  },
  "repository": {
    "type": "git",
    "url": "https://gitee.com/zccbbg/ruoyi-wms-vue.git"
  },
  "dependencies": {
    "@element-plus/icons-vue": "2.0.10",
    "@vueup/vue-quill": "1.2.0",
    "@vueuse/core": "9.5.0",
    "@zxing/browser": "^0.1.5",
    "axios": "0.27.2",
    "echarts": "5.4.0",
    "element-plus": "2.2.27",
    "file-saver": "2.0.5",
    "fuse.js": "6.6.2",
    "js-cookie": "3.0.1",
    "jsbarcode": "^3.11.6",
    "jsencrypt": "3.3.1",
    "moment": "^2.30.1",
    "nprogress": "0.2.0",
    "pinia": "2.0.22",
    "qrcode": "^1.5.3",
    "vue": "3.2.45",
    "vue-cropper": "1.0.3",
    "vue-plugin-hiprint": "^0.0.56",
    "vue-router": "4.1.4",
    "vue3-seamless-scroll": "^2.0.1",
    "webrtc-adapter": "^9.0.4"
  },
  "devDependencies": {
    "@vitejs/plugin-basic-ssl": "^1.2.0",
    "@vitejs/plugin-vue": "3.1.0",
    "@vue/compiler-sfc": "3.2.45",
    "sass": "1.56.1",
    "unplugin-auto-import": "0.11.4",
    "unplugin-vue-setup-extend-plus": "0.4.9",
    "vite": "3.2.3",
    "vite-plugin-compression": "0.5.1",
    "vite-plugin-svg-icons": "2.0.1"
  }
}

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

#### wms-ruoyi-master/正式环境代码/application.yml
```
# 项目相关配置
ruoyi:
  # 名称
  name: ruoyi-wms-service
  # 版本
  version: 5.2.0
  # 版权年份
  copyrightYear: 2024
  # 缓存懒加载
  cacheLazy: false

captcha:
  enable: true
  # 页面 <参数设置> 可开启关闭 验证码校验
  # 验证码类型 math 数组计算 char 字符验证
  type: MATH
  # line 线段干扰 circle 圆圈干扰 shear 扭曲干扰
  category: CIRCLE
  # 数字验证码位数
  numberLength: 1
  # 字符验证码长度
  charLength: 4

# 开发环境配置
server:
  # 服务器的HTTP端口，默认为8080
  port: 8080
  servlet:
    # 应用的访问路径
    context-path: /
  # undertow 配置
  undertow:
    # HTTP post内容的最大大小。当值为-1时，默认值为大小是无限的
    max-http-post-size: -1
    # 以下的配置会影响buffer,这些buffer会用于服务器连接的IO操作,有点类似netty的池化内存管理
    # 每块buffer的空间大小,越小的空间被利用越充分
    buffer-size: 512
    # 是否分配的直接内存
    direct-buffers: true
    threads:
      # 设置IO线程数, 它主要执行非阻塞的任务,它们会负责多个连接, 默认设置每个CPU核心一个线程
      io: 8
      # 阻塞任务线程池, 当执行类似servlet请求阻塞操作, undertow会从这个线程池中取得线程,它的值设置取决于系统的负载
      worker: 256

# 日志配置
logging:
  level:
    com.ruoyi: info
    org.springframework: warn
  config: classpath:logback-plus.xml

# 用户配置
user:
  password:
    # 密码最大错误次数
    maxRetryCount: 5
    # 密码锁定时间（默认10分钟）
    lockTime: 10

# Spring配置
spring:
  application:
    name: ${ruoyi.name}
  # 资源信息
  messages:
    # 国际化资源文件路径
    basename: i18n/messages
  profiles:
    active: dev
  # 文件上传
  servlet:
    multipart:
      # 单个文件大小
      max-file-size: 10MB
      # 设置总上传的文件大小
      max-request-size: 20MB
  # 服务模块
  devtools:
    restart:
      # 热部署开关
      enabled: true
  mvc:
    format:
      date-time: yyyy-MM-dd HH:mm:ss
  jackson:
    # 日期格式化
    date-format: yyyy-MM-dd HH:mm:ss
    serialization:
      # 格式化输出
      indent_output: false
      # 忽略无法转换的对象
      fail_on_empty_beans: false
    deserialization:
      # 允许对象忽略json中不存在的属性
      fail_on_unknown_properties: false

# Sa-Token配置
sa-token:
  # token名称 (同时也是cookie名称)
  token-name: Authorization
  # token有效期 设为一天 (必定过期) 单位: 秒
  timeout: 86400
  # 多端不同 token 有效期 可查看 LoginHelper.loginByDevice 方法自定义
  # token最低活跃时间 (指定时间无操作就过期) 单位: 秒
  active-timeout: 86400
  # 允许动态设置 token 有效期
  dynamic-active-timeout: true
  # 是否允许同一账号并发登录 (为true时允许一起登录, 为false时新登录挤掉旧登录)
  is-concurrent: true
  # 在多人登录同一账号时，是否共用一个token (为true时所有登录共用一个token, 为false时每次登录新建一个token)
  is-share: false
  # 是否尝试从header里读取token
  is-read-header: true
  # 是否尝试从cookie里读取token
  is-read-cookie: false
  # token前缀
  token-prefix: "Bearer"
  # jwt秘钥
  jwt-secret-key: abcdefghijklmnopqrstuvwxyz

# security配置
security:
  # 排除路径
  excludes:
    # 静态资源
    - /*.html
    - /**/*.html
    - /**/*.css
    - /**/*.js
    # 公共路径
    - /favicon.ico
    - /error
    # swagger 文档配置
    - /*/api-docs
    - /*/api-docs/**
    # actuator 监控配置
    - /actuator
    - /actuator/**

# MyBatisPlus配置
# https://baomidou.com/config/
mybatis-plus:
  # 不支持多包, 如有需要可在注解配置 或 提升扫包等级
  # 例如 com.**.**.mapper
  mapperPackage: com.ruoyi.**.mapper
  # 对应的 XML 文件位置
  mapperLocations: classpath*:mapper/**/*Mapper.xml
  # 实体扫描，多个package用逗号或者分号分隔
  typeAliasesPackage: com.ruoyi.**.domain
  # 启动时是否检查 MyBatis XML 文件的存在，默认不检查
  checkConfigLocation: fa
```
