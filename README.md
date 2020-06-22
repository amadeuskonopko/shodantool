what is shodan tool?

shodan is a command line tool to query shodan data
-requires a valid api key
-can query for ipv4 or ipv6, or both
-support for 2 letter country code filter
-support for product filter
-support for wildcard search term
-supports saving output to file
-requires jq and bc packages

./shodan.sh -c,--country [2 letter country code] -p,--product [shodan product filter] -v,--version [filter for IPv4,IPv6 address] --date [Epoch time] --string,-s [search term] --output,-o [save output to file]

example: ./shodan.sh -c CA -p 'Android Debug Bridge' -v 4 -o android-devices.txt
