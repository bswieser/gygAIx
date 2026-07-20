@echo off
setlocal

:: Check if an argument was provided
if "%~1"=="" (
    echo Usage: rescale.bat ^<image_file^>
    exit /b 1
)

:: Define a temporary PowerShell script path
set "ps_script=%temp%\rescale_temp.ps1"

:: Build the PowerShell script dynamically
echo param($ImagePath) > "%ps_script%"
echo Add-Type -AssemblyName System.Drawing >> "%ps_script%"
echo $File = Get-Item $ImagePath -ErrorAction Stop >> "%ps_script%"
echo $Img = [System.Drawing.Image]::FromFile($File.FullName) >> "%ps_script%"
:: Calculate 25%% scale (ensuring it's at least 1x1 pixel to avoid crashes)
echo $NewW = [Math]::Max([int]($Img.Width * 0.25), 1) >> "%ps_script%"
echo $NewH = [Math]::Max([int]($Img.Height * 0.25), 1) >> "%ps_script%"
echo $Bmp = New-Object System.Drawing.Bitmap($NewW, $NewH) >> "%ps_script%"
echo $Graphics = [System.Drawing.Graphics]::FromImage($Bmp) >> "%ps_script%"
:: Fill background white in case the input is a transparent PNG or GIF
echo $Graphics.Clear([System.Drawing.Color]::White) >> "%ps_script%"
:: High-quality scaling algorithm
echo $Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic >> "%ps_script%"
echo $Graphics.DrawImage($Img, 0, 0, $NewW, $NewH) >> "%ps_script%"
:: Set up JPEG Encoder and moderate compression (Quality = 60/100)
echo $EncoderInfo = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() ^| Where-Object { $_.MimeType -eq 'image/jpeg' } >> "%ps_script%"
echo $EncoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1) >> "%ps_script%"
echo $EncoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 60L) >> "%ps_script%"
:: Construct output filename and save
echo $OutPath = Join-Path $File.DirectoryName "$($File.BaseName)-rescaled.jpg" >> "%ps_script%"
echo $Bmp.Save($OutPath, $EncoderInfo, $EncoderParams) >> "%ps_script%"
:: Release memory locks on the files
echo $Graphics.Dispose() >> "%ps_script%"
echo $Bmp.Dispose() >> "%ps_script%"
echo $Img.Dispose() >> "%ps_script%"
echo Write-Host "Success: Saved downscaled JPG to $OutPath" -ForegroundColor Green >> "%ps_script%"

:: Execute the temporary PowerShell script with the provided argument
powershell -NoProfile -ExecutionPolicy Bypass -File "%ps_script%" "%~1"

:: Cleanup the temporary file
del "%ps_script%"
