#!/bin/sh

#### BEGIN CONFIGURATION ####

# set dump directory variables
SRCDIR='/tmp/s3backups'
DESTDIR='backup'
BUCKET='j2mariadb'

# database access details
HOST='127.0.0.1'
PORT='3306'
USER='username'
PASS='password'

NOW=$(date +"%Y.%m.%d.%H.%M")
#### END CONFIGURATION ####

# make the temp directory if it doesn't exist and cd into it
mkdir -p $SRCDIR
cd $SRCDIR

databases=`mysql -h $HOST --user=$USER --password=$PASS -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`


for DB in $databases;
do
if [ "$DB" != "information_schema" ] && [ "$DB" != _* ] ; then
        echo "Dumping database: $DB"
mysqldump -h $HOST --force --opt --user=$USER --password=$PASS --add-drop-database  --databases $DB > $NOW-$DB.sql

tar -czPf $NOW-$DB.tar.gz $NOW-$DB.sql
fi
/bin/aws --profile j2sqlbackup s3 cp $SRCDIR/$NOW-$DB.tar.gz s3://$BUCKET/$DESTDIR/
done

# remove all files in our source directory
cd
rm -f $SRCDIR/*
