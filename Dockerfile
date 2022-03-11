FROM ruby:2.3.8

RUN apt-get update && \
    apt-get install -y --force-yes libruby aspell-es aspell-en libxml2-dev \
                       libxslt1-dev libmagickcore-dev libmagickwand-dev imagemagick \
                       zlib1g-dev build-essential \
                       libqtwebkit-dev libreadline-dev libsqlite3-dev libssl-dev \
                       libffi-dev

ENV app /usr/src/app

ARG RAILS_ENV
ENV RAILS_ENV=${RAILS_ENV:-production}

RUN if [ "$RAILS_ENV" = "development" ]; \
    then sed -i -e 's=^mozilla/DST_Root_CA_X3.crt=!mozilla/DST_Root_CA_X3.crt=' '/etc/ca-certificates.conf'; \
         update-ca-certificates; \
    fi

# Create app directory
WORKDIR $app

# Install app dependencies
ENV BUNDLE_PATH /usr/src/bundle
COPY Gemfile* $app/
RUN bundle install --path /usr/src/bundle --jobs 4

# Bundle app source
COPY . $app

# dumb-init
ADD dumb-init_1.2.0 /usr/bin/dumb-init
RUN chmod +x /usr/bin/dumb-init

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD [ "bundle", "exec", "rails", "server" ]
