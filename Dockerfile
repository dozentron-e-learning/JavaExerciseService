#danke für die schöne vorlage marcel
ARG ruby_version=2.6
ARG rails_version="6.0.0.rc1"
FROM ruby:${ruby_version}-alpine

ENV RAILS_VERSION=${rails_version:-6.0.0.rc1}
ENV RAILS_ENV production
ENV TZ Europe/Berlin

EXPOSE 3000

ENTRYPOINT ["./start.sh"]

WORKDIR /application

RUN apk add --no-cache build-base libxml2-dev libxslt-dev libxml2 libxslt tzdata && \
  gem install bundler && gem install rails --version "= ${RAILS_VERSION}" && \
  apk del --no-cache build-base libxml2-dev libxslt-dev && \
  mkdir config && \
  ln -s /run/secrets/master.key config/master.key

ADD Gemfile* /application/

RUN apk add --no-cache build-base libxml2-dev libxslt-dev git && \
  bundle install --without development test --deployment && \
  apk del --no-cache build-base libxml2-dev libxslt-dev git

ADD . /application
RUN chmod +x start.sh
