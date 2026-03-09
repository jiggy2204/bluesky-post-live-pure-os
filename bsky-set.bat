:: bsky-set.bat
:: Fires when your stream starts. Update the script path below.
@echo off
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\YourName\path\to\bsky-live-status.ps1" -Mode set
