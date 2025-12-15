#!/bin/bash
# ISMS Web Deployment Script
# Supports: Vercel, Netlify, Firebase Hosting

set -e

echo "🚀 ISMS Web Deployment Script"
echo "================================"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Get deployment target
echo ""
echo "Select deployment target:"
echo "1) Vercel"
echo "2) Netlify"
echo "3) Firebase Hosting"
echo "4) Build only (no deploy)"
read -p "Enter choice (1-4): " choice

# Build Flutter web app
echo ""
echo "📦 Building Flutter web app..."
flutter clean
flutter pub get
flutter build web --release

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# Deploy based on choice
case $choice in
    1)
        echo ""
        echo "🚀 Deploying to Vercel..."
        if ! command -v vercel &> /dev/null; then
            echo "Installing Vercel CLI..."
            npm install -g vercel
        fi
        cd build/web
        vercel --prod
        ;;
    2)
        echo ""
        echo "🚀 Deploying to Netlify..."
        if ! command -v netlify &> /dev/null; then
            echo "Installing Netlify CLI..."
            npm install -g netlify-cli
        fi
        netlify deploy --prod --dir=build/web
        ;;
    3)
        echo ""
        echo "🚀 Deploying to Firebase Hosting..."
        if ! command -v firebase &> /dev/null; then
            echo "Installing Firebase CLI..."
            npm install -g firebase-tools
        fi
        firebase deploy --only hosting
        ;;
    4)
        echo ""
        echo "✅ Build complete! Files are in build/web/"
        echo "You can manually deploy the build/web folder to your hosting provider."
        ;;
    *)
        echo "❌ Invalid choice!"
        exit 1
        ;;
esac

echo ""
echo "✅ Deployment complete!"

