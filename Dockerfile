FROM ruby:3.3.6-slim

RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    libsqlite3-dev \
    sqlite3 \
    build-essential \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && truncate -s 0 /var/log/*log

RUN gem update --system && \
    gem install bundler

WORKDIR /app

COPY . .

RUN bundle install

CMD ["/usr/bin/bash"]
