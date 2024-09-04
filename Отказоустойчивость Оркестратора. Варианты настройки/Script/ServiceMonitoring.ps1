# Скрипт осуществляет мониторинг статуса служб на удаленном сервере и включение / выключение соответствующих служб на локальном сервере

# Конфигурация
$primaryServer = "192.168.1.1" # IP-адрес основного (удаленного) сервера
$serviceNames = "Primo.Orchestrator.RDP2", "Primo,Orchestrator.States" # Названия служб через запятую
$checkInterval = 10 # Интервал проверки в секундах

# Учетные данные администратора
$username = "User1" # Имя пользователя администратора
$password = "Qwe123!@#" | ConvertTo-SecureString -AsPlainText -Force # Пароль
$credential = New-Object System.Management.Automation.PSCredential ($username, $password)

function Check-ServiceStatus {
    param (
        [string]$server,
        [string]$service,
        [PSCredential]$credential
    )
    
    try {
        Write-Host "Attempting to check status of service '$service' on server '$server'..."
        $scriptBlock = {
            param($serviceName)
            $serviceStatus = Get-Service -Name $serviceName
            return $serviceStatus
        }
        
        $serviceStatus = Invoke-Command -ComputerName $server -ScriptBlock $scriptBlock -ArgumentList $service -Credential $credential -ErrorAction Stop
        Write-Host "Service status on server '$server': $($serviceStatus.Status)"
        if ($serviceStatus.Status -eq 'Running') {
            return $true
        } else {
            return $false
        }
    } catch {
        Write-Error "Error checking service status on server '$server': $_"
        return $false
    }
}

function Start-ServiceLocally {
    param (
        [string]$service
    )
    
    try {
        Write-Host "Attempting to start service '$service' on the local server..."
        $serviceStatus = Get-Service -Name $service -ErrorAction Stop
        if ($serviceStatus.Status -ne 'Running') {
            Start-Service -Name $service
            Write-Host "Service '$service' was successfully started on the local server."
        } else {
            Write-Host "Service '$service' is already running on the local server."
        }
    } catch {
        Write-Error "Error starting service '$service' on the local server: $_"
    }
}

function Stop-ServiceLocally {
    param (
        [string]$service
    )
    
    try {
        Write-Host "Attempting to stop service '$service' on the local server..."
        $serviceStatus = Get-Service -Name $service -ErrorAction Stop
        if ($serviceStatus.Status -eq 'Running') {
            Stop-Service -Name $service
            Write-Host "Service '$service' was successfully stopped on the local server."
        } else {
            Write-Host "Service '$service' is not running on the local server."
        }
    } catch {
        Write-Error "Error stopping service '$service' on the local server: $_"
    }
}

while ($true) {
	foreach ($serviceName in $serviceNames) {
		Write-Host "Checking service '$serviceName' status on primary server '$primaryServer'..."
		$serviceStatus = Check-ServiceStatus -server $primaryServer -service $serviceName -credential $credential
		if (-not $serviceStatus) {
			Write-Host "Service '$serviceName' on the primary server is not running. Starting the service on the local server..."
			Start-ServiceLocally -service $serviceName
		} else {
			Write-Host "Service '$serviceName' on the primary server is running normally. Stopping the service on the local server if running..."
			Stop-ServiceLocally -service $serviceName
		}
	}
    Write-Host "Sleeping for $checkInterval seconds..."
    Start-Sleep -Seconds $checkInterval
}
