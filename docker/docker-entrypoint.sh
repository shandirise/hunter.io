#!/bin/sh
set -e

# Dynamically bind Apache to the PORT provided by Koyeb / Render / Cloud Run (default: 8000)
PORT="${PORT:-8000}"
sed -i "s/Listen .*/Listen ${PORT}/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:[0-9]*>/<VirtualHost \*:${PORT}>/" /etc/apache2/sites-available/000-default.conf

# Ensure storage directories exist
mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs storage/app/public bootstrap/cache database

# Setup SQLite if using sqlite connection
if [ "${DB_CONNECTION:-sqlite}" = "sqlite" ]; then
    if [ ! -f database/database.sqlite ]; then
        touch database/database.sqlite
    fi
fi

# Ensure .env exists
if [ ! -f .env ]; then
    cp .env.example .env
fi

# Generate APP_KEY if not set in environment or in .env
if [ -z "$APP_KEY" ]; then
    echo "Notice: APP_KEY is empty. Generating an application key..."
    php artisan key:generate --force
fi

# Run database migrations
echo "Running database migrations..."
php artisan migrate --force

# Seed demo opportunities if needed
echo "Seeding opportunity demo data..."
php artisan db:seed --class=OpportunitySeeder --force || true

# CRITICAL: Grant full ownership and write permissions to www-data AFTER all artisan commands have run
echo "Setting runtime permissions for www-data..."
chown -R www-data:www-data storage bootstrap/cache database .env
chmod -R 775 storage bootstrap/cache database
chmod 664 .env
chmod -R 664 database/database.sqlite* 2>/dev/null || true

echo "Fundor application ready. Starting Apache web server on port ${PORT}..."
exec "$@"
