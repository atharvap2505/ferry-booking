# Ferry Booking System

Flutter + SQLite ferry booking application.

## Implemented Scope

- Ferry domain schema: operators, ports, routes, users, bookings
- Login and signup forms
- Route search, results, details, and booking flow
- Booking history and status updates
- Profile view/edit (role-aware)
- Admin dashboard with route/user/booking views
- App-level role checks
- SQL evidence script for DBA, view-only, and view+update users

## Database Files

- `database.sql`: main SQLite schema and seed data
- `database_permissions.sql`: MySQL/PostgreSQL style user/grant evidence script

## Seed User Accounts

Use these credentials in login:

- DBA user
	- email: `dba@ferrybook.com`
	- password: `dba123`
	- role: `DBA`
- View-only user
	- email: `viewer@ferrybook.com`
	- password: `view123`
	- role: `VIEW_ONLY`
- View+update user
	- email: `updater@ferrybook.com`
	- password: `update123`
	- role: `VIEW_UPDATE_NO_CREATE_USER`
- Admin user
	- email: `admin@ferrybook.com`
	- password: `admin123`
	- role: `ADMIN`
- Customer user
	- email: `user1@ferrybook.com`
	- password: `password123`
	- role: `CUSTOMER`

## Fresh Setup (No Flutter Installed)

This section is for a clean machine setup.

### Windows (Flutter + Desktop/Linux-not-applicable + Android optional)

1. Install Git
- Download and install: https://git-scm.com/download/win

2. Install Flutter SDK
- Download Flutter SDK zip: https://docs.flutter.dev/get-started/install/windows
- Extract to a path like `C:\src\flutter` (avoid spaces/special chars)

3. Add Flutter to PATH
- Add `C:\src\flutter\bin` to your user/system `Path`

4. Install required tooling
- Install Visual Studio 2022 (for Windows desktop builds) with:
	- `Desktop development with C++`
	- Windows 10/11 SDK
- Optional (for Android): install Android Studio + Android SDK + emulator

5. Verify installation
```powershell
flutter doctor -v
```

6. Clone and open project
```powershell
git clone <your-repo-url>
cd ferry-booking
```

7. Install dependencies
```powershell
flutter pub get
```

8. Run project
- Windows desktop:
```powershell
flutter run -d windows
```
- Android emulator/device (optional):
```powershell
flutter run -d <device_id>
```

### Linux (Flutter + Linux desktop)

1. Install Git and base tools

Debian/Ubuntu:
```bash
sudo apt update
sudo apt install -y git curl unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev
```

Arch/EndeavourOS:
```bash
sudo pacman -S --needed git curl unzip xz zip clang cmake ninja pkgconf gtk3
```

2. Install Flutter SDK
- Follow: https://docs.flutter.dev/get-started/install/linux
- Extract SDK (example): `~/develop/flutter`

3. Add Flutter to PATH
- Add to shell profile (`~/.bashrc` or `~/.config/fish/config.fish`)
- Example (bash/zsh):
```bash
export PATH="$HOME/develop/flutter/bin:$PATH"
```

4. Verify and enable Linux desktop support
```bash
flutter doctor -v
flutter config --enable-linux-desktop
```

5. Clone and open project
```bash
git clone <your-repo-url>
cd ferry-booking
```

6. Ensure Linux platform files exist
```bash
flutter create --platforms=linux .
```

7. Install dependencies
```bash
flutter pub get
```

8. Run project
```bash
flutter run -d linux
```

## Quick Troubleshooting

- If `flutter` is not found:
	- Re-check PATH and restart terminal.
- If desktop target is missing:
	- Run `flutter config --enable-linux-desktop` or use Windows desktop target.
- If dependencies fail:
	- Run `flutter clean && flutter pub get`.

## Run

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
```

## Notes About DB Rights

SQLite does not support native `CREATE USER`/`GRANT` semantics. For evaluation, both are included:

- In-app role checks in Flutter
- SQL grant script (`database_permissions.sql`) for RDBMS demonstrations

## Project Checkpoints Mapping

- Frontend forms: login, signup, route search, payment, profile
- Backend relation design: schema relations with foreign keys in `database.sql`
- Frontend-backend connectivity: all major screens query or write via SQLite
- Role coverage: DBA/view-only/view+update represented in seeded users
- AI integration: N/A
