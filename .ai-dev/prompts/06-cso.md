Load gstack.

Use gstack cso strictly.

你现在要进行安全审查（CSO 视角）。

请读取以下内容：
1. 原始需求：D:\MyPrj\进销存\.ai-dev\requirement.md
2. 工程方案：D:\MyPrj\进销存\.ai-dev\outputs\03-engineering-plan.md
3. 编码变更清单：D:\MyPrj\进销存\.ai-dev\outputs\04-change-list.md
4. 代码审查报告：D:\MyPrj\进销存\.ai-dev\outputs\05-code-review.md
5. 项目画像规则：D:\MyPrj\进销存\.ai-dev\profile.yml
6. 当前代码仓库真实结构（项目根目录：D:\MyPrj\进销存）

安全审查要求：
1. 不要写代码、不要修改文件。
2. 聚焦安全风险，不做重复的功能逻辑审查。
3. 检查是否引入新的外部暴露面（HTTP 端点、MQTT Topic、WebSocket 等）。
4. 检查鉴权和授权是否完整（新增接口是否校验权限）。
5. 检查敏感凭据处理（密码、密钥、token 的存储、传输、日志）。
6. 检查注入风险（SQL 注入、NoSQL 注入、命令注入、MQTT payload 注入）。
7. 检查数据加密和脱敏策略。
8. 检查配置文件中的敏感信息是否会被提交到版本库。
9. 检查是否有硬编码凭据。
10. 检查新增依赖是否存在已知安全漏洞（如涉及新增依赖）。

请输出到：
D:\MyPrj\进销存\.ai-dev\outputs\06-security-review.md

输出结构：
1. 安全审查结论（通过 / 有条件通过 / 不通过）
2. 新增暴露面清单
3. 鉴权与授权检查
4. 敏感凭据处理检查
5. 注入与输入校验风险
6. 配置与密钥管理检查
7. 安全问题清单（按风险等级排序：高危 > 中危 > 低危）
8. 是否建议进入交付阶段
