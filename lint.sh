#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2025 Matt Gleason <mattg3398@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
set -e

reuse lint
cargo fmt --all --check
cargo sort --check */Cargo.toml
cargo audit
cargo clippy --workspace --all-targets -- -D warnings
RUSTFLAGS="-D warnings" cargo check --workspace --all-targets
