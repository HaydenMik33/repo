@echo off

if [%1]==[] goto usage
goto continue

:continue
set TOOL_ID=%1

call common.bat

set EQSRV_NAME=%TOOL_ID%srv

set EQSIM_NAME=%TOOL_ID%gw

set ASHLHOME=%~dp0Rudolph\AutoShell\ashl3.10.0

rem  Check AutoShell

if EXIST %ASHLHOME%\bin\sendmq.exe goto ok1
goto sendmqMissingError
:ok1

%ASHLHOME%\bin\sendmq %EQSRV_NAME% do=exit
%ASHLHOME%\bin\sendmq %EQSIM_NAME% do=exit

taskkill /F /IM java.exe

goto success

:usage
echo Required argument tool id missing
goto success

:sendmqMissingError
echo sendmq.exe not found at %ASHLHOME%\bin

:success
cd %~dp0
exit /b