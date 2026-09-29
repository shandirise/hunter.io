# ============================================================
# STAGE 1: Build Frontend React SPA
# ============================================================
FROM node:22-alpine AS frontend-builder
WORKDIR /build

# Install frontend dependencies (frontend now lives at the repo root: resources/js + src)
# Upstream manages dependencies with pnpm, so pnpm-lock.yaml is the source of truth (package-lock.json is not kept in sync)
RUN npm install -g pnpm@10
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Copy frontend source and build SPA into public/spa (vite root is resources/, outDir ../public/spa)
COPY vite.config.ts tsconfig.json tsconfig.app.json tsconfig.node.json openapi.yaml ./
COPY resources/ resources/
COPY src/ src/
RUN pnpm run build

# ============================================================
# STAGE 2: Production PHP 8.4 + Apache Server
# ============================================================
FROM php:8.4-apache AS production

# Install system utilities, zip library, and PHP extensions directly via official tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install zip bcmath \
    && a2enmod rewrite \
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
COPY resources/ resources/
COPY artisan ./
COPY .env.example .env

# Copy built frontend SPA from Stage 1 into public/spa
COPY --from=frontend-builder /build/public/spa public/spa

# Setup storage directory permissions BEFORE composer install (needed for artisan package:discover)
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs storage/app/public bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Install production PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Copy Apache configuration and entrypoint script
COPY docker/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose default port (Koyeb / Cloud standard)
EXPOSE 8000

ENV PORT=8000
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
ENV APP_ENV=production
ENV APP_DEBUG=true
ENV LOG_CHANNEL=stderr
ENV APP_KEY=base64:cT4Fjn2g0mZsp6c3LEo7ROFUqTZAYoEwp2n5NssbsWw=
ENV DB_CONNECTION=sqlite
ENV DB_DATABASE=/var/www/html/database/database.sqlite
ENV SESSION_DRIVER=file

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]

