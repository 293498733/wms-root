## Task: 开发返回确认单前端 API 封装层

在 src/api/wms/returnNotice.js 中封装9个接口的请求函数

### Implementation Context

参照 repairNotice.js 的模式，使用 @/utils/request 封装。

注意 Controller 路径是 PascalCase：/wms/ReturnNotice（后端实际路由）

封装9个函数：
1. listReturnNotice(query) → GET /wms/ReturnNotice/list，params
2. getReturnNotice(id) → GET /wms/ReturnNotice/{id}
3. addReturnNotice(data) → POST /wms/ReturnNotice，data
4. updateReturnNotice(data) → PUT /wms/ReturnNotice，data
5. delReturnNotice(ids) → DELETE /wms/ReturnNotice/{ids}
6. submitReturnNotice(data) → POST /wms/ReturnNotice/submit，data
7. confirmReturnNotice(id) → POST /wms/ReturnNotice/confirm/{id}
8. voidReturnNotice(id) → POST /wms/ReturnNotice/void/{id}
9. listReturnableSkus(repairNoticeId) → GET /wms/ReturnNotice/returnableSkus/{repairNoticeId}

使用 export function 命名导出。
所有路径使用模板字符串拼接待路径参数。


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

### Relevant Input Files

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

#### wms-ruoyi-master/ruoyi-admin-wms/src/main/java/com/ruoyi/wms/controller/ReturnNoticeController.java
```
package com.ruoyi.wms.controller;

import cn.dev33.satoken.annotation.SaCheckPermission;
import com.ruoyi.common.core.domain.R;
import com.ruoyi.common.core.validate.AddGroup;
import com.ruoyi.common.core.validate.EditGroup;
import com.ruoyi.common.idempotent.annotation.RepeatSubmit;
import com.ruoyi.common.log.annotation.Log;
import com.ruoyi.common.log.enums.BusinessType;
import com.ruoyi.common.mybatis.core.page.PageQuery;
import com.ruoyi.common.mybatis.core.page.TableDataInfo;
import com.ruoyi.common.web.core.BaseController;
import com.ruoyi.wms.domain.bo.ReturnNoticeBo;
import com.ruoyi.wms.domain.vo.ReturnNoticeVo;
import com.ruoyi.wms.domain.vo.ReturnableSkuVo;
import com.ruoyi.wms.service.RepairNoticeService;
import com.ruoyi.wms.service.ReturnNoticeService;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 返回通知单Controller
 *
 * @author zcc
 * @date 2026-05-11
 */
@Validated
@RequiredArgsConstructor
@RestController
@RequestMapping("/wms/ReturnNotice")
public class ReturnNoticeController extends BaseController {

    private final ReturnNoticeService returnNoticeService;
    private final RepairNoticeService repairNoticeService;

    /**
     * 接口1：查询返回通知单列表
     */
    @SaCheckPermission("wms:returnNotice:list")
    @GetMapping("/list")
    public TableDataInfo<ReturnNoticeVo> list(ReturnNoticeBo bo, PageQuery pageQuery) {
        return returnNoticeService.queryPageList(bo, pageQuery);
    }

    /**
     * 接口2：获取返回通知单详情
     */
    @SaCheckPermission("wms:returnNotice:query")
    @GetMapping("/{id}")
    public R<ReturnNoticeVo> getInfo(@NotNull(message = "主键不能为空") @PathVariable Long id) {
        return R.ok(returnNoticeService.queryById(id));
    }

    /**
     * 接口3：新增返回通知单（保存草稿）
     */
    @SaCheckPermission("wms:returnNotice:add")
    @Log(title = "返回通知单", businessType = BusinessType.INSERT)
    @RepeatSubmit()
    @PostMapping()
    public R<Long> add(@Validated(AddGroup.class) @RequestBody ReturnNoticeBo bo) {
        Long id = returnNoticeService.insertByBo(bo);
        return R.ok(id);
    }

    /**
     * 接口4：编辑返回通知单
     */
    @SaCheckPermission("wms:returnNotice:edit")
    @Log(title = "返回通知单", businessType = BusinessType.UPDATE)
    @RepeatSubmit()
    @PutMapping()
    public R<Void> edit(@Validated(EditGroup.class) @RequestBody ReturnNoticeBo bo) {
        returnNoticeService.updateByBo(bo);
        return R.ok();
    }

    /**
     * 接口5：删除返回通知单
     */
    @SaCheckPermission("wms:returnNotice:remove")
    @Log(title = "返回通知单", businessType = BusinessType.DELETE)
    @DeleteMapping("/{ids}")
    public R<Void> remove(@NotEmpty(message = "主键不能为空") @PathVariable Long[] ids) {
        returnNoticeService.deleteByIds(List.of(ids));
        return R.ok();
    }

    /**
     * 接口6：提交返回通知单
     */
 
```
