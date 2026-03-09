:: bsky-clear.bat
:: Fires when your stream ends. Update the script path below.
@echo off
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\YourName\path\to\bsky-live-status.ps1" -Mode clear
