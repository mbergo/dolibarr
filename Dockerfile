FROM php:8.2-apache-bookworm

LABEL maintainer="Dolibarr Docker Maintainers"

# Environment variables
ENV PHP_INI_DATE_TIMEZONE='UTC' \
    PHP_INI_MEMORY_LIMIT='256M' \
    PHP_INI_UPLOAD_MAX_FILESIZE='20M' \
    PHP_INI_POST_MAX_SIZE='25M' \
    PHP_INI_ALLOW_URL_FOPEN='1' \
    PHP_INI_MAX_EXECUTION_TIME='300' \
    APACHE_DOCUMENT_ROOT='/var/www/html/htdocs' \
    DOLI_DOCUMENT_ROOT='/var/www/documents'

# Install system dependencies and PHP extensions
RUN apt-get update -y \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
        libc-client-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libkrb5-dev \
        libldap2-dev \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
        libicu-dev \
        libonig-dev \
        default-mysql-client \
        postgresql-client \
        cron \
        unzip \
        curl \
        git \
        vim \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        calendar \
        gd \
        intl \
        mysqli \
        pdo_mysql \
        soap \
        zip \
        opcache \
        exif \
        mbstring \
    && docker-php-ext-configure pgsql -with-pgsql \
    && docker-php-ext-install pdo_pgsql pgsql \
    && docker-php-ext-configure ldap --with-libdir=lib/$(gcc -dumpmachine)/ \
    && docker-php-ext-install -j$(nproc) ldap \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap

# Enable Apache modules
RUN a2enmod rewrite headers expires deflate ssl proxy proxy_http proxy_fcgi

# Use production PHP configuration as base
RUN mv ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini

# Configure PHP
RUN { \
        echo 'date.timezone = ${PHP_INI_DATE_TIMEZONE}'; \
        echo 'memory_limit = ${PHP_INI_MEMORY_LIMIT}'; \
        echo 'upload_max_filesize = ${PHP_INI_UPLOAD_MAX_FILESIZE}'; \
        echo 'post_max_size = ${PHP_INI_POST_MAX_SIZE}'; \
        echo 'allow_url_fopen = ${PHP_INI_ALLOW_URL_FOPEN}'; \
        echo 'max_execution_time = ${PHP_INI_MAX_EXECUTION_TIME}'; \
        echo 'display_errors = Off'; \
        echo 'log_errors = On'; \
        echo 'error_log = /dev/stderr'; \
        echo 'opcache.enable = 1'; \
        echo 'opcache.enable_cli = 0'; \
        echo 'opcache.memory_consumption = 256'; \
        echo 'opcache.interned_strings_buffer = 8'; \
        echo 'opcache.max_accelerated_files = 100000'; \
        echo 'opcache.revalidate_freq = 2'; \
        echo 'opcache.save_comments = 1'; \
    } > ${PHP_INI_DIR}/conf.d/dolibarr.ini

# Configure Apache
RUN { \
        echo '<VirtualHost *:80>'; \
        echo '    ServerName localhost'; \
        echo '    DocumentRoot ${APACHE_DOCUMENT_ROOT}'; \
        echo '    <Directory ${APACHE_DOCUMENT_ROOT}>'; \
        echo '        Options -Indexes +FollowSymLinks'; \
        echo '        AllowOverride All'; \
        echo '        Require all granted'; \
        echo '    </Directory>'; \
        echo '    ErrorLog ${APACHE_LOG_DIR}/error.log'; \
        echo '    CustomLog ${APACHE_LOG_DIR}/access.log combined'; \
        echo '</VirtualHost>'; \
    } > ${APACHE_CONFDIR}/sites-available/000-default.conf

# Create necessary directories
RUN mkdir -p /var/www/documents \
    && mkdir -p /var/www/html/htdocs/conf \
    && mkdir -p /var/www/html/htdocs/custom

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY --chown=www-data:www-data htdocs /var/www/html/htdocs
COPY --chown=www-data:www-data scripts /var/www/html/scripts
COPY --chown=www-data:www-data dev /var/www/html/dev
COPY --chown=www-data:www-data doc /var/www/html/doc

# Copy entrypoint script and database fixes
COPY docker-entrypoint.sh /usr/local/bin/
COPY init-db-fixes.sql /var/www/html/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/htdocs/conf \
    && chown -R www-data:www-data /var/www/documents \
    && chmod -R 775 /var/www/documents

# Expose port
EXPOSE 80

# Set entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# Start Apache
CMD ["apache2-foreground"]
