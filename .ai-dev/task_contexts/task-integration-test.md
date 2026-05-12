## Task: 全流程集成测试（手动测试用例执行）

启动前后端服务，执行工程方案中定义的全部 6 个测试场景的手动测试

### Implementation Context

启动前后端服务，执行全流程集成测试。

【启动步骤】
1. 启动后端：
   ```
   cd /d D:\MyPrj\进销存
   mvn spring-boot:run -f wms-ruoyi-master/ruoyi-admin-wms/pom.xml -Dmaven.test.skip=true
   ```
   或者使用已配置的脚本启动。

2. 启动前端：
   ```
   cd /d D:\MyPrj\进销存\ruo-yi-wms-vue-master
   npm run dev
   ```

【测试场景（共 6 个）】

**场景 1：基本分组展示**
1. 登录系统，进入「返修通知单」列表页
2. 筛选状态为「已提交」且处理机构为当前机构的数据
3. 点击某条通知单的「开始处理」按钮
4. ✅ 确认核对明细弹窗打开
5. ✅ 验证分组汇总表格：物品按规格型号分组显示，每行显示物品名称/规格型号/预期数量/实际数量/匹配状态
6. ✅ 验证预期数量 = 该规格型号下的明细条数
7. ✅ 验证匹配状态图标颜色（一致=绿色/不一致=红色）
8. ✅ 验证不一致行高亮（红色背景）

**场景 2：展开子表查看条码**
1. 在核对明细弹窗中，点击分组行首的展开箭头（▶）
2. ✅ 验证展开子表：显示该分组下所有明细，包含：序号/条码/预期数量/实际数量(可编辑)/匹配状态

**场景 3：修改实际数量**
1. 展开任意分组
2. 修改某条明细的「实际数量」输入框
3. ✅ 验证：该明细行「匹配」状态实时更新
4. ✅ 验证：父级分组的「实际数量」汇总和「匹配」状态也实时更新
5. ✅ 验证：不一致的行高亮

**场景 4：子表分页（如数据量足够）**
1. 找到一个有 200 条以上明细的分组并展开
2. ✅ 验证：子表底部显示分页组件
3. 点击翻页按钮
4. ✅ 验证：切换页码后数据正确切换

**场景 5：核对通过（入库）**
1. 选择一个入库仓库
2. 点击「核对无误-入库」按钮
3. ✅ 如所有分组均匹配→直接提交，弹窗关闭
4. ✅ 如有分组不匹配→弹框"存在数量不一致的物品，确认仍要入库吗？"
5. 点击「确认入库」
6. ✅ 验证：弹窗关闭，列表页刷新，该通知单状态变更为「处理中」
7. ✅ 验证：入库单已创建（可通过入库单列表查看）
8. ✅ 验证：库存数量已增加
9. ✅ 验证：入库单明细中每条的实际数量与前端提交的一致（非硬编码 1）

**场景 6：核对退回**
1. 在核对明细弹窗中，点击「核对有误-退回」
2. 在弹出框中输入退回原因（必填）
3. ✅ 点击「确认退回」
4. ✅ 验证：弹窗关闭，列表页刷新，该通知单状态变更为「待提交」

【测试记录格式】
对于每个场景，记录：
- 测试时间
- 测试结果（通过/失败/阻塞）
- 如果失败，记录错误详情和截图参考
- 如果阻塞，记录阻塞原因

【注意点】
1. 测试前确保数据库中有测试数据（至少有一条状态=2 且包含多个 SKU 的返修通知单）
2. 测试时需要创建一个有多个 SKU（>200 条明细）的通知单来验证分页
3. 测试环境建议使用开发数据库，不要使用生产数据


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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/resources/application.yml
```
# 项目相关配置
ruoyi:
  # 名称
  name: ruoyi-wms-service
  # 版本
  version: ${revision}
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
    com.ruoyi: @logging.level@
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
    active: @profiles.active@
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
  # 启动时是否检查 MyBatis XML 文件的存在，
```
