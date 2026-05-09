你现在要为目标项目生成项目画像（profile）。

请扫描以下目录的真实代码结构：
D:\MyPrj\进销存

扫描内容：
1. 技术栈判断（语言、框架、构建工具、JDK 版本）
2. 项目模块结构（多模块工程的模块列表和分组）
3. 分层架构（controller/service/dao/mapper 等层级）
4. 数据库使用情况（MySQL/MongoDB/Redis，ORM 风格）
5. 中间件使用情况（MQTT/RabbitMQ/Kafka/ActiveMQ 等）
6. 已有编码规范（日志风格、注释语言、命名习惯）
7. 受保护路径（生产配置、部署脚本、Dockerfile 等）
8. 构建和测试命令

输出要求：
1. 输出为 YAML 格式，结构参考模板文件：D:\MyPrj\进销存\.ai-dev\profile.yml
2. 保留模板中的通用规则，只补充扫描到的具体信息
3. 如果某项扫描不到，保留模板默认值，不要猜测
4. 模块分组按实际目录结构填写
5. 受保护路径按实际文件填写

请输出到：
D:\MyPrj\进销存\.ai-dev\profile.yml
