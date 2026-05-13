# 端到端验证报告：子表分页与分组独立页码

> 验证日期：2026-05-13
> 验证目标：单组明细超过200条时子表自动分页（每页50条）、不同分组独立页码互不影响
> 验证方式：代码审计 + 逻辑推演

---

## 1. 代码审计结论

### 1.1 分页逻辑实现状态

| 功能点 | 状态 | 位置 | 说明 |
|--------|------|------|------|
| 分页阈值 `pageItemThreshold = 200` | ✅ 已实现 | `RepairNoticeCheckDialog.vue` props (L228-231) | 通过 props 注入，默认值200 |
| 每页条数 `pageItemSize = 50` | ✅ 已实现 | `RepairNoticeCheckDialog.vue` props (L232-235) | 通过 props 注入，默认值50 |
| 独立页码映射 `subPageMap: Map<rowKey, currentPage>` | ✅ 已实现 | `RepairNoticeCheckDialog.vue` L256 | 使用 `rowKey` 作为 key（唯一标识每个分组行） |
| `rowItemPage(row)` 子表分页切片 | ✅ 已实现 | `RepairNoticeCheckDialog.vue` L412-420 | 按当前页码做 `items.slice(start, start + pageItemSize)` |
| `getCurrentPage(row)` / `handleSubPageChange(row, page)` | ✅ 已实现 | L402-404 / L407-409 | 从 subPageMap 读写分组独立页码 |
| 弹窗打开时重置所有页码 | ✅ 已实现 | `initData()` L309 / `resetState()` L320 | `subPageMap.value = new Map()` |
| 分页组件仅在超过阈值时显示 | ✅ 已实现 | 模板 L113 | `v-if="row.items && row.items.length > pageItemThreshold"` |
| 汇总表格分组分页 `groupPage` | ✅ 已实现 | L253, L370-376, L388-389 | 独立于子表分页的汇总表格分页 |

### 1.2 架构验证

**子表分页数据流：**
```
用户点击展开分组(row)
  → handleExpandChange(row, expandedRows)
    → subPageMap.set(row.rowKey, 1)  // 首次展开初始化为第1页
  → 模板渲染 rowItemPage(row)
    → getCurrentPage(row) → subPageMap.get(row.rowKey) || 1
    → items.slice((page-1)*50, page*50)

用户点击子表分页器
  → handleSubPageChange(row, page)
    → subPageMap.set(row.rowKey, page)  // 存储该分组独立页码
  → 响应式更新 rowItemPage(row) 计算
    → 按新页码切片
```

**页码重置时机：**
| 场景 | 行为 |
|------|------|
| 弹窗打开 (visible=true) | `initData()` 执行 `subPageMap.value = new Map()` |
| 弹窗关闭 (visible=false) | `resetState()` 执行 `subPageMap.value = new Map()` |
| 切换分组展开 | 各分组使用自己的 `rowKey` 独立存储页码，互不影响 |

---

## 2. 核心逻辑详解

### 2.1 分页阈值与显示条件

**显示条件**（模板 L113）：
```html
<el-pagination
  v-if="row.items && row.items.length > pageItemThreshold"
  ...
/>
```

- `row.items` 不存在或为空数组 → 不显示
- `row.items.length` ≤ 200 → 不显示（无需分页）
- `row.items.length` > 200 → 显示分页组件

**汇总表格的分页阈值**（模板 L169）：
```html
<el-pagination v-if="groupedDetails.length > pageItemThreshold" ... />
```
汇总表格（分组列表）同样遵循 200 条阈值，超过时启用分页。

### 2.2 子表分页切片 `rowItemPage(row)`

```javascript
function rowItemPage(row) {
  const items = row.items || [];
  if (items.length <= props.pageItemThreshold) {
    return items;                  // ≤ 200 条，返回全部
  }
  const page = getCurrentPage(row); // 取该分组的独立页码
  const start = (page - 1) * props.pageItemSize;
  return items.slice(start, start + props.pageItemSize); // 每页50条
}
```

### 2.3 独立页码存储

```javascript
const subPageMap = ref(new Map());  // Map<rowKey, currentPage>

function getCurrentPage(row) {
  return subPageMap.value.get(row.rowKey) || 1;
}

function handleSubPageChange(row, page) {
  subPageMap.value.set(row.rowKey, page);
}
```

**使用 `rowKey` 而非 `skuName` 的原因：**
- `rowKey` 由 `generateRowKey()` 生成，格式为 `group_{random}_{timestamp}`，保证每个分组行实例唯一
- 防止同一 `skuName` 在不同时间段加载时 key 冲突
- 与 el-table 的 `row-key="rowKey"` 保持一致

### 2.4 弹窗重置

**初始化时重置**（`initData()` 方法）：
```javascript
function initData() {
  // ... 初始化 groupedDetails ...
  groupPage.value = 1;
  subPageMap.value = new Map();  // 全部重置为第1页
  warehouseId.value = null;
  confirmLoading.value = false;
  rejectLoading.value = false;
}
```

**关闭时重置**（`resetState()` 方法）：
```javascript
function resetState() {
  warehouseId.value = null;
  confirmLoading.value = false;
  rejectLoading.value = false;
  groupPage.value = 1;
  subPageMap.value = new Map();  // 全部重置为第1页
}
```

触发链路：
- `watch(() => props.visible, ...)` → visible=true → `initData()`
- `watch(localVisible, ...)` → localVisible=false → `resetState()`

---

## 3. 手动测试脚本

### 3.1 测试数据准备

需准备一条返修通知单，包含以下分组明细（通过后端 `RepairNoticeCheckDetailVo` 返回）：

| 规格型号 (skuName) | 分组物品名称 (itemName) | 明细条数 | pages | 预期行为 |
|-------------------|------------------------|---------|-------|---------|
| 规格A | 物品A | 220条 | 5页（50×4 + 20） | 触发分页（>200） |
| 规格B | 物品B | 5条 | 1页（全部显示） | 不触发分页（≤200） |

> **数据构造建议**：在开发/测试数据库的 `repair_notice_detail` 表中为目标通知单插入 220 条 skuName="规格A" 的明细和 5 条 skuName="规格B" 的明细，确保每个条码 (barcode) 唯一。

### 3.2 测试步骤与预期

| 步骤 | 操作 | 预期结果 | 验收项 |
|------|------|---------|-------|
| **1** | 打开核对明细弹窗，点击"规格A"分组行首展开 | 子表显示 1-50 条；下方显示 `<el-pagination small>`，总数 220，当前第 1 页 | 验收标准5 |
| **2** | 点击分页第 2 页 | 子表显示 51-100 条；当前页变为第 2 页 | 验收标准5 |
| **3** | 点击分页第 5 页 | 子表显示 201-220 条（最后 20 条）；当前页变为第 5 页 | 验收标准5 |
| **4** | 收起"规格A"，展开"规格B" | 显示全部 5 条明细；**无分页组件**（5 < 200） | 验收标准6 |
| **5** | 重新展开"规格A" | 页码**保持在第 5 页**（201-220 条），未被"规格B"的切换影响 | 验收标准6 |
| **6** | 关闭弹窗，重新打开 | 展开"规格A"：页码重置为第 1 页（1-50 条） | 验收标准5 |
| **7** | 展开"规格B" | 显示全部 5 条明细，无分页组件 | 验收标准5,6 |

### 3.3 边界测试

| 边界 | 测试方法 | 预期 |
|------|---------|------|
| 恰好 200 条 | 规格A 只有 200 条明细 | 不显示分页组件（阈值严格 >200，≥200 都直接返回全部） |
| 恰好 201 条 | 规格A 有 201 条明细 | 显示分页组件，共 5 页（50×4 + 1） |
| 恰好 250 条 | 规格A 有 250 条明细 | 显示分页组件，共 5 页（50×5），第5页满页 |
| 50 条 | 规格A 有 50 条明细 | 不显示分页组件（≤200） |
| 0 条 | 分组无明细 | `row.items || []` 为空数组，`rowItemPage` 返回空；无分页组件 |
| 多次快速切换 | 规格A 展开→翻页→规格B 展开→规格A 展开 | 页码保持，不丢失 |
| 连续翻页到头/尾 | 第1页点「上一页」、最后1页点「下一页」 | el-pagination 默认处理，不会越界 |

### 3.4 验收标准对应

| 验收标准 | 描述 | 验证方式 |
|---------|------|---------|
| **5. 单组 >200 条时子表显示分页，每页50条** | 规格A (220条) 触发分页，规格B (5条) 不触发 | 步骤 1-3, 6-7；边界测试 |
| **6. 不同分组独立分页，切换互不影响** | 规格A 保持第5页，规格B 不干扰 | 步骤 4-5 |

---

## 4. 代码覆盖清单

| 文件 | 行数 | 关键函数/变量 | 说明 |
|------|------|-------------|------|
| `ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/components/RepairNoticeCheckDialog.vue` | 624 | `subPageMap`、`rowItemPage()`、`getCurrentPage()`、`handleSubPageChange()`、`handleExpandChange()`、`groupPage`、`displayGroups`、`handleGroupPageChange()` | 核对明细弹窗组件，含完整的分页逻辑 |

### 4.1 关键函数明细

| 函数/变量 | 类型 | 行号 | 职责 |
|----------|------|------|------|
| `pageItemThreshold` | prop | L228-231 | 分页阈值（默认200） |
| `pageItemSize` | prop | L232-235 | 每页条数（默认50） |
| `groupPage` | ref | L253 | 汇总表格当前页码 |
| `subPageMap` | ref | L256 | 子表分页映射 `<rowKey, currentPage>` |
| `initData()` | function | L280-313 | 初始化数据，重置所有页码 |
| `resetState()` | function | L315-322 | 关闭弹窗时重置状态 |
| `displayGroups` | computed | L370-377 | 汇总表格分页计算 |
| `getGroupIndex()` | function | L380-385 | 分组序号（考虑分页偏移） |
| `handleGroupPageChange()` | function | L388-389 | 汇总表格翻页 |
| `handleExpandChange()` | function | L393-398 | 展开时初始化子表页码 |
| `getCurrentPage()` | function | L402-404 | 获取子表当前页码 |
| `handleSubPageChange()` | function | L407-409 | 子表翻页 |
| `rowItemPage()` | function | L412-420 | 子表分页切片 |

---

## 5. 逻辑正确性证明

### 5.1 分页条件正确性

```
条件: row.items && row.items.length > pageItemThreshold

case 1: row.items = undefined → false ✓（不显示）
case 2: row.items = [] → false ✓（不显示）
case 3: row.items.length = 5 → false ✓（不显示）
case 4: row.items.length = 200 → false ✓（不显示，严格大于）
case 5: row.items.length = 201 → true ✓（显示）
case 6: row.items.length = 220 → true ✓（显示）
```

### 5.2 独立页码正确性

```
条件: subPageMap 使用 rowKey 作为 key

- 规格A 展开 → rowKey="group_a1_xxx"
  → subPageMap.set("group_a1_xxx", 5)  // 翻到第5页
- 规格B 展开 → rowKey="group_b1_yyy"
  → subPageMap.set("group_b1_yyy", 1)  // 首次展开初始化为1
- 规格A 重新展开 → rowKey="group_a1_xxx" 保持不变
  → getCurrentPage → subPageMap.get("group_a1_xxx") → 5 ✓（保持不变）
```

**注意**：如果 el-table 的展开/收起导致 row 实例重建，`rowKey` 会变化（因为 `generateRowKey()` 每次生成新值）。  
但在 Vue 的 el-table 实现中，展开行使用 `row-key` 指定的字段进行行标识，同一数据行的 `rowKey` 在展开/收起过程中保持引用不变（因为 `groupedDetails` 中的对象引用未变）。因此页码确实能保持。

### 5.3 重置正确性

```
弹窗关闭 → localVisible=false → resetState()
  → subPageMap.value = new Map()  // 清空所有分组页码
弹窗打开 → visible=true → initData()
  → groupedDetails.value = raw.map(...)  // 重新生成 rowKey
  → subPageMap.value = new Map()  // 所有页码重置为第1页
```

---

## 6. 结论

- ✅ **分页逻辑已完整实现**：阈值 200 条、每页 50 条、独立页码映射 (`Map<rowKey, currentPage>`)
- ✅ **分页组件的显示条件正确**：`v-if="row.items && row.items.length > pageItemThreshold"`
  - ≤200 条不显示分页组件
  - >200 条显示分页组件
- ✅ **不同分组独立页码互不影响**：通过 `subPageMap` 以 `rowKey` 为键，每个分组独立维护
- ✅ **弹窗关闭重置**：`resetState()` 在 `watch(localVisible, ...)` 中执行，`initData()` 在 `watch(visible, ...)` 中执行
- ✅ **汇总表格分组分页**：`displayGroups` + `groupPage` 独立于子表分页
- ✅ **验收标准 5**（单组 >200 条时子表显示分页，每页50条）：**可通过**
- ✅ **验收标准 6**（不同分组独立分页，切换互不影响）：**可通过**

---

## Key Decisions

1. **subPageMap 使用 rowKey 作为 key 而非 skuName**：`rowKey` 由 `generateRowKey()` 生成（格式 `group_{random}_{timestamp}`），保证每个分组行实例唯一，避免同一 `skuName` 在不同加载场景下 key 冲突，同时与 el-table 的 `row-key="rowKey"` 保持一致。

2. **分页阈值 pageItemThreshold = 200 硬编码为 props 默认值**：通过 props 注入（`default: 200`）而非直接硬编码，便于单元测试时覆盖，但实际运行时使用默认 200 条阈值，不配置化。

3. **汇总表格与子表分页独立**：汇总表格使用 `groupPage` 单个 ref，子表使用 `subPageMap` 以 `rowKey` 为键的 Map，两者互不干扰。汇总表格同样遵循 >200 条阈值。

4. **展开时初始化子表页码**：`handleExpandChange` 在展开时检查 `subPageMap` 是否已有该 `rowKey` 的页码，没有则初始化为第 1 页，避免未翻页时 `getCurrentPage` 返回 `undefined`。

5. **与现有代码的集成约定**：
   - 分页逻辑完全封装在 `RepairNoticeCheckDialog.vue` 组件内部
   - 父组件无需关心子表分页，通过 `groupedDetails` prop 传递原始数据即可
   - 数据初始化/重置在 `initData()`/$`resetState()` 中统一管理

6. **约束条件**：
   - 分页组件使用 Element Plus 的 `<el-pagination small>`，仅支持 `prev, pager, next` 布局
   - 子表分页与 el-table 的展开行绑定，如果 el-table 的 `row-key` 行为发生变化（如行实例重建），需要重新验证页码保持逻辑
   - 分页阈值和每页条数通过 props 配置，如需全局修改可调整默认值
