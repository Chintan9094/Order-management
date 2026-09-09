<?php

return [

    'paths' => ['api/*', 'sanctum/csrf-cookie', '*'],

    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],

    'allowed_origins' => ['*'],

    'allowed_origins_patterns' => [],

    'allowed_headers' => [
        'Content-Type',
        'Accept',
        'Authorization',
        'X-Requested-With',
        'X-Client-Session',
        'X-Session-Token',
        'X-XSRF-TOKEN',
    ],

    'exposed_headers' => [],

    'max_age' => 86400,

    'supports_credentials' => false,

];
