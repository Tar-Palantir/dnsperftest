#!/usr/bin/env bash

command -v bc > /dev/null || { echo "bc was not found. Please install bc."; exit 1; }
{ command -v drill > /dev/null && dig=drill; } || { command -v dig > /dev/null && dig=dig; } || { echo "dig was not found. Please install dnsutils."; exit 1; }



NAMESERVERS=`cat /etc/resolv.conf | grep ^nameserver | cut -d " " -f 2 | sed 's/\(.*\)/&#&/'`

PROVIDERS="
1.1.1.1#cloudflare 
4.2.2.1#level3 
8.8.8.8#google 
9.9.9.9#quad9 
80.80.80.80#freenom 
208.67.222.123#opendns 
199.85.126.20#norton 
185.228.168.168#cleanbrowsing 
77.88.8.7#yandex 
176.103.130.132#adguard 
156.154.70.3#neustar 
8.26.56.26#comodo
114.114.114.114#114DNS-cn
223.5.5.5#AliDNS-cn
180.76.76.76#BaiduDNS-cn
223.87.253.182#ChengduDNS-cn
119.29.29.29#DNSPod-cn
101.226.4.6#DNSPi-cn
"

# Domains to test. Duplicated domains are ok
DOMAINS2TEST="
www.google.com#google
www.amazon.com#amazon
www.facebook.com#facebook
www.youtube.com#youtube
www.twitter.com#twitter
www.github.com#github
www.gmail.com#gmail
"

DOMAINSCN2TEST="
www.github.com#github
www.baidu.com#baidu
www.jd.com#jd
www.taobao.com#taobao
"
function test()
{
    echo $1
    totaldomains=0
    printf "%-18s" ""
    for d in $2; do
        totaldomains=$((totaldomains + 1))
        printf "%-10s" ${d##*#}
    done
    printf "%-11s" "Average"
    printf "%-15s" "IP"
    echo ""

    for p in $NAMESERVERS $PROVIDERS; do
        pip=${p%%#*}
        pname=${p##*#}
        ftime=0

        printf "%-18s" "$pname"
        for d in $2; do
            ttime=`$dig +tries=1 +time=2 +stats @$pip $d |grep "Query time:" | cut -d : -f 2- | cut -d " " -f 2`
            if [ -z "$ttime" ]; then
	            #let's have time out be 1s = 1000ms
	            ttime=1000
            elif [ "x$ttime" = "x0" ]; then
	            ttime=1
	        fi

            printf "%-10s" "$ttime ms"
            ftime=$((ftime + ttime))
        done
        avg=`bc -lq <<< "scale=2; $ftime/$totaldomains"`

        printf "%-11s" "$avg ms"
        printf "%-15s" "$pip"
        echo ""
    
    done
}

test "US Test" "$DOMAINS2TEST"
test "CN Test" "$DOMAINSCN2TEST"

exit 0;
