<!--
SPDX-FileCopyrightText: 2025 Matt Gleason <mattg3398@gmail.com>
SPDX-License-Identifier: GPL-3.0-or-later
-->

# Acyclic
Acyclic will provide a task tracking service based on Directed Acyclic Graphs (DAGs) to model how tasks that depend on each other are ordered, accumulate their time totals, and automatically assign labels to new tasks based on where they are added in a DAG. Ideally this will be usable as a personal TODO list app, as well as an organizational tool.

## Planned Features
- Markdown for a task's description and comments section
- Time estimates accumulated from subtasks
- Indicate task path with the largest time estimate
- Task labels that can be inherited by a task's subtasks
- Task start dates and deadlines with calendar reminders
- Recurring tasks that are regularly opened along with their subtasks
- Task burndown charts
- Code linter that converts TODO comments to task drafts
- Integration with Github to automatically change the status of programming tasks

## Development

### Environment Setup

I'd like to protect the `dev` and `main` branches, as well as lint all code before it is committed. These git hooks do it all automatically.

    cp .githooks/* .git/hooks/

This project will be primarily develop in Rust. You may need `curl` to install it:

    sudo apt install curl

Follow the Rust installation instructions [here](https://www.rust-lang.org/tools/install). This will install `rustup` and `cargo`, but you may need to restart your terminal to update your `PATH` to include them.

Use `./lint.sh` and `./format.sh` to check and format code. Install the tools used in the scripts:

    rustup component add clippy
    cargo install cargo-audit cargo-sort
    sudo apt install reuse

More info on `reuse` can be found [here](https://reuse.software/spec-3.3/)

I found that [Postman](https://www.postman.com/downloads/) is useful for working with the backend.

For working with a local database, install Postgres, run it, and set a password:

    sudo apt install postgresql postgreql-contrib
    sudo pg_ctlcluster 16 main start
    sudo -u postgres psql postgres
    postgres=# \password postgres
    // Set password
    postgres=# quit

Stop Postgres when needed:

    sudo pg_ctlcluster 16 main stop

Install [pgadmin](https://www.pgadmin.org/download/pgadmin-4-apt/) and navigate to [http://127.0.0.1/pgadmin4](http://127.0.0.1/pgadmin4) to manage the database.
