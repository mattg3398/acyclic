<!--
SPDX-FileCopyrightText: 2025 Matt Gleason <mattg3398@gmail.com>
SPDX-License-Identifier: GPL-3.0-or-later
-->

# Structure

## Database

Later on, I plan to add a logging plugin that will allow me to show concise edit history notes for every relationship in the database.

- Tasks: one Domain to many Tasks
  - UUID
  - Domain ID
  - Author: User ID
  - Number: sequential per Domain
  - Next Comment Number
  - Title: markdown string
  - Body: markdown string
  - Estimate: serialized estimate value
  - Subtasks estimate: serialized estimate sum
  - Estimator: user ID
  - Cached subtask estimate total
  - Timestamp
  - Status enum: smallint >= 0

- TaskChildren: many Parents to many Children
  - UUID
  - Domain ID
  - Creator: User ID
  - Parent Task ID
  - Child Task ID
  - Timestamp

- Tags: one Domain to many Tags
  - UUID
  - Domain ID
  - Master: boolean
  - Title: string
  - color

- TaskTags: many Tasks to many Tags
  - UUID
  - Domain ID
  - Creator: User ID
  - Tag ID
  - Timestamp

- TaskComments: one Task to many Comments
  - UUID
  - Domain ID
  - Task ID
  - Author: User ID
  - Number: sequential per Task
  - Body: markdown string

- Users
  - UUID
  - Display Name
  - Profile Picture
  - Email
  - Color scheme
  - Login info

- TaskAssignments: many Tasks to many Users
  - UUID
  - Domain ID
  - Task ID
  - Assigner ID
  - Assignee ID
  - Timestamp

- Domains
  - UUID
  - Display Name
  - Unique slug
  - Icon URL
  - Next Task Number
  - Estimate type
  - Visibility (invite-only, public)
  - Task number format enum: smallint >= 0
  - Subscription level? smallint >= 0

- DomainRoles: many Domains to many Users
  - UUID
  - Domain ID
  - User ID
  - Role enum
  - Permissions bitmask

## Enums

    pub enum Status {
        Planning,
        Backlog,
        Progress,
        Review,
        Testing,
        Done,
        Canceled,
        Maintenance,
    }

    // XXS, XS, S, M, L, XL, XXL
    pub struct ShirtSize([i32; 7]);
    // Minutes, Hours, Days, Weeks, Months, Years, Decades, Centuries
    pub struct TimeScale([i32; 8]);

    pub enum Estimate {
        Minutes(i32),  // Use i32 instead of u32 to match database
        ShirtSize(ShirtSize),
        TimeScale(TimeScale),
    }

    bitflags::bitflags! {
        pub struct Permission: u32 {
            const READ              = 0b0000000000000000;
            const MANAGE_TASK       = 0b0000000000000001;
            const MANAGE_TAG        = 0b0000000000000010;
            const DELETE            = 0b0000000000000100;
            const MANAGE_MEMBERS    = 0b0000000000001000;
            const MANAGE_ADMINS     = 0b0000000000010000;
            const INVITE_OWNERS     = 0b0000000000100000;
            const MANAGE_DOMAIN     = 0b0000000001000000;
        }
    }

    // Use ordering to easily check role rank
    // Convert to default permissions bitmasks
    pub enum Role {
        OWNER,
        ADMIN,
        MEMBER,
        VIEWER,
    }

## Runtime Structure

- List of Domains
  - DAG of Tasks
  - Potentially a Dashmap, LRUcache/RWLock, or other simultaneous access modifier

- Task DAG Node
  - ID
  - List of Child task IDs
  - Estimate enum aggregated from children
  - All tag IDs added to the task and inherited from parents

## HTTP Interface

- Create User (POST)
  - Display Name
  - Email
  - Profile picture
  - Check if email is already in use and suggest login

- Create Domain (POST)
  - User ID
  - Domain Name
  - Task number format
  - Check if domain name is taken and suggest changing it
  - Add User ID, Domain ID, and Owner role to DomainRoles

- Add/Manage User in Domain (POST)
  - Admin: User ID
  - Domain ID
  - Target: User ID
  - Target Role
  - Target Permissions
  - Check admin's permissions and target's role and permissions

- Remove Self from Domain (POST)
  - User ID
  - Domain ID

- Create Task (POST)
  - Author: User ID
  - Domain ID
  - Title
  - Body
  - Estimate
  - Status
  - Assignees
  - Tags
  - Parent tasks
  - Check author's permissions
  - Notify users in the domain that were assigned or tagged
  - Add as child of parent tasks, inherit their master tags and add to their estimates recursively

- Create Tag (POST)
  - User ID
  - Domain ID
  - Title
  - Master: boolean
  - Color
  - Icon ID
  - Check user's permissions

- Create TagIcon (POST)
  - User ID
  - Domain ID
  - Icon URL
  - Check user's permissions

- Add Subtask to Task (POST)
  - User ID
  - Domain ID
  - Task ID
  - Subtask ID
  - Check user's permissions and ensure the task isn't a child of the subtask
  - Add task's master tags to subtasks recursively
  - Add subtask's estimate to task's estimate and its parent's estimates recursively

- Add Tag to Task (POST)
  - User ID
  - Domain ID
  - Task ID
  - Tag ID
  - Check user's permissions
  - Add master tags on to subtasks recursively

- Edit Task Estimate (POST)
  - User ID
  - Domain ID
  - Task ID
  - New Estimate
  - Check user's permissions
  - Add difference to parent's estimates recursively

- Edit Task Body/Title (POST)
  - User ID
  - Domain ID
  - Task ID
  - New Body/Title
  - Check user's permissions and if user is the task's author
  - Notify users in the domain that were tagged

- Edit Comment (POST)
  - User ID
  - Domain ID
  - Task ID
  - Comment ID
  - New comment
  - Notify users in the domain that were tagged

- Edit Task Status (POST)
  - User ID
  - Domain ID
  - Task ID
  - New Status
  - Check user's permissions
  - If moving to Done or Canceled
    - Check if child tasks are done
    - Remove its estimate from its parent's estimates recursively
  - If moving from Done or Canceled
    - Move parent tasks to same status
    - Add its estimate to its parent's estimates recursively

- View Domain DAG (GET)
  - User ID
  - Domain ID
  - Check if user is in Domain
  - Respond with list of Task IDs with Titles, Estimates, Tags, Assignees, and master list of edges
  - If DAG is large, break down into self-contained subgraphs that can be loaded with additional "View Subgraph" GETs

- Filter Domain DAG by title/estimate/tag (GETs)
  - User ID
  - Domain ID
  - Filter value
  - Check if user is in Domain
  - Respond with list of matching tasks

- View Subgraph (GET)
  - User ID
  - Domain ID
  - Head Task ID
  - Check if user is in Domain
  - Respond with lists of tasks and edges
  - If DAG is large, break down into self-contained subgraphs that can be loaded with additional "View Subgraph" GETs

- View Task (GET)
  - User ID
  - Domain ID
  - Task ID
  - Check if user is in Domain
  - Respond with Task Body and Comments
