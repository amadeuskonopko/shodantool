#!/bin/bash



# todo: check for empty API_KEY
API_KEY=$(cat apikey)

function usage {
USAGE="$1 -c,--country [2 letter country code] -p,--product [shodan product filter] -v,--version [filter for IPv4,IPv6 address] --date [Epoch time]  --string,-s [search term] --output,-o [save output to file]\r\n\r\nexample: $0 -c CA -p 'Android Debug Bridge' -v 4 -o android-devices.txt"
echo -e $USAGE
exit 1
}

# requires packages bc and jq
which jq > /dev/null
if [[ $? -eq '1' ]]; then
	echo "[*] please install package jq"
	usage $0
fi

which bc > /dev/null
if [[ $? -eq '1' ]]; then
	echo "[*] please install package bc"
	usage $0
fi

# Parse arguments
args=$*
argPos=2
QUERY="query='"

for i in $args
do
	if [[ $i == "--country" || $i == "-c" ]]; then
		country="${!argPos}"
		argPos=$(echo "$argPos + 2" | bc)
	elif [[ $i == "--product" || $i == "-p" ]]; then
		product="${!argPos}"
		argPos=$(echo "$argPos + 2" | bc)
	elif [[ $i == "--version" || $i == "-v" ]]; then
		version="${!argPos}"
		argPos=$(echo "$argPos + 2" | bc)
	elif [[ $i == "--date" || $i == "-d" ]]; then
		date="${!argPos}"
		argPos=$(echo "$argPos + 2" | bc)
	elif [[ $i == "--string" || $i == "-s" ]]; then
		string="${!argPos}"
		argPos=$(echo "$argPos + 2" | bc)
	elif [[ $i == "--output" || $i == "-o" ]]; then
		output="${!argPos}"
		argPos=$(echo "$argPos + 2" | bc)
	fi
done

# add product filter to query
echo $product | grep -qP "^[A-Za-z ]{1,32}$"
if [[ $? == 0 ]]; then 
	QUERY+="product:\"$product\""
else
	usage $0
fi

# add country to query if it matches two letters 
echo $country | grep -qP "^[A-Za-z]{2}$"
if [[ $? == 0 ]]; then 
	QUERY+=" country:$country"
else
	echo "[*] Invalid Country Code: $country"
	#usage $0
fi

# filter for ipv4/ipv6 
echo $version| grep -qP "^4$"
if [[ $? == 0 ]]; then 
	QUERY+=" net:0.0.0.0/0"
fi

echo $version| grep -qP "^6$"
if [[ $? == 0 ]]; then 
	QUERY+=" has_ipv6:true"
fi

# add a date (in epoch) to filter received data through
echo $date| grep -qP "^[0-9]{10}$"
if [[ $? == 0 ]]; then 
	LASTUPDATE=$date
fi

# add a string you want to search for
echo $string| grep -qP "^[A-Za-z0-9 ]{1,99}$"
if [[ $? == 0 ]]; then 
	QUERY+=" \"$string\""
fi

QUERY+="'"

# save the output to file 
echo $output| grep -qP "^[A-Za-z0-9_/.-]{1,99}$"
if [[ $? == 0 ]]; then 
	SHODAN_OUT=$output
else
	SHODAN_OUT="shodan-tool-$(date +%s).json"
fi

echo "[*] Searching Shodan with the query: $QUERY"

SHODAN_ENDPOINT_COUNT="https://api.shodan.io/shodan/host/count"
SHODAN_ENDPOINT_SEARCH="https://api.shodan.io/shodan/host/search"
FACETS="facets=country:10000"
curlCmd="curl -s -G $SHODAN_ENDPOINT_COUNT --data-urlencode "key=$API_KEY" --data-urlencode "$QUERY" --data-urlencode $FACETS"
RESP_COUNT=$(eval $curlCmd)
TOTAL_HITS=$( echo $RESP_COUNT | jq '.total')

if [[ $TOTAL_HITS -le 0 ]]; then
	echo "[*] $TOTAL_HITS hits found."
	exit 1
fi

echo "[*] Found $TOTAL_HITS hits."

NUM_PAGES=$(echo "$TOTAL_HITS / 100" | bc)
REMAINDER=$(echo "$TOTAL_HITS % 100" | bc)

if [[ $REMAINDER -gt '0' ]]; then
	NUM_PAGES=$(echo "$NUM_PAGES + 1" | bc)
fi

echo "[*] Saving as $SHODAN_OUT"

for i in $(seq 1 $NUM_PAGES);
	do
		RETRY=0
		# get page, if there's an error, try again up to 5 times
		PAGE_ERROR="true"
		while [[ $PAGE_ERROR == "true" ]];
			do
				echo "[*] Getting page $i of $NUM_PAGES";
				curlCmd="curl -s -G $SHODAN_ENDPOINT_SEARCH --data-urlencode "key=$API_KEY" --data-urlencode "$QUERY" --data-urlencode "page=$i""
				RESULTS=$(eval $curlCmd)
				PAGE_ERROR=$(echo $RESULTS | jq '.|has("error")')
				echo $RESULTS | jq '.|if(has("matches")) then .matches[] else empty end' >> $SHODAN_OUT
				RETRY=$(echo "$RETRY + 1" | bc)
				if [[ $RETRY -ge 5 ]]; then
					echo "[*] retry limit exceeded... quitting"
					exit 1
				fi
				sleep 2
			done
	done

echo "[*] Done!"
