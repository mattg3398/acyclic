-- SPDX-FileCopyrightText: 2025 Matt Gleason <mattg3398@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-or-later

CREATE DOMAIN DISPLAY_NAME AS VARCHAR(64);
CREATE DOMAIN TASK_TITLE AS VARCHAR(128);

CREATE DOMAIN EMAIL_ADDRESS AS VARCHAR(254)
    CONSTRAINT HAS_AT CHECK (POSITION('@' IN VALUE) > 1);

-- This will often be used as an enum variant
CREATE DOMAIN WHOLE_NUM AS INTEGER
    CONSTRAINT NOT_NEGATIVE CHECK (VALUE >= 0);

CREATE TABLE USERS (
    user_id BIGSERIAL PRIMARY KEY,
    name DISPLAY_NAME NOT NULL,
    email EMAIL_ADDRESS NOT NULL UNIQUE,
    picture_url TEXT NOT NULL,
    theme WHOLE_NUM NOT NULL DEFAULT 0,
    -- TODO: pick hashing algorithm and maybe set length constraint
    password_hash TEXT NOT NULL,
    email_notifications BOOLEAN NOT NULL DEFAULT TRUE,
    time_created TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE DOMAINS (
    domain_id BIGSERIAL PRIMARY KEY,
    name DISPLAY_NAME NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    visibility WHOLE_NUM NOT NULL DEFAULT 0,
    picture_url TEXT NOT NULL,
    next_task_number INTEGER NOT NULL DEFAULT 0,
    next_comment_number INTEGER NOT NULL DEFAULT 0,
    task_num_format WHOLE_NUM NOT NULL DEFAULT 0,
    estimate_type WHOLE_NUM NOT NULL DEFAULT 0,
    time_created TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE DOMAIN_MEMBERS (
    member_id BIGSERIAL PRIMARY KEY,
    domain_id BIGSERIAL NOT NULL REFERENCES DOMAINS(domain_id) ON DELETE CASCADE,
    creator_id BIGSERIAL REFERENCES USERS(user_id) ON DELETE SET NULL,
    user_id BIGSERIAL REFERENCES USERS(user_id) ON DELETE CASCADE,
    role WHOLE_NUM NOT NULL DEFAULT 0,
    permissions INTEGER NOT NULL DEFAULT 0,
    time_created TIMESTAMPTZ DEFAULT now(),
    UNIQUE(domain_id, user_id)
);

CREATE TABLE TASKS (
    task_id BIGSERIAL PRIMARY KEY,
    domain_id BIGSERIAL NOT NULL REFERENCES DOMAINS(domain_id) ON DELETE CASCADE,
    author_id BIGSERIAL REFERENCES USERS(user_id) ON DELETE SET NULL,
    task_number INTEGER NOT NULL,
    title TASK_TITLE NOT NULL,
    body TEXT NOT NULL DEFAULT '',
    estimate JSONB,
    subtask_total_estimate JSONB,
    status WHOLE_NUM NOT NULL DEFAULT 0,
    deadline TIMESTAMPTZ,
    time_created TIMESTAMPTZ DEFAULT now(),
    UNIQUE(domain_id, task_number)
);

CREATE OR REPLACE FUNCTION assign_next_task_number()
RETURNS TRIGGER AS $$
DECLARE
    next_number INTEGER;
BEGIN
    UPDATE domains
    SET next_task_number = next_task_number + 1
    WHERE domain_id = NEW.domain_id
    RETURNING next_task_number - 1 INTO next_number;

    NEW.task_number := next_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_task_number
BEFORE INSERT ON TASKS
FOR EACH ROW
EXECUTE FUNCTION assign_next_task_number();

CREATE TABLE TASK_CHILDREN (
    relation_id BIGSERIAL PRIMARY KEY,
    domain_id BIGSERIAL NOT NULL REFERENCES DOMAINS(domain_id) ON DELETE CASCADE,
    user_id BIGSERIAL REFERENCES USERS(user_id) ON DELETE SET NULL,
    task_id BIGSERIAL NOT NULL REFERENCES TASKS(task_id) ON DELETE CASCADE,
    child_id BIGSERIAL NOT NULL REFERENCES TASKS(task_id) ON DELETE CASCADE,
    time_created TIMESTAMPTZ DEFAULT now(),
    UNIQUE(task_id, child_id)
);

CREATE TABLE TASK_ASSIGNMENTS (
    assignment_id BIGSERIAL PRIMARY KEY,
    domain_id BIGSERIAL NOT NULL REFERENCES DOMAINS(domain_id) ON DELETE CASCADE,
    task_id BIGSERIAL NOT NULL REFERENCES TASKS(task_id) ON DELETE CASCADE,
    assigner_id BIGSERIAL REFERENCES USERS(user_id) ON DELETE SET NULL,
    assignee_id BIGSERIAL REFERENCES USERS(user_id) ON DELETE SET NULL,
    time_created TIMESTAMPTZ DEFAULT now(),
    UNIQUE(task_id, assignee_id)
);

CREATE TABLE TASK_COMMENTS (
    comment_id BIGSERIAL PRIMARY KEY,
    domain_id BIGSERIAL NOT NULL REFERENCES DOMAINS(domain_id) ON DELETE CASCADE,
    task_id BIGSERIAL NOT NULL REFERENCES TASKS(task_id) ON DELETE CASCADE,
    author_id BIGSERIAL REFERENCES USERS(user_id) ON DELETE SET NULL,
    comment_number INTEGER NOT NULL,
    body TEXT NOT NULL DEFAULT '',
    time_created TIMESTAMPTZ DEFAULT now(),
    time_edited TIMESTAMPTZ DEFAULT now()
);

CREATE OR REPLACE FUNCTION assign_next_comment_number()
RETURNS TRIGGER AS $$
DECLARE
    next_number INTEGER;
BEGIN
    UPDATE domains
    SET next_comment_number = next_comment_number + 1
    WHERE domain_id = NEW.domain_id
    RETURNING next_comment_number - 1 INTO next_number;

    NEW.comment_number := next_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_comment_number
BEFORE INSERT ON TASK_COMMENTS
FOR EACH ROW
EXECUTE FUNCTION assign_next_comment_number();

CREATE TABLE TAGS (
    tag_id BIGSERIAL PRIMARY KEY,
    domain_id BIGSERIAL NOT NULL REFERENCES DOMAINS(domain_id) ON DELETE CASCADE,
    is_master BOOLEAN NOT NULL DEFAULT FALSE,
    title DISPLAY_NAME NOT NULL,
    color INTEGER NOT NULL
);

CREATE TABLE TASK_TAGS (
    relation_id BIGSERIAL PRIMARY KEY,
    domain_id BIGSERIAL NOT NULL REFERENCES DOMAINS(domain_id) ON DELETE CASCADE,
    user_id BIGSERIAL REFERENCES USERS(user_id) ON DELETE SET NULL,
    task_id BIGSERIAL NOT NULL REFERENCES TASKS(task_id) ON DELETE CASCADE,
    tag_id BIGSERIAL NOT NULL REFERENCES TAGS(tag_id) ON DELETE CASCADE,
    time_created TIMESTAMPTZ DEFAULT now(),
    UNIQUE(task_id, tag_id)
);

CREATE TABLE TASK_LOGS (
    log_id BIGSERIAL PRIMARY KEY,
    task_id BIGSERIAL REFERENCES TASKS(task_id) ON DELETE CASCADE,
    domain_id BIGSERIAL NOT NULL REFERENCES DOMAINS(domain_id) ON DELETE CASCADE,
    user_id BIGSERIAL REFERENCES USERS(user_id) ON DELETE SET NULL,
    operation WHOLE_NUM NOT NULL DEFAULT 0,
    title TASK_TITLE,
    body_edited BOOLEAN NOT NULL DEFAULT FALSE,
    estimate JSONB,
    subtask_total_estimate JSONB,
    status WHOLE_NUM,
    deadline TIMESTAMPTZ,
    assignee_id BIGSERIAL REFERENCES USERS(user_id) ON DELETE SET NULL,
    tag_id BIGSERIAL REFERENCES TAGS(tag_id) ON DELETE CASCADE,
    child_id BIGSERIAL REFERENCES TASKS(task_id) ON DELETE CASCADE,
    time_changed TIMESTAMPTZ DEFAULT now()
);
