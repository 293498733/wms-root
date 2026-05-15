@echo off
set JAVA_HOME=C:\jdk17
set PATH=%JAVA_HOME%\bin;D:\apache-maven-3.9.8\bin;%PATH%
cd /d D:\MyPrj\进销存\wms-ruoyi-master
echo === Maven Version ===
call mvn --version
echo === Compiling (skip tests) ===
call mvn clean compile -DskipTests -q
echo EXIT_CODE=%ERRORLEVEL%
