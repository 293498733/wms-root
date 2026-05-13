## Task: 新建核对明细弹窗 RepairNoticeCheckDialog.vue

创建核对明细弹窗组件实现分组汇总表格展开子表数量编辑匹配状态分页仓库选择退回/入库按钮

### Implementation Context

新建RepairNoticeCheckDialog.vue（文件不存在）。Vue3+ElementPlus+Composition API+Script Setup。
Props: checkDetail(Object) visible(Boolean) pageItemThreshold(Number default=200) pageItemSize(Number default=50)
Emits: confirm({warehouseId,details}) reject(rejectReason) update:visible

UI结构从上到下：
1. el-dialog 标题"核对明细" width="1000px"
2. 通知单信息头：noticeNo + 状态标签
3. el-alert type="warning" show-icon :closable="false"："请核对实物数量，点击行首展开查看条码明细"
4. 仓库 el-select 必填：从 wmsStore.warehouseList 加载(v-model="warehouseId" rule必填)
5. 汇总表格 el-table type="expand"：
   列：序号(#) | 物品名称 | 规格型号 | 预期数量 | 实际数量(只读展示汇总值) | 匹配 | 操作
   展开子表：序号(#) | 条码 | 预期数量 | 实际数量(el-input-number min=0 :controls=false) | 匹配(el-tag)
   修改数量实时更新matched状态和分组汇总值
   分页el-pagination small当items.length>threshold(200)，每分组独立维护currentPageMap
6. 空状态：groupedDetails为空时显示el-empty description="该通知单无可核对的物品明细"
7. 底部按钮(左右居右)：取消 | 核对有误-退回 | 核对无误-入库
   - 取消：emit("update:visible", false)
   - 退回：ElMessageBox.prompt("退回原因", "请填写核对退回原因", {inputType:"textarea", inputValidator:v=>!!v, inputErrorMessage:"退回原因不能为空"})
   - 入库：先校验仓库 -> 检查匹配状态(有不匹配时二次确认) -> emit confirm

按钮互斥：confirmLoading/rejectLoading两个ref，请求中互斥disabled

注意：Element Plus组件已全局注册无需额外import；仓库从useWmsStore()获取；DictTag已全局注册


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

#### ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/useRepairNotice.js
```
## File: useRepairNotice.js (512 lines, 14KB)

**Imports**: 3 modules
**Exports**: 1 items

### Functions (32)
- `function normalizeFaultyDetail(detail = {}, index = 0) {`
- `function normalizeFaultyDetails(formData = {}) {`
- `function buildSubmitPayload(formData = {}) {`
- `function normalizePageParams(pageInfo = {}) {`
- `function getList() {`
- `function resetFormData() {`
- `function cancel() {`
- `function handleQuery(nextQuery = {}) {`
- `function handlePageChange(pageInfo = {}) {`
- `function resetQuery() {`
- `function handleAdd() {`
- `function handleUpdate(row) {`
- `function handleView(row) {`
- `function handleDelete(row) {`
- `function handleExport() {`
- `function isDraftStatus(status) {`
- `function isSubmittedStatus(status) {`
- `function isProcessingStatus(status) {`
- `function isFinishedStatus(status) {`
- `function isApplicant(row) {`
- `function isHandlerDeptUser(row) {`
- `function canEdit(row) {`
- `function canDelete(row) {`
- `function canSubmit(row) {`
- `function canStartProcess(row) {`
- `function validateForDraft(formRef, callback) {`
- `function validateForSubmit(formRef, callback) {`
- `function saveDraft({ formRef, formData }) {`
- `function submitProcess({ formRef, formData }) {`
- `function handleStartProcess(row) {`
```

#### ruo-yi-wms-vue-master/src/api/wms/repairNotice.js
```
import request from "@/utils/request";

// 查询列表
export function listNotice(query) {
  return request({
    url: "/wms/RepairNotice/list",
    method: "get",
    params: query
  });
}

// 入库单选择返修通知单（仅当前机构且已提交）
export function listReceiptSelectableNotice(query) {
  return request({
    url: "/wms/RepairNotice/receiptSelectList",
    method: "get",
    params: query
  });
}

// 查询详情
export function getNotice(id) {
  return request({
    url: `/wms/RepairNotice/${id}`,
    method: "get"
  });
}

// 新增
export function addNotice(data) {
  return request({
    url: "/wms/RepairNotice",
    method: "post",
    data
  });
}

// 修改
export function updateNotice(data) {
  return request({
    url: "/wms/RepairNotice",
    method: "put",
    data
  });
}

// 删除
export function delNotice(id) {
  return request({
    url: `/wms/RepairNotice/${id}`,
    method: "delete"
  });
}

// 暂存
export function saveDraftNotice(data) {
  return request({
    url: "/wms/RepairNotice/draft",
    method: "post",
    data
  });
}

// 提交处理
export function submitRepairNotice(data) {
  return request({
    url: "/wms/RepairNotice/submit",
    method: "post",
    data
  });
}

// 移动端轻量提交
export function submitRepairNoticeMobile(data) {
  return request({
    url: "/wms/RepairNotice/mobileSubmit",
    method: "post",
    data
  });
}

// 开始处理
export function startProcessNotice(id) {
  return request({
    url: `/wms/RepairNotice/startProcess/${id}`,
    method: "post"
  });
}

// 核对通过-自动创建入库单草稿
export function confirmCheck(noticeId, data) {
  return request({
    url: `/wms/RepairNotice/confirmCheck/${noticeId}`,
    method: "post",
    data
  });
}

// 核对退回
export function rejectCheck(noticeId, data) {
  return request({
    url: `/wms/RepairNotice/rejectCheck/${noticeId}`,
    method: "post",
    data
  });
}

```

#### ruo-yi-wms-vue-master/src/store/modules/wms.js
```
import { listWarehouseNoPage } from '@/api/wms/warehouse';
import { listMerchantNoPage } from "@/api/wms/merchant";
import { listItemCategory, treeSelectItemCategory } from "@/api/wms/itemCategory";
import { listItemBrand } from "@/api/wms/itemBrand";
import {defineStore} from "pinia";
import {ref} from "vue";

export const useWmsStore = defineStore('wms', () => {

  // 仓库管理
  const warehouseList = ref([]);
  const warehouseMap = ref(new Map());

  const getWarehouseList = () => {
    listWarehouseNoPage({}).then((res) => {
      warehouseList.value = res.data;
      const map = new Map();
      warehouseList.value.forEach((supplier) => {
        map.set(supplier.id, supplier);
      });
      warehouseMap.value = map;
    });
  };

  // 企业管理
  const merchantList = ref([]);
  const merchantMap = ref(new Map());

  const getMerchantList = () => {
    listMerchantNoPage({}).then((res) => {
      merchantList.value = res.data;
      const map = new Map();
      merchantList.value.forEach((supplier) => {
        map.set(supplier.id, supplier);
      });
      merchantMap.value = map;
    });
  }

  // 物品分类管理
  const itemCategoryList = ref([])
  const itemCategoryTreeList = ref([])
  const itemCategoryMap = ref(new Map())

  const getItemCategoryList = () => {
    return new Promise((resolve, reject) => {
      listItemCategory({}).then(res => {
        itemCategoryList.value = res.data;
        const map = new Map()
        itemCategoryList.value.forEach(supplier => {
          map.set(supplier.id, supplier)
        })
        itemCategoryMap.value = map
        resolve()
      }).catch(() => reject())
    })
  }

  const getItemCategoryTreeList = async () => {
    return new Promise((resolve, reject) => {
      treeSelectItemCategory().then(res => {
        itemCategoryTreeList.value = res.data
        resolve(res.data)
      }).catch(() => reject())
    })
  }

  // 物品品牌管理
  const itemBrandList = ref([])
  const itemBrandMap = ref(new Map())

  const getItemBrandList =  () => {
    return new Promise((resolve, reject) => {
      listItemBrand({}).then(res => {
        itemBrandList.value = res.data
        const map = new Map()
        itemBrandList.value.forEach(supplier => {
          map.set(supplier.id, {...supplier})
        })
        itemBrandMap.value = map
        resolve()
      }).catch(() => reject())
    })
  }

  return {
    // 仓库管理
    warehouseList,
    warehouseMap,
    getWarehouseList,
    // 企业管理
    merchantList,
    merchantMap,
    getMerchantList,
    // 物品分类管理
    itemCategoryList,
    itemCategoryTreeList,
    itemCategoryMap,
    getItemCategoryList,
    getItemCategoryTreeList,
    // 物品品牌管理
    itemBrandList,
    itemBrandMap,
    getItemBrandList
  };
});

```
