@echo off
REM ═══════════════════════════════════════════════════════════════
REM نظام كاشير لمة كافيه - بناء نسخة Windows
REM Lumah Cafe POS System - Windows Build Script
REM ═══════════════════════════════════════════════════════════════

echo.
echo 🔨 جاري بناء نظام كاشير لمة كافيه للويندوز...
echo Building Lumah Cashier System for Windows...
echo.

REM فحص وجود Flutter
flutter --version
if errorlevel 1 (
    echo ❌ خطأ: Flutter غير مثبت على النظام
    echo Error: Flutter is not installed
    pause
    exit /b 1
)

echo.
echo ✅ تم العثور على Flutter بنجاح
echo ✅ Flutter found successfully
echo.

REM التنظيف
echo 🧹 تنظيف البناءات السابقة...
echo Cleaning previous builds...
flutter clean
if errorlevel 1 (
    echo ⚠️ تنبيه: حدث خطأ أثناء التنظيف
    echo Warning: Error during cleanup
)

echo.
echo 📥 تحديث الاعتماديات...
echo Updating dependencies...
flutter pub get
if errorlevel 1 (
    echo ❌ خطأ: فشل تحديث الاعتماديات
    echo Error: Failed to update dependencies
    pause
    exit /b 1
)

echo.
echo 🏗️  جاري بناء نسخة Windows Release...
echo Building Windows Release version...
echo.
flutter build windows --release
if errorlevel 1 (
    echo ❌ خطأ: فشل البناء
    echo Error: Build failed
    pause
    exit /b 1
)

echo.
echo ✅ تم بناء التطبيق بنجاح!
echo ✅ Build completed successfully!
echo.

REM فحص Inno Setup
where ISCC.exe >nul 2>nul
if errorlevel 1 (
    echo.
    echo ⚠️  تنبيه: Inno Setup غير مثبت
    echo Warning: Inno Setup is not installed
    echo.
    echo 📥 يرجى تحميل Inno Setup من:
    echo Please download from: https://jrsoftware.org/isdl.php
    echo.
    echo 📁 المجلد الذي يحتوي التطبيق:
    echo Application folder: build\windows\runner\Release\
    echo.
    pause
) else (
    echo.
    echo 🔨 جاري بناء الـ Installer...
    echo Building installer...
    echo.
    ISCC.exe installer.iss
    
    if errorlevel 1 (
        echo ❌ خطأ: فشل بناء الـ Installer
        echo Error: Installer build failed
    ) else (
        echo.
        echo ✅ تم بناء الـ Installer بنجاح!
        echo ✅ Installer created successfully!
        echo.
        echo 📦 الملف النهائي:
        echo Final file: build\windows\runner\Release\LumahCashier-Setup-1.0.0.exe
        echo.
    )
    pause
)

echo.
echo ═══════════════════════════════════════════════════════════════
echo 📋 ملخص البناء:
echo Build Summary:
echo.
echo ✅ التطبيق: build\windows\runner\Release\test_project.exe
echo ✅ الـ Installer: build\windows\runner\Release\LumahCashier-Setup-1.0.0.exe
echo.
echo 🎯 الخطوة التالية: توزيع الـ Installer على المستخدمين
echo Next Step: Distribute the installer to users
echo ═══════════════════════════════════════════════════════════════
echo.

pause
