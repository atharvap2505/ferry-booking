-- Reference script for RDBMS role/privilege evaluation.
-- SQLite does not support CREATE USER / GRANT, so keep this as evidence for
-- MySQL/PostgreSQL-style deployment and viva requirements.

-- DBA user: full permissions, including user/table management.
CREATE USER dba_user IDENTIFIED BY 'dbaStrong@123';
GRANT ALL PRIVILEGES ON ferry_booking.* TO dba_user WITH GRANT OPTION;

-- View-only user: can read but cannot modify schema/data.
CREATE USER viewer_user IDENTIFIED BY 'viewer@123';
GRANT SELECT ON ferry_booking.FERRY_OPERATORS TO viewer_user;
GRANT SELECT ON ferry_booking.PORTS TO viewer_user;
GRANT SELECT ON ferry_booking.ROUTES TO viewer_user;
GRANT SELECT ON ferry_booking.USERS TO viewer_user;
GRANT SELECT ON ferry_booking.BOOKINGS TO viewer_user;

-- View+update user: read and update rights, no CREATE USER/TABLE rights.
CREATE USER updater_user IDENTIFIED BY 'updater@123';
GRANT SELECT, UPDATE ON ferry_booking.FERRY_OPERATORS TO updater_user;
GRANT SELECT, UPDATE ON ferry_booking.PORTS TO updater_user;
GRANT SELECT, UPDATE ON ferry_booking.ROUTES TO updater_user;
GRANT SELECT, UPDATE ON ferry_booking.USERS TO updater_user;
GRANT SELECT, UPDATE ON ferry_booking.BOOKINGS TO updater_user;

-- Explicitly do not grant CREATE USER/TABLE permissions to updater_user.
-- For PostgreSQL equivalent, map to roles:
--   CREATE ROLE viewer_user LOGIN PASSWORD 'viewer@123';
--   GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_user;
--   CREATE ROLE updater_user LOGIN PASSWORD 'updater@123';
--   GRANT SELECT, UPDATE ON ALL TABLES IN SCHEMA public TO updater_user;
