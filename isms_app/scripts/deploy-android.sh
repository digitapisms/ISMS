#!/bin/bash
# ISMS Android App Deployment Script
# Deploys to Google Play Store

set -e

echo "🚀 ISMS Android Deployment Script"
echo "=================================="

# Check prerequisites
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed."
    exit 1
fi

if ! command -v fastlane &> /dev/null; then
    echo "⚠️  Fastlane not found. Installing..."
    gem install fastlane
fi

# Build Android app
echo ""
echo "📦 Building Android app..."
flutter clean
flutter pub get
flutter build appbundle --release

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# Deploy to Play Store
echo ""
echo "🚀 Deploying to Google Play Store..."
cd android
fastlane deploy
cd ..

echo ""
echo "✅ Deployment complete!"

