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

