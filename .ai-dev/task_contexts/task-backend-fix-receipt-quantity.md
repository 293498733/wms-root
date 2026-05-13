## Task: 修复入库单数量校验逻辑（硬编码1->大于0）

修改ReceiptOrderService中validateRepairReceiptDetails的数量校验从必须等于1改为必须大于0

### Implementation Context

修改validateRepairReceiptDetails方法中的数量校验。
改前：compareTo(BigDecimal.ONE) != 0 -> "返修入库物品数量必须为1"
改后：compareTo(java.math.BigDecimal.ZERO) <= 0 -> "返修入库物品数量必须大于0"
只改这一处，不修改其他任何逻辑。


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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/service/ReceiptOrderService.java
```
## File: ReceiptOrderService.java (328 lines, 13KB)

**Package**: package com.ruoyi.wms.service;
**Imports**: 32 packages

### Classes/Interfaces (1)
- `public class ReceiptOrderService {`

### Constants/Fields
private static final Long REPAIR_RECEIPT_OPT_TYPE = 1L;

### Methods (29)
- `public ReceiptOrderVo queryById(Long id){`
- `public Long queryIdByOrderNo(String orderNo){`
- `public TableDataInfo<ReceiptOrderVo> queryPageList(ReceiptOrderBo bo, PageQuery pageQuery) {`
- `public List<ReceiptOrderVo> queryList(ReceiptOrderBo bo) {`
- `private LambdaQueryWrapper<ReceiptOrder> buildQueryWrapper(ReceiptOrderBo bo) {`
- `public Long insertByBo(ReceiptOrderBo bo) {`
- `public void receive(ReceiptOrderBo bo) {`
- `private void validateBeforeReceive(ReceiptOrderBo bo) {`
- `throw new BaseException("商品明细不能为空");`
- `public void updateByBo(ReceiptOrderBo bo) {`
- `public void editToInvalid(Long id) {`
- `public void deleteById(Long id) {`
- `private void validateIdBeforeDelete(Long id) {`
- `throw new ServiceException("删除失败", HttpStatus.CONFLICT,"入库单【" + receiptOrderVo.getOrderNo() + "】已入库，无法删除！");`
- `public void deleteByIds(Collection<Long> ids) {`
- `public void validateReceiptOrderNo(String receiptOrderNo) {`
- `private boolean isRepairReceipt(ReceiptOrderBo bo) {`
- `private void validateDuplicateSkuInDetails(List<ReceiptOrderDetailBo> details) {`
- `throw new ServiceException("商品明细必须包含skuId");`
- `throw new ServiceException("同一单据不允许重复选择同一物品");`
- `private void validateRepairReceiptDetails(ReceiptOrderBo bo) {`
- `throw new ServiceException("返修入库必须选择返修通知单");`
- `throw new ServiceException("返修通知单不存在");`
- `throw new ServiceException("仅已提交或处理中状态的返修通知单可用于返修入库");`
- `throw new ServiceException("该返修通知单不属于当前机构，无法用于返修入库");`
- `throw new ServiceException("返修通知单未关联可入库物品");`
- `throw new ServiceException("入库物品不属于所选返修通知单");`
- `throw new ServiceException("返修入库物品数量必须大于0");`
- `private void autoFinishRepairNoticeIfComplete(ReceiptOrderBo bo) {`
```
