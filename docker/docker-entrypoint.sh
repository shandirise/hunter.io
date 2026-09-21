#!/bin/sh
set -e

# Dynamically bind Apache to the PORT provided by Koyeb / Render / Cloud Run (default: 8000)
PORT="${PORT:-8000}"
sed -i "s/Listen .*/Listen ${PORT}/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:[0-9]*>/<VirtualHost \*:${PORT}>/" /etc/apache2/sites-available/000-default.conf

# Ensure storage directories exist and have proper permissions
mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs storage/app/public bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Generate APP_KEY if not provided
if [ -z "$APP_KEY" ]; then
    echo "Notice: APP_KEY is empty. Generating an application key..."
    php artisan key:generate --force
fi

# Setup SQLite if using sqlite connection
if [ "${DB_CONNECTION:-sqlite}" = "sqlite" ]; then
    mkdir -p database
    if [ ! -f database/database.sqlite ]; then
        touch database/database.sqlite
    fi
    chown -R www-data:www-data database
    chmod -R 775 database
    chmod 664 database/database.sqlite
fi

# Run database migrations
echo "Running database migrations..."
php artisan migrate --force

# Seed demo opportunities if needed
echo "Seeding opportunity demo data..."
php artisan db:seed --class=OpportunitySeeder --force || true

echo "Fundor application ready. Starting Apache web server on port ${PORT}..."
exec "$@"
