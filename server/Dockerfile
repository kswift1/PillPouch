# syntax=docker/dockerfile:1

FROM rust:1-bookworm AS builder

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends pkg-config libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

COPY Cargo.toml Cargo.lock ./
COPY crates ./crates
COPY migrations ./migrations

RUN cargo build --release -p api --bin pillpouch-api

FROM debian:bookworm-slim AS runtime

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/pillpouch-api /usr/local/bin/pillpouch-api
COPY migrations ./migrations
COPY seed ./seed
COPY assets ./assets

ENV DATABASE_URL=sqlite:///data/pillpouch.db
ENV SEED_RECOMMENDATIONS_PATH=seed/recommendations.json
ENV SEED_CATEGORIES_PATH=seed/categories.json
ENV STATIC_ASSETS_DIR=assets
ENV RUST_LOG=info

EXPOSE 8080

CMD ["pillpouch-api"]
