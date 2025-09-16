# Setup-ScheduledTask.ps1
# This script sets up a Windows scheduled task to periodically update the GalleryMD container

# Configuration
$taskName = "GalleryMD-DockerUpdate"
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Update-GalleryMD.ps1"
$frequency = "HOURLY"  # Options: MINUTE, HOURLY, DAILY, WEEKLY, MONTHLY
$interval = 1  # How many units of the frequency to wait between runs

Write-Host "Setting up scheduled task to update GalleryMD container..." -ForegroundColor Cyan

# Create the action to run the PowerShell script
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

# Create the trigger based on frequency
switch ($frequency) {
    "MINUTE" {
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $interval)
    }
    "HOURLY" {
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours $interval)
    }
    "DAILY" {
        $trigger = New-ScheduledTaskTrigger -Daily -At (Get-Date -Hour 0 -Minute 0 -Second 0) -DaysInterval $interval
    }
    "WEEKLY" {
        $trigger = New-ScheduledTaskTrigger -Weekly -At (Get-Date -Hour 0 -Minute 0 -Second 0) -WeeksInterval $interval
    }
    default {
        Write-Host "Invalid frequency. Using HOURLY." -ForegroundColor Yellow
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)
    }
}

# Set up the principal (run as current user)
$principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType S4U -RunLevel Highest

# Register the task
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Description "Updates GalleryMD Docker container with the latest image from Docker Hub"

Write-Host "Scheduled task '$taskName' created successfully!" -ForegroundColor Green
Write-Host "The container will be updated $frequency (every $interval unit(s))" -ForegroundColor Cyan
Write-Host "To modify the schedule, use Windows Task Scheduler" -ForegroundColor Yellow