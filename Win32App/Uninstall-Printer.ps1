<#
.Synopsis
Created on:   31/12/2021
Created by:   Ben Whitmore
Filename:     Remove-Printer.ps1

powershell.exe -executionpolicy bypass -file .\Remove-Printer.ps1 -PrinterName "Canon Printer Upstairs"

.Example
.\Remove-Printer.ps1 -PrinterName "Canon Printer Upstairs"
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $True)]
    [String]$PortName,
    [Parameter(Mandatory = $True)]
    [String]$PrinterIP,
    [Parameter(Mandatory = $True)]
    [String]$PrinterName,
    [Parameter(Mandatory = $True)]
    [String]$DriverName
)

function Write-LogEntry {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Value,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "$($PrinterName)-uninstall.log",
        [switch]$Stamp
    )

    #Build Log File appending System Date/Time to output
    $LogFile = Join-Path -Path $env:ProgramData -ChildPath $("Microsoft\IntuneManagementExtension\Logs\$FileName")
    $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), " ", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))
    $Date = (Get-Date -Format "MM-dd-yyyy")

    If ($Stamp) {
        $LogText = "<$($Value)> <time=""$($Time)"" date=""$($Date)"">"
    }
    else {
        $LogText = "$($Value)"   
    }
	
    Try {
        Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFile -ErrorAction Stop
    }
    Catch [System.Exception] {
        Write-Warning -Message "Unable to add log entry to $LogFile.log file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

Write-LogEntry -Value "##################################"
Write-LogEntry -Stamp -Value "Uninstall started"
Write-LogEntry -Value "##################################"
Write-LogEntry -Value "Uninstall Printer using the following values..."
Write-LogEntry -Value "Port Name: $PortName"
Write-LogEntry -Value "Printer Name: $PrinterName"
Write-LogEntry -Value "Driver Name: $DriverName"

$INFARGS = @(
    "/delete-driver"
    "$INFFile"
)

Try {
    #Remove Printer
    $PrinterExist = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    if ($PrinterExist) {
        Remove-Printer -Name $PrinterName -Confirm:$false
        Remove-PrinterDriver -Name $DriverName -Confirm:$false
        Remove-PrinterPort -Name $PortName
        Start-Process pnputil.exe -ArgumentList $INFARGS -wait -passthru
    }
}
Catch {
    Write-Warning "Error removing Printer"
    Write-Warning "$($_.Exception.Message)"
    Write-LogEntry -Stamp -Value "Error removingPrinter"
    Write-LogEntry -Stamp -Value "$($_.Exception)"
}