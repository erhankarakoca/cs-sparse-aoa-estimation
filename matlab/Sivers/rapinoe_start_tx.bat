:: batch file

:: warning: case-sensitive

call "C:\Users\yaser.yagan\AppData\Local\anaconda3\Scripts\activate.bat"

@echo off

SET SERIAL_NUMBER=%1

cd "..\..\python\Sivers"

set "FILENAME=%cd%\tx_config.txt"

python tx_setup.py

python -i evk.py -s %SERIAL_NUMBER% < "%FILENAME%"
