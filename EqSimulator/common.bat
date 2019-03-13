@echo off

rem Startup script for testing. Will start ACI nameserver, equipment 
rem server and simulator.

rem The setting below may need to be an IP address if you're off the network.
rem See README.txt for info.
set ACI_CONF=%COMPUTERNAME%:1500
set LOG_DIR=%~dp0Logs\%TOOL_ID%
set CONFIG_DIR=%~dp0Config
set CONFIG_DIR=%CONFIG_DIR:\=/%

set EQSRV_NAME=%TOOL_ID%srv
set EQSRV_DIR=%~dp0Eqsrv
set EQSRV_DIR=%EQSRV_DIR:\=/%

set EQSIM_NAME=%TOOL_ID%gw

set ASHLHOME=%~dp0Rudolph\AutoShell\ashl3.10.0
set ASHLHOME_FS=%ASHLHOME:\=/%
set TCL_LIBRARY=%ASHLHOME_FS%/tcl85
set TK_LIBRARY=%ASHLHOME_FS%/tk85
set ASTK_DIR=%ASHLHOME_FS%/astk

exit /b