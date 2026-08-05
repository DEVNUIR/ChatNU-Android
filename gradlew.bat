@echo off
set DIR=%~dp0
set CLASSPATH=%DIR%gradle\wrapper\gradle-wrapper.jar
if not exist "%CLASSPATH%" (
  echo Missing gradle\wrapper\gradle-wrapper.jar. Regenerate it with: gradle wrapper --gradle-version 8.13
  exit /b 1
)
if defined JAVA_HOME (
  set JAVA_EXE=%JAVA_HOME%\bin\java.exe
) else (
  set JAVA_EXE=java.exe
)
"%JAVA_EXE%" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*
