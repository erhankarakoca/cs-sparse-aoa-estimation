:: batch file

:: warning: case-sensitive

call "C:\Users\yaser.yagan\AppData\Local\anaconda3\Scripts\activate.bat"

@echo off

SET SERIAL_NUMBER=%1
if "%3"=="" (SET CMD=%2) else (SET CMD=%2,%3)

echo %CMD:~1,-1%>cmd.txt
set "FILENAME=%cd%\cmd.txt"

cd "..\..\python\Sivers"

python -i evk.py -s %SERIAL_NUMBER% <"%FILENAME%"
