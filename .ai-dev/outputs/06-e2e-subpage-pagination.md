# 端到端验证报告：子表分页与分组独立页码

> 验证日期：2026-05-12
> 验证目标：单组明细超过200条时子表自动分页（每页50条）、不同分组独立页码互不影响

---

## 1. 代码审计结论

### 1.1 分页逻辑实现状态

| 功能点 | 状态 | 文件位置 | 行号 |
|--------|------|---------|------|
| 分页阈值 `pageItemThreshold = 200` | ✅ 已实现 | `RepairNoticeCheckDialog.vue` | L159 |
| 每页条数 `pageItemSize = 50` | ✅ 已实现 | `RepairNoticeCheckDialog.vue` | L161 |
| 独立页码映射 `pageMap: Map<skuName, currentPage>` | ✅ 已实现 | `RepairNoticeCheckDialog.vue` | L163 |
| `paginatedItems(group)` 分页切片 | ✅ 已实现 | `RepairNoticeCheckDialog.vue` | L183-191 |
| `getPageNum(skuName)` / `setPageNum(skuName, page)` | ✅ 已实现 | `RepairNoticeCheckDialog.vue` | L175-181 |
| 弹窗打开时重置所有页码 (`watch open → new Map()`) | ✅ 已实现 | `RepairNoticeCheckDialog.vue` | L195-199 |
| 分页组件仅在超过阈值时显示 | ✅ 已修复 | `RepairNoticeCheckDialog.vue` | L71 |

### 1.2 修复项

**问题**：分页组件 `<el-pagination>` 的显示条件原为 `v-if="row.items"`，导致只要有明细（哪怕只有1条）就会显示分页组件，与需求"超过200条才显示"不符。

**修复**：改为 `v-if="row.items && row.items.length > pageItemThreshold"`，确保仅在明细数超过200条阈值时显示分页组件。

---

## 2. 分页核心逻辑详解

### 2.1 `paginatedItems(group)` 函数

```javascript
function paginatedItems(group) {
  if (!group.items || group.items.length === 0) return [];
  if (group.items.length <= pageItemThreshold) return group.items;  // ≤200 条，不处理

  const currentPage = getPageNum(group.skuName);  // 取该分组独立页码
  const start = (currentPage - 1) * pageItemSize;
  const end = start + pageItemSize;
  return group.items.slice(start, end);  // 切片返回
}
```

- **≤ 200 条**：直接返回全部 items，不分页
- **> 200 条**：根据该分组独立页码做切片，每页50条

### 2.2 独立页码维护

```javascript
const pageMap = ref(new Map());  // Map<skuName, currentPage>

function getPageNum(skuName) {
  return pageMap.value.get(skuName) || 1;  // 默认第1页
}

function setPageNum(skuName, page) {
  pageMap.value.set(skuName, page);  // 独立存储
}
```

每个 `skuName` 分组独立维护自己的当前页码，切换分组互不影响。

### 2.3 弹窗打开重置

```javascript
watch(() => props.open, (val) => {
  if (val) {
    checkForm.value.warehouseId = null;
    pageMap.value = new Map();  // 重新打开时全部重置为第1页
  }
});
```

---

## 3. 手动测试脚本

### 3.1 测试数据准备

需准备一条返修通知单，包含以下分组明细：

| 规格型号 | 明细条数 | 预期行为 |
|---------|---------|---------|
| 规格A | 220条 | 触发分页（>200，4页：50+50+50+50+20） |
| 规格B | 5条 | 不触发分页（≤200，全部显示） |

### 3.2 测试步骤与预期

| 步骤 | 操作 | 预期结果 | 验收项 |
|------|------|---------|-------|
| 1 | 打开核对明细弹窗，展开"规格A"分组 | 子表显示1-50条，下方显示分页组件，显示"共 220 条"，当前第1页 | 验收标准5 |
| 2 | 点击分页第2页 | 子表显示51-100条 | 验收标准5 |
| 3 | 切换到"规格B"分组展开 | 显示全部5条，无分页组件 | 验收标准6 |
| 4 | 回到"规格A"分组展开 | 页码保持在第2页（51-100条），未被"规格B"影响 | 验收标准6 |
| 5 | 关闭弹窗，重新打开 | 所有页码重置为第1页，"规格A"显示1-50条 | 验收标准5 |

### 3.3 验收标准对应

| 验收标准 | 描述 | 验证方式 |
|---------|------|---------|
| 5. 单组 >200 条时子表显示分页，每页50条 | 规格A(220条)显示4页分页控件 | 步骤1-2, 5 |
| 6. 不同分组独立分页，切换互不影响 | 规格B无分页且不影响规格A页码 | 步骤3-4 |

---

## 4. 代码文件清单

| 文件 | 行数 | 说明 |
|------|------|------|
| `ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/components/RepairNoticeCheckDialog.vue` | 309 | 核对明细弹窗组件，含分页逻辑 |

---

## 5. 结论

- ✅ **分页逻辑已完整实现**：阈值200条、每页50条、独立页码映射
- ✅ **修复分页组件显示条件**：改为 `row.items.length > pageItemThreshold`，仅超阈值时显示
- ✅ **独立页码互不影响**：通过 `Map<skuName, currentPage>` 实现
- ✅ **弹窗关闭重置**：watch open 监听，重新打开时重置 pageMap
- ✅ 验收标准5（单组>200条分页）和验收标准6（分组独立页码）均可满足
