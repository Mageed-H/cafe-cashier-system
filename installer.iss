; ═══════════════════════════════════════════════════════════════
; نظام كاشير لمة كافيه - Inno Setup Script
; Lumah Cafe POS System - Windows Installer
; ═══════════════════════════════════════════════════════════════

[Setup]
; معلومات التطبيق
AppName=نظام كاشير لمة كافيه
AppVersion=1.0.0
AppVerName=نظام كاشير لمة كافيه 1.0.0
AppPublisher=Software Engineering by Abd-Almajeed Hameed
AppPublisherURL=https://github.com/Mageed-H/cafe-cashier-system
AppSupportURL=https://github.com/Mageed-H/cafe-cashier-system
AppUpdatesURL=https://github.com/Mageed-H/cafe-cashier-system
AppContact=07764567567

; المجلد الافتراضي والملفات
DefaultDirName={pf}\LumahCashier
DefaultGroupName=نظام كاشير لمة كافيه
AllowNoIcons=yes
OutputDir=build\windows\runner\Release
OutputBaseFilename=LumahCashier-Setup-1.0.0
SetupIconFile=assets\logo.png
UninstallIconFile=assets\logo.png
WizardStyle=modern
WizardImageFile=compiler:WizardImage.bmp
WizardSmallImageFile=compiler:WizardSmallImage.bmp

; الأمان والتثبيت
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=commandline
Compression=lzma2
SolidCompression=yes
ChangesAssociations=no
ChangesEnvironment=no
DisableProgramGroupPage=auto
DisableReadyPage=no
DisableFinishedPage=no
LicenseFile=LICENSE.txt

; اللغات المدعومة
LanguageDetectionMethod=locale
ShowLanguageDialog=auto
DefaultLanguage=english

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"

; ═══════════════════════════════════════════════════════════════
; الملفات المراد نسخها
; ═══════════════════════════════════════════════════════════════

[Files]
; الملف التنفيذي الرئيسي
Source: "build\windows\runner\Release\test_project.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion

; كل ملفات DLL والموارد
Source: "build\windows\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; الشعار والموارد
Source: "assets\logo.png"; DestDir: "{app}\assets"; Flags: ignoreversion

; قاعدة البيانات (إن وجدت)
Source: "build\windows\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; ملفات التوثيق
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion isreadme

; ═══════════════════════════════════════════════════════════════
; اختصارات القائمة والسطح
; ═══════════════════════════════════════════════════════════════

[Icons]
; اختصارات البداية
Name: "{group}\نظام كاشير لمة كافيه"; Filename: "{app}\test_project.exe"; Comment: "تشغيل نظام الكاشير"; WorkingDir: "{app}"
Name: "{group}\إلغاء التثبيت"; Filename: "{uninstallexe}"; Comment: "حذف البرنامج"

; اختصار سطح المكتب
Name: "{commondesktop}\نظام كاشير لمة كافيه"; Filename: "{app}\test_project.exe"; Comment: "نظام إدارة المقهى والألعاب"; WorkingDir: "{app}"

; ═══════════════════════════════════════════════════════════════
; تشغيل البرنامج بعد التثبيت
; ═══════════════════════════════════════════════════════════════

[Run]
Filename: "{app}\test_project.exe"; Description: "تشغيل نظام الكاشير الآن"; Flags: nowait postinstall skipifsilent unchecked

; ═══════════════════════════════════════════════════════════════
; تنظيف الملفات عند الحذف
; ═══════════════════════════════════════════════════════════════

[UninstallDelete]
Type: dirifempty; Name: "{app}\assets"
Type: dirifempty; Name: "{app}\data"
Type: dirifempty; Name: "{app}"

; ═══════════════════════════════════════════════════════════════
; كود مخصص (إضافي)
; ═══════════════════════════════════════════════════════════════

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
end;

procedure InitializeWizard();
begin
  // يمكن إضافة كود إضافي هنا
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
end;
