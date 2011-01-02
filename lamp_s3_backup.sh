#!/bin/bash

# ------------------------------------------------------------------------------------------ 
# LAMP Backup with S3
# note: to push the files to Amazon S3 you need to install s3cmd from http://s3tools.org/s3cmd
# author: Justen Doherty (phpchap@gmail.com)
# -

SITENAME="whitewater"  									# the name of your site, prepended to the backup folder  
TODAYS_BACKUP_DIRECTORY=$SITENAME"_backup_`date +%d%m%Y`"				# name of the backup folder, format: SITENAME_backup_ddmmyyyy 
BACKUP_DIRECTORY="/backup/"								# location on disk where backup is written
BACKUP_DESTINATION=$BACKUP_DIRECTORY$TODAYS_BACKUP_DIRECTORY"/source_`date +%s`.tar"	# full path to source will be tarred 
DIRECTORY_TO_BACKUP="home/whitewater"							# backup this folder (and subdirectories)

# report specific 
REPORT_LOCATION=$BACKUP_DIRECTORY$TODAYS_BACKUP_DIRECTORY"/report_`date +%s`.txt"	# detailed report of the backup
REPORT_NEWLINE="-----------------------------------------------------"			# new line in report
EMAIL_RECIPIENT="phpchap@gmail.com"							# email recipient of the report
EMAIL_SUBJECT=$SITENAME" Backup for `date +%m%d%Y`"					# subject of email

# MySQL specific 
MYSQL_USERNAME="username"								# mysql username
MYSQL_PASSWORD="password"								# mysql password
MYSQLDUMP_FILENAME="/db_`date +%s`.sql.gz"						# database dump name
MYSQLDUMP_LOCATION=$BACKUP_DIRECTORY$TODAYS_BACKUP_DIRECTORY$MYSQLDUMP_FILENAME		# full path to database dump
DATABASE_BACKUP_LIST="db1 db2 db3"							# database(s) to backup

# Amazon S3 specific 
S3_BACKUP_LOCATION="whitewaterblog/backups/"						# Amazon S3 bucket location

# PHP ini location 
PHP_INI="php.ini"									# filename of php.ini
PHP_INI_LOCATION="/etc/"$PHP_INI							# location of php.ini

# Apache httpd.conf location
HTTPD_CONF="httpd.conf"									# filename of httpd.conf
APACHE_HTTPD_CONF_LOCATION="/etc/httpd/conf/"$HTTPD_CONF				# location of httpd.conf

# MySQL my.conf location
MY_CONF="my.cnf"									# filename of my.cnf
MYSQL_MY_CONF_LOCATION="/etc/"$MY_CONF							# location of my.cnf

# -
# -----------------------------------------------------------------------------------------


# get the current space on the box..
echo "Making directory "$BACKUP_DIRECTORY$TODAYS_BACKUP_DIRECTORY
mkdir $BACKUP_DIRECTORY$TODAYS_BACKUP_DIRECTORY

# create the report 
touch $REPORT_LOCATION

echo $REPORT_NEWLINE | tee -a $REPORT_LOCATION
echo "Backup Report ("$REPORT_LOCATION") on `date +%m-%d-%Y`" | tee -a $REPORT_LOCATION

# Copy all the LAMP configuration files... 
# copy php config
cp $PHP_INI_LOCATION $BACKUP_DIRECTORY$TODAYS_BACKUP_DIRECTORY"/"$PHP_INI

# copy mysql config
cp $MYSQL_MY_CONF_LOCATION $BACKUP_DIRECTORY$TODAYS_BACKUP_DIRECTORY"/"$MY_CONF

# copy apache config
cp $APACHE_HTTPD_CONF_LOCATION $BACKUP_DIRECTORY$TODAYS_BACKUP_DIRECTORY"/"$HTTPD_CONF

echo $REPORT_NEWLINE | tee -a $REPORT_LOCATION
echo "Copied LAMP config files " | tee -a $REPORT_LOCATION

ls -al $BACKUP_DIRECTORY$TODAYS_BACKUP_DIRECTORY | tee -a $REPORT_LOCATION

# get the current space on the box..
df -h | tee -a $REPORT_LOCATION

echo $REPORT_NEWLINE | tee -a $REPORT_LOCATION
echo "Adding :: "$DIRECTORY_TO_BACKUP" into :: "$BACKUP_DESTINATION | tee -a $REPORT_LOCATION

#  grab all the code excluding the .svn folders.. 
tar --exclude='.svn' -cvf $BACKUP_DESTINATION -C / $DIRECTORY_TO_BACKUP

# list the tar contents in the report.. 
echo $REPORT_NEWLINE | tee -a $REPORT_LOCATION
tar -tvf $BACKUP_DESTINATION | awk '{print $6}' | tee -a $REPORT_LOCATION 

# backup MySQL
echo $REPORT_NEWLINE | tee -a $REPORT_LOCATION
echo "Dumping the following MySQL databases :: '"$DATABASE_BACKUP_LIST"' into :: "$MYSQLDUMP_LOCATION | tee -a $REPORT_LOCATION
mysqldump --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD --databases $DATABASE_BACKUP_LIST | gzip > $MYSQLDUMP_LOCATION

# zip up the tape archive 
echo $REPORT_NEWLINE | tee -a $REPORT_LOCATION
echo "Zip up the filesystem :: "$BACKUP_DESTINATION | tee -a $REPORT_LOCATION
gzip $BACKUP_DESTINATION

# now, push everything over to Amazon S3
echo $REPORT_NEWLINE | tee -a $REPORT_LOCATION

echo "Sending the backup to Amazon.. " | tee -a $REPORT_LOCATION
echo "s3cmd put -r /backup/"$TODAYS_BACKUP_DIRECTORY " s3://"$S3_BACKUP_LOCATION

s3cmd put -r /backup/$TODAYS_BACKUP_DIRECTORY s3://$S3_BACKUP_LOCATION | tee -a $REPORT_LOCATION

# send the reporting email..
mail -s $EMAIL_SUBJECT $EMAIL_RECIPIENT < $REPORT_LOCATION

echo "(REPORT) vi " $REPORT_LOCATION

# gunzip source_1292789551.tar.gz
# tar -xvf source_1292789551.tar