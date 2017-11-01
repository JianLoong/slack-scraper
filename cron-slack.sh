#!/bin/sh
# Requires curl and jq library
# Slack token. Required for GET request. 
XOXP_TOKEN=YOUR_TOKEN_HERE
curr_time_stamp=$(date +%s)
no_of_days=1
one_day_time_stamp=86400
days_behind=$(expr $no_of_days \* $one_day_time_stamp)
from=$(expr $curr_time_stamp - $days_behind)

echo $from

# Start of downloading all files

total_pages=$(curl -s "https://slack.com/api/files.list?token=${XOXP_TOKEN}&ts_from=${from}&ts_to=now&pretty=0" | jq '.paging | .pages')  
echo There are $total_pages pages

# Do request for each page
for i in `seq $i $total_pages`;
	do
        echo At page $i	of $total_pages
        # Get all URLs for download based on the timestamps
        response=$(curl -s "https://slack.com/api/files.list?token=${XOXP_TOKEN}&ts_from=${from}&ts_to=now&page=${i}&pretty=0" | jq '.files[] | .url_private_download')
		# Split them based on linebreaks
		urls=(${response//\n\r/ })

		count=0
		for var in "${urls[@]}"
		do
			# Remove leading and trailing "
			temp="${var%\"}"
			temp="${temp#\"}"
			((count++))
			echo "Downloading file $count of ${#urls[@]}"
			echo "$temp"
			
			# Peform curl get to obtain them. Spoofing browser to do it. Do NOT run parallel
			(curl -O "${temp}" -H 'pragma: no-cache' -H 'dnt: 1' -H 'accept-encoding: gzip, deflate, sdch, br' -H 'accept-language: en-US,en;q=0.8,ms;q=0.6,zh-TW;q=0.4,zh;q=0.2' -H 'upgrade-insecure-requests: 1' -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.116 Safari/537.36' -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'cache-control: no-cache' -H 'authority: files.slack.com' -H 'cookie: _ga=GA1.2.930175955.1474361867; _gat=1; a-71426613667=h0DrvxDZPSLr71vZckMR8boeNk8SV%2BXqceFuVsqocr48SSZwvs0FeBZL%2Buj9kBGPLOgq96n%2FLMp7guVWXBnprg%3D%3D; a=71426613667; b=.6zoubchs3k000skccs4s00484' --compressed;)
		done
	done    
echo "Done"



# Start of downloading all messages.
# First get all channel info IDs.

response=$(curl -s "https://slack.com/api/channels.list?token=${XOXP_TOKEN}&pretty=0" | jq '.channels[] | .id')
channels=(${response//\n\r/ })
total=${#channels[@]}
echo There are ${total} channels

# Create directory for messages
mkdir messages


count=0
for channel in "${channels[@]}"
	do

		((count++))
		temp="${channel%\"}"
		temp="${temp#\"}"

		echo At channel $temp : is $count of $total

		latest=$curr_time_stamp

		counter=1
		while [ $counter -le $no_of_days ]; 
			do
				echo Paging day $counter of $no_of_days
				
				oldest=$(expr $latest - $one_day_time_stamp)

				result=$(curl -s "https://slack.com/api/channels.history?token=${XOXP_TOKEN}&channel=${temp}&latest=${latest}&oldest=${oldest}&count=1000&inclusive=1&pretty=0" | jq  '.messages[]')

				length=${#result}

				# Don't make directory if no contents returned

				if [ "$length" != 0 ];then
					mkdir -p messages/$temp
					dt=$(date -r $latest '+%d-%m-%Y')
					echo $result >> messages/$temp/$dt.json
				fi

				latest=$oldest
				let counter=counter+1
			done
	done



# Without library
# export PYTHONIOENCODING=utf8

# total_pages=$(curl -s "https://slack.com/api/files.list?token=${XOXP_TOKEN}&ts_from=${from}&ts_to=now&pretty=0" | \
#     python -c "import sys, json; print json.load(sys.stdin)['paging']['pages']")

# echo There are $total_pages pages

# # Do request for each page
# for i in `seq $i $total_pages`;
# 	do
#         echo At page $i	of $total_pages
#         response=$(curl -s "https://slack.com/api/files.list?token=${XOXP_TOKEN}&ts_from=${from}&ts_to=now&page=${i}&pretty=1"
#     done

# echo "Done"