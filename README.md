# coselig_staff_portal

Coselig Staff Portal — 前端（Flutter）專案。

簡短說明

- 這是 Coselig 人員入口網站的 Flutter 前端程式碼，包含 Web 與多平台建置設定。

快速開始

前置需求

- 已安裝 Flutter SDK（建議使用穩定版）。

取得相依套件

```bash
flutter pub get
```

開發（本機測試）

```bash
flutter run -d chrome
```

建置（Web - 釋出）

```bash
flutter build web --release
```

若要建置 Android / iOS / Windows 等平台，請使用相對應的 `flutter build` 指令。

專案結構（重點）

- `lib/`：主要 Dart 程式碼（頁面、元件、服務等）。
- `web/`：Web 相關資源（index.html、icons、manifest）。
- `android/`, `ios/`, `windows/`, `macos/`, `linux/`：各平台原生設定與建置檔。
- `assets/`：圖片、字型等靜態資源。

貢獻

- 請在開始開發前先開 issue 或跟專案負責人確認需求。
- 提交 PR 前請確保格式化與基本測試通過。

授權

如有 LICENSE 檔請參閱，或聯絡專案擁有者取得詳細授權資訊。

聯絡

如需協助或有問題，請聯絡專案維護者或在 repository 中建立 issue。

部署腳本範例（`deploy.ps1`）

下面是後端專案中用來自動建置與部署前端的 PowerShell 腳本 `deploy.ps1`，可作為參考：

```powershell
# deploy.ps1
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# param([string]$version, [string]$buildNumber)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pubspec = Join-Path $scriptDir "..\coselig_staff_portal_frontend\pubspec.yaml"

if (-not $version) {
 $fullVer = (Select-String -Path $pubspec -Pattern '^version:\s*(\S+)').Matches[0].Groups[1].Value
 $parts = $fullVer -split '\+'
 $version = $parts[0]
 $buildNumber = if ($parts[1]) { $parts[1] } else { 1 }
}

Write-Host "======================================"
Write-Host "Coselig Staff System Auto Deployment"
Write-Host "Version: $version (Build #$buildNumber)"
Write-Host "======================================"

Write-Host ""
Write-Host "[1/4] Building Flutter Frontend..."
$frontendDir = Join-Path $scriptDir "..\coselig_staff_portal_frontend"
Set-Location $frontendDir
$cmd = "flutter build web --release --build-name=$version --build-number=$buildNumber"
Write-Host "Running: $cmd"
& flutter build web --release --build-name=$version --build-number=$buildNumber
if ($LASTEXITCODE -ne 0) {
 Write-Host "Build failed!"
 Read-Host "Press Enter to exit"
 exit 1
}
Write-Host "Step 1 completed"

Write-Host ""
Write-Host "[2/4] Generating asset list..."
$backendDir = 'D:\workspace\coselig_staff_portal_backend'
Set-Location $backendDir
& node upload.js
if ($LASTEXITCODE -ne 0) {
 Write-Host "Asset list generation failed!"
 Read-Host "Press Enter to exit"
 exit 1
}
Write-Host "Step 2 completed"

Write-Host ""
Write-Host "[3/4] Uploading static files to KV..."
$assetsPath = 'D:\workspace\coselig_staff_portal_backend\assets.json'
Write-Host "assetsPath: $assetsPath"
& npx wrangler kv bulk put $assetsPath --namespace-id e7ff4caa1f96456aadc4c1c5bf71b584 --remote
if ($LASTEXITCODE -ne 0) {
 Write-Host "Upload failed!"
 Read-Host "Press Enter to exit"
 exit 1
}
Write-Host "Step 3 completed"

Write-Host ""
Write-Host "[4/4] Deploying Workers..."
& npx wrangler deploy
if ($LASTEXITCODE -ne 0) {
 Write-Host "Deployment failed!"
 Read-Host "Press Enter to exit"
 exit 1
}
Write-Host "Step 4 completed"

Write-Host ""
Write-Host "======================================"
Write-Host "Deployment successful! Version: $version (Build #$buildNumber)"
Write-Host "Access: https://employeeservice.coseligtest.workers.dev"
Write-Host "======================================"

Write-Host ""
Write-Host "Updating version number..."
$nextBuildNumber = [int]$buildNumber + 1
$nextVersion = "$version+$nextBuildNumber"
(Get-Content $pubspec) -replace '^version:\s*\S+', "version: $nextVersion" | Set-Content $pubspec
Write-Host "Next deployment version will be: $nextVersion"

Read-Host "Press Enter to exit"
```

注意：請在使用前確認 `frontend` 與 `backend` 的工作目錄路徑、KV namespace id 與 `upload.js` 設定是否符合您的環境。
