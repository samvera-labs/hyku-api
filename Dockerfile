# Base stage for building final images
FROM phusion/passenger-ruby27:2.0.0 as base_image

RUN install_clean --allow-unauthenticated \
	sendmail \
	libxml2-dev \
	libxslt-dev \
	dumb-init \
	default-jre \
	ghostscript \
	imagemagick \
	libpq-dev \
	libreoffice \
	libsasl2-dev \
	netcat \
	postgresql-client \
	rsync \
	zip \
	unzip \
	gnupg2 \
	ffmpeg \
	vim

RUN apt clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# If changes are made to fits version or location, amend `LD_LIBRARY_PATH` in docker-compose.yml accordingly.
RUN mkdir -p /opt/fits && \
    curl -fSL -o /opt/fits/fits-latest.zip https://projects.iq.harvard.edu/files/fits/files/fits-1.3.0.zip && \
    cd /opt/fits && unzip fits-latest.zip && \
    chmod +X /opt/fits/fits.sh

# Entry point from the docker-compose - last stage as Docker works backwards
FROM base_image as development_image

WORKDIR /home/app

COPY --chown=app:app . /home/app
COPY --chown=app:app lib/hyku/api/version.rb ./lib/hyku/api/version.rb
COPY --chown=app:app hyku-api.gemspec ./hyku-api.gemspec
COPY --chown=app:app Gemfile ./Gemfile
COPY --chown=app:app Gemfile.lock ./Gemfile.lock
COPY --chown=app:app spec/internal_test_hyku/Gemfile ./spec/internal_test_hyku/Gemfile
COPY --chown=app:app spec/internal_test_hyku/Gemfile.lock ./spec/internal_test_hyku/Gemfile.lock

ENV CFLAGS=-Wno-error=format-overflow
RUN bundle config build.nokogiri --use-system-libraries \
	&& bundle config set without 'production' \
	&& bundle config set with 'aws development test postgres' \
	&& setuser app bundle install --jobs=4 --retry=3

RUN chmod 777 .bundle/config # Otherwise `app` owns this file and the host cannot run bundler commands
