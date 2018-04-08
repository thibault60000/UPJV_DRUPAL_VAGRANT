#!/bin/bash

VAGRANT_ROOT="/var/www"
DOCUMENT_ROOT="/var/www/drupal"

APPLICATION_NAME="my-project"
APPLICATION_HOMEPAGE="http://localhost:8090"

MYSQL_DB=my_project
MYSQL_DB_LOGIN=my_user
MYSQL_DB_PASSWORD=my_password

MYSQL_DB_DATE=`date +'%Y%m%d%H%M%S'`
MYSQL_DB_DUMP=$VAGRANT_ROOT/$MYSQL_DB-$MYSQL_DB_DATE.sql

cd $VAGRANT_ROOT

if [ ! -f $MYSQL_DB_DUMP ];
then
    echo "Database dump running..."
    mysqldump -u$MYSQL_DB_LOGIN -p$MYSQL_DB_PASSWORD $MYSQL_DB > $MYSQL_DB_DUMP
    
    if [ -f $MYSQL_DB_DUMP ];
    then
        echo "Database dump complete !"
        echo "The related file location is : $MYSQL_DB_DUMP"
    else 
        echo "Database dump failed !"
    fi
else
    echo "The file $MYSQL_DB_DUMP already exists !"
    echo "Database dump aborted !"
fi	
