@echo off
set JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.12.7-hotspot
set PATH=%JAVA_HOME%\bin;%PATH%
call "D:\apache-maven-3.6.3\bin\mvn.cmd" %*
