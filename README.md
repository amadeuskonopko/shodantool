what is shodan tool?<br>
<br>
shodan is a command line tool to query shodan data<br>
-requires a valid api key<br>
-can query for ipv4 or ipv6, or both<br>
-support for 2 letter country code filter<br>
-support for product filter<br>
-support for wildcard search term<br>
-supports saving output to file<br>
-requires jq and bc packages<br>

./shodan.sh -c,--country [2 letter country code] -p,--product [shodan product filter] -v,--version [filter for IPv4,IPv6 address] --date [Epoch time] --string,-s [search term] --output,-o [save output to file]<br>
<br>
example: ./shodan.sh -c CA -p 'Android Debug Bridge' -v 4 -o android-devices.txt<br>
