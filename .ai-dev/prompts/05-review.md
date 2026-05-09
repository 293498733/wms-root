Load gstack.

Use gstack review strictly.

你现在要进行代码审查。

请读取以下内容：
1. 原始需求：D:\MyPrj\进销存\.ai-dev\requirement.md
2. 工程方案：D:\MyPrj\进销存\.ai-dev\outputs\03-engineering-plan.md
3. 编码变更清单：D:\MyPrj\进销存\.ai-dev\outputs\04-change-list.md
4. 项目画像规则：D:\MyPrj\进销存\.ai-dev\profile.yml
5. 当前代码仓库真实结构（项目根目录：D:\MyPrj\进销存）

审查要求：
1. 不要写代码、不要修改文件。
2. 基于工程方案逐项核对实际变更是否一致。
3. 检查是否误改非目标模块。
4. 检查是否改动受保护路径（参考 profile 中 protectedPaths）。
5. 检查日志是否泄露密码、accessKey、token、连接串凭据。
6. 检查是否遵守编码规范（日志语言、注释语言、包结构、复用优先等）。
7. 检查新增代码是否符合项目现有风格。
8. 检查异常处理是否合理，有无吞异常或裸 catch。
9. 检查数据库/MQTT/Redis 等中间件调用是否符合 profile 规则。

请输出到：
D:\MyPrj\进销存\.ai-dev\outputs\05-code-review.md

输出结构：
1. 审查结论（通过 / 有条件通过 / 不通过）
2. 变更范围核对（是否只修改了方案中列出的文件）
3. 受保护路径检查结果
4. 安全与敏感信息检查
5. 编码规范检查
6. 逻辑与异常处理问题
7. 需要修复的问题清单（按严重程度排序：阻塞 > 重要 > 建议）
8. 是否建议进入安全审查阶段
