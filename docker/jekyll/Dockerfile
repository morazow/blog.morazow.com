FROM ruby:2.5.1-alpine
MAINTAINER m.orazow <m.orazow@gmail.com>

RUN apk add --no-cache \
      libcurl          \
      build-base

RUN mkdir -p /tmp/blog
VOLUME /tmp/blog
WORKDIR /tmp/blog

ADD Gemfile* /tmp/blog/

## Install bundler & gems
RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc
RUN gem install bundler --no-document
RUN bundle install

EXPOSE 4000

ENTRYPOINT ["/usr/local/bin/bundle", "exec"]
