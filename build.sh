#!/bin/bash

set -e  # Останавливаться при ошибках

echo "🚀 Начинаем сборку iOS IPA без подписи..."

# Получаем информацию о SDK
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
echo "📱 iOS SDK path: $SDK_PATH"

# Очищаем предыдущие сборки
rm -rf Payload
rm -f ClickerApp
rm -f ClickerApp.ipa

# Создаем структуру папок
mkdir -p Payload/ClickerApp.app

echo "🔨 Компилируем Swift код..."
# Компилируем Swift код с правильным таргетом
xcrun swiftc ClickerApp.swift \
  -sdk "$SDK_PATH" \
  -target arm64-apple-ios17.0 \
  -o ClickerApp \
  -framework UIKit \
  -framework Foundation \
  -L "$SDK_PATH/usr/lib" \
  -I "$SDK_PATH/usr/include" \
  -Xlinker -dead_strip

# Проверяем что бинарник создан
if [ ! -f "ClickerApp" ]; then
    echo "❌ Ошибка: бинарник не создан"
    exit 1
fi

echo "✅ Бинарник успешно скомпилирован"
ls -la ClickerApp

echo "📦 Копируем бинарник..."
cp ClickerApp Payload/ClickerApp.app/
chmod +x Payload/ClickerApp.app/ClickerApp

echo "📝 Создаем Info.plist..."
cat > Payload/ClickerApp.app/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>ClickerApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.ClickerApp</string>
    <key>CFBundleInfo极ctionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</极>
    <string>ClickerApp</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>MinimumOSVersion</key>
    <string>17.0</string>
</dict>
</plist>
EOF

echo "🖼️ Создаем PkgInfo..."
echo "APPL????" > Payload/ClickerApp.app/PkgInfo

echo "📦 Создаем IPA..."
cd Payload
echo "Содержимое папки перед созданием IPA:"
ls -la ClickerApp.app/
zip -qr ../ClickerApp.ipa .
cd ..

echo "✅ Проверяем IPA..."
if [ ! -f "ClickerApp.ipa" ]; then
    echo "❌ Ошибка: IPA не создан"
    exit 1
fi

IPA_SIZE=$(du -h ClickerApp.ipa | cut -f1)
echo "📊 Размер IPA: $IPA_SIZE"

echo "📁 Содержимое IPA:"
unzip -l ClickerApp.ipa

# Очистка
rm -rf Payload
rm -f ClickerApp

echo "🎉 Сборка завершена успешно!"
echo "📦 Файл: ClickerApp.ipa ($IPA_SIZE)"
