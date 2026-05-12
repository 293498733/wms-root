## Task: 开发物流单号生成工具类

在 common-redis 模块创建 RepairLogisticsOrderNoUtils，使用 Redis 原子递增生成前缀为 WLD 的物流单号

### Implementation Context

完全参照 ReturnNoticeNoUtils 实现。

规则：WLD + yyyyMMddHHmmss + 4位流水号
示例：WLD202605121430150001

关键实现：
- 前缀 PREFIX = "WLD"
- 时间格式：yyyyMMddHHmmss
- 日期格式：yyyyMMdd（用于 Redis key）
- Redis key: "repair_logistics:no:" + dayStr
- 使用 RedisUtils.incrAtomicValue(redisKey) 获取原子自增值
- 第一次生成（seq==1）时设置过期时间 Duration.ofDays(2)
- 流水号超过 9999 时抛 IllegalStateException
- 工具类构造方法私有化

包路径：com.ruoyi.common.redis.utils
注意：此文件在 ruoyi-common/ruoyi-common-redis 模块下，需要在 pom.xml 确认该模块已引入 RedisUtils


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

#### wms-ruoyi-master/ruoyi-common/ruoyi-common-redis/src/main/java/com/ruoyi/common/redis/utils/ReturnNoticeNoUtils.java
```
package com.ruoyi.common.redis.utils;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 返回通知单号生成工具类
 *
 * 规则：
 * FHTZD + yyyyMMddHHmmss + 4位流水号
 *
 * 示例：
 * FHTZD202605111430150001
 */
public class ReturnNoticeNoUtils {

    /**
     * 单号前缀：返修回通知单（区别于 FXTZD 返修通知单）
     */
    private static final String PREFIX = "FHTZD";

    /**
     * 时间格式
     */
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    /**
     * 日期格式
     */
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyyMMdd");

    private ReturnNoticeNoUtils() {
    }

    /**
     * 生成返回通知单号
     *
     * 使用 Redis 原子递增，保证多实例下唯一
     */
    public static String generateNoticeNo() {
        LocalDateTime now = LocalDateTime.now();
        String timeStr = now.format(TIME_FORMATTER);
        String dayStr = now.format(DATE_FORMATTER);

        // 每天一个自增 key
        String redisKey = "return_notice:no:" + dayStr;

        long seq = RedisUtils.incrAtomicValue(redisKey);

        // 第一次生成时顺便设置过期时间，避免 redis key 永久堆积
        if (seq == 1) {
            RedisUtils.expire(redisKey, Duration.ofDays(2));
        }

        if (seq > 9999) {
            throw new IllegalStateException("当天返回通知单号生成次数过多，请稍后重试");
        }

        return PREFIX + timeStr + String.format("%04d", seq);
    }
}

```
