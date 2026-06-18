FROM ruby:4.0.3

ARG RAILS_VERSION=8.1.3

RUN apt-get update -qq \
  && apt-get install --yes --no-install-recommends \
    build-essential \
    curl \
    git \
    libsqlite3-dev \
    nodejs \
    npm \
    sqlite3 \
  && rm -rf /var/lib/apt/lists/*

RUN gem install rails -v "${RAILS_VERSION}"

WORKDIR /workspace
