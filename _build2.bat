@echo off
setlocal
set "JAVA_HOME=C:\jdk17"
set "PATH=C:\jdk17\bin;D:\apache-maven-3.9.8\bin;%PATH%"
cd /d "D:\MyPrj\进销存\wms-ruoyi-master"
echo 1. Checking java...
where java
echo.
echo 2. Maven version...
call "D:\apache-maven-3.9.8\bin\mvn.cmd" --version
echo.
echo 3. Compiling...
call "D:\apache-maven-3.9.8\bin\mvn.cmd" clean compile -DskipTests
echo EXIT_CODE=%ERRORLEVEL%
endlocal
