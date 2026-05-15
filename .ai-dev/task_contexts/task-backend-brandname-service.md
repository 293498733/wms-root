## Task: 后端：ItemSkuQrPreService.generate() 增加品牌查询逻辑

在 generate() 方法中新增 ItemBrandMapper 注入，批量查询品牌名称并填充到 VO 的 brandName 字段

### Implementation Context

修改 ItemSkuQrPreService.java，核心变更如下：

1. 新增 ItemBrandMapper 注入（使用 @RequiredArgsConstructor 的 final 字段方式）：
   ```java
   private final ItemBrandMapper itemBrandMapper;
   ```

2. generate() 方法中，在 `itemMapper.selectBatchIds(itemIds)` 之后新增品牌批量查询逻辑：

   ```java
   // 在 List<Item> items = itemMapper.selectBatchIds(itemIds); 之后
   // 在 Map<Long, Item> itemMap = ... 之后

   // ★ 新增：批量查询品牌名称
   Set<Long> brandIds = items.stream()
       .map(Item::getItemBrand)
       .filter(Objects::nonNull)
       .collect(Collectors.toSet());
   Map<Long, String> brandMap = new HashMap<>();
   if (CollUtil.isNotEmpty(brandIds)) {
       List<ItemBrand> brands = itemBrandMapper.selectBatchIds(brandIds);
       brandMap = brands.stream()
           .collect(Collectors.toMap(ItemBrand::getId, ItemBrand::getBrandName, (a, b) -> a));
   }
   ```

3. 在 `saveBatch(records);` 之后，`MapstructUtils.convert(records, ItemSkuQrPreVo.class)` 之后，
   遍历 voList 设置 brandName：
   ```java
   List<ItemSkuQrPreVo> voList = MapstructUtils.convert(records, ItemSkuQrPreVo.class);
   for (ItemSkuQrPreVo vo : voList) {
       Item item = itemMap.get(vo.getItemId());
       if (item != null && item.getItemBrand() != null) {
           vo.setBrandName(brandMap.getOrDefault(item.getItemBrand(), ""));
       } else {
           vo.setBrandName("");
       }
   }
   result.setRecords(voList);
   ```

4. 新增 import：
   - import com.ruoyi.wms.domain.entity.ItemBrand;
   - import com.ruoyi.wms.mapper.ItemBrandMapper;
   - import java.util.Set;
   - import java.util.HashMap;
   - import java.util.HashSet;（如果使用 HashSet 则需）

关键约束：
- Item 表通过 itemBrand（Long）字段关联 ItemBrand 表
- ItemBrand 已存在 ItemBrandMapper，继承自 BaseMapperPlus<ItemBrand, ItemBrandVo>，有 selectBatchIds 方法
- item.getBrandId() 可能为 null，需要 filter(Objects::nonNull) 排除
- brandName 为空字符串而非 null，避免前端显示 "null"
- 不使用数据库冗余存储，brandName 仅在 VO 层面动态填充
- 向前兼容：旧前端不读取 brandName 字段不影响业务
- 必须保留 generate() 方法的所有现有业务逻辑和校验规则


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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/service/ItemSkuQrPreService.java
```
## File: ItemSkuQrPreService.java (245 lines, 10KB)

**Package**: package com.ruoyi.wms.service;
**Imports**: 34 packages

### Classes/Interfaces (1)
- `public class ItemSkuQrPreService extends ServiceImpl<ItemSkuQrPreMapper, ItemSkuQrPre> {`

### Constants/Fields
public static final int STATUS_UNUSED = 0;
public static final int STATUS_USED = 1;
public static final int STATUS_CANCELLED = 2;
public static final int STATUS_EXPIRED = 3;
private static final int MAX_BATCH_TOTAL = 1000;
private static final int DEFAULT_VALID_DAYS = 90;

### Methods (22)
- `public TableDataInfo<ItemSkuQrPreVo> queryPageList(ItemSkuQrPreBo bo, PageQuery pageQuery) {`
- `public List<ItemSkuQrPreVo> queryList(ItemSkuQrPreBo bo) {`
- `public ItemSkuQrPreVo queryByPreCode(String preCode) {`
- `public ItemSkuQrPreGenerateVo generate(ItemSkuQrPreGenerateBo bo) {`
- `throw new ServiceException("请选择需要生成二维码的规格型号");`
- `throw new ServiceException("生成数量必须大于0");`
- `throw new ServiceException("单次最多生成" + MAX_BATCH_TOTAL + "个二维码");`
- `throw new ServiceException("存在无效的规格型号，请刷新后重试");`
- `public int cancelBatch(String batchNo) {`
- `throw new ServiceException("批次号不能为空");`
- `public int markExpired() {`
- `public int cleanHistory(Integer retentionDays) {`
- `throw new ServiceException("历史保留天数不能小于30天");`
- `public void consumeIfAvailable(String preCode, Long itemId, Long skuId) {`
- `throw new ServiceException("二维码预生成码不存在", HttpStatus.CONFLICT);`
- `throw new ServiceException("二维码已使用、已作废或已过期", HttpStatus.CONFLICT);`
- `throw new ServiceException("二维码已过期", HttpStatus.CONFLICT);`
- `throw new ServiceException("扫码规格型号与二维码预生成规格型号不一致", HttpStatus.CONFLICT);`
- `throw new ServiceException("二维码状态已变化，请刷新后重试", HttpStatus.CONFLICT);`
- `private LambdaQueryWrapper<ItemSkuQrPre> buildQueryWrapper(ItemSkuQrPreBo bo) {`
- `private ItemSkuQrPre findByPreCode(String preCode) {`
- `private void refreshExpiredStatus(ItemSkuQrPre record) {`
```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/mapper/ItemBrandMapper.java
```
package com.ruoyi.wms.mapper;

import com.ruoyi.wms.domain.entity.ItemBrand;
import com.ruoyi.wms.domain.vo.ItemBrandVo;
import com.ruoyi.common.mybatis.core.mapper.BaseMapperPlus;

/**
 * 商品品牌Mapper接口
 *
 * @author zcc
 * @date 2024-07-30
 */
public interface ItemBrandMapper extends BaseMapperPlus<ItemBrand, ItemBrandVo> {

}

```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/entity/Item.java
```
package com.ruoyi.wms.domain.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.ruoyi.common.mybatis.core.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.io.Serial;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("wms_item")
public class Item extends BaseEntity {

    @Serial
    private static final long serialVersionUID = 1L;

    /**
     *
     */
    @TableId(value = "id")
    private Long id;

    /**
     * 编号
     */
    private String itemCode;

    /**
     * 名称
     */
    private String itemName;

    /**
     * 分类
     */
    private String itemCategory;

    /**
     * 单位类别
     */
    private String unit;

    /**
     * 品牌
     */
    private Long itemBrand;

    /**
     * 备注
     */
    private String remark;


}

```

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/entity/ItemBrand.java
```
package com.ruoyi.wms.domain.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.ruoyi.common.mybatis.core.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;


import java.io.Serial;

/**
 * 商品品牌对象 wms_item_brand
 *
 * @author zcc
 * @date 2024-07-30
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("wms_item_brand")
public class ItemBrand extends BaseEntity {

    @Serial
    private static final long serialVersionUID=1L;

    /**
     *
     */
    @TableId(value = "id")
    private Long id;
    /**
     * 品牌名称
     */
    private String brandName;

}

```

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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/domain/vo/ItemSkuQrPreGenerateVo.java
```
package com.ruoyi.wms.domain.vo;

import lombok.Data;

import java.io.Serial;
import java.io.Serializable;
import java.util.List;

@Data
public class ItemSkuQrPreGenerateVo implements Serializable {

    @Serial
    private static final long serialVersionUID = 1L;

    private String batchNo;

    private Integer total;

    private Integer validDays;

    private List<ItemSkuQrPreVo> records;
}

```
