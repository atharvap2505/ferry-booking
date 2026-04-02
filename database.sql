PRAGMA foreign_keys=ON;
BEGIN TRANSACTION;

DROP TABLE IF EXISTS BOOKINGS;
DROP TABLE IF EXISTS ROUTES;
DROP TABLE IF EXISTS USERS;
DROP TABLE IF EXISTS PORTS;
DROP TABLE IF EXISTS FERRY_OPERATORS;
DROP TABLE IF EXISTS AUDIT_LOG;

CREATE TABLE FERRY_OPERATORS (
    operator_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    operator_code TEXT NOT NULL UNIQUE,
    company_code TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE PORTS (
    port_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    city TEXT NOT NULL,
    country TEXT NOT NULL,
    port_code TEXT NOT NULL UNIQUE,
    regional_code TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE USERS (
    userID TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    name TEXT NOT NULL,
    phone TEXT,
    isAdmin INTEGER NOT NULL DEFAULT 0 CHECK (isAdmin IN (0, 1)),
    role TEXT NOT NULL DEFAULT 'CUSTOMER' CHECK (role IN ('DBA', 'VIEW_ONLY', 'VIEW_UPDATE_NO_CREATE_USER', 'ADMIN', 'CUSTOMER')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ROUTES (
    route_id INTEGER PRIMARY KEY,
    route_number TEXT NOT NULL UNIQUE,
    operator_id INTEGER NOT NULL,
    departure_port_id INTEGER NOT NULL,
    arrival_port_id INTEGER NOT NULL,
    departure_time TEXT NOT NULL,
    arrival_time TEXT NOT NULL,
    capacity INTEGER NOT NULL DEFAULT 200 CHECK (capacity > 0),
    fare REAL NOT NULL CHECK (fare >= 0),
    status TEXT NOT NULL CHECK (status IN ('On Time', 'Delayed', 'Cancelled', 'Boarding')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (operator_id) REFERENCES FERRY_OPERATORS(operator_id),
    FOREIGN KEY (departure_port_id) REFERENCES PORTS(port_id),
    FOREIGN KEY (arrival_port_id) REFERENCES PORTS(port_id),
    CHECK (departure_port_id <> arrival_port_id)
);

CREATE TABLE BOOKINGS (
    bookingID TEXT PRIMARY KEY,
    userID TEXT NOT NULL,
    routeID INTEGER NOT NULL,
    bookingDate TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('Pending', 'Confirmed', 'Cancelled')),
    total_fare REAL NOT NULL CHECK (total_fare >= 0),
    payment_method TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (userID) REFERENCES USERS(userID),
    FOREIGN KEY (routeID) REFERENCES ROUTES(route_id)
);

CREATE TABLE AUDIT_LOG (
    audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    details TEXT,
    changed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO FERRY_OPERATORS (operator_id, name, operator_code, company_code) VALUES
    (1, 'BlueWave Ferries', 'BWF', 'BW-001'),
    (2, 'SeaLink Transit', 'SLT', 'SL-002'),
    (3, 'HarborConnect', 'HBC', 'HC-003');

INSERT INTO PORTS (port_id, name, city, country, port_code, regional_code) VALUES
    (1, 'Gateway Port', 'Mumbai', 'India', 'MUM-GW', 'IN-WEST'),
    (2, 'Harbor Terminal', 'Goa', 'India', 'GOA-HT', 'IN-WEST'),
    (3, 'Island Pier', 'Kochi', 'India', 'KOC-IP', 'IN-SOUTH'),
    (4, 'Bay Dock', 'Chennai', 'India', 'CHE-BD', 'IN-SOUTH'),
    (5, 'Coral Wharf', 'Port Blair', 'India', 'PBL-CW', 'IN-ISLAND');

INSERT INTO USERS (userID, email, password, name, phone, isAdmin, role) VALUES
    ('DBA001', 'dba@ferrybook.com', 'dba123', 'DB Admin', '90000-00001', 1, 'DBA'),
    ('VIEW001', 'viewer@ferrybook.com', 'view123', 'Read Only User', '90000-00002', 0, 'VIEW_ONLY'),
    ('UPD001', 'updater@ferrybook.com', 'update123', 'Update User', '90000-00003', 0, 'VIEW_UPDATE_NO_CREATE_USER'),
    ('ADMIN001', 'admin@ferrybook.com', 'admin123', 'System Admin', '90000-00004', 1, 'ADMIN'),
    ('USER001', 'user1@ferrybook.com', 'password123', 'Customer User', '90000-00005', 0, 'CUSTOMER');

INSERT INTO ROUTES (
    route_id,
    route_number,
    operator_id,
    departure_port_id,
    arrival_port_id,
    departure_time,
    arrival_time,
    capacity,
    fare,
    status
) VALUES
    (101, 'FW-101', 1, 1, 2, '2026-03-31 08:00:00', '2026-03-31 10:30:00', 220, 1499.00, 'On Time'),
    (102, 'FW-102', 2, 2, 3, '2026-03-31 11:00:00', '2026-03-31 13:15:00', 180, 1299.00, 'Delayed'),
    (103, 'FW-103', 3, 3, 4, '2026-03-31 15:00:00', '2026-03-31 17:45:00', 200, 1599.00, 'Boarding'),
    (104, 'FW-104', 1, 4, 5, '2026-03-31 19:30:00', '2026-03-31 23:30:00', 250, 2499.00, 'On Time'),
    (105, 'FW-105', 2, 1, 3, '2026-04-01 06:00:00', '2026-04-01 09:10:00', 210, 1399.00, 'On Time'),
    (106, 'FW-106', 3, 1, 4, '2026-04-01 09:30:00', '2026-04-01 13:05:00', 190, 1699.00, 'Boarding'),
    (107, 'FW-107', 1, 1, 5, '2026-04-01 14:00:00', '2026-04-01 20:10:00', 240, 2799.00, 'On Time'),
    (108, 'FW-108', 2, 2, 1, '2026-04-01 07:45:00', '2026-04-01 10:15:00', 180, 1299.00, 'On Time'),
    (109, 'FW-109', 3, 2, 4, '2026-04-01 12:10:00', '2026-04-01 15:40:00', 205, 1749.00, 'Delayed'),
    (110, 'FW-110', 1, 2, 5, '2026-04-01 18:30:00', '2026-04-02 00:15:00', 260, 2899.00, 'On Time'),
    (111, 'FW-111', 2, 3, 1, '2026-04-02 06:20:00', '2026-04-02 09:25:00', 195, 1349.00, 'On Time'),
    (112, 'FW-112', 3, 3, 2, '2026-04-02 10:00:00', '2026-04-02 12:10:00', 175, 1199.00, 'On Time'),
    (113, 'FW-113', 1, 3, 5, '2026-04-02 13:40:00', '2026-04-02 19:50:00', 230, 2699.00, 'Boarding'),
    (114, 'FW-114', 2, 4, 1, '2026-04-02 07:10:00', '2026-04-02 10:45:00', 215, 1649.00, 'On Time'),
    (115, 'FW-115', 3, 4, 2, '2026-04-02 11:30:00', '2026-04-02 14:50:00', 200, 1549.00, 'On Time'),
    (116, 'FW-116', 1, 4, 3, '2026-04-02 16:00:00', '2026-04-02 18:55:00', 185, 1449.00, 'Cancelled'),
    (117, 'FW-117', 2, 5, 1, '2026-04-03 05:30:00', '2026-04-03 11:40:00', 255, 2999.00, 'On Time'),
    (118, 'FW-118', 3, 5, 2, '2026-04-03 08:00:00', '2026-04-03 13:20:00', 245, 2849.00, 'Delayed'),
    (119, 'FW-119', 1, 5, 3, '2026-04-03 12:45:00', '2026-04-03 17:40:00', 235, 2599.00, 'On Time'),
    (120, 'FW-120', 2, 5, 4, '2026-04-03 18:10:00', '2026-04-03 22:55:00', 220, 2499.00, 'On Time'),
    (121, 'FW-121', 3, 1, 2, '2026-04-04 08:15:00', '2026-04-04 10:40:00', 210, 1499.00, 'On Time'),
    (122, 'FW-122', 1, 1, 3, '2026-04-04 11:20:00', '2026-04-04 14:10:00', 205, 1419.00, 'Delayed'),
    (123, 'FW-123', 2, 1, 4, '2026-04-04 15:30:00', '2026-04-04 18:50:00', 198, 1729.00, 'Boarding'),
    (124, 'FW-124', 3, 1, 5, '2026-04-04 19:00:00', '2026-04-05 00:50:00', 250, 2869.00, 'On Time'),
    (125, 'FW-125', 1, 2, 1, '2026-04-05 06:40:00', '2026-04-05 09:00:00', 180, 1289.00, 'On Time'),
    (126, 'FW-126', 2, 2, 3, '2026-04-05 10:10:00', '2026-04-05 12:20:00', 175, 1219.00, 'On Time'),
    (127, 'FW-127', 3, 2, 4, '2026-04-05 13:50:00', '2026-04-05 17:20:00', 200, 1689.00, 'Delayed'),
    (128, 'FW-128', 1, 2, 5, '2026-04-05 19:20:00', '2026-04-06 01:10:00', 260, 2949.00, 'On Time'),
    (129, 'FW-129', 2, 3, 1, '2026-04-06 07:00:00', '2026-04-06 10:00:00', 190, 1369.00, 'On Time'),
    (130, 'FW-130', 3, 3, 2, '2026-04-06 11:35:00', '2026-04-06 13:45:00', 180, 1199.00, 'On Time'),
    (131, 'FW-131', 1, 3, 4, '2026-04-06 14:30:00', '2026-04-06 17:00:00', 185, 1469.00, 'On Time'),
    (132, 'FW-132', 2, 3, 5, '2026-04-06 18:00:00', '2026-04-06 23:30:00', 240, 2749.00, 'Boarding'),
    (133, 'FW-133', 3, 4, 1, '2026-04-07 06:30:00', '2026-04-07 10:00:00', 212, 1629.00, 'On Time'),
    (134, 'FW-134', 1, 4, 2, '2026-04-07 10:40:00', '2026-04-07 14:00:00', 205, 1549.00, 'On Time'),
    (135, 'FW-135', 2, 4, 3, '2026-04-07 15:20:00', '2026-04-07 18:10:00', 190, 1429.00, 'Delayed'),
    (136, 'FW-136', 3, 4, 5, '2026-04-07 19:15:00', '2026-04-08 00:05:00', 248, 2529.00, 'On Time'),
    (137, 'FW-137', 1, 5, 1, '2026-04-08 05:10:00', '2026-04-08 11:15:00', 255, 3019.00, 'On Time'),
    (138, 'FW-138', 2, 5, 2, '2026-04-08 08:40:00', '2026-04-08 14:00:00', 242, 2869.00, 'On Time'),
    (139, 'FW-139', 3, 5, 3, '2026-04-08 12:35:00', '2026-04-08 17:20:00', 233, 2639.00, 'Cancelled'),
    (140, 'FW-140', 1, 5, 4, '2026-04-08 18:05:00', '2026-04-08 22:55:00', 225, 2519.00, 'On Time'),
    (141, 'FW-141', 2, 1, 2, '2026-04-09 06:10:00', '2026-04-09 08:40:00', 210, 1519.00, 'On Time'),
    (142, 'FW-142', 3, 1, 3, '2026-04-09 09:15:00', '2026-04-09 12:10:00', 205, 1449.00, 'On Time'),
    (143, 'FW-143', 1, 1, 4, '2026-04-09 13:25:00', '2026-04-09 16:55:00', 198, 1769.00, 'Delayed'),
    (144, 'FW-144', 2, 1, 5, '2026-04-09 18:40:00', '2026-04-10 00:25:00', 252, 2899.00, 'On Time'),
    (145, 'FW-145', 3, 2, 1, '2026-04-10 06:30:00', '2026-04-10 08:55:00', 180, 1299.00, 'On Time'),
    (146, 'FW-146', 1, 2, 3, '2026-04-10 10:05:00', '2026-04-10 12:20:00', 176, 1239.00, 'Boarding'),
    (147, 'FW-147', 2, 2, 4, '2026-04-10 13:40:00', '2026-04-10 17:15:00', 202, 1699.00, 'On Time'),
    (148, 'FW-148', 3, 2, 5, '2026-04-10 19:00:00', '2026-04-11 00:40:00', 262, 2979.00, 'On Time'),
    (149, 'FW-149', 1, 3, 1, '2026-04-11 07:10:00', '2026-04-11 10:10:00', 191, 1389.00, 'On Time'),
    (150, 'FW-150', 2, 3, 2, '2026-04-11 11:25:00', '2026-04-11 13:35:00', 184, 1219.00, 'On Time'),
    (151, 'FW-151', 3, 3, 4, '2026-04-11 14:45:00', '2026-04-11 17:20:00', 188, 1489.00, 'Delayed'),
    (152, 'FW-152', 1, 3, 5, '2026-04-11 18:50:00', '2026-04-12 00:30:00', 243, 2789.00, 'On Time'),
    (153, 'FW-153', 2, 4, 1, '2026-04-12 06:45:00', '2026-04-12 10:15:00', 215, 1669.00, 'On Time'),
    (154, 'FW-154', 3, 4, 2, '2026-04-12 10:55:00', '2026-04-12 14:05:00', 208, 1569.00, 'On Time'),
    (155, 'FW-155', 1, 4, 3, '2026-04-12 15:20:00', '2026-04-12 18:10:00', 195, 1469.00, 'On Time'),
    (156, 'FW-156', 2, 4, 5, '2026-04-12 19:35:00', '2026-04-13 00:20:00', 249, 2559.00, 'Cancelled'),
    (157, 'FW-157', 3, 5, 1, '2026-04-13 05:20:00', '2026-04-13 11:25:00', 257, 3049.00, 'On Time'),
    (158, 'FW-158', 1, 5, 2, '2026-04-13 08:50:00', '2026-04-13 14:10:00', 246, 2889.00, 'On Time'),
    (159, 'FW-159', 2, 5, 3, '2026-04-13 12:40:00', '2026-04-13 17:35:00', 236, 2669.00, 'Delayed'),
    (160, 'FW-160', 3, 5, 4, '2026-04-13 18:15:00', '2026-04-13 23:05:00', 228, 2549.00, 'On Time'),
    (161, 'FW-161', 1, 1, 2, '2026-04-14 06:05:00', '2026-04-14 08:35:00', 212, 1529.00, 'On Time'),
    (162, 'FW-162', 2, 1, 3, '2026-04-14 09:30:00', '2026-04-14 12:20:00', 207, 1459.00, 'On Time'),
    (163, 'FW-163', 3, 1, 4, '2026-04-14 13:50:00', '2026-04-14 17:15:00', 201, 1789.00, 'Boarding'),
    (164, 'FW-164', 1, 1, 5, '2026-04-14 19:10:00', '2026-04-15 01:00:00', 253, 2929.00, 'On Time'),
    (165, 'FW-165', 2, 2, 1, '2026-04-15 06:35:00', '2026-04-15 09:00:00', 181, 1309.00, 'On Time'),
    (166, 'FW-166', 3, 2, 3, '2026-04-15 10:25:00', '2026-04-15 12:40:00', 178, 1249.00, 'On Time'),
    (167, 'FW-167', 1, 2, 4, '2026-04-15 14:05:00', '2026-04-15 17:35:00', 204, 1719.00, 'On Time'),
    (168, 'FW-168', 2, 2, 5, '2026-04-15 19:15:00', '2026-04-16 00:55:00', 263, 3009.00, 'On Time'),
    (169, 'FW-169', 3, 3, 1, '2026-04-16 07:00:00', '2026-04-16 10:00:00', 192, 1399.00, 'On Time'),
    (170, 'FW-170', 1, 3, 2, '2026-04-16 11:40:00', '2026-04-16 13:50:00', 186, 1229.00, 'On Time'),
    (171, 'FW-171', 2, 3, 4, '2026-04-16 15:00:00', '2026-04-16 17:30:00', 189, 1499.00, 'Delayed'),
    (172, 'FW-172', 3, 3, 5, '2026-04-16 19:05:00', '2026-04-17 00:45:00', 244, 2819.00, 'On Time'),
    (173, 'FW-173', 1, 4, 1, '2026-04-17 06:55:00', '2026-04-17 10:20:00', 216, 1679.00, 'On Time'),
    (174, 'FW-174', 2, 4, 2, '2026-04-17 11:05:00', '2026-04-17 14:15:00', 209, 1579.00, 'On Time'),
    (175, 'FW-175', 3, 4, 3, '2026-04-17 15:35:00', '2026-04-17 18:25:00', 196, 1479.00, 'Boarding'),
    (176, 'FW-176', 1, 4, 5, '2026-04-17 19:50:00', '2026-04-18 00:35:00', 250, 2589.00, 'On Time'),
    (177, 'FW-177', 2, 5, 1, '2026-04-18 05:35:00', '2026-04-18 11:40:00', 258, 3079.00, 'On Time'),
    (178, 'FW-178', 3, 5, 2, '2026-04-18 09:00:00', '2026-04-18 14:20:00', 247, 2919.00, 'Delayed'),
    (179, 'FW-179', 1, 5, 3, '2026-04-18 12:55:00', '2026-04-18 17:50:00', 237, 2699.00, 'On Time'),
    (180, 'FW-180', 2, 5, 4, '2026-04-18 18:20:00', '2026-04-18 23:10:00', 229, 2579.00, 'On Time'),
    (181, 'FW-181', 3, 1, 2, '2026-04-19 06:15:00', '2026-04-19 08:45:00', 213, 1539.00, 'On Time'),
    (182, 'FW-182', 1, 2, 3, '2026-04-19 09:45:00', '2026-04-19 12:00:00', 179, 1259.00, 'On Time'),
    (183, 'FW-183', 2, 3, 4, '2026-04-19 13:55:00', '2026-04-19 16:30:00', 190, 1519.00, 'On Time'),
    (184, 'FW-184', 3, 4, 5, '2026-04-19 17:35:00', '2026-04-19 22:20:00', 251, 2619.00, 'Cancelled'),
    (185, 'FW-185', 1, 1, 3, '2026-04-19 18:15:00', '2026-04-19 21:00:00', 208, 1469.00, 'On Time');

INSERT INTO BOOKINGS (
    bookingID,
    userID,
    routeID,
    bookingDate,
    status,
    total_fare,
    payment_method
) VALUES
    ('BK001', 'USER001', 101, '2026-03-30', 'Confirmed', 1499.00, 'UPI'),
    ('BK002', 'UPD001', 102, '2026-03-30', 'Pending', 1299.00, 'Card');

CREATE TRIGGER trg_users_set_updated_at
AFTER UPDATE ON USERS
FOR EACH ROW
BEGIN
    UPDATE USERS
    SET updated_at = CURRENT_TIMESTAMP
    WHERE userID = NEW.userID;
END;

CREATE TRIGGER trg_routes_set_updated_at
AFTER UPDATE ON ROUTES
FOR EACH ROW
BEGIN
    UPDATE ROUTES
    SET updated_at = CURRENT_TIMESTAMP
    WHERE route_id = NEW.route_id;
END;

CREATE TRIGGER trg_bookings_set_updated_at
AFTER UPDATE ON BOOKINGS
FOR EACH ROW
BEGIN
    UPDATE BOOKINGS
    SET updated_at = CURRENT_TIMESTAMP
    WHERE bookingID = NEW.bookingID;
END;

CREATE TRIGGER trg_bookings_validate_insert
BEFORE INSERT ON BOOKINGS
FOR EACH ROW
BEGIN
    SELECT CASE
        WHEN (SELECT status FROM ROUTES WHERE route_id = NEW.routeID) = 'Cancelled'
        THEN RAISE(ABORT, 'Cannot book a cancelled route')
    END;

    SELECT CASE
        WHEN NEW.status IN ('Pending', 'Confirmed')
             AND (
                SELECT COUNT(*)
                FROM BOOKINGS b
                WHERE b.routeID = NEW.routeID
                  AND b.status IN ('Pending', 'Confirmed')
             ) >= (
                SELECT capacity FROM ROUTES WHERE route_id = NEW.routeID
             )
        THEN RAISE(ABORT, 'Route capacity reached')
    END;
END;

CREATE TRIGGER trg_bookings_validate_update
BEFORE UPDATE ON BOOKINGS
FOR EACH ROW
BEGIN
    SELECT CASE
        WHEN OLD.status = 'Cancelled' AND NEW.status IN ('Pending', 'Confirmed')
        THEN RAISE(ABORT, 'Cancelled booking cannot be reactivated')
    END;

    SELECT CASE
        WHEN (SELECT status FROM ROUTES WHERE route_id = NEW.routeID) = 'Cancelled'
             AND NEW.status IN ('Pending', 'Confirmed')
        THEN RAISE(ABORT, 'Cannot keep active booking on cancelled route')
    END;

    SELECT CASE
        WHEN NEW.status IN ('Pending', 'Confirmed')
             AND (
                SELECT COUNT(*)
                FROM BOOKINGS b
                WHERE b.routeID = NEW.routeID
                  AND b.status IN ('Pending', 'Confirmed')
                  AND b.bookingID <> OLD.bookingID
             ) >= (
                SELECT capacity FROM ROUTES WHERE route_id = NEW.routeID
             )
        THEN RAISE(ABORT, 'Route capacity reached')
    END;
END;

CREATE TRIGGER trg_users_audit_insert
AFTER INSERT ON USERS
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_LOG (entity_type, entity_id, action, details)
    VALUES (
        'USERS',
        NEW.userID,
        'INSERT',
        'email=' || NEW.email || ';role=' || NEW.role
    );
END;

CREATE TRIGGER trg_users_audit_update
AFTER UPDATE ON USERS
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_LOG (entity_type, entity_id, action, details)
    VALUES (
        'USERS',
        NEW.userID,
        'UPDATE',
        'old_role=' || OLD.role || ';new_role=' || NEW.role || ';old_email=' || OLD.email || ';new_email=' || NEW.email
    );
END;

CREATE TRIGGER trg_users_audit_delete
AFTER DELETE ON USERS
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_LOG (entity_type, entity_id, action, details)
    VALUES (
        'USERS',
        OLD.userID,
        'DELETE',
        'email=' || OLD.email || ';role=' || OLD.role
    );
END;

CREATE TRIGGER trg_routes_audit_insert
AFTER INSERT ON ROUTES
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_LOG (entity_type, entity_id, action, details)
    VALUES (
        'ROUTES',
        CAST(NEW.route_id AS TEXT),
        'INSERT',
        'route=' || NEW.route_number || ';status=' || NEW.status
    );
END;

CREATE TRIGGER trg_routes_audit_update
AFTER UPDATE ON ROUTES
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_LOG (entity_type, entity_id, action, details)
    VALUES (
        'ROUTES',
        CAST(NEW.route_id AS TEXT),
        'UPDATE',
        'old_status=' || OLD.status || ';new_status=' || NEW.status || ';old_fare=' || CAST(OLD.fare AS TEXT) || ';new_fare=' || CAST(NEW.fare AS TEXT)
    );
END;

CREATE TRIGGER trg_routes_audit_delete
AFTER DELETE ON ROUTES
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_LOG (entity_type, entity_id, action, details)
    VALUES (
        'ROUTES',
        CAST(OLD.route_id AS TEXT),
        'DELETE',
        'route=' || OLD.route_number || ';status=' || OLD.status
    );
END;

CREATE TRIGGER trg_bookings_audit_insert
AFTER INSERT ON BOOKINGS
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_LOG (entity_type, entity_id, action, details)
    VALUES (
        'BOOKINGS',
        NEW.bookingID,
        'INSERT',
        'user=' || NEW.userID || ';route=' || CAST(NEW.routeID AS TEXT) || ';status=' || NEW.status
    );
END;

CREATE TRIGGER trg_bookings_audit_update
AFTER UPDATE ON BOOKINGS
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_LOG (entity_type, entity_id, action, details)
    VALUES (
        'BOOKINGS',
        NEW.bookingID,
        'UPDATE',
        'old_status=' || OLD.status || ';new_status=' || NEW.status || ';old_route=' || CAST(OLD.routeID AS TEXT) || ';new_route=' || CAST(NEW.routeID AS TEXT)
    );
END;

CREATE TRIGGER trg_bookings_audit_delete
AFTER DELETE ON BOOKINGS
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_LOG (entity_type, entity_id, action, details)
    VALUES (
        'BOOKINGS',
        OLD.bookingID,
        'DELETE',
        'user=' || OLD.userID || ';route=' || CAST(OLD.routeID AS TEXT) || ';status=' || OLD.status
    );
END;

COMMIT;
