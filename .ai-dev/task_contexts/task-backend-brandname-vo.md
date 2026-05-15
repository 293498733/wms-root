## Task: 后端：ItemSkuQrPreVo 新增 brandName 字段

在 ItemSkuQrPreVo.java 中新增 private String brandName 字段，用于承载品牌名称返回给前端

### Implementation Context

在 ItemSkuQrPreVo.java 中新增字段：

```java
/**
 * 品牌名称（非持久化字段，由 Service 层手动填充）
 */
private String brandName;
```

技术要点：
- 该类使用 Lombok @Data，新增字段自动生成 getter/setter
- 该类使用 @AutoMapper(target = ItemSkuQrPre.class)，由于 ItemSkuQrPre 实体中没有 brandName 字段，
  MapStruct Plus 编译时会自动忽略此字段的映射（不会报错），运行时从实体→VO 转换时 brandName 始终为 null
- brandName 将通过 ItemSkuQrPreService.generate() 手动填充（在下个任务中实现）
- 不修改数据库表 wms_item_sku_qr_pre，不做冗余存储（工程方案决策）
- 确保 serialVersionUID 不变（不需要新增 serialVersionUID 变更）
- 保留所有已有字段不变


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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/vo/ItemSkuQrPreVo.java
```
package com.ruoyi.wms.domain.vo;

import com.alibaba.excel.annotation.ExcelIgnoreUnannotated;
import com.ruoyi.wms.domain.entity.ItemSkuQrPre;
import io.github.linpeilie.annotations.AutoMapper;
import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.Date;

@Data
@ExcelIgnoreUnannotated
@AutoMapper(target = ItemSkuQrPre.class)
public class ItemSkuQrPreVo implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    private Long id;

    private String batchNo;

    private String preCode;

    private Long itemId;

    private String itemCode;

    private String itemName;

    private Integer status;

    private Date expireTime;

    private Long usedSkuId;

    private Date usedTime;

    private String remark;

    private LocalDateTime createTime;
}

```
