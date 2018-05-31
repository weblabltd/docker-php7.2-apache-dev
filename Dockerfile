FROM ubuntu:xenial
MAINTAINER Alexander Marinov <alexander.marinov@web-lab.ltd>

ENV DEBIAN_FRONTEND noninteractive

# Setup the Ubuntu PPA for PHP - https://launchpad.net/~ondrej/+archive/ubuntu/php
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv 14AA40EC0831756756D7F66C4F4EA0AAE5267A6C && \
      echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu xenial main" > /etc/apt/sources.list.d/ondrej-ubuntu-php-xenial.list

# Setup Apache using mod_php
RUN apt-get update && \
    apt-get -y install \
		supervisor \
		apache2 \
		libapache2-mod-php7.2 \
		php7.2-common \
		php7.2-cli \
		php7.2-mysql \
		php7.2-intl \
		php7.2-curl \
		php-memcached \
		php7.2-mbstring \
		php-xdebug \
		php7.2-gd \
		php7.2-gmagick \
		php7.2-xml \
		php7.2-bcmath \
		php7.2-zip \
    && apt-get autoremove -y \
    && apt-get clean all && \
    echo "ServerName php72.dev.localhost" >> /etc/apache2/apache2.conf

RUN mkdir -p /opt/docker

COPY docker/*.sh /opt/docker/
COPY docker/supervisord-apache2.conf /etc/supervisor/conf.d/apache2.conf

RUN chmod 755 /opt/docker/*.sh

# Environment variables to configure php
ENV PHP_UPLOAD_MAX_FILESIZE 40M
ENV PHP_POST_MAX_SIZE 50M
ENV PHP_MEMORY_LIMIT 256M

ENV PROJECT_DOCROOT /var/www/project
ENV PROJECT_WEBROOT /var/www/project/web

# Set XDebug's config
COPY docker/90-xdebug-custom.ini /etc/php/7.2/apache2/conf.d/

# Configure apache
RUN a2enmod rewrite ssl

COPY docker/apache-default.conf /etc/apache2/sites-available/000-default.conf
COPY docker/apache-default-ssl.conf /etc/apache2/sites-available/default-ssl.conf

RUN a2ensite default-ssl

RUN sed -ri ' \
	s!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g; \
	s!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g; \
	' /etc/apache2/apache2.conf

EXPOSE 80 443
CMD ["/opt/docker/bootstrap.sh"]
