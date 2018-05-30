#!/usr/bin/ruby

work_dir = ""
`mkdir #{work_dir}`

utc_time_now = Time.now.utc
jst_time_now = utc_time_now + 3600 * 9
file_timestamp = jst_time_now.strftime("%Y%m%d_%H")
check_back_time = 12

duration_threshold = 3000
duration_logs = "#{work_dir}/duration.log"
duration_time3000_logs = "#{work_dir}/#{file_timestamp}_duration_time3000.log"
duration_time3000_logs_zip = "#{work_dir}/#{file_timestamp}_duration_time3000.zip"
search_word = "duration"

db_name = ""

# 1.check_back_timeに指定した時間分のrdsログをダウンロードし、search_wordを含む行のみをファイル出力する
check_back_time.downto 1 do |time|
  subtraction_time = utc_time_now - 3600 * time
  file_name_time = subtraction_time.strftime("%Y-%m-%d-%H")
  file_name = "error/postgresql.log.#{file_name_time}"
  
  "search #{file_name}"
  `aws rds download-db-log-file-portion \
     --region ap-northeast-1 \
     --db-instance-identifier #{db_name} \
     --no-paginate --output text \
     --log-file-name #{file_name} | 
   grep #{search_word} >> #{duration_logs}
  ` 
end

# 2.1で出力したファイルを1行ずつ読み込む。
# ログのduration時間がduration_thresholdで指定した値以上の場合はduration_time3000_logsへ書き込む
`touch #{duration_time3000_logs}`
File.open(duration_logs) do |logs|
  logs.each_line do |line|
    duration_time = line.slice(/duration:\s\d+\.\d+/)
                        .slice(/\d+\.\d+/)
                        .to_i

    if duration_time >= duration_threshold
      File.open(duration_time3000_logs, "a") do |danger_logs|
        danger_logs.puts(line)
      end
    end
  end
end

# 3.duration_time3000_logsのログをカウントする
duration_count = `wc -l < #{duration_time3000_logs}`
duration_count.chomp!

target_time_from = (jst_time_now - 3600 * 12).strftime("%Y年%m月%d日 %H:00")
target_time_to = jst_time_now.strftime("%Y年%m月%d日 %H:00")

# 4.duration_time3000_logsをパスワード付きでzip圧縮
zip_pass = ""
`zip -P #{zip_pass} #{duration_time3000_logs_zip} #{duration_time3000_logs}`
attach_file = `base64 #{duration_time3000_logs_zip}`

mailing_list = [
  "",
#  ""
].join(" ")
mail_subject = ""
mail_body = <<-BODY
BODY
mail_boundary = "BOUNDARY"

# 5.4のzipを添付してメール送信
`sendmail -t << EOF
To: #{mailing_list}
Subject: #{mail_subject}
MIME-Version:1.0
Content-type:multipart/mixed; boundary=#{mail_boundary}
Content-Transfer-Encoding: 7bit

--#{mail_boundary}
Content-type: text/plain; charset=iso-2022-jp
Content-Transfer-Encoding: 7bit

#{mail_body}

--#{mail_boundary}
Content-type: application/zip;
 name=#{duration_time3000_logs_zip}
Content-Transfer-Encoding: base64
Content-Disposition : attachment;
 filename=#{duration_time3000_logs_zip}

#{attach_file}

--#{mail_boundary}--
EOF
`

`rm -r #{work_dir}`
