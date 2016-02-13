FROM ubuntu:14.04
MAINTAINER m.orazow <m.orazow@gmail.com>

## Install essentials
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get -y install \ 
    build-essential \
    wget curl nodejs \
    openssl libssl-dev zlib1g-dev \
    libyaml-dev libreadline-dev libxml2-dev libxslt1-dev

## Needed for pygments
RUN apt-get install python

## Install ruby
RUN wget http://ftp.ruby-lang.org/pub/ruby/2.2/ruby-2.2.3.tar.gz
RUN tar -xzvf ruby-2.2.3.tar.gz
RUN cd ruby-2.2.3 && ./configure --disable-install-doc && make && sudo make install

## Install bundler & gems
RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc
RUN gem install bundler --no-document

ENV BUNDLE_PATH=/gems

## Cleanup
RUN apt-get clean && apt-get purge \
      && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY . /tmp/blog
WORKDIR /tmp/blog
