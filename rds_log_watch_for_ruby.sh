#!/usr/bin/ruby

require "time"

work_dir = "ruby_db_shutdown_logs"
`mkdir #{work_dir}`

utc_time_now = Time.now.utc

db_name = ""
search_word = "''"
shut_down_log = "#{work_dir}/shut_down.log"
download_logs_generation = 1

download_logs_generation.downto 0 do |time|
  subtraction_time = utc_time_now - 3600 * time
  file_name_time = subtraction_time.strftime("%Y-%m-%d-%H")
  file_name = "error/postgresql.log.#{file_name_time}"
  
  `aws rds download-db-log-file-portion \
     --region ap-northeast-1 \
     --db-instance-identifier #{db_name} \
     --no-paginate --output text \
     --log-file-name #{file_name} | 
     grep #{search_word} >> #{shut_down_log} 
  `
end

read_shut_down_logs = File.read(shut_down_log).split("\n")
invalid_log_threshold_minutes = 20
invalid_logging_time = utc_time_now - 60 * invalid_log_threshold_minutes
alert_taget_logs = read_shut_down_logs.select do |log|
   logging_time = Time.parse(log.slice(/\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2}/))
                       .utc + 3600 * 9
   logging_time >= invalid_logging_time
end

mailing_list = [
  "",
#  ""
].join(" ")
mail_subject = "kmprd-ruby-db shutdownログ出力"
mail_body = <<-BODY
BODY

if !alert_taget_logs.empty?
  `echo -e "Subject:#{mail_subject} #{mail_body}" | sendmail #{mailing_list}`
end

`rm -r #{work_dir}`
