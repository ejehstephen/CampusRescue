CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Active patrol units (security, medics, fire marshals)
CREATE TABLE IF NOT EXISTS "responder" (
    "id" VARCHAR(64) PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL,
    "role" VARCHAR(255) NOT NULL,
    "phone" VARCHAR(64) NOT NULL,
    "is_available" BOOLEAN NOT NULL DEFAULT TRUE,
    "current_zone" VARCHAR(255) NOT NULL,
    "current_x_ratio" DOUBLE PRECISION NOT NULL,
    "current_y_ratio" DOUBLE PRECISION NOT NULL,
    "target_x_ratio" DOUBLE PRECISION,
    "target_y_ratio" DOUBLE PRECISION,
    "route_progress" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "active_incident_id" VARCHAR(64),
    "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS "responder_zone_idx" ON "responder"("current_zone");
CREATE INDEX IF NOT EXISTS "responder_available_idx" ON "responder"("is_available");

-- SOS alerts and reported distress calls
CREATE TABLE IF NOT EXISTS "incident" (
    "id" VARCHAR(64) PRIMARY KEY,
    "category" VARCHAR(255) NOT NULL,
    "description" TEXT NOT NULL,
    "campus_zone" VARCHAR(255) NOT NULL,
    "room_number" VARCHAR(255),
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "x_ratio" DOUBLE PRECISION NOT NULL,
    "y_ratio" DOUBLE PRECISION NOT NULL,
    "urgency" VARCHAR(64) NOT NULL,
    "status" VARCHAR(64) NOT NULL,
    "timestamp" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "assigned_responder_id" VARCHAR(64) REFERENCES "responder"("id") ON DELETE SET NULL,
    "eta_seconds" INTEGER,
    "resolved_at" TIMESTAMP WITH TIME ZONE,
    "resolution_notes" TEXT
);

CREATE INDEX IF NOT EXISTS "incident_status_idx" ON "incident"("status");
CREATE INDEX IF NOT EXISTS "incident_zone_idx" ON "incident"("campus_zone");
CREATE INDEX IF NOT EXISTS "incident_timestamp_idx" ON "incident"("timestamp" DESC);
CREATE INDEX IF NOT EXISTS "incident_composite_zone_status_idx" ON "incident"("campus_zone", "status");

-- Audit trails for incident timeline & SLA tracking
CREATE TABLE IF NOT EXISTS "incident_audit_log" (
    "id" SERIAL PRIMARY KEY,
    "incident_id" VARCHAR(64) NOT NULL REFERENCES "incident"("id") ON DELETE CASCADE,
    "event_type" VARCHAR(128) NOT NULL,
    "actor" VARCHAR(255) NOT NULL,
    "details" TEXT NOT NULL,
    "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS "audit_incident_idx" ON "incident_audit_log"("incident_id");

-- Seed responders
INSERT INTO "responder" ("id", "name", "role", "phone", "is_available", "current_zone", "current_x_ratio", "current_y_ratio")
VALUES
    ('RESP-01', 'Officer Danladi', 'Campus Security Patrol', '+234 800 000 1111', FALSE, 'Hostel Quad', 0.65, 0.35),
    ('RESP-02', 'Nurse Fatima', 'Emergency Medical Staff', '+234 800 000 2222', TRUE, 'Campus Clinic', 0.86, 0.70),
    ('RESP-03', 'Patrol Team Delta', 'Rapid Security Response', '+234 800 000 3333', TRUE, 'Central Library', 0.62, 0.65),
    ('RESP-04', 'Capt. Ibrahim', 'Fire Safety Marshal', '+234 800 000 4444', TRUE, 'Engineering Annex', 0.25, 0.68)
ON CONFLICT ("id") DO NOTHING;

-- Seed sample incidents
INSERT INTO "incident" ("id", "category", "description", "campus_zone", "room_number", "latitude", "longitude", "x_ratio", "y_ratio", "urgency", "status", "timestamp", "assigned_responder_id", "eta_seconds")
VALUES
    ('INC-8041', 'Medical', 'Severe asthma attack, student struggling to breathe.', 'Science Block B', 'Room 204', 6.5244, 3.3792, 0.28, 0.32, 'high', 'pending', CURRENT_TIMESTAMP - INTERVAL '2 minutes', NULL, 120),
    ('INC-8040', 'Security', 'Physical confrontation reported near gate exit.', 'Hostel Quad', 'Gate 3', 6.5255, 3.3801, 0.72, 0.28, 'medium', 'enRoute', CURRENT_TIMESTAMP - INTERVAL '11 minutes', 'RESP-01', 45),
    ('INC-8039', 'Fire / Hazard', 'Small chemical spill extinguished; room needs ventilation.', 'Engineering Annex', 'Lab 4', 6.5230, 3.3780, 0.25, 0.68, 'low', 'resolved', CURRENT_TIMESTAMP - INTERVAL '1 hour', 'RESP-02', NULL)
ON CONFLICT ("id") DO NOTHING;
