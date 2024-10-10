:: batch file

:: warning: case-sensitive

@echo off

SET SERIAL_NUMBER=%1
if "%3"=="" (SET CMD=%2) else (SET CMD=%2,%3)

echo %CMD:~1,-1%>cmd.txt
set "FILENAME=%cd%\cmd.txt"

cd "..\..\python\Sivers"

python -i evk.py -s %SERIAL_NUMBER% <"%FILENAME%"
