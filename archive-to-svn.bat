@echo off
chcp 65001 >nul
title 进销存系统 - SVN归档脚本

:: ============================================================
:: 进销存系统 — SVN归档脚本
:: 用途：每次大版本发布时，将当前代码同步到SVN留档
:: 
:: 用法：
::   1. 先配置下面的 SVN_REPO_URL
::   2. 双击运行，或命令行执行
::   3. 脚本会自动复制代码到临时目录并提交到SVN
:: ============================================================

setlocal enabledelayedexpansion

:: ========== 配置区域 - 修改这里 ==========
:: SVN仓库地址（改成你的SVN服务器地址）
set SVN_REPO_URL=https://你的svn服务器/svn/进销存
:: SVN本地工作目录（SVN checkout出来的目录）
set SVN_WORK_DIR=D:\MyPrj\进销存_svn
:: 本次版本标签（默认取当前日期）
set VERSION_TAG=v%date:~0,4%%date:~5,2%%date:~8,2%
:: ========================================

echo ╔══════════════════════════════════════════╗
echo ║     进销存系统 - SVN归档脚本             ║
echo ╚══════════════════════════════════════════╝
echo.
echo 版本标签: %VERSION_TAG%
echo 源目录: %CD%
echo SVN目录: %SVN_WORK_DIR%
echo.

:: 检查SVN是否可用
where svn >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [错误] 找不到svn命令，请安装SVN客户端
    pause
    exit /b 1
)

:: 检查SVN工作目录是否存在
if not exist "%SVN_WORK_DIR%" (
    echo [信息] SVN工作目录不存在，正在checkout...
    svn checkout %SVN_REPO_URL% "%SVN_WORK_DIR%"
    if !ERRORLEVEL! neq 0 (
        echo [错误] SVN checkout失败，请检查地址和权限
        pause
        exit /b 1
    )
)

:: 更新SVN工作目录
echo [信息] 更新SVN工作目录...
svn update "%SVN_WORK_DIR%"
if %ERRORLEVEL% neq 0 (
    echo [警告] SVN update失败，可能首次使用或网络问题
)

:: 创建版本标签目录
set TAG_DIR=%SVN_WORK_DIR%\%VERSION_TAG%
echo [信息] 创建版本目录: %VERSION_TAG%
mkdir "%TAG_DIR%" 2>nul

:: 复制前端代码（排除不需要的目录）
echo [信息] 复制前端代码...
if exist "%CD%\ruo-yi-wms-vue-master" (
    xcopy "%CD%\ruo-yi-wms-vue-master" "%TAG_DIR%\ruo-yi-wms-vue-master" /E /I /Y /EXCLUDE:%TEMP%\exclude.txt >nul 2>&1
)

:: 复制后端代码
echo [信息] 复制后端代码...
if exist "%CD%\wms-ruoyi-master" (
    xcopy "%CD%\wms-ruoyi-master" "%TAG_DIR%\wms-ruoyi-master" /E /I /Y >nul 2>&1
)

:: 复制根目录关键文件
copy "%CD%\README.md" "%TAG_DIR%\" >nul 2>&1

:: SVN添加新文件
echo [信息] 添加新文件到SVN...
cd /d "%SVN_WORK_DIR%"
svn add --force * --auto-props 2>nul

:: 提交到SVN
echo [信息] 提交到SVN...
svn commit -m "[归档] 进销存系统 版本 %VERSION_TAG%"
if %ERRORLEVEL% equ 0 (
    echo.
    echo ╔══════════════════════════════════════════╗
    echo ║  ✅ SVN归档完成！                        ║
    echo ║  版本: %VERSION_TAG%                      ║
    echo ║  路径: %TAG_DIR%                          ║
    echo ╚══════════════════════════════════════════╝
) else (
    echo.
    echo ╔══════════════════════════════════════════╗
    echo ║  ⚠️ SVN提交失败，请手动检查              ║
    echo ╚══════════════════════════════════════════╝
)

cd /d "%CD%"
echo.
echo 按任意键退出...
pause >nul
