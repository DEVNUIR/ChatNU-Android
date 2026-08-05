@echo off
setlocal
set "DIR=%~dp0"
set "CLASSPATH=%DIR%gradle\wrapper\gradle-wrapper.jar"
set "WRAPPER_URL=https://services.gradle.org/distributions/gradle-8.13-wrapper.jar"
set "WRAPPER_SHA256=81a82aaea5abcc8ff68b3dfcb58b3c3c429378efd98e7433460610fecd7ae45f"

if not exist "%CLASSPATH%" (
  echo Bootstrapping the verified Gradle 8.13 wrapper...
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $dest='%CLASSPATH%'; New-Item -ItemType Directory -Force -Path (Split-Path $dest) ^| Out-Null; Invoke-WebRequest -UseBasicParsing -Uri '%WRAPPER_URL%' -OutFile $dest; $actual=(Get-FileHash $dest -Algorithm SHA256).Hash.ToLower(); if($actual -ne '%WRAPPER_SHA256%'){Remove-Item -Force $dest; throw 'Gradle wrapper checksum mismatch'}"
  if errorlevel 1 exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$actual=(Get-FileHash '%CLASSPATH%' -Algorithm SHA256).Hash.ToLower(); if($actual -ne '%WRAPPER_SHA256%'){throw 'Gradle wrapper checksum mismatch'}"
if errorlevel 1 exit /b 1

if defined JAVA_HOME (
  set "JAVA_EXE=%JAVA_HOME%\bin\java.exe"
) else (
  set "JAVA_EXE=java.exe"
)

"%JAVA_EXE%" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*
endlocal
