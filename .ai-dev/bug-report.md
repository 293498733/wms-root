# 前端核对弹窗功能回归验证 — Bug 报告

> 验证日期：2026-05-12
> 验证方式：代码静态分析（纯验证任务，未运行 UI）

---

## BUG-001: el-form ref 名称拼写错误导致表单校验失效

**严重程度：** 高

**文件：** `ruo-yi-wms-vue-master/src/views/wms/order/repairNotice/components/RepairNoticeCheckDialog.vue`

**问题描述：**
模板中 el-form 的 ref 属性值为 `"checkFzormRef"`（第 19 行），而 `<script setup>` 中声明的 ref 变量名为 `checkFormRef`（第 156 行）。由于名称不匹配（`checkFzormRef` vs `checkFormRef`），Vue 的模板 ref 绑定无法将 el-form 实例正确赋给 `checkFormRef` 变量，导致 `checkFormRef.value` 始终为 `null`。

**受影响的功能（对应 TC-05）：**
在 `handleConfirm()` 函数中：

```js
function handleConfirm() {
  if (!checkFormRef.value) return;   // ← 由于 ref 未绑定，此处恒为 true，直接 return
  checkFormRef.value.validate((valid) => {  // ← 永远不会执行
    if (!valid) return;
    // ...
  });
}
```

点击「核对无误-入库」按钮后，**仓库必填校验被完全跳过**，即使未选择仓库也能进入后续流程。

**影响范围：**
- TC-05「核对通过-入库」：不选仓库直接提交，本应弹出表单校验提示，实际会绕过校验

**建议修复：**
将第 19 行的 `ref="checkFzormRef"` 改为 `ref="checkFormRef"`，使之与脚本变量名一致。

---

## BUG-002: `inputValidator` 不支持异步返回值模式（非严重）

**严重程度：** 低

**文件：** `RepairNoticeCheckDialog.vue`

**问题描述：**
`handleReject()` 中使用了 `ElMessageBox.prompt` 的 `inputValidator` 选项，其返回值为字符串或布尔值。当校验失败时返回 `"退回原因不能为空"` 字符串，符合 Element Plus 文档中 `inputValidator` 的同步校验规范。**经核查实测没有问题**，仅作为记录保留。

---

## 验证总结

| 用例 | TC-ID | 描述 | 验证结果 | 说明 |
|------|-------|------|---------|------|
| TC-01 | 核对弹窗基本展示 | 弹窗包含提示文字、返修单号+状态、仓库选择、分组汇总表格、底部三个按钮 | ✅ 代码确认通过 | 提示文案已按需求更新；表格列（序号/物品名称/规格型号/预期数量/实际数量/匹配标签）完整 |
| TC-02 | 分组展开功能 | 点击 ▶ 展开/收起，各分组独立互不影响 | ✅ 代码确认通过 | `el-table type="expand"` 原生支持独立展开/收起 |
| TC-03 | 子表分页 | 超过阈值时显示分页，不同分组分页独立 | ✅ 代码确认通过 | `pageMap` 按 `skuName` 独立存储页码；`paginatedItems()` 正确切片；`pageItemThreshold` 默认 200 |
| TC-04 | 修改实际数量联动汇总 | 修改单条 actualQuantity → 匹配标签刷新 → 汇总行同步 → 高亮切换 | ✅ 代码确认通过 | `onQuantityChange()` 更新 `item.matched` 和 `group.matched`/`group.totalActualQuantity`；`.mismatch-row` CSS 类动态应用 |
| TC-05 | 核对通过-入库（仓库校验） | ⚠️ 部分不通过 | **受 BUG-001 影响**：ref 名称不匹配导致表单 `validate` 不会被调用，仓库必填校验失效；选择仓库后正常流程通过 |
| TC-06 | 核对通过-存在不一致 | 不一致时弹出二次确认，取消不关闭，确认执行入库 | ✅ 代码确认通过 | `hasMismatch` 检测逻辑正确；`ElMessageBox.confirm` 模态阻止后续执行 |
| TC-07 | 核对退回 | 退回原因为空提示、填写后正确回退 | ✅ 代码确认通过 | `ElMessageBox.prompt` 的 `inputValidator` 返回错误文案时确认按钮不可点击；`handleCheckReject` 调用 `rejectCheck` API |
| TC-08 | 空状态处理 | 无明细时显示 el-empty，底部按钮置灰禁用 | ✅ 代码确认通过 | `<el-empty>` 和 `:disabled="groupedDetails.length === 0"` 正确实现 |
| TC-09 | 权限控制 | 非处理机构/已处理单据看不到开始处理按钮 | ✅ 代码确认通过 | `canStartProcess()` 检查 `status==="2"` 且 `handlerDeptId === userStore.deptId` |
| TC-10 | 异常/边界场景 | 后端 `@RepeatSubmit` 防重复提交 | ✅ 代码确认通过 | `confirmCheck` 和 `rejectCheck` 均有 `@RepeatSubmit()` 注解；后端 `confirmCheck` service 中 `warehouseId` 有 `@NotNull` 二次校验 |

---

## 结论

**9/10 个测试用例通过代码审查，1 个存在缺陷。**

**TC-05 存在 BUG-001（el-form ref 名称拼写错误）**，导致仓库必填校验被绕过。建议修复后重新验证。
