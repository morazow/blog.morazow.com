FROM ruby:3.2

WORKDIR /site

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 2.4.18 && bundle install

EXPOSE 4000

ENTRYPOINT ["bundle", "exec", "jekyll"]
CMD ["build"]
