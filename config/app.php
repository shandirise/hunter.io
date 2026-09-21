<?php

/**
 * Application General Configuration.
 */

return [

    'name' => env('APP_NAME', 'Fundor.hu'),

    'env' => env('APP_ENV', 'production'),

    'debug' => (bool) env('APP_DEBUG', false),

    'url' => env('APP_URL', 'http://localhost'),

    'timezone' => env('APP_TIMEZONE', 'UTC'),

    'locale' => env('APP_ENV') === 'production' ? 'hu' : 'en',

    'fallback_locale' => env('APP_FALLBACK_LOCALE', 'en'),

    'faker_locale' => env('APP_FAKER_LOCALE', 'hu_HU'),

    'cipher' => 'AES-256-CBC',

    'key' => (function () {
        $key = env('APP_KEY');
        if (empty($key)) {
            return 'base64:cT4Fjn2g0mZsp6c3LEo7ROFUqTZAYoEwp2n5NssbsWw=';
        }
        if (strlen($key) === 64 && ctype_xdigit($key)) {
            return 'base64:' . base64_encode(hex2bin($key));
        }
        if (str_starts_with($key, 'base64:')) {
            $decoded = base64_decode(substr($key, 7));
            if (strlen($decoded) === 32) {
                return $key;
            }
        }
        if (strlen($key) === 32) {
            return $key;
        }
        return 'base64:cT4Fjn2g0mZsp6c3LEo7ROFUqTZAYoEwp2n5NssbsWw=';
    })(),

    'previous_keys' => [
        ...array_filter(
            explode(',', env('APP_PREVIOUS_KEYS', ''))
        ),
    ],

    'maintenance' => [
        'driver' => env('APP_MAINTENANCE_DRIVER', 'file'),
        'store' => env('APP_MAINTENANCE_STORE', 'database'),
    ],

];
