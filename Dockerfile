FROM php:8.3-apache

ARG MOODLE_URL="https://download.moodle.org/download.php/stable502/moodle-latest-502.tgz"

ENV TZ=Asia/Jakarta

RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata \
    curl \
    ca-certificates \
    tar \
    unzip \
    graphviz \
    aspell \
    ghostscript \
    clamav \
    libcurl4-openssl-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libwebp-dev \
    libicu-dev \
    libxml2-dev \
    libzip-dev \
    libldap2-dev \
    libpq-dev \
    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
    && docker-php-ext-install -j$(nproc) \
        mysqli \
        pdo_mysql \
        pgsql \
        pdo_pgsql \
        curl \
        gd \
        intl \
        soap \
        zip \
        ldap \
        opcache \
        exif \
        mbstring \
    && a2enmod rewrite headers expires \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "${MOODLE_URL}" -o /tmp/moodle.tgz \
    && tar -xzf /tmp/moodle.tgz -C /var/www/html/ \
    && rm /tmp/moodle.tgz

RUN mkdir -p /var/www/moodledata \
    && chown -R www-data:www-data /var/www/moodledata \
    && chmod -R 770 /var/www/moodledata \
    && chown -R www-data:www-data /var/www/html/moodle \
    && find /var/www/html/moodle -type d -exec chmod 755 {} \; \
    && find /var/www/html/moodle -type f -exec chmod 644 {} \;

COPY moodle.conf /etc/apache2/sites-available/moodle.conf
COPY moodle.ini /usr/local/etc/php/conf.d/moodle.ini

RUN a2dissite 000-default.conf \
    && a2ensite moodle.conf

WORKDIR /var/www/html/moodle

EXPOSE 80

CMD ["apache2-foreground"]