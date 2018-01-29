#! /bin/bash

IFS=','
MAILING_LIST=(
 example@xxx.co.jp
 sample@xxx.com
)

date=`date +"%Y-%m-%d"`

current_hour=`date --date "9 hours ago" "+%k"`
current_file_name_hour=`printf "%02d" $current_hour`
current_file_name="error/postgresql.log.$date-$current_file_name_hour"
local_copy_file="current_postgresql.log"
region="ap-northeast-1"
instance_name=""

aws rds download-db-log-file-portion \
  --region $region \
  --db-instance-identifier $instance_name \
  --no-paginate \
  --output text \
  --log-file-name $current_file_name > $local_copy_file

current_log=$(cat $local_copy_file)

filter_word="ERROR"
mail_subject="alarm notice"
mail_body="mail body"

if [[ `echo $current_log|grep $filter_word` ]]; then
  echo "Subject: $mail_subject \n\n $mail_body" | /usr/lib/sendmail ${MAILING_LIST[*]}]}
fi
