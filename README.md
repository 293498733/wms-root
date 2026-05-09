# 进销存管理系统

基于若依(RuoYi)框架的WMS进销存管理系统

## 版本管理说明

### 日常开发（Git - 主版本管理）
日常所有开发、修改、提交使用 Git：
```bash
git add .
git commit -m "feat: xxx"
git push origin main
```

### 大版本归档（SVN - 留档备份）
每次大版本发布时，同步到 SVN 留档：
```bash
# 方式1：手动（推荐）
将项目目录复制一份到 SVN 工作目录，提交

# 方式2：脚本归档（见 archive-to-svn.bat）
```

### 目录结构
```
├── ruo-yi-wms-vue-master/    # 前端 Vue 项目
│   └── ...
├── wms-ruoyi-master/          # 后端 Spring Boot 项目
│   └── ...
├── archive-to-svn.bat         # SVN归档脚本
└── README.md
```
