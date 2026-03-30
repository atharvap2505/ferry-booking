# Ferry Booking System - Implementation Plan and Gap Analysis

## 1. Evaluation Criteria (What Will Be Tested)

- Attendance
- Member contributions
- Frontend design status (login form and other forms)
- Backend design status (relations implemented as per ER diagram)
- DBA rights implementation (read, write, create user/table, etc.)
- At least one user with view-only rights
- At least one user with view+update rights, but no create-user rights
- Frontend-backend connectivity
- Integration of at least one AI agent

## 2. Current Repository Assessment

The current project is still implemented as an airline booking app. Major logic and SQL references are airline-specific and must be migrated to ferry-specific entities.

### 2.1 Confirmed mismatches in active code

- App and routes still use flight terminology and SkyLiner branding.
- Active SQL joins still use `flights`, `airlines`, and `airports`.
- Booking flow still writes to `flightID` fields.
- Admin sections exist but are largely placeholder-level.
- Test coverage is minimal and not aligned with requirements.

### 2.2 Critical technical inconsistencies

1. Existing database schema and seed data are airline-based, not ferry-based.
2. `bookings.flightID` is TEXT while referenced `flights.flight_id` is INTEGER (type/identity mismatch).
3. UI displays `price` in results/details but price is not fetched in the active SQL query.
4. Role model is only `isAdmin` boolean; insufficient for the required permission matrix.
5. Project metadata still identifies the app as airline booking.

## 3. Review of Your Proposed Ferry Schema

Provided schema (core entities):

- `FERRY_OPERATORS`
- `PORTS`
- `USERS`
- `ROUTES`
- `BOOKINGS`

The schema is a good core and has correct primary relationships for route search and booking flow.

## 4. What Is Missing (Recommended Additions)

To satisfy your grading criteria and avoid future blockers, these additive changes are recommended:

1. Role/permission representation:
- Add `USERS.role` (or a separate `USER_ROLES` table).
- Suggested role values: `DBA`, `VIEW_ONLY`, `VIEW_UPDATE_NO_CREATE_USER`, `CUSTOMER`.

2. Booking/payment completeness:
- Add `BOOKINGS.total_fare` and optional `payment_method`.

3. Operational constraints:
- Add CHECK constraints for `ROUTES.status` and `BOOKINGS.status`.
- Add UNIQUE constraints where appropriate (`email`, `operator_code`, `port_code`, possibly `route_number`).

4. Auditability:
- Add `created_at` and `updated_at` columns for at least `USERS`, `ROUTES`, `BOOKINGS`.

5. Security baseline:
- Store password hashes instead of plain text.

Note: You approved additive extensions, keeping local SQLite, and using both DB-level grants and app-level role checks.

## 5. Required Change Scope in This Repository

## 5.1 Database

- Replace `database.sql` with ferry schema and ferry seed data.
- Ensure FK consistency and status constraints.
- Add a separate SQL script for role/grant evidence:
  - DBA full rights
  - One view-only user
  - One view+update user with no create-user right

## 5.2 Flutter app logic

- Refactor active SQL and UI from flight/airline/airport to route/operator/port.
- Update booking writes from `flightID` to `routeID`.
- Add app-level authorization guards for the required roles.
- Complete admin pages to demonstrate meaningful functionality for grading.

## 5.3 Branding and package identity

- Update package/app naming from airline to ferry across metadata and Android config.

## 5.4 Tests

- Replace default smoke test with domain tests:
  - login/auth routing by role
  - route search filtering
  - booking create/cancel/update behavior
  - restricted user permission behavior

## 6. Implementation Plan (As Finalized)

## Plan: Ferry Schema Gap Review and Migration Blueprint

The project should migrate from airline entities to ferry entities while preserving local SQLite connectivity, and extend the schema minimally for role/permission and DBA testability. The recommended approach is to do a two-layer permission model (DB grants plus app roles), then refactor app SQL and UI naming to the ferry domain, and finally add focused tests aligned to your grading checklist.

### Steps

1. Validate and finalize schema baseline against your provided ER model with additive extensions only: keep FERRY_OPERATORS, PORTS, USERS, ROUTES, BOOKINGS as core tables, then add only what is required for role/grant verification and route booking correctness.
2. Define permission architecture in parallel tracks.
   - Database permissions track: create SQL users/roles/scripts for DBA full rights, one view-only user, and one view+update user without create-user privilege.
   - App authorization track: introduce role field/role mapping in USERS (or role table) and guard admin/user screens/actions.
3. Replace airline schema and seed data in `database.sql`, including fixing key consistency and status constraints.
4. Update app-side data access in `lib/main.dart` to query ferry tables/columns (routes/operators/ports/bookings) and remove airline-specific assumptions.
5. Rebrand and route rename in UI: rename flight labels/screens/routes to ferry equivalents, and adjust booking details fields to route/operator/port terminology.
6. Complete backend-frontend connectivity checks under SQLite mode: ensure login, search, booking insert/delete, history, and profile update all run against new schema with no null/unknown columns.
7. Implement evaluation evidence assets:
   - SQL script proving DBA rights and restricted-user rights.
   - In-app screenshots/flow proof for forms and connectivity.
  - AI integration proof point (simple assistant/help module acceptable) with usage path documented (currently pending, removed from codebase by request).
8. Replace placeholder test with domain tests in `test/widget_test.dart` and add data-layer checks for auth, route filtering, and booking lifecycle.
9. Update project metadata/docs for ferry identity and setup clarity in `README.md`, `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, and `android/app/build.gradle.kts`.

### Relevant files

- `database.sql`
- `lib/main.dart`
- `test/widget_test.dart`
- `README.md`
- `pubspec.yaml`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`
- `android/app/src/main/kotlin/com/example/airlinebooking/MainActivity.kt`
- `assets/database.db`

### Verification

1. Run SQL integrity checks: foreign keys on, joins for routes/operators/ports, and booking insert/update scenarios per role profile.
2. Execute app flows manually: login (admin/user/restricted), search routes, route details, booking confirmation, booking history, profile edit.
3. Validate permission requirements with explicit SQL evidence: DBA full rights, view-only cannot write, view+update can update allowed rows but cannot create user/table.
4. Run Flutter tests and ensure domain tests pass for auth routing and booking flow.
5. Confirm no airline naming remains in active app surfaces and package metadata unless intentionally retained.

### Decisions

- Approved: additive schema extensions are allowed.
- Approved: enforce both DB grants and app-level roles.
- Approved: keep backend connectivity local SQLite.
- Included scope: migration to ferry domain plus grading-readiness for permissions/forms/connectivity/testing.
- Excluded scope: full API/server migration and production-grade IAM.

### Further considerations

1. Recommended schema additions: `USERS.role` (or `USER_ROLES` table), `BOOKINGS.total_fare`, `ROUTES.capacity`, and `created_at/updated_at` columns.
2. Recommended status constraints: CHECK constraints for `ROUTES.status` and `BOOKINGS.status`.
3. Recommended security baseline: store password hashes instead of plain text for demonstration quality, even in local SQLite.
