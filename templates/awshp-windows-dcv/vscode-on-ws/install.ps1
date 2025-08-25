function Download-VSCode {
    param ()
    Write-Output "[INFO] Starting Download-VSCode function"

    $downloads = @(
        @{
            Name = "VSCode"
            Required = $true
            Path = "C:\Users\Administrator\VSCodeSetup-x64-1.95.0.exe"
            Uri = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
        }
    )

    foreach ($download in $downloads) {
        if ($download.Required -and -not (Test-Path $download.Path)) {
            try {
                Write-Output "[INFO] Downloading $($download.Name)"

                # Display progress manually (no events)
                $progressActivity = "Downloading $($download.Name)"
                $progressStatus = "Starting download..."
                Write-Progress -Activity $progressActivity -Status $progressStatus -PercentComplete 0

                # Synchronously download the file
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($download.Uri, $download.Path)

                # Update progress
                Write-Progress -Activity $progressActivity -Status "Completed" -PercentComplete 100

                Write-Output "[INFO] $($download.Name) downloaded successfully."
            } catch {
                Write-Output "[ERROR] Failed to download $($download.Name): $_"
                throw
            }
        } else {
            Write-Output "[INFO] $($download.Name) already exists. Skipping download."
        }
    }

    Write-Output "[INFO] All downloads completed"
    Read-Host "[DEBUG] Press Enter to proceed to the next step"
}


function Install-VSCode {
    param ()
    Write-Output "[INFO] Starting Install-VSCode function"

    $download_path = "C:\Users\Administrator\VSCodeSetup-x64-1.95.0.exe"
    
    Write-Output "[INFO] Installing VSCode"
    Start-Process -FilePath $download_path -Argument "/VERYSILENT /MERGETASKS=!runcode,desktopicon" -Wait
}

# Main Script Execution
Write-Output "[INFO] Starting script"
Download-VSCode
Install-VSCode
Write-Output "[INFO] Script completed"