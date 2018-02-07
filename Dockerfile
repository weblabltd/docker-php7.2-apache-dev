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
#		php-xdebug \
		php7.2-gd \
		php-imagick \
		php7.2-xml \
		php7.2-bcmath \
		php7.2-zip \
#	necessary for pecl install
		php7.2-dev php-pear \
    && apt-get autoremove -y \
    && apt-get clean all && \
    echo "ServerName php72.dev.wlb.io" >> /etc/apache2/apache2.conf


# Install XDebug from pecl until there is a stable version
RUN pecl install xdebug-2.6.0beta1 && \
    echo 'zend_extension=/usr/lib/php/20170718/xdebug.so' > /etc/php/7.2/mods-available/xdebug.ini && \
    ln -s /etc/php/7.2/mods-available/xdebug.ini /etc/php/7.2/cli/conf.d/20-xdebug.ini && \
    ln -s /etc/php/7.2/mods-available/xdebug.ini /etc/php/7.2/apache2/conf.d/20-xdebug.ini


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
RUN a2enmod rewrite

COPY docker/apache-default.conf /etc/apache2/sites-available/000-default.conf

RUN sed -ri ' \
	s!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g; \
	s!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g; \
	' /etc/apache2/apache2.conf

EXPOSE 80
CMD ["/opt/docker/bootstrap.sh"]

