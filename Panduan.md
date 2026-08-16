# Panduan.md — DHBH POS Windows Build, Optimization, and Client Installation Guide for AI Coding Agents

> Internal engineering guide for building, packaging, installing, and running the DHBH POS Flutter application on Windows desktop client devices.
>
> This document is intended for human developers and AI coding agents working on this repository.

---

## 1. Objective

Build the DHBH POS application as a Windows desktop application that can be installed and run directly on client desktop machines.

The application must:

1. Build successfully as a Windows release binary.
2. Run on common desktop hardware, including low-end clinic PCs.
3. Connect to the live Supabase project.
4. Support cashier, admin, and employee login.
5. Support receipt printing via Windows printer or Bluetooth thermal printer where available.
6. Be packaged in a way that allows client staff to install and run it with minimal technical steps.

---

## 2. Project Facts

| Item | Value |
|---|---|
| App Name | DHBH POS |
| Flutter Package | `com.dhbh.dhbh_app` |
| Primary Target Platform | Windows Desktop |
| Architecture Pattern | Riverpod + Repository + Service + Supabase |
| Backend | Supabase |
| Supabase Project Ref | `jiunlvlcwsntjbyybszd` |
| Supabase REST URL | `https://jiunlvlcwsntjbyybszd.supabase.co/rest/v1/` |
| Supabase Config File | `lib/config/supabase_config.dart` |
| Database Mode | Online-only. Supabase is the main source of truth |
| SQLite Usage | Manual backup only. Not used for live POS operations |
| Main State Provider | `lib/providers/pos_provider.dart` |
| Main Supabase Service | `lib/services/supabase_service.dart` |
| Main POS Screen | `lib/screens/pos_screen.dart` |
| Windows Printer Service | `lib/services/windows_printer_service.dart` |
| Windows Bluetooth Printer Service | `lib/services/windows_bluetooth_printer_service.dart` |
| Error Log Location | `%TEMP%\dhbh_flutter_errors.log` |

---

## 3. AI Agent Rules

When modifying or building this project, the AI agent must follow these rules.

### 3.1 Mandatory Rules

1. Use Flutter stable with Windows desktop support.
2. Ensure Dart SDK satisfies `^3.11.5` as required by `pubspec.yaml`.
3. Always run `flutter pub get` after dependency changes.
4. Always build Windows release using `flutter build windows --release`.
5. Never call Supabase directly from screens. Use repository/service/provider layers.
6. Use Riverpod for application state. Do not use `setState()` for global state.
7. Do not remove Supabase configuration from `lib/config/supabase_config.dart` unless explicitly instructed.
8. Do not commit secrets, service role keys, database passwords, or production tokens.
9. Do not modify RLS policies unless explicitly requested.
10. Do not introduce offline-first logic unless explicitly requested. The app is currently online-only.

### 3.2 Build Goals

The agent should ensure:

1. The app compiles without errors.
2. The release executable starts successfully.
3. Login works against Supabase.
4. Products load for the logged-in user branch.
5. Cart and payment flow work.
6. Transactions can be saved to Supabase.
7. Printing does not crash when no printer is available.
8. The application remains usable on low-spec Windows machines.

---

## 4. Supabase MCP Usage

If the AI coding environment has Supabase MCP access, use it to verify live application data before and after build.

> Important:
>
> - Do not store Supabase service role keys inside this document.
> - Do not store Supabase service role keys inside the Flutter app.
> - Use Supabase MCP only from a trusted developer or agent environment.
> - Passwords cannot and must not be extracted from Supabase. Use documented default credentials or reset passwords via Supabase Auth admin process.

### 4.1 Expected MCP Connection Details

Use these non-secret identifiers:

```text
SUPABASE_PROJECT_REF=jiunlvlcwsntjbyybszd
SUPABASE_URL=https://jiunlvlcwsntjbyybszd.supabase.co
SUPABASE_REST_URL=https://jiunlvlcwsntjbyybszd.supabase.co/rest/v1/
```

Secret values such as `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ACCESS_TOKEN`, or database URL must be provided from a secure secret manager or local MCP configuration.

Example MCP server environment placeholders:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "supabase-mcp",
      "args": ["--project-ref", "jiunlvlcwsntjbyybszd"],
      "env": {
        "SUPABASE_URL": "https://jiunlvlcwsntjbyybszd.supabase.co",
        "SUPABASE_SERVICE_ROLE_KEY": "SET_FROM_SECRET_MANAGER"
      }
    }
  }
}
```

The exact MCP server command may differ depending on the installed Supabase MCP implementation.

---

## 5. Supabase MCP Validation Queries

The agent should use Supabase MCP to validate the following before packaging.

### 5.1 Check Active Branches

```sql
select
  id,
  name,
  address,
  phone,
  is_active
from public.branches
where is_active = true
order by id;
```

Expected active branches:

| Branch ID | Branch Name |
|---:|---|
| 1 | DHBH Kranggan |
| 2 | DHBH Cikampek |

### 5.2 Check Roles

```sql
select
  id,
  name,
  description
from public.user_roles
order by id;
```

Expected roles:

| Role ID | Role Name |
|---:|---|
| 1 | admin |
| 2 | kasir |
| 3 | karyawan |

### 5.3 Check Active Users

```sql
select
  coalesce(u.email, lower(regexp_replace(up.full_name, '\s+', '.', 'g')) || '@dhbh.com') as email,
  up.full_name,
  up.username,
  ur.name as role,
  b.name as branch,
  up.is_active
from public.user_profiles up
join public.user_roles ur on ur.id = up.role_id
left join public.branches b on b.id = up.branch_id
left join auth.users u on u.id = up.id
where up.is_active = true
order by b.name nulls last, ur.name, up.full_name;
```

### 5.4 Check Product Count

```sql
select count(*) as active_product_count
from public.products
where is_active = true;
```

### 5.5 Check Branch Price Overrides

```sql
select
  p.name as product_name,
  b.name as branch_name,
  pbp.price_clinic,
  pbp.price_home_visit
from public.product_branch_prices pbp
join public.products p on p.id = pbp.product_id
join public.branches b on b.id = pbp.branch_id
order by b.name, p.name;
```

---

## 6. Internal Login Credentials

> Security Notice:
>
> This section is for internal deployment and support only.
> Do not publish this file publicly.
> Rotate default passwords after production onboarding if possible.

The default staff password documented for provisioned accounts is:

```text
dhbh12345
```

This password applies to staff accounts created using the standard provisioning pattern:

```text
nama@dhbh.com
```

### 6.1 DHBH Kranggan — Branch ID 1

| Email | Default Password | Role | Branch |
|---|---|---|---|
| firdaus@dhbh.com | dhbh12345 | karyawan | DHBH Kranggan |
| herman@dhbh.com | dhbh12345 | karyawan | DHBH Kranggan |
| harsono@dhbh.com | dhbh12345 | karyawan | DHBH Kranggan |
| siti@dhbh.com | dhbh12345 | karyawan | DHBH Kranggan |
| abu@dhbh.com | dhbh12345 | karyawan | DHBH Kranggan |
| nur@dhbh.com | dhbh12345 | karyawan | DHBH Kranggan |
| amel@dhbh.com | dhbh12345 | karyawan | DHBH Kranggan |
| pramono@dhbh.com | dhbh12345 | karyawan | DHBH Kranggan |
| fadli@dhbh.com | dhbh12345 | karyawan | DHBH Kranggan |
| ikhsan@dhbh.com | dhbh12345 | karyawan | DHBH Kranggan |
| alan@dhbh.com | dhbh12345 | karyawan | DHBH Kranggan |
| yolanda@dhbh.com | dhbh12345 | karyawan | DHBH Kranggan |
| suhaemi@dhbh.com | dhbh12345 | karyawan | DHBH Kranggan |
| sohidi@dhbh.com | dhbh12345 | admin | DHBH Kranggan |
| nisa@dhbh.com | dhbh12345 | kasir | DHBH Kranggan |

### 6.2 DHBH Cikampek — Branch ID 2

| Email | Default Password | Role | Branch |
|---|---|---|---|
| dzikri@dhbh.com | dhbh12345 | karyawan | DHBH Cikampek |
| vey@dhbh.com | dhbh12345 | karyawan | DHBH Cikampek |
| dika@dhbh.com | dhbh12345 | karyawan | DHBH Cikampek |
| wartok@dhbh.com | dhbh12345 | admin | DHBH Cikampek |
| ridwan@dhbh.com | dhbh12345 | kasir | DHBH Cikampek |

### 6.3 Legacy Accounts

| Email | Default Password | Notes |
|---|---|---|
| admin@admin.com | Use Supabase password reset if unknown | Legacy admin account |
| jul@kasir.com | Use Supabase password reset if unknown | Legacy kasir account |

### 6.4 Important Password Note

Supabase MCP cannot retrieve plaintext passwords.

If an account cannot login:

1. Confirm the user exists in `auth.users`.
2. Confirm `user_profiles` exists and is active.
3. Confirm `role_id` and `branch_id` are correct.
4. Reset password using Supabase Auth admin tooling.
5. Update internal credential documentation if a new password is assigned.

---

## 7. System Requirements

### 7.1 Minimum System Requirements

| Component | Minimum Requirement |
|---|---|
| OS | Windows 10 64-bit, version 1809 or newer |
| CPU | Dual-core x64 processor, 1.8 GHz or faster |
| RAM | 4 GB |
| Storage | 2 GB free space |
| Display | 1366 x 768 |
| GPU | Integrated GPU supported. Hardware acceleration recommended but not mandatory |
| Network | Stable internet connection with HTTPS outbound access |
| Printer | Optional. Windows printer or Bluetooth thermal printer |
| Bluetooth | Optional. Required only for Bluetooth thermal printer |
| Runtime Dependency | Microsoft Visual C++ Redistributable, current version recommended |

### 7.2 Recommended System Requirements

| Component | Recommended |
|---|---|
| OS | Windows 11 64-bit |
| CPU | Intel Core i3/i5, AMD Ryzen 3/5, or equivalent quad-core |
| RAM | 8 GB |
| Storage | SSD with at least 5 GB free space |
| Display | 1920 x 1080 |
| Network | Wired LAN or stable Wi-Fi |
| Printer | USB thermal printer, Windows shared printer, or Bluetooth thermal printer |
| Bluetooth | Windows Bluetooth adapter with paired thermal printer |

### 7.3 Hardware Compatibility Notes

1. The app should run on low-end clinic PCs.
2. Integrated Intel/AMD graphics are sufficient.
3. Dedicated GPU is not required.
4. Touchscreen is not required but should not break the UI.
5. The application is optimized for desktop mouse/keyboard usage.
6. ARM64 Windows devices:
   - Preferred: native Windows ARM64 Flutter build if available in the build environment.
   - Fallback: ship x64 build and run through Windows on ARM emulation.
   - For maximum compatibility, distribute the x64 release build.

---

## 8. Build Prerequisites

The build machine must have:

### 8.1 Flutter SDK

Use a stable Flutter SDK that supports Windows desktop and Dart `^3.11.5`.

Verify:

```powershell
flutter --version
flutter doctor
```

Expected:

```text
Flutter SDK installed
Windows desktop support enabled
Visual Studio installed
```

### 8.2 Visual Studio Build Tools

Install Visual Studio 2022 or Visual Studio Build Tools 2022.

Required workload:

```text
Desktop development with C++
```

Required components:

```text
MSVC v143 or newer C++ build tools
Windows 10 or Windows 11 SDK
C++ CMake tools for Windows
```

### 8.3 Enable Windows Desktop Support

```powershell
flutter config --enable-windows-desktop
```

### 8.4 Project Dependencies

From project root:

```powershell
flutter clean
flutter pub get
```

---

## 9. Windows Release Build Commands

Use PowerShell from the Flutter project root.

### 9.1 Standard Release Build

```powershell
flutter clean
flutter pub get
flutter build windows --release
```

Expected output folder:

```text
build/windows/x64/runner/Release/
```

Expected executable, depending on project configuration:

```text
dhbh_app.exe
```

If the executable name differs, locate the generated `.exe` file inside:

```text
build/windows/x64/runner/Release/
```

### 9.2 Optimized Release Build

Use this for client distribution:

```powershell
flutter clean
flutter pub get
flutter build windows --release --split-debug-info=build/debug-info --obfuscate
```

If icon rendering issues appear after obfuscation or tree shaking, rebuild with:

```powershell
flutter build windows --release --split-debug-info=build/debug-info --obfuscate --no-tree-shake-icons
```

### 9.3 Build Verification

Confirm the following files exist:

```powershell
dir build\windows\x64\runner\Release
```

Check for:

```text
dhbh_app.exe
flutter_windows.dll
data folder
required plugin DLLs
```

Run the executable directly:

```powershell
.\build\windows\x64\runner\Release\dhbh_app.exe
```

---

## 10. Hardware Optimization Guidelines

The application should remain responsive on all supported hardware.

### 10.1 Build-Time Optimization

Use these principles:

1. Always distribute `--release` builds.
2. Do not distribute debug builds to clients.
3. Keep asset sizes small.
4. Avoid large uncompressed images.
5. Use `--split-debug-info` to reduce release artifact size and preserve crash symbol information.
6. Use `--obfuscate` only if the team accepts stack trace symbolication workflow.
7. If release icon issues occur, use `--no-tree-shake-icons`.

### 10.2 Runtime Optimization Rules

When modifying UI code:

1. Prefer `const` widgets where possible.
2. Avoid unnecessary rebuilds in Riverpod consumers.
3. Use `ListView.builder` for long lists.
4. Avoid heavy synchronous work on the UI thread.
5. Use async operations for Supabase calls.
6. Do not block checkout while waiting for printer status.
7. Use skeleton/loading states instead of freezing the screen.
8. Avoid expensive shadows and blur effects on low-end machines.
9. Use `RepaintBoundary` around complex animated or frequently changing widgets.
10. Avoid repeated expensive image decoding where possible.

### 10.3 Low-End PC Guidance

For low-spec client PCs:

1. Close unnecessary background applications.
2. Prefer wired network over unstable Wi-Fi.
3. Use integrated graphics if no dedicated GPU is available.
4. Ensure Windows power mode is not set to extreme battery saver.
5. Disable Windows animation effects if the machine is very slow.
6. Use USB or Windows shared printer if Bluetooth is unstable.

---

## 11. Packaging for Client Installation

The application must be easy to install and run on client desktop devices.

Two distribution options are supported:

1. Portable folder deployment.
2. Windows installer using Inno Setup.

For official client installation, prefer the installer.

---

## 12. Portable Deployment Option

This is the simplest option.

### 12.1 Build Release

```powershell
flutter build windows --release
```

### 12.2 Copy Release Folder

Copy the entire release folder:

```text
build/windows/x64/runner/Release
```

Example destination:

```text
C:\DHBH POS\
```

or:

```text
%LOCALAPPDATA%\DHBH POS\
```

### 12.3 Create Shortcut

Create a desktop shortcut pointing to:

```text
C:\DHBH POS\dhbh_app.exe
```

or:

```text
%LOCALAPPDATA%\DHBH POS\dhbh_app.exe
```

### 12.4 Run

Double-click the shortcut.

No installation is required for this method.

---

## 13. Installer Option Using Inno Setup

Use Inno Setup to create a simple Windows installer.

### 13.1 Install Inno Setup

Download and install Inno Setup from the official website.

### 13.2 Recommended Installer Behavior

The installer should:

1. Require minimal user interaction.
2. Install per user if possible to avoid UAC issues.
3. Create desktop shortcut.
4. Create Start Menu shortcut.
5. Launch application after installation, optional.
6. Not require administrator rights unless installing into Program Files.

### 13.3 Example Inno Setup Script

Save as:

```text
installer/dhbh_pos_installer.iss
```

Example content:

```iss
#define MyAppName "DHBH POS"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "DHBH"
#define MyAppExeName "dhbh_app.exe"
#define SourceReleaseDir "..\build\windows\x64\runner\Release"

[Setup]
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=Output
OutputBaseFilename=DHBH-POS-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
Source: "{#SourceReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
```

> **Note (2026-08-15):** the actual checked-in `installer/dhbh_pos_installer.iss` was built and verified with the non-deprecated architecture identifiers `ArchitecturesAllowed=x64compatible` / `ArchitecturesInstallIn64BitMode=x64compatible`, which also permits x64 emulation on ARM64 Windows. See the Deployment Log in §25.

### 13.4 Build Installer

1. Build Flutter Windows release first.
2. Open Inno Setup Compiler.
3. Open `installer/dhbh_pos_installer.iss`.
4. Click Build.
5. Output installer:

```text
installer/Output/DHBH-POS-Setup.exe
```

### 13.5 Installer Notes

If the generated executable name is not `dhbh_app.exe`, update:

```iss
#define MyAppExeName "dhbh_app.exe"
```

with the actual executable name.

---

## 14. Client Desktop Installation Guide

Use this guide when installing on a clinic desktop.

### 14.1 Pre-Installation Checklist

Before installation, confirm:

1. Device uses Windows 10 or Windows 11 64-bit.
2. Device has at least 4 GB RAM.
3. Device has stable internet access.
4. HTTPS outbound access is allowed.
5. User can access the internet without proxy blocking.
6. Printer is installed if receipt printing is required.

### 14.2 Installation Steps

1. Copy `DHBH-POS-Setup.exe` to the desktop.
2. Double-click the installer.
3. If Windows SmartScreen appears, click:
   - `More info`
   - `Run anyway`
4. Click `Next`.
5. Accept installation location.
6. Enable desktop shortcut.
7. Click `Install`.
8. Launch application after installation.

### 14.3 First Launch

After launching:

1. Wait for Supabase connection check.
2. Login screen should appear.
3. Enter email.
4. Enter password.
5. Click login.
6. Verify branch name appears in the app bar.
7. Verify product list loads.
8. Verify transaction history loads.
9. Verify printer status if printing is required.

---

## 15. Login Testing

Use one of the active accounts from the credential matrix.

Recommended test accounts:

| Purpose | Email | Password |
|---|---|---|
| Kranggan admin test | sohidi@dhbh.com | dhbh12345 |
| Kranggan kasir test | nisa@dhbh.com | dhbh12345 |
| Cikampek admin test | wartok@dhbh.com | dhbh12345 |
| Cikampek kasir test | ridwan@dhbh.com | dhbh12345 |
| Karyawan test | firdaus@dhbh.com | dhbh12345 |

Expected behavior:

1. Login succeeds.
2. User branch is loaded.
3. Products load.
4. POS screen is usable.
5. Cart can add items.
6. Payment dialog can open.
7. Transaction can be saved.

---

## 16. Printer Setup Guide

The application supports multiple printing paths.

### 16.1 Windows Printer Path

Used when:

1. Windows desktop.
2. No Bluetooth thermal printer connected.
3. A Windows printer is available.

Setup:

1. Install printer driver in Windows.
2. Set desired receipt printer as default printer, or ensure `XP-58` printer is available if used.
3. Test print from Windows.
4. Run DHBH POS.
5. Perform test transaction.
6. Confirm print output.

### 16.2 Windows Bluetooth Thermal Printer Path

Used when:

1. Windows desktop.
2. Bluetooth adapter available.
3. Bluetooth thermal printer paired or discoverable.

Setup:

1. Turn on Bluetooth printer.
2. Open Windows Bluetooth settings.
3. Pair printer if necessary.
4. Launch DHBH POS.
5. Allow application auto-connect if configured.
6. If auto-connect fails, use app Bluetooth connection dialog if available.

Default printer MAC documented in project:

```text
66:12:3f:23:ef:92
```

If a different printer is used, update configuration or select device manually where supported.

### 16.3 No Printer Available

The application must not fake printing success.

If no printer is connected:

1. Application should show no printer connected message where applicable.
2. Transaction should still be saved.
3. Print status may remain `unprinted` or `failed` depending on flow.

---

## 17. Supabase Connection Notes

The app uses hardcoded Supabase configuration in:

```text
lib/config/supabase_config.dart
```

The configuration contains:

```text
supabaseUrl
supabaseAnonKey
```

The Supabase anon key is safe for client-side usage when RLS is configured.

Do not add:

```text
service_role key
database password
JWT secret
Supabase access token
```

into the Flutter app or into this document.

### 17.1 Network Requirements

Required outbound access:

```text
https://jiunlvlcwsntjbyybszd.supabase.co
```

Ports:

```text
443 TCP
```

The application performs DNS and connectivity checks before login.

### 17.2 Timezone Note

All daily reporting uses WIB, UTC+07:00.

Do not change timezone handling unless explicitly required.

---

## 18. Performance Acceptance Criteria

The build is considered acceptable if:

1. Application launches within reasonable time on target hardware.
2. Login screen appears without freezing.
3. Product list loads without UI deadlock.
4. Cart operations are responsive.
5. Payment dialog opens without lag.
6. Transaction save completes with clear success or error feedback.
7. History screen loads without excessive delay.
8. Menu screen daily summary loads.
9. Printing does not crash the app.
10. No unhandled exception appears in `%TEMP%\dhbh_flutter_errors.log` during normal flow.

---

## 19. Testing Checklist Before Delivery

Before giving the installer to a client, verify:

### 19.1 Build Test

```powershell
flutter clean
flutter pub get
flutter build windows --release
```

Result:

- [ ] Build succeeds.
- [ ] No fatal warnings.
- [ ] Release folder exists.
- [ ] Executable exists.

### 19.2 Launch Test

- [ ] Executable starts.
- [ ] No immediate crash.
- [ ] Login screen appears.
- [ ] Network banner does not permanently block UI.

### 19.3 Login Test

- [ ] Admin login works.
- [ ] Kasir login works.
- [ ] Karyawan login works.
- [ ] Wrong password shows error.
- [ ] Offline state shows meaningful message.

### 19.4 POS Test

- [ ] Products appear.
- [ ] Category filter works.
- [ ] Search works.
- [ ] Add product to cart works.
- [ ] Quantity update works.
- [ ] Remove item works.
- [ ] Home visit selection works where applicable.
- [ ] Branch-specific price appears correctly.

### 19.5 Payment Test

- [ ] Payment dialog opens.
- [ ] Customer name validation works.
- [ ] Payment method can be selected.
- [ ] Cash change calculation works.
- [ ] Non-cash amount paid auto-fills.
- [ ] Terapis selection works if available.
- [ ] Note can be added.
- [ ] Transaction saves to Supabase.

### 19.6 History Test

- [ ] Transaction history loads.
- [ ] Branch-filtered history is correct.
- [ ] Transaction can be expanded.
- [ ] Refund flow appears only where allowed.
- [ ] Print again works if printer connected.

### 19.7 Printer Test

- [ ] Windows printer prints receipt.
- [ ] Bluetooth printer prints receipt if connected.
- [ ] No printer condition does not crash app.
- [ ] Print status updates correctly.

### 19.8 Client Installation Test

- [ ] Installer runs.
- [ ] App installs without admin where configured.
- [ ] Desktop shortcut works.
- [ ] Start Menu shortcut works.
- [ ] App launches after install.
- [ ] App survives restart.

---

## 20. Troubleshooting

### 20.1 Build Fails: Visual Studio Not Found

Symptoms:

```text
Visual Studio not installed
Windows version not supported
```

Fix:

1. Install Visual Studio 2022 or Build Tools.
2. Install `Desktop development with C++`.
3. Install Windows SDK.
4. Run:

```powershell
flutter doctor
```

### 20.2 Build Fails: Flutter Windows Desktop Not Enabled

Fix:

```powershell
flutter config --enable-windows-desktop
flutter doctor
```

### 20.3 App Does Not Start

Possible fixes:

1. Run executable from terminal to view console output.
2. Check `%TEMP%\dhbh_flutter_errors.log`.
3. Install latest Microsoft Visual C++ Redistributable.
4. Verify Windows is 64-bit and supported.
5. Temporarily disable antivirus for testing.

### 20.4 Login Fails

Check:

1. Internet connection.
2. DNS resolution.
3. Access to `https://jiunlvlcwsntjbyybszd.supabase.co`.
4. Email and password.
5. User is active in `user_profiles`.
6. User has valid `role_id` and `branch_id`.

Use Supabase MCP:

```sql
select
  u.email,
  up.full_name,
  up.is_active,
  ur.name as role,
  b.name as branch
from auth.users u
left join public.user_profiles up on up.id = u.id
left join public.user_roles ur on ur.id = up.role_id
left join public.branches b on b.id = up.branch_id
where u.email = 'user@example.com';
```

### 20.5 Products Do Not Load

Check:

1. Logged-in user has `branch_id`.
2. Supabase RLS allows product read.
3. Network connection is stable.
4. Debug logs with tag `[DHBH Supabase]`.

### 20.6 Price Appears Wrong

Check branch price override:

```sql
select
  p.name,
  p.price_clinic as default_clinic,
  p.price_home_visit as default_home_visit,
  pbp.branch_id,
  pbp.price_clinic as branch_clinic,
  pbp.price_home_visit as branch_home_visit
from public.products p
left join public.product_branch_prices pbp
  on pbp.product_id = p.id
where p.is_active = true
order by p.name;
```

Expected logic:

```text
Effective clinic price = branch override price_clinic ?? product default price_clinic
Effective home visit price = branch override price_home_visit ?? product default price_home_visit ?? product default price_clinic
```

### 20.7 Printer Not Printing

Check:

1. Printer is connected.
2. Printer driver is installed.
3. Bluetooth printer is paired.
4. Correct printer is selected/default.
5. Application print gate detects printer.
6. Use logs with tags:

```text
[Printer]
[WinPrinter]
[Bluetooth]
```

### 20.8 Application Feels Slow

Check:

1. Release build is being used, not debug.
2. CPU usage in Task Manager.
3. Network latency.
4. Product image sizes.
5. Excessive rebuilds in Flutter DevTools.
6. Windows power mode.

---

## 21. Security Notes

1. Do not expose Supabase service role key in client builds.
2. Do not store plaintext database credentials in the app.
3. Do not commit MCP secrets to Git.
4. Keep `Panduan.md` internal only if it contains credentials.
5. Rotate default passwords after staff onboarding if operationally possible.
6. Restrict physical access to cashier desktops.
7. Ensure Windows receives security updates.
8. Do not run the POS application as administrator unless required by printer driver constraints.

---

## 22. Definition of Done

The task is complete when:

1. `flutter build windows --release` succeeds.
2. Installer or portable package is generated.
3. Application installs on a clean Windows desktop.
4. Application launches without manual developer intervention.
5. User can login using documented account.
6. Products load for the correct branch.
7. A test transaction can be created.
8. Transaction appears in history.
9. Printing works or fails gracefully without crashing.
10. No sensitive secret is committed into the repository.
11. This document remains updated with the current deployment instructions.

---

## 23. Quick Command Reference

```powershell
# Check environment
flutter doctor

# Clean and install dependencies
flutter clean
flutter pub get

# Standard release build
flutter build windows --release

# Optimized release build
flutter build windows --release --split-debug-info=build/debug-info --obfuscate

# Optimized release build without icon tree shaking
flutter build windows --release --split-debug-info=build/debug-info --obfuscate --no-tree-shake-icons

# Run built executable
.\build\windows\x64\runner\Release\dhbh_app.exe

# View error log
notepad $env:TEMP\dhbh_flutter_errors.log
```

---

## 24. Agent Handover Summary

For AI coding agents:

1. Build the Windows release first.
2. Verify login and product loading against live Supabase.
3. Use Supabase MCP for live data validation when available.
4. Do not retrieve or store passwords from Supabase.
5. Use the documented default password for provisioned staff accounts.
6. Package the release using Inno Setup or portable deployment.
7. Ensure the client can install and run with minimal steps.
8. Keep the application online-only unless explicitly instructed otherwise.
9. Prioritize stability on low-end Windows hardware.
10. Do not introduce secrets into source control.

---

## 25. Deployment Log

> Keep this section updated with what was actually built, verified, and optimized. Newest entries on top.

### 2026-08-15 — Windows release built, optimized, and packaged (verified end-to-end)

**Build**
- Flutter stable 3.47.0 / Dart 3.13.0; Windows desktop enabled; Visual Studio Build Tools 2022 17.14.23 + Windows 10 SDK 10.0.26100.0.
- `flutter clean && flutter pub get && flutter build windows --release` → `build\windows\x64\runner\Release\dhbh_app.exe` ✅ (executable name confirmed via `windows/CMakeLists.txt` `BINARY_NAME = "dhbh_app"`).

**Asset / icon optimization (build-time, per §10.1)**
- `lib/assets/logo-dhbh.png`: 2048×2048 / 32bpp ARGB / **4.05 MB → 256×256 / 96 KB** (97.7% smaller), high-quality bicubic, alpha preserved. Displayed at ≤100×100 px so 256 px is more than sufficient (incl. HiDPI). Regenerable via `installer/optimize_logo.ps1` (original backed up under `build/logo-backup/`).
- `windows/runner/resources/app_icon.ico`: replaced default Flutter icon with a DHBH-branded **multi-size ICO (16/24/32/48/64/128/256)** generated from the logo — verified embedded in the .exe (extracted 32×32 icon matches). Regenerable via `installer/make_icon.ps1`.

**Launch verification (each full build)**
- `dhbh_app.exe` launched from the release folder and stayed running >20 s with **no `%TEMP%\dhbh_flutter_errors.log`** on every run (PIDs 23344, 25784, 14008, 26060, 23688). RAM ~135–153 MB at idle — fine for 4 GB low-end PCs.

**Installer**
- `installer/dhbh_pos_installer.iss` (Inno Setup 7) built with `ArchitecturesAllowed/InstallIn64BitMode = x64compatible` (avoids deprecated `x64` warning and permits ARM64 x64-emulation).
- Output: **`installer/Output/DHBH-POS-Setup.exe` (13.9 MB)**, lzma2 solid compression, per-user install (no UAC), desktop + Start Menu shortcuts, launches after install.
- **Silent install test passed end-to-end**: `/VERYSILENT /DIR=%LOCALAPPDATA%\DHBH-POS-Test` → exit 0; all files present (`dhbh_app.exe`, 9 plugin DLLs, `data/app.so`, `flutter_assets`); installed app ran 15 s with no error log; uninstaller exit 0 and removed the test directory.

**Still open for a live-data check (requires a running client/session):**
- Interactive login against live Supabase (uses documented default password `dhbh12345`), product/branch-price load, save a test transaction, and receipt printing paths. These cannot be exercised headlessly; use the §19 checklist on a clinic PC with a printer.

End of document.
