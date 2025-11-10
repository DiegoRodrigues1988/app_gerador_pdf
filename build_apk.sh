#!/bin/bash
# Script para buildar APK em Release Mode - Linux/Mac
# Execute: bash build_apk.sh

echo "╔════════════════════════════════════════╗"
echo "║   PDF fácil - APK Release Builder      ║"
echo "╚════════════════════════════════════════╝"
echo ""

echo "Verificando Flutter..."
flutter --version

echo ""
echo "Limpando build anterior..."
flutter clean

echo ""
echo "Baixando dependências..."
flutter pub get

echo ""
echo "Gerando APK de Release..."
flutter build apk --release

echo ""
echo "╔════════════════════════════════════════╗"
echo "║   ✅ APK Gerado com Sucesso!          ║"
echo "╚════════════════════════════════════════╝"

echo ""
echo "📍 Localização do APK:"
echo "build/app/outputs/flutter-apk/app-release.apk"

echo ""
echo "🎉 Agora você pode compartilhar o APK via WhatsApp!"
