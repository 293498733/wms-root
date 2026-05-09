Load gstack.

你现在要为企业级软件开发需求执行完整的规划流程。请严格按以下 3 个阶段顺序执行，每个阶段完成后输出到对应文件，然后自动进入下一阶段。

---

## 阶段 1：需求分析

Use gstack office-hours strictly.

请读取以下内容：
1. 平台任务需求：D:\MyPrj\进销存\.ai-dev\requirement.md
2. 项目画像规则：D:\MyPrj\进销存\.ai-dev\profile.yml
3. 当前代码仓库真实结构（项目根目录：D:\MyPrj\进销存）

要求：
1. 不要写代码。
2. 不要修改文件。
3. 不要假设不存在的业务模块。
4. 必须基于当前仓库真实文件分析。
5. 必须指出需求不明确的地方。
6. 必须提出需要人工确认的问题。
7. 如果需求不足以进入设计阶段，明确说明阻塞点。

请输出到：
D:\MyPrj\进销存\.ai-dev\outputs\01-analysis.md

输出结构：
1. 需求理解
2. 当前项目相关性分析
3. 关键业务问题
4. 边界场景
5. 风险点
6. 需要人工确认的问题
7. 是否建议进入产品评审阶段

**阶段 1 完成后，立即进入阶段 2，不要等待用户确认。**

---

## 阶段 2：产品范围评审

Use gstack plan-ceo-review strictly.

请读取：
1. D:\MyPrj\进销存\.ai-dev\requirement.md
2. D:\MyPrj\进销存\.ai-dev\outputs\01-analysis.md

要求：
1. 不要写代码。
2. 不要修改文件。
3. 从产品价值、范围控制、交付风险角度评审。
4. 判断是否适合进入工程设计。
5. 如果范围过大，必须拆分 MVP。

请输出到：
D:\MyPrj\进销存\.ai-dev\outputs\02-product-review.md

输出结构：
1. 需求价值判断
2. 范围是否合理
3. MVP 拆分建议
4. 不建议做的部分
5. 需要人工确认的问题
6. 是否建议进入工程方案设计

**阶段 2 完成后，立即进入阶段 3，不要等待用户确认。**

---

## 阶段 3：工程方案设计

Use gstack plan-eng-review strictly.

请读取：
1. D:\MyPrj\进销存\.ai-dev\requirement.md
2. D:\MyPrj\进销存\.ai-dev\outputs\01-analysis.md
3. D:\MyPrj\进销存\.ai-dev\outputs\02-product-review.md
4. D:\MyPrj\进销存\.ai-dev\profile.yml
5. 当前代码仓库真实结构（项目根目录：D:\MyPrj\进销存）

要求：
1. 不要写代码。
2. 不要修改文件。
3. 必须先分析当前项目结构。
4. 不要假设不存在的模块。
5. 只分析本次功能相关影响。
6. 必须列出准备修改的文件。
7. 涉及数据库时，必须给出 SQL、回滚 SQL、影响范围。

请输出到：
D:\MyPrj\进销存\.ai-dev\outputs\03-engineering-plan.md

输出结构：
1. 当前项目技术栈判断
2. 相关目录和文件
3. 需要修改的文件
4. 需要新增的文件
5. 后端设计方案
6. 前端设计方案，如涉及
7. 数据库变更，如涉及
8. 风险点
9. 测试点
10. 是否建议进入编码阶段

---

## 全部完成后

3 个阶段全部完成后，请输出一份总结：

```
=== 规划流程完成 ===

阶段 1 需求分析：  ✓ 已输出到 D:\MyPrj\进销存\.ai-dev\outputs\01-analysis.md
阶段 2 产品评审：  ✓ 已输出到 D:\MyPrj\进销存\.ai-dev\outputs\02-product-review.md
阶段 3 工程方案：  ✓ 已输出到 D:\MyPrj\进销存\.ai-dev\outputs\03-engineering-plan.md

阻塞问题汇总：
- （列出阶段 1/2/3 中发现的所有需要人工确认的问题）

是否建议进入编码阶段：是/否
如果不建议，原因：xxx

下一步：请确认上述阻塞问题后，执行阶段 4 编码实现。
```
