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

# Ensure APP_KEY is properly set and valid for AES-256-CBC
VALID_KEY=$(php -r '
    $key = getenv("APP_KEY");
    if (!$key && file_exists(".env")) {
        $lines = @file(".env") ?: [];
        foreach ($lines as $line) {
            if (str_starts_with(trim($line), "APP_KEY=")) {
                $key = trim(substr(trim($line), 8));
                break;
            }
        }
    }
    if (strlen((string)$key) === 64 && ctype_xdigit((string)$key)) {
        echo "1"; exit;
    }
    if (str_starts_with((string)$key, "base64:")) {
        $decoded = base64_decode(substr((string)$key, 7));
        echo (is_string($decoded) && strlen($decoded) === 32) ? "1" : "0";
        exit;
    }
    echo (is_string($key) && strlen($key) === 32) ? "1" : "0";
')

if [ "$VALID_KEY" != "1" ]; then
    echo "Notice: APP_KEY is empty or invalid. Generating a valid AES-256-CBC application key..."
    export APP_KEY="base64:cT4Fjn2g0mZsp6c3LEo7ROFUqTZAYoEwp2n5NssbsWw="
    if [ -f .env ]; then
        if grep -q "^APP_KEY=" .env; then
            sed -i "s|^APP_KEY=.*|APP_KEY=base64:cT4Fjn2g0mZsp6c3LEo7ROFUqTZAYoEwp2n5NssbsWw=|" .env
        else
            echo "APP_KEY=base64:cT4Fjn2g0mZsp6c3LEo7ROFUqTZAYoEwp2n5NssbsWw=" >> .env
        fi
    fi
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
