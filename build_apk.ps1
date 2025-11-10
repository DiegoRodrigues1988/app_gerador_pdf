# Script para buildar APK em Release Mode - Windows PowerShell
# Execute: .\build_apk.ps1

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   PDF fácil - APK Release Builder      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host ""
Write-Host "Verificando Flutter..." -ForegroundColor Yellow
flutter --version

Write-Host ""
Write-Host "Limpando build anterior..." -ForegroundColor Yellow
flutter clean

Write-Host ""
Write-Host "Baixando dependências..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "Gerando APK de Release..." -ForegroundColor Yellow
flutter build apk --release

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ APK Gerado com Sucesso!          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green

Write-Host ""
Write-Host "📍 Localização do APK:" -ForegroundColor Cyan
Write-Host "build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor White

Write-Host ""
Write-Host "Abrindo pasta do APK..." -ForegroundColor Yellow
$apkPath = "$PSScriptRoot\build\app\outputs\flutter-apk"
if (Test-Path $apkPath) {
    explorer $apkPath
} else {
    Write-Host "⚠️  Pasta não encontrada. Verifique se o build foi bem-sucedido." -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 Agora você pode compartilhar o APK via WhatsApp!" -ForegroundColor Green
