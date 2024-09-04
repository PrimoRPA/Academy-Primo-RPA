Действия, которые необходимо выполнить перед запуском.

На удаленной машине:
Enable-PSRemoting -Force
Start-Service WinRM
Set-Service -Name WinRM -StartupType Automatic

На локальной машине:
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "IP адрес удаленного сервера" -Concatenate

