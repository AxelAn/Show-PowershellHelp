@ECHO OFF
PowerShell.exe -WindowStyle Hidden -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-STA -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File ""%~dpn0.ps1""' -Verb RunAs}"
