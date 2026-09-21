# ============================================================
# STAGE 1: Build Frontend React SPA
# ============================================================
FROM node:22-alpine AS frontend-builder
WORKDIR /build

# Install frontend dependencies
COPY frontend/package*.json ./frontend/
WORKDIR /build/frontend
RUN npm ci

# Copy frontend source and build SPA into ../public/spa
COPY frontend/ ./
RUN npm run build

# ============================================================
# STAGE 2: Production PHP 8.4 + Apache Server
# ============================================================
FROM php:8.4-apache AS production

# Install PHP extensions without heavy C compilation overhead
COPY --from=mlocati/php-extension-installer:latest /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_sqlite pdo_pgsql pdo_mysql bcmath zip \
    && a2enmod rewrite \
    && apt-get update && apt-get install -y --no-install-recommends git unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Optimize PHP memory limits for 512MB free tier containers
RUN echo "memory_limit = 128M" > /usr/local/etc/php/conf.d/docker-php-memlimit.ini


# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy backend application source
COPY composer.json composer.lock ./
COPY app/ app/
COPY bootstrap/ bootstrap/
COPY config/ config/
COPY database/ database/
COPY routes/ routes/
COPY public/ public/
COPY lang/ lang/
COPY artisan ./
COPY .env.example .env

# Copy built frontend SPA from Stage 1 into public/spa
COPY --from=frontend-builder /build/public/spa public/spa

# Install production PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Copy Apache configuration and entrypoint script
COPY docker/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Setup storage directory permissions
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs storage/app/public bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Expose default port (Koyeb / Cloud standard)
EXPOSE 8000

ENV PORT=8000
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
