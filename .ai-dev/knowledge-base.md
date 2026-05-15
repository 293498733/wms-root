# AI Dev Flow — 自动知识积累

> 由管线自动生成，记录各任务的关键决策。下游任务自动参考。

---

### [task-frontend-returnnotice-dialog-width] 前端：ReturnNoticeDialog.vue 弹窗宽度调整为 960px
**Category**: frontend | **Time**: 2026-05-15 10:21

*From `ruo-yi-wms-vue-master/src/views/wms/order/returnNotice/components/ReturnNoticeDialog.vue`:*
- - 弹窗宽度从 1100px 改为 960px，与 ItemQrGenerateDialog 弹窗宽度一致，统一视觉风格
- - 960px 在 1366px 分辨率下（减去侧边栏约 220px 后剩余 1140px）居中展示，两侧各有约 90px 边距
- - 仅修改 `<el-dialog>` 的 width 属性，其他属性（append-to-body、destroy-on-close、class）及所有业务逻辑保持不变

---

### [task-frontend-qr-category-column] 前端：ItemQrGenerateDialog.vue 生成前表格新增物品分类列
**Category**: frontend | **Time**: 2026-05-15 10:21

*From `ruo-yi-wms-vue-master/src/views/wms/basic/item/components/ItemQrGenerateDialog.vue`:*
- - renderQrSheet(): 拼接 brandName + itemName 作为第一行文本（品牌名称+规格型号名称），preCode 保持第二行。
- - exportHtml(): 同理拼接 brandName + itemName 作为卡片标题，编码在第二行 span 展示。
- - 使用 [record.brandName, record.itemName].filter(Boolean).join(' ') 模式，可安全处理 brandName 为 null/undefined/空字符串的情况。
- - 未改动 exportCsv() 的 CSV 列定义；未改动 qrRecords 表格的列定义；未改动其他业务逻辑。
- - record.brandName 由后端 generateItemSkuQrPre API 返回的 ItemSkuQrPreVo.brandName 字段提供。
- - 在"规格型号名称"列之后、"编号"列之前插入"物品分类"列，保持与 ItemTable.vue 中分类列一致的显示逻辑（row.itemCategoryInfo?.categoryName || '-'）
- - 使用 show-overflow-tooltip 处理长文本溢出，min-width="140" 与"编号"列宽度一致
- - 未改动生成后视图（v-else 模板中 qrRecords 表格）、未改动导出/打印/下载方法、未改动业务逻辑
- - 数据通过 generateLines 的 ...item 展开保留，由后端 ItemService.fillItemCategoryInfo() 填充

---

### [task-frontend-returnnotice-layout] 前端：ReturnNoticeDialog.vue 表单栅格布局优化
**Category**: frontend | **Time**: 2026-05-15 10:22

*From `ruo-yi-wms-vue-master/src/views/wms/order/returnNotice/components/ReturnNoticeDialog.vue`:*
- - 弹窗宽度从 1100px 改为 960px，与 ItemQrGenerateDialog 弹窗宽度一致，统一视觉风格
- - 960px 在 1366px 分辨率下（减去侧边栏约 220px 后剩余 1140px）居中展示，两侧各有约 90px 边距
- - 仅修改 `<el-dialog>` 的 width 属性，其他属性（append-to-body、destroy-on-close、class）及所有业务逻辑保持不变
- - 表单栅格布局优化：在 960px 弹窗宽度下调整 el-col :span 值，使表单布局更紧凑合理
- - Row 1（返回单号+单据状态+总数量）：span 从 11+6+6 调整为 8+5+5（合计 18），靠左排列留空 6 格，减少浪费
- - Row 2（关联返修通知单+出库仓库）：span 从 11+6 调整为 10+8（合计 18），扩大选择区域，减少右侧空白
- - Row 3（物流公司+物流单号）：span 保持 8+8 不变
- - Row 4（备注）：span 从 11 调整为 16，使 textarea 宽度与上方字段对齐
- - 仅修改 el-col 的 :span 属性值，不增删 el-col 元素，不改 el-form-item 内部结构和 CSS 样式
- - 明细表格列宽调整：SKU编码 min-width: 140→120，SKU名称 min-width: 180→150，可返回数量 width: 120→100，本次返回数量 width: 180→140
- - 调整后各列宽度合计 60(#)+120+150+100+140=570px，在 960px 弹窗（减去 padding 约 48px = 912px 可用）中留出约 342px 弹性空间，不会出现水平滚动条
- - 仅修改 el-table-column 的 width/min-width 属性值，保留 show-overflow-tooltip、align、template 插槽等原有属性不变
- - el-input-number 的 style="width: 140px" 保持不变，不影响本次返回数量列的输入组件样式

---

