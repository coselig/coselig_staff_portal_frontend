# Coselig Staff Portal — Workspace Instructions

## 專案架構與慣例

- **前端**：Flutter Web，主程式於 `lib/`，靜態資源於 `assets/`、`web/`。
- **後端**：Node.js (Cloudflare Workers)，主程式於 `src/`。
- **部署**：前後端整合，靜態檔案存於 Cloudflare KV，API 運行於同一域名。
- **版本管理**：`pubspec.yaml` 控制，build number 每次部署遞增，UI 自動顯示版本。

## 開發與建置指令

### 前端 Flutter Web
- 安裝相依：`flutter pub get`
- 本機開發：`flutter run -d chrome`
- Web 釋出：`flutter build web --release`

### 後端/部署
- 產生靜態資產清單：`node upload.js`（於 backend 執行，掃描 frontend build/web）
- 上傳靜態檔至 KV：
  - `npm exec --package=wrangler@4.68.0 -- wrangler kv bulk put assets.json --namespace-id <id>`
- 部署 Workers：
  - `npm exec --package=wrangler@4.68.0 -- wrangler deploy`

### 一鍵部署腳本
- 參考 `DEPLOY.md` 或 `deploy.ps1`/`deploy.bat`，自動化上述流程。

## 重要注意事項
- **CI/CD**：建議 wrangler 以 devDependency 或 npm exec 執行，避免全域安裝。
- **跨域 Cookie 問題**：前後端同域名部署，Session 管理更可靠。
- **KV Namespace**：需正確設定於 wrangler.jsonc，並同步於部署腳本。
- **回滾/歷史版本**：可用 wrangler CLI 查詢與回滾 Workers 部署。
- **環境需求**：Flutter 3.38.5+、Node.js 18+、Wrangler 4.54.0+

## 文件連結
- [前端 README.md](README.md)
- [後端部署與架構 DEPLOY.md](../coselig_staff_portal_backend/DEPLOY.md)

---

> 本說明僅摘要專案主要開發、建置、部署慣例。詳細操作與常見問題請參閱上述文件。
