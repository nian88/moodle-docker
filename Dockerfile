FROM php:8.3-apache-bookworm

ARG MOODLE_URL="https://github.com/moodle/moodle/archive/refs/tags/v5.2.0.tar.gz"

ENV TZ=Asia/Jakarta
ENV DEBIAN_FRONTEND=noninteractive
ENV COMPOSER_ALLOW_SUPERUSER=1

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata \
    curl \
    ca-certificates \
    tar \
    unzip \
    git \
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
    libonig-dev \
    libpspell-dev \
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
        pspell \
    && a2enmod rewrite headers expires \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html/moodle \
    && curl -fL --retry 5 --retry-delay 5 "${MOODLE_URL}" -o /tmp/moodle.tar.gz \
    && tar -xzf /tmp/moodle.tar.gz -C /var/www/html/moodle --strip-components=1 \
    && rm /tmp/moodle.tar.gz

RUN cd /var/www/html/moodle \
    && composer install --no-dev --classmap-authoritative --no-interaction --prefer-dist

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