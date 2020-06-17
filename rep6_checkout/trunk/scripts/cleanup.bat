::Cleanup script to clean diretories created during
:: Short Build.
::Created By Amit Kalia Date:19/10/2011

@echo off
set dir=%1%
set time=%2%

::Diredctory where tje logs will be stored
set logfile=C:\tools\cleanup.log

::usage:-cleanup.bat <directory to search for> <timestamp>
::Command to cleaup the files by timestamp

ForFiles /P "%dir%" /D -%time% /C "CMD /C if @ISDIR==TRUE echo RD /Q /S @FILE &RD /Q /S @FILE" >%logfile% 2>&1
