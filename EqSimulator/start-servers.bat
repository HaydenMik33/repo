@echo off

rem Startup script for testing. Will start ACI nameserver, equipment 
rem server and simulator.

if [%1]==[] goto usage
goto continue

:continue
set TOOL_ID=%1
call common.bat

rem  Check AutoShell

if EXIST %ASHLHOME%\bin\acinsd.bat goto ok1
goto acinsdMissingError
:ok1

rem  start the ACI nameserver 
echo.
echo Starting the ACI nameserver
start /B %ASHLHOME%\bin\acinsd -s -q -d -c -y DISCOVER 1500
timeout /t 10 /nobreak

rem start the equipment server
echo.
echo Starting equipment server

if EXIST %LOG_DIR% goto ok2
mkdir %LOG_DIR%
:ok2
cd %LOG_DIR%
start /B %ASHLHOME%\bin\tcleqsrv name=%TOOL_ID%srv startup=%EQSRV_DIR%/eqsrv.xsu
timeout /t 2 /nobreak

echo.
echo Configuring equipment server
%ASHLHOME%\bin\sendmq %EQSRV_NAME% do="set sys\>msg_dest=%EQSIM_NAME%"
%ASHLHOME%\bin\sendmq %EQSRV_NAME% do="remove sys\>eq\>eqid"
%ASHLHOME%\bin\sendmq %EQSRV_NAME% do="set sys\>eq\>eqid\>%TOOL_ID%\>sxid=0"

start /B %ASHLHOME%\bin\tcleqsrv name=%TOOL_ID%gw toolid=%TOOL_ID% startup=%EQSRV_DIR%/eqsrvsim.xsu
timeout /t 2 /nobreak

echo.
echo Configuring equipment simulator
%ASHLHOME%\bin\sendmq %EQSIM_NAME% do="set sys\>msg_dest=%EQSRV_NAME%"
%ASHLHOME%\bin\sendmq %EQSIM_NAME% do="remove sys\>eq\>eqid"
%ASHLHOME%\bin\sendmq %EQSIM_NAME% do="set sys\>eq\>eqid\>%TOOL_ID%\>sxid=0"
%ASHLHOME%\bin\sendmq %EQSIM_NAME% do="initialize file=%CONFIG_DIR%/%TOOL_ID%.xml"

echo.
echo Testing startup with an S1F1 command (areyouthere)
%ASHLHOME%\bin\sendmq %EQSRV_NAME% do="areyouthere eq=%TOOL_ID%"
echo.

goto success

:usage
echo Required argument tool id missing
goto success

:acinsdMissingError
echo acinsd.bat not found at %ASHLHOME%\bin

:success
cd %~dp0
exit /b
