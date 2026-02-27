# 📦 دليل بناء نسخة Windows مع Installer

## الخطوة 1️⃣: متطلبات النظام على Windows

قبل البدء، تأكد من تثبيت:
- ✅ Visual Studio 2019 أو أحدث (مع C++ build tools)
- ✅ Windows SDK
- ✅ Flutter SDK (آخر نسخة)

## الخطوة 2️⃣: بناء تطبيق Windows Release

```bash
# على جهازك Windows في الـ terminal
cd C:\path\to\test_project

# بناء النسخة Release
flutter build windows --release
```

**النتيجة:** سيتم إنشاء المجلد:
```
build/windows/runner/Release/
```

هذا المجلد يحتوي على:
- `test_project.exe` (الملف التنفيذي الرئيسي)
- ملفات DLL المطلوبة
- الموارد (assets)

---

## الخطوة 3️⃣: تثبيت Inno Setup

### الطريقة الأولى: Inno Setup (الأفضل)

1. **حمل Inno Setup** من:
   https://jrsoftware.org/isdl.php
   
2. **اختر الإصدار المناسب:**
   - `innosetup-6.x.x.exe` (for Windows)

3. **ركب البرنامج** بالطريقة العادية

### الطريقة الثانية: Windows Package Manager
```bash
choco install innosetup  # إذا كان لديك Chocolatey
```

---

## الخطوة 4️⃣: إنشاء Inno Setup Script

أنشئ ملف باسم `installer.iss` في جذر المشروع:

```ini
[Setup]
AppName=نظام كاشير لمة كافيه
AppVersion=1.0.0
AppPublisher=Software Engineering
AppPublisherURL=https://github.com/Mageed-H
DefaultDirName={pf}\LumahCashier
DefaultGroupName=نظام كاشير لمة
OutputDir=build\windows\runner\Release\
OutputBaseFilename=LumahCashier-Setup-1.0.0
SetupIconFile=assets\logo.png
WizardStyle=modern
LanguageDetectionMethod=locale
ShowLanguageDialog=auto

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"

[Files]
; الملف التنفيذي الرئيسي
Source: "build\windows\runner\Release\test_project.exe"; DestDir: "{app}"; Flags: ignoreversion

; ملفات DLL المطلوبة
Source: "build\windows\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

; الموارد والأصول
Source: "assets\*"; DestDir: "{app}\assets"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\نظام الكاشير"; Filename: "{app}\test_project.exe"; WorkingDir: "{app}"
Name: "{commondesktop}\نظام الكاشير"; Filename: "{app}\test_project.exe"; WorkingDir: "{app}"

[Run]
Filename: "{app}\test_project.exe"; Description: "تشغيل البرنامج الآن"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: dirifempty; Name: "{app}"
```

---

## الخطوة 5️⃣: تجميع الـ Installer

### الطريقة الأولى: استخدام Inno Setup GUI

1. افتح Inno Setup Compiler
2. اختر File → Open
3. اختر ملف `installer.iss`
4. اضغط Compile

### الطريقة الثانية: استخدام Command Line

```bash
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
```

**النتيجة:** سيتم إنشاء ملف:
```
LumahCashier-Setup-1.0.0.exe
```

---

## الخطوة 6️⃣: توقيع الـ Installer (اختياري لكن موصى به)

للحصول على علامة ✅ الأمان عند التثبيت:

```bash
# إذا كان لديك Digital Certificate
signtool.exe sign /f "certificate.pfx" /p "password" /t "http://timestamp.authority.com" "LumahCashier-Setup-1.0.0.exe"
```

---

## طريقة بديلة: MSIX Package (أسهل وأحدث)

```bash
# بناء MSIX Package مباشرة
flutter pub run windows_package_installer:create_msix \
  --output-path=build/windows/runner/Release/ \
  --display-name="نظام كاشير لمة" \
  --publisher-display-name="Software Engineering" \
  --identity-name="SoftwareEngineering.LumahCashierPOS"
```

هذا ينتج عنه ملف `.msix` يمكن تثبيته مباشرة على Windows 10+

---

## الملفات النهائية

بعد الانتهاء ستحصل على:

```
📁 build/windows/runner/Release/
├── test_project.exe          (التطبيق الأساسي)
├── *.dll                      (المكتبات المطلوبة)
├── assets/                    (الموارد - شعار إلخ)
└── 📦 LumahCashier-Setup-1.0.0.exe  (الـ Installer النهائي)
```

---

## خطوات التثبيت للمستخدم

1. تحميل `LumahCashier-Setup-1.0.0.exe`
2. النقر عليه مرتين
3. اتباع الخطوات البسيطة
4. اختيار مجلد التثبيت (افتراضياً: `C:\Program Files\LumahCashier`)
5. اكتمال التثبيت والتشغيل

---

## ملاحظات مهمة 📌

- تأكد من أن جميع ملفات DLL موجودة
- اختبر التطبيق على جهاز Windows قبل نشر الـ Installer
- استخدم Digital Certificate للحصول على ثقة Windows
- أضف شعار احترافي للـ Installer
- اختبر التثبيت من البداية على جهاز نظيف

---

## روابط مفيدة

- 🔗 Inno Setup: https://jrsoftware.org/
- 🔗 Flutter Windows Docs: https://docs.flutter.dev/platform-integration/windows
- 🔗 Signing Windows Apps: https://docs.microsoft.com/en-us/windows/msix/package-signing-overview

---

**تم إعداد هذا الدليل لنسخة الويندوز من نظام كاشير لمة كافيه ✅**
