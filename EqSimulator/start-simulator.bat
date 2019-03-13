@echo off

rem Startup script for testing. 

if [%1]==[] goto usage
goto continue

:continue
set TOOL_ID=%1
set EQSIM_NAME=%TOOL_ID%sim

mkdir Logs\%TOOL_ID%
cd Logs\%TOOL_ID%

start /B %ASHLHOME%\bin\tcleqsrv name=%EQSIM_NAME% toolid=%TOOL_ID% startup=../../Eqsrv/eqsrvsim.xsu
timeout /t 2 /nobreak

echo.
echo Configuring equipment simulator
%ASHLHOME%\bin\sendmq %EQSIM_NAME% do="set sys\>msg_dest=%TOOL_ID%gwsim"
%ASHLHOME%\bin\sendmq %EQSIM_NAME% do="remove sys\>eq\>eqid"
%ASHLHOME%\bin\sendmq %EQSIM_NAME% do="set sys\>eq\>eqid\>%TOOL_ID%\>sxid=0"
%ASHLHOME%\bin\sendmq %EQSIM_NAME% do="initialize"

goto success

:usage
echo Required argument tool id missing
goto success

:success
cd %~dp0
exit /b
