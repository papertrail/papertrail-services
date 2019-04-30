FROM ruby:2.6.3-slim
ENV PORT 3000

WORKDIR /app

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --fix-missing --no-install-recommends \
    build-essential \
    curl \
    git && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


COPY Gemfile Gemfile
RUN bundle install

COPY . .

ENTRYPOINT bundle exec unicorn -p $PORT -c ./config/unicorn.rb