#!/bin/bash

echo "SHBANGGGG!!!"

echo -n "Enter the website name: "
read website_name

echo -n "Enter a port to deploy your site on: "
read port

root_dir=/var/www/$website_name/public
add_to_hosts="127.0.0.1     $website_name"

cat > /etc/nginx/sites-available/$website_name << EOF
server {
    listen $port;
    server_name $website_name;
    root $root_dir;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/$website_name/;
    }
}
EOF

ln -s /etc/nginx/sites-available/$website_name /etc/nginx/sites-enabled/

echo "$add_to_hosts" >> /etc/hosts

echo "The Nginx configuration file for $website_name has been created."

# Create directory structure
project_root="/var/www/$website_name"
mkdir -p "$project_root/"

# Set ownership and permissions
sudo chown -R www-data:www-data "$project_root"
sudo chmod -R 775 "$project_root"

# Create a bare-bone Laravel project
cd "$project_root"

composer create-project --prefer-dist laravel/laravel . 

# Create a database and user with the same name as the website
mysql -u root -e "CREATE DATABASE $website_name;"
mysql -u root -e "CREATE USER '$website_name'@'localhost' IDENTIFIED BY 'password';"
mysql -u root -e "GRANT ALL PRIVILEGES ON $website_name.* TO '$website_name'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

echo "database credentials created"

# Restart Nginx
sudo service nginx restart

echo "The Laravel project for $website_name has been created and the Nginx service has been restarted."

echo "Check if the site is up"

curl -R  $website_name:$port 
