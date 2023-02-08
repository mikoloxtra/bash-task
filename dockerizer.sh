#!/bin/bash

#!/bin/bash

# Set the website name from the command line argument
website=$1

# Create the Dockerfile
cat > Dockerfile << EOF
FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libzip-dev \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        iconv \
        mbstring \
        pdo \
        pdo_mysql \
        zip

WORKDIR /var/www/$website

COPY . /var/www/$website

RUN chown -R www-data:www-data /var/www/$website \
    && find /var/www/$website -type d -exec chmod 755 {} + \
    && find /var/www/$website -type f -exec chmod 644 {} +
EOF

# Create the docker-compose.yml file
cat > docker-compose.yml << EOF
version: '3'

services:
  web:
    build: .
    ports:
      - "80:80"
    volumes:
      - ./:/var/www/$website
  db:
    image: mysql:8.0
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: $website
      MYSQL_USER: $website
      MYSQL_PASSWORD: secret
EOF

# Create the Nginx virtual host folder
mkdir -p nginx/vhosts

# Create the Nginx virtual host file
cat > nginx/vhosts/$website << EOF
server {
    listen 80;
    server_name $website;
    root /var/www/$website/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass web:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/$website/public;
    }
}
EOF
