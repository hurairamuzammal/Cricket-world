$ErrorActionPreference = "Stop"

$blobsDir = Join-Path $PSScriptRoot "..\blobs"
if (-not (Test-Path $blobsDir)) {
    New-Item -ItemType Directory -Path $blobsDir | Out-Null
    Write-Host "Created blobs directory at $blobsDir"
}

$dllUrl = "https://github.com/am15h/tflite_flutter_helper/raw/master/src/tflite_flutter_helper/libtensorflowlite_c-win.dll"
$outputPath = Join-Path $blobsDir "libtensorflowlite_c-win.dll"

Write-Host "Downloading libtensorflowlite_c-win.dll from $dllUrl..."
Invoke-WebRequest -Uri $dllUrl -OutFile $outputPath

if (Test-Path $outputPath) {
    Write-Host "Successfully downloaded to $outputPath"
} else {
    Write-Error "Failed to download file."
}
