# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t restaurants_api .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name restaurants_api restaurants_api

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.2
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# <<< IMPORTANTE: parametrize ambiente e bundler >>>
ARG RAILS_ENV=development
ARG BUNDLE_WITHOUT=""
ARG BUNDLE_DEPLOYMENT=0
ENV RAILS_ENV="${RAILS_ENV}" \
    BUNDLE_WITHOUT="${BUNDLE_WITHOUT}" \
    BUNDLE_DEPLOYMENT="${BUNDLE_DEPLOYMENT}" \
    BUNDLE_PATH="/usr/local/bundle"

FROM base AS build
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .
RUN bundle exec bootsnap precompile app/ lib/

FROM base
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# garanta que o entrypoint existe e é executável no repositório
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["bin/rails","server","-b","0.0.0.0","-p","3000"]
