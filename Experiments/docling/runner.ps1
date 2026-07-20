# 1. Set the memory limits so Docling doesn't crash on large layouts
$env:DOCLING_CORE_MAX_IMAGE_DECODED_SIZE="524288000"
$env:MAX_IMAGE_DECODED_SIZE="524288000"

Write-Host "Searching for dmg-*.png files..." -ForegroundColor Cyan

# 2. Get all matching files in the current folder
$files = Get-ChildItem -Filter "dmg-*.png"

if ($files.Count -eq 0) {
    Write-Host "No files found matching the pattern." -ForegroundColor Red
    exit
}

# 3. Sort the files numerically based on 'X' (so dmg-2 comes before dmg-10)
$sortedFiles = $files | Sort-Object { [int]($_.BaseName -replace 'dmg-','') }

Write-Host "Found $($sortedFiles.Count) files to check." -ForegroundColor Cyan
Write-Host "----------------------------------------"

# 4. Loop through each file
foreach ($file in $sortedFiles) {
    
    # Construct the expected JSON filename (e.g., dmg-97.json)
    $expectedJson = $file.BaseName + ".json"
    
    # 5. Check if the JSON already exists
    if (Test-Path $expectedJson) {
        Write-Host "[-] Skipping $($file.Name) - $expectedJson already exists." -ForegroundColor DarkGray
    } 
    else {
        Write-Host "[+] Processing $($file.Name)..." -ForegroundColor Green
        
        # 6. Call Docling
        # Note: We use cmd /c here to ensure PowerShell waits for the Python process to finish
        cmd /c "docling $($file.Name) --to json --image-export-mode referenced"
        
        Write-Host "    Finished $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "----------------------------------------"
Write-Host "All processing complete!" -ForegroundColor Cyan
