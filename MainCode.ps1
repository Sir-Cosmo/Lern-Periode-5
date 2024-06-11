$sourceFolder = "C:\Users\Tom School\Pictures\Screenshots"
$targetFolder = "C:\Users\Tom School\Pictures\Bilder_Sortiert"
$logFile = "C:\Users\Tom School\Pictures\log.txt"

# Create the log file if it doesn't exist
if (-not (Test-Path -Path $logFile)) {
    New-Item -ItemType File -Path $logFile -Force | Out-Null
}

function Log-Action {
    param(
        [string]$Action,
        [string]$FilePath
    )

    $timestamp = Get-Date
    $logEntry = "$timestamp - $Action"

    if ($FilePath -ne "") {
        $logEntry += ": $FilePath"
    }

    Add-Content -Path $logFile -Value $logEntry  # Append to the log file
}

# Get all files with supported extensions
Get-ChildItem $sourceFolder -Recurse -File | Where-Object {
    $_.Extension -in @(".png", ".jpg", ".jpeg")
} | ForEach-Object {
    # Get Date (from metadata or file attributes)
    $dateTaken = $null
    if ($_.PropertyItems -and $_.PropertyItems.Count -gt 0) {
        $dateProperty = $_.PropertyItems | Where-Object { $_.Id -eq 36867 }
        if ($dateProperty) {
            $dateTakenString = [System.Text.Encoding]::ASCII.GetString($dateProperty.Value[0..18]).TrimEnd([char]0)
            # Attempt to parse the date string
            try {
                $dateTaken = [datetime]::ParseExact($dateTakenString, "yyyy:MM:dd HH:mm:ss", $null)
            } catch {
                # Log the failure and fall back to LastWriteTime
                Log-Action "Failed to parse date from metadata, falling back to LastWriteTime" $_.FullName
                $dateTaken = $_.LastWriteTime
            }
        } else {
            $dateTaken = $_.LastWriteTime
        }
    } else {
        $dateTaken = $_.LastWriteTime
    }

    # Ensure $dateTaken is not null
    if (-not $dateTaken) {
        Log-Action "Failed to determine date for file" $_.FullName
        continue
    }

    # Create Year and Month Folders (if they don't exist)
    $yearFolder = Join-Path $targetFolder ($dateTaken.Year)
    $monthFolder = Join-Path $yearFolder ($dateTaken.ToString("MMMM"))

    if (-not (Test-Path $yearFolder)) {
        New-Item -ItemType Directory -Path $yearFolder
        Log-Action "Created folder" $yearFolder  # Log folder creation
    }

    if (-not (Test-Path $monthFolder)) {
        New-Item -ItemType Directory -Path $monthFolder
        Log-Action "Created folder" $monthFolder  # Log folder creation
    }

    # Move Screenshot
    Move-Item -Path $_.FullName -Destination $monthFolder
    Log-Action "Moved file" $_.FullName  # Log file move
}
