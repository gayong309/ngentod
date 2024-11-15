#!/bin/bash

# Setup Pterodactyl Panel
cd /var/www/pterodactyl
composer install --no-dev --optimize-autoloader
php artisan key:generate
php artisan migrate --seed
php artisan p:environment:setup
php artisan p:environment:database
php artisan p:environment:mail
php artisan cache:clear
php artisan config:clear
php artisan view:clear

# Configure and start services
service mariadb start
service nginx start

# Start SSH server
/usr/sbin/sshd -D
