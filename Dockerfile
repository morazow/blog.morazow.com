FROM ruby:2.5.1-alpine
MAINTAINER m.orazow <m.orazow@gmail.com>

RUN apk add --no-cache \
      libcurl          \
      build-base

ENV BLOG_PATH /tmp/blog
RUN mkdir -p $BLOG_PATH
WORKDIR $BLOG_PATH

ADD Gemfile* $BLOG_PATH/

## Install bundler & gems
RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc
RUN gem install bundler --no-document
RUN bundle install

EXPOSE 4000

ENTRYPOINT ["/usr/local/bin/bundle", "exec", "jekyll"]
