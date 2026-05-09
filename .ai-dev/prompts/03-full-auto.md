Load gstack.

# == PIPELINE MODE - DO NOT EXIT ==
# 你正在执行全自动开发管线 (Stage 0-7)。
# 规则：
# 1. 每个阶段完成后，立即写入状态文件 `.ai-dev/.pipeline_stage`
# 2. 每次对话开始，先检查状态文件，从上次中断处继续
# 3. 不要在阶段之间自由聊天、不要提建议、不要发散
# 4. 只在"阻塞检查点"停下来等待用户回答
# 5. 用户回答阻塞问题后，立即继续执行下一阶段，不得进入闲聊模式
# 6. 所有输出必须写入对应文件，不要只在对话中展示
# ==============================

---

## 状态检查 (每次对话首先执行)

检查文件 `D:\MyPrj\进销存\.ai-dev\.pipeline_stage` 是否存在：

- **不存在**：从阶段 0 开始执行
- **内容为 `refine_done`**：跳到阶段 1
- **内容为 `plan_done`**：跳到阶段 4
- **内容为 `implement_done`**：跳到阶段 5
- **内容为 `review_done`**：跳到阶段 6
- **内容为 `security_done`**：跳到阶段 7

当前状态：请读取 `D:\MyPrj\进销存\.ai-dev\.pipeline_stage` 后确定。

---

## 阶段 0：项目画像扫描

Use gstack 扫描项目：

1. 读取项目根目录 `D:\MyPrj\进销存` 的实际代码结构
2. 判断技术栈、模块划分、关键路径
3. 如 `D:\MyPrj\进销存\.ai-dev\profile.yml` 已存在且内容完整，跳过本阶段
4. 如需要更新，写入 `D:\MyPrj\进销存\.ai-dev\profile.yml`

**完成后**：写入 `D:\MyPrj\进销存\.ai-dev\.pipeline_stage` 内容为 `refine_done`，立即进入阶段 1。

---

## 阶段 1：需求精炼

Use gstack office-hours strictly.

读取用户原始需求 `D:\MyPrj\进销存\.ai-dev\requirement.md`。

要求：
1. **不要写代码，不要修改文件。**
2. 检查需求完整性。如存在关键模糊点，向用户提问（每次最多 3 个问题）。
3. 精炼后的结构化需求 **覆盖写入** `D:\MyPrj\进销存\.ai-dev\requirement.md`。
4. 输出结构见下方。

输出章节（不可省略）：
```
# 功能需求
## 功能名称
## 业务背景
## 功能要求（含接口定义、业务流程）
## 限制条件
## 验收标准
## 补充信息
```

**完成后**：写入 `D:\MyPrj\进销存\.ai-dev\.pipeline_stage` 内容为 `refine_done`，立即进入阶段 2。

---

## 阶段 2：自动规划（需求分析 + 产品评审 + 工程方案）

Use gstack plan-ceo-review strictly for product review.
Use gstack plan-eng-review strictly for engineering plan.

**三项依次执行，全部输出到文件：**

### 子阶段 2a — 需求分析
输出到 `D:\MyPrj\进销存\.ai-dev\outputs\01-analysis.md`：
1. 需求理解
2. 当前项目相关性分析
3. 关键业务问题
4. 边界场景
5. 风险点
6. 需要人工确认的问题

### 子阶段 2b — 产品评审
输出到 `D:\MyPrj\进销存\.ai-dev\outputs\02-product-review.md`：
1. 需求价值判断
2. 范围是否合理
3. MVP 拆分建议
4. 是否需要人工确认

### 子阶段 2c — 工程方案
输出到 `D:\MyPrj\进销存\.ai-dev\outputs\03-engineering-plan.md`：
1. 当前项目技术栈判断
2. 相关目录和文件
3. 需要修改的文件
4. 需要新增的文件
5. 后端设计方案
6. 前端设计方案（如涉及）
7. 数据库变更（如涉及）
8. 风险点
9. 测试点
10. 是否建议进入编码阶段

**完成后**：写入 `D:\MyPrj\进销存\.ai-dev\.pipeline_stage` 内容为 `plan_done`。

---

## ⚠ 阻塞检查点 1 ⚠

**停止并输出以下内容，等待用户确认：**

```
=== 规划阶段完成 ===

产出文件：
  需求分析：D:\MyPrj\进销存\.ai-dev\outputs\01-analysis.md
  产品评审：D:\MyPrj\进销存\.ai-dev\outputs\02-product-review.md
  工程方案：D:\MyPrj\进销存\.ai-dev\outputs\03-engineering-plan.md

阻塞问题汇总（必须全部回答后才能继续）：
| # | 问题 | 选项/默认 |
|---|------|-----------|
| Q1 | ... | ... |

确认后我将进入阶段 4 编码实现。
请回复「继续」或回答上述问题。
```

**此检查点只输出一次。用户回复后，不重复输出，直接进入阶段 4。**

---

## 阶段 4：编码实现

读取：
1. `D:\MyPrj\进销存\.ai-dev\requirement.md`
2. `D:\MyPrj\进销存\.ai-dev\outputs\01-analysis.md`
3. `D:\MyPrj\进销存\.ai-dev\outputs\02-product-review.md`
4. `D:\MyPrj\进销存\.ai-dev\outputs\03-engineering-plan.md`
5. `D:\MyPrj\进销存\.ai-dev\profile.yml`

编码要求：
1. 只修改工程方案中列出的相关文件。
2. 禁止全局重构。
3. 禁止删除已有业务逻辑。
4. 禁止修改受保护路径。
5. 保持当前项目代码风格。
6. 如果发现工程方案与代码实际情况不一致，立即停止，**不要强行修改**。记录差异到 `D:\MyPrj\进销存\.ai-dev\outputs\04-change-list.md`。
7. 修改完成后，输出实际修改文件清单和测试步骤到 `D:\MyPrj\进销存\.ai-dev\outputs\04-change-list.md`。

**完成后**：写入 `D:\MyPrj\进销存\.ai-dev\.pipeline_stage` 内容为 `implement_done`，执行**编译验证**：

1. 打开 `D:\MyPrj\进销存\.ai-dev\profile.yml`，读取 `commands.build` 的值。
2. 执行该编译命令。
3. 如编译或测试失败，停止并报告失败原因。
4. 通过后立即进入阶段 5。

---

## 阶段 5：代码审查

Use gstack review strictly.

读取 `D:\MyPrj\进销存\.ai-dev\outputs\03-engineering-plan.md` 和 `D:\MyPrj\进销存\.ai-dev\outputs\04-change-list.md`，对比审查：

1. 实际改动是否与工程方案一致
2. 是否有越权修改
3. 是否有 SQL 安全风险
4. 是否有循环依赖或其他架构问题

输出到 `D:\MyPrj\进销存\.ai-dev\outputs\05-code-review.md`。

**完成后**：写入 `D:\MyPrj\进销存\.ai-dev\.pipeline_stage` 内容为 `review_done`，立即进入阶段 6。

---

## 阶段 6：安全审查

Use gstack cso strictly.

审查范围：
1. 接口暴露面
2. 认证/鉴权
3. 敏感数据处理
4. 第三方依赖

输出到 `D:\MyPrj\进销存\.ai-dev\outputs\06-security-review.md`。

**完成后**：写入 `D:\MyPrj\进销存\.ai-dev\.pipeline_stage` 内容为 `security_done`。

---

## ⚠ 阻塞检查点 2 ⚠

**如安全审查发现严重漏洞（rating=critical/high），停止并输出：**

```
=== 安全审查完成 ===

严重漏洞：
| # | 漏洞 | 文件 | 修复建议 |
|---|------|------|----------|
| ... |

是否继续进入交付阶段？
```

**如无严重漏洞，不停止，直接进入阶段 7。**

---

## 阶段 7：交付报告

读取所有产物文件，生成交付报告。

输出到 `D:\MyPrj\进销存\.ai-dev\outputs\07-delivery-report.md`：
1. 需求概述
2. 改动文件清单
3. 数据库变更摘要
4. 测试建议
5. 部署注意事项
6. 遗留风险

**完成后**：删除 `D:\MyPrj\进销存\.ai-dev\.pipeline_stage`（管线结束）。

```
=== 全流程完成 ===

交付报告：D:\MyPrj\进销存\.ai-dev\outputs\07-delivery-report.md

所有产物：
  需求：    D:\MyPrj\进销存\.ai-dev\requirement.md
  需求分析：D:\MyPrj\进销存\.ai-dev\outputs\01-analysis.md
  产品评审：D:\MyPrj\进销存\.ai-dev\outputs\02-product-review.md
  工程方案：D:\MyPrj\进销存\.ai-dev\outputs\03-engineering-plan.md
  变更清单：D:\MyPrj\进销存\.ai-dev\outputs\04-change-list.md
  代码审查：D:\MyPrj\进销存\.ai-dev\outputs\05-code-review.md
  安全审查：D:\MyPrj\进销存\.ai-dev\outputs\06-security-review.md
  交付报告：D:\MyPrj\进销存\.ai-dev\outputs\07-delivery-report.md
```
