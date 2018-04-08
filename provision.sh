#!/bin/bash

VAGRANT_ROOT="/var/www"
DOCUMENT_ROOT="/var/www/drupal"

APPLICATION_NAME="my-project"
APPLICATION_HOMEPAGE="http://localhost:8090"

GIT_PROJECT_NAME="Drupal"
GIT_PROJECT_REPOSITORY="http://git.drupal.org/project/drupal.git"
GIT_PROJECT_BRANCH="8.4.x"

MYSQL_HOST=localhost
MYSQL_LOGIN=root
MYSQL_PASSWORD=root

MYSQL_DB_NAME=my_project
MYSQL_DB_LOGIN=my_user
MYSQL_DB_PASSWORD=my_password

debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD"

debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $MYSQL_PASSWORD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_PASSWORD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $MYSQL_PASSWORD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"

# Fix for https://bugs.launchpad.net/ubuntu/+source/livecd-rootfs/+bug/1561250
if ! grep -q "ubuntu-xenial" /etc/hosts; then
    echo "127.0.0.1 ubuntu-xenial" >> /etc/hosts
fi

# Install dependencies
add-apt-repository ppa:ondrej/php
apt-get update

# install basics
apt-get install -y apache2 libapache2-mod-php7.0 git curl php7.0 php7.0-bcmath php7.0-bz2 php7.0-cli php7.0-curl php7.0-intl php7.0-json php7.0-mbstring

# install mysql phpmyadmin
apt-get install -y mysql-server phpmyadmin php7.0-mysql

# install ldap
apt-get install -y php7.0-ldap

# install cas
apt-get install -y php7.0-soap php7.0-xml php7.0-xsl

# install miscelleanous
apt-get install -y php7.0-zip php7.0-gd

# Configure Apache
echo "
<VirtualHost *:80>
    ServerName $APPLICATION_NAME.local
    DocumentRoot $DOCUMENT_ROOT
    AllowEncodedSlashes On
    
    <Directory $DOCUMENT_ROOT>
		Options -Indexes +FollowSymLinks
        DirectoryIndex index.php index.html
        Order allow,deny
        Allow from all
        AllowOverride All
    </Directory>
    
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
" > /etc/apache2/sites-available/000-default.conf

# Active erreurs php
sudo sed -i.bak 's/display_errors = Off/display_errors = On/g' /etc/php/7.0/apache2/php.ini

a2enmod rewrite
service apache2 restart

if [ -e /usr/local/bin/composer ]; then
    /usr/local/bin/composer self-update
else
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi

# Reset home directory of vagrant user
if ! grep -q "cd /var/www" /home/ubuntu/.profile; then
    echo "cd /var/www" >> /home/ubuntu/.profile
fi

if [ ! -f /var/log/databasesetup ];
then
    echo "CREATE USER '$MYSQL_DB_LOGIN'@'$MYSQL_HOST' IDENTIFIED BY '$MYSQL_DB_PASSWORD'" | mysql -u$MYSQL_LOGIN -p$MYSQL_PASSWORD
    echo "CREATE DATABASE IF NOT EXISTS $MYSQL_DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci" | mysql -u$MYSQL_LOGIN -p$MYSQL_PASSWORD
    echo "GRANT ALL ON $MYSQL_DB_NAME.* TO '$MYSQL_DB_LOGIN'@'$MYSQL_HOST'" | mysql -u$MYSQL_LOGIN -p$MYSQL_PASSWORD
    echo "flush privileges" | mysql -u$MYSQL_LOGIN -p$MYSQL_PASSWORD

    touch /var/log/databasesetup

    if [ -f /var/www/$MYSQL_DB_NAME.sql ];
    then
        mysql -u$MYSQL_LOGIN -p$MYSQL_PASSWORD $MYSQL_DB_NAME < /var/www/$MYSQL_DB_NAME.sql
    fi
fi

if [ ! -d $DOCUMENT_ROOT ];
then
	mkdir $DOCUMENT_ROOT
	chown www-data:www-data -R $DOCUMENT_ROOT
	echo "Going to $GIT_PROJECT_NAME directory..."
	cd $DOCUMENT_ROOT
	echo "Retrieving $GIT_PROJECT_NAME version $GIT_PROJECT_BRANCH..."
	git clone --branch $GIT_PROJECT_BRANCH $GIT_PROJECT_REPOSITORY .
	echo "Checking out $GIT_PROJECT_NAME version $GIT_PROJECT_BRANCH..."
	git checkout $GIT_PROJECT_BRANCH
fi

echo "Updating with composer..."
cd $DOCUMENT_ROOT
sudo composer update
sudo composer update

echo "** Visit $APPLICATION_HOMEPAGE in your browser for to view the application $APPLICATION_NAME **"