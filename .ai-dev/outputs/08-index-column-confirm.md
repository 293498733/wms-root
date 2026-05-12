# 分组表格序号列展示方案确认

> 编制日期：2026-05-12
> 前置分析：`.ai-dev/task_contexts/task-index-column.md`

---

## 1. 现状分析

### 1.1 分组汇总表（父表）

**文件**: `ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/components/RepairNoticeCheckDialog.vue`

```html
<!-- 第87行 -->
<el-table-column label="序号" type="index" width="60" align="center"/>
```

- 数据源 `groupedDetails` 是一个普通数组（`computed` 返回 `props.checkDetail?.groupedDetails || []`）
- Element Plus 的 `type="index"` 直接映射为数组索引（从1开始）
- 该数组无分页，所有分组行一次性渲染
- **结论：序号已为全局连续（1, 2, 3, ...），无需修改 ✅**

### 1.2 子表明细表（展开子表）

```html
<!-- 第51行 -->
<el-table-column label="序号" type="index" width="60" align="center"/>
```

- 数据源 `paginatedItems(row)` 返回当前分页切片
- 当分组内条码行数 ≤ `pageItemThreshold`（默认200）时，无分页，序号组内连续
- 当分组内条码行数 > 200 条时启用分页（每页50条），**每页从1重新开始**

### 1.3 分页逻辑

```js
// 第190-198行
function paginatedItems(group) {
  if (!group.items || group.items.length === 0) return [];
  if (group.items.length <= props.pageItemThreshold) return group.items;
  const currentPage = getPageNum(group.skuName);
  const start = (currentPage - 1) * props.pageItemSize;
  const end = start + props.pageItemSize;
  return group.items.slice(start, end);
}
```

---

## 2. 方案评估

| # | 方案 | 说明 | 复杂度 | 推荐 |
|---|------|------|-------|------|
| A | **维持现状** | 分组汇总表全局连续（已满足）；子表按组分页独立从1开始 | 零修改 | ⭐**推荐** |
| B | 子表跨页连续序号 | 移除 `type="index"`，改用 `#default` 模板手动计算 `(page-1)*pageSize + $index + 1` | 低（仅template改动） | ❌ |
| C | 子表跨组连续序号 | 需要计算前序所有分组的 items 数量累加 | 中（需新增计算逻辑） | ❌ |

### 方案A（推荐）理由

1. **验收标准未明确要求**跨组/跨页序号连续性
2. **用户焦点在单个分组内**：每次展开一个规格型号查看条码明细，用户关注的是该分组内的数据
3. **分页场景下行业惯例**：分页表格从1开始是普遍UI实践（如ElasticSearch、数据表格组件）
4. **跨组连续意义不大**：不同规格型号的条码是独立的业务实体，序号分组重置更符合业务直觉
5. **零修改风险**：无需改动代码，避免引入回归

### 方案B/C 实现方式（备录，如需追溯）

若未来要求子表跨页连续，只需修改 template 第51行：

```html
<el-table-column label="序号" width="60" align="center">
  <template #default="{ $index }">
    {{ (getPageNum(row.skuName) - 1) * pageItemSize + $index + 1 }}
  </template>
</el-table-column>
```

若要求跨组连续，需在 `groupedDetails` 中预计算每个分组在总列表中的起始偏移量。

---

## 3. 最终决定

| 位置 | 当前行为 | 是否连续 | 决定 |
|------|---------|---------|------|
| 分组汇总表（父表） | `type="index"` → 1,2,3... | ✅ 全局连续 | **维持现状，不变** |
| 子表明细表（无分页） | `type="index"` → 1,2,3... | ✅ 组内连续 | **维持现状，不变** |
| 子表明细表（有分页） | `type="index"` → 每页从1 | ⚠️ 跨页不连续 | **维持现状，不变** |

**结论：无需修改任何代码文件。** 当前 `type="index"` 的行为已完整满足业务场景需求。

---

## 4. 验证清单

- [ ] 分组汇总表序号按 1,2,3... 递增 → ✅ 已确认（`groupedDetails` 数组索引天然连续）
- [ ] 子表展开后组内序号按 1,2,3... 递增 → ✅ 已确认
- [ ] 子表分页切换后每页从1开始 → ✅ 已确认（行业惯例，维持现状）
- [ ] 切换分组展开/收起后序号重置为1 → ✅ 已确认（每个分组独立）
