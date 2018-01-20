#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATHH
# Description: script for Auto test VPS's bandwith, I/O speed, route to mainland China & CPU performance
# Thanks: LookBack <admin@dwhd.org>; Nils Steinger; Teddysun
# Toyo: https://doub.io
# H2YTech: https://www.minecloud.asia
# For https://VPS.BEST

# Additional: Thanks Oldking's SuperBench.sh, Mixed by SunsetLast

RED='\033[0;31m' && GREEN='\033[0;32m' && YELLOW='\033[0;33m' && PLAIN='\033[0m'
next() { printf "%-70s\n" "-" | sed 's/\s/-/g'; }
get_opsy() {
	[[ -f /etc/redhat-release ]] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
	[[ -f /etc/os-release ]] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
	[[ -f /etc/lsb-release ]] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=$(uname -m)
}
Installation_dependency(){
	if [[ ${release} == "centos" ]]; then
		yum install mtr curl time virt-what -y
		[[ ${action} == "a" ]] && yum install epel-release make gcc gcc-c++ gdbautomake autoconf hdparm -y
		curl -s --max-time 10 -o ioping.static http://wget.racing/ioping.static
		chmod +x ioping.static
	else
		apt-get install curl mtr time virt-what python -y
		[[ ${action} == "a" ]] && apt-get install make gcc gdb automake autoconf hdparm -y
		curl -s --max-time 10 -o ioping.static http://wget.racing/ioping.static
		chmod +x ioping.static
	fi
}

get_info(){
	logfile="test.log"
	IP=$(curl -s myip.ipip.net | awk -F ' ' '{print $2}' | awk -F '：' '{print $2}')
	IPaddr=$(curl -s myip.ipip.net | awk -F '：' '{print $3}')
	if [[ -z "$IP" ]]; then
		IP=$(curl -s ip.cn | awk -F ' ' '{print $2}' | awk -F '：' '{print $2}')
		IPaddr=$(curl -s ip.cn | awk -F '：' '{print $3}')	
	fi
	time=$(date '+%Y-%m-%d %H:%I:%S')
	backtime=$(date +%Y-%m-%d)
	vm=$(virt-what)
	[[ -z ${vm} ]] && vm="none"
	cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
	freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	tram=$( free -m | awk '/Mem/ {print $2}' )
	uram=$( free -m | awk '/Mem/ {print $3}' )
	swap=$( free -m | awk '/Swap/ {print $2}' )
	uswap=$( free -m | awk '/Swap/ {print $3}' )
	up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime )
	load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
	opsy=$( get_opsy )
	arch=$( uname -m )
	lbit=$( getconf LONG_BIT )
	kern=$( uname -r )
	ipv6=$( wget -qO- -t1 -T2 ipv6.icanhazip.com )
	disk_size1=($( LANG=C df -ahPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $2}' ))
	disk_size2=($( LANG=C df -ahPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $3}' ))
	disk_total_size=$( calc_disk ${disk_size1[@]} )
	disk_used_size=$( calc_disk ${disk_size2[@]} )
}
system_info(){
	clear
	echo "========== Now begin to Test ==========" > $logfile
	echo "Test Time：$time" | tee -a $logfile
	next | tee -a $logfile
	echo "CPU model            : $cname" | tee -a $logfile
	echo "Number of cores      : $cores" | tee -a $logfile
	echo "CPU frequency        : $freq MHz" | tee -a $logfile
	echo "Total size of Disk   : $disk_total_size GB ($disk_used_size GB Used)" | tee -a $logfile
	echo "Total amount of Mem  : $tram MB ($uram MB Used)" | tee -a $logfile
	echo "Total amount of Swap : $swap MB ($uswap MB Used)" | tee -a $logfile
	echo "System uptime        : $up" | tee -a $logfile
	echo "Load average         : $load" | tee -a $logfile
	echo "OS                   : $opsy" | tee -a $logfile
	echo "Arch                 : $arch ($lbit Bit)" | tee -a $logfile
	echo "Kernel               : $kern" | tee -a $logfile
	echo "ip                   : $IP" | tee -a $logfilename
	echo "ipaddr               : $IPaddr" | tee -a $logfile
	echo "vm                   : $vm" | tee -a $logfile
	next | tee -a $logfile
}
ioping() {
        printf 'ioping: seek rate\n    ' | tee -a $logfile
        ./ioping.static -R -w 5 . | tail -n 1 | tee -a $logfile
        printf 'ioping: sequential speed\n    ' | tee -a $logfile
        ./ioping.static -RL -w 5 . | tail -n 2 | head -n 1 | tee -a $logfile
	next | tee -a $logfile
}
calc_disk() {
	local total_size=0
	local array=$@
	for size in ${array[@]}
	do
		[[ "${size}" == "0" ]] && size_t=0 || size_t=$(echo ${size:0:${#size}-1})
		[[ "$(echo ${size:(-1)})" == "M" ]] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' / 1024}' )
		[[ "$(echo ${size:(-1)})" == "T" ]] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' * 1024}' )
		[[ "$(echo ${size:(-1)})" == "G" ]] && size=${size_t}
		total_size=$( awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}' )
	done
	echo ${total_size}
}
io_test_1() {
	(LANG=C dd if=/dev/zero of=test_$$ bs=64k count=4k oflag=dsync && rm -f test_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}
io_test_2() {
	(LANG=C dd if=/dev/zero of=test_$$ bs=8k count=256k conv=fdatasync && rm -f test_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}
io_test(){
	io1=$( $1 )
	echo "I/O speed(1st run)   : $io1" | tee -a $logfile
	io2=$( $1 )
	echo "I/O speed(2nd run)   : $io2" | tee -a $logfile
	io3=$( $1 )
	echo "I/O speed(3rd run)   : $io3" | tee -a $logfile
	ioraw1=$( echo "$io1" | awk 'NR==1 {print $1}' )
	[[ "$(echo "$io1" | awk 'NR==1 {print $2}')" == "GB/s" ]] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
	ioraw2=$( echo "$io2" | awk 'NR==1 {print $1}' )
	[[ "$(echo "$io2" | awk 'NR==1 {print $2}')" == "GB/s" ]] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
	ioraw3=$( echo "$io3" | awk 'NR==1 {print $1}' )
	[[ "$(echo "$io3" | awk 'NR==1 {print $2}')" == "GB/s" ]] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
	unit="$(echo "$io1" | awk 'NR==1 {print $2}')"
	if [[ "${unit}" == "GB/s" ]]; then
		unit="MB/s"
	else
		if [[ "$(echo "$io1" | awk 'NR==1 {print $2}')" == "kB/s" ]]; then
			unit="kB/s"
			[[ "$(echo "$io2" | awk 'NR==1 {print $2}')" == "MB/s" ]] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
			[[ "$(echo "$io3" | awk 'NR==1 {print $2}')" == "MB/s" ]] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
		elif [[ "$(echo "$io2" | awk 'NR==1 {print $2}')" == "kB/s" ]]; then
			unit="kB/s"
			[[ "$(echo "$io1" | awk 'NR==1 {print $2}')" == "MB/s" ]] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
			[[ "$(echo "$io3" | awk 'NR==1 {print $2}')" == "MB/s" ]] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
		elif [[ "$(echo "$io3" | awk 'NR==1 {print $2}')" == "kB/s" ]]; then
			unit="kB/s"
			[[ "$(echo "$io1" | awk 'NR==1 {print $2}')" == "MB/s" ]] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
			[[ "$(echo "$io2" | awk 'NR==1 {print $2}')" == "MB/s" ]] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
		fi
	fi
	ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
	ioavg=$( awk 'BEGIN{printf "%.1f", '$ioall' / 3}' )
	echo "Average I/O speed    : $ioavg ${unit}" | tee -a $logfile
	next | tee -a $logfile
}
speed_test() {
	local speedtest=$(wget -4O /dev/null -T300 $1 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}')
	local ipaddress=$(ping -c1 -n `awk -F'/' '{print $3}' <<< $1` | awk -F'[()]' '{print $2;exit}')
	local nodeName=$2
	printf "${YELLOW}%-32s${GREEN}%-24s${RED}%-14s${PLAIN}\n" "${nodeName}:" "${ipaddress}:" "${speedtest}"
}
speed() {
	printf "%-32s%-24s%-14s\n" "Node Name:" "IPv4 address:" "Download Speed"
	speed_test 'https://origin-a.akamaihd.net/Origin-Client-Download/origin/mac/live/Origin.dmg' 'Akamai'
        speed_test 'http://cachefly.cachefly.net/100mb.test' 'CacheFly'
	speed_test 'https://downloadsapachefriends.global.ssl.fastly.net/xampp-files/7.1.8/xampp-win32-7.1.8-0-VC14-installer.exe' 'Fastly'
	#speed_test 'http://soft.duote.com.cn/chrome_63.0.3239.84.exe' 'CNC CDN'
	speed_test 'http://en.chinacache.com/wp-content/uploads/LinkedIn.pdf' 'ChinaCache CDN'
	speed_test 'http://cdn.zstack.io/product_downloads/vrouter/zstack-vrouter-2.1.0.qcow2' 'AliYun CDN'
	speed_test 'http://pkg.biligame.com/fatego/fatego_v1.16.0_bili_375772.apk' 'QCloud CDN'
        speed_test 'http://sw.bos.baidu.com/sw-search-sp/software/1bc31d3a7e33c/SketchUpPro_zh_CN_17.1.174.0.exe' 'BaiduYun CDN'
	speed_test 'http://bigota.d.miui.com/JMACNBL18.0/miui_Mioneplus_JMACNBL18.0_6b0e616a48_4.1.zip' 'KS Yun CDN'
	speed_test 'http://speedtest.tokyo.linode.com/100MB-tokyo.bin' 'Linode, Tokyo, JP'
	speed_test 'http://speedtest.tokyo2.linode.com/100MB-tokyo2.bin' 'Linode, Tokyo2, JP'
	speed_test 'http://speedtest.singapore.linode.com/100MB-singapore.bin' 'Linode, Singapore, SG'
	speed_test 'http://speedtest.fremont.linode.com/100MB-fremont.bin' 'Linode, Fremont, CA'
	speed_test 'http://speedtest.newark.linode.com/100MB-newark.bin' 'Linode, Newark, NJ'
	speed_test 'http://speedtest.london.linode.com/100MB-london.bin' 'Linode, London, UK'
	speed_test 'http://speedtest.frankfurt.linode.com/100MB-frankfurt.bin' 'Linode, Frankfurt, DE'
	speed_test 'http://speedtest.tok02.softlayer.com/downloads/test100.zip' 'Softlayer, Tokyo, JP'
	speed_test 'http://speedtest.sng01.softlayer.com/downloads/test100.zip' 'Softlayer, Singapore, SG'
	speed_test 'http://speedtest.sng01.softlayer.com/downloads/test100.zip' 'Softlayer, Seoul, KR'
	speed_test 'http://speedtest.hkg02.softlayer.com/downloads/test100.zip' 'Softlayer, HongKong, CN'
	speed_test 'http://speedtest.dal13.softlayer.com/downloads/test100.zip' 'Softlayer, Dallas, TX'
	speed_test 'http://speedtest.sea01.softlayer.com/downloads/test100.zip' 'Softlayer, Seattle, WA'
	speed_test 'http://speedtest.fra02.softlayer.com/downloads/test100.zip' 'Softlayer, Frankfurt, DE'
	speed_test 'http://speedtest.par01.softlayer.com/downloads/test100.zip' 'Softlayer, Paris, FR'
	speed_test 'http://fra-de-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Frankfurt, DE'
	speed_test 'http://par-fr-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Paris, France'
	speed_test 'http://ams-nl-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Amsterdam, NL'
	speed_test 'http://lon-gb-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, London, UK'
	speed_test 'http://sgp-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Singapore, SG'
	speed_test 'https://nj-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, New York (NJ)'
	speed_test 'https://hnd-jp-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Tokyo, Japan'
	speed_test 'https://il-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Chicago, Illinois'
	speed_test 'https://ga-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Atlanta, Georgia'
	speed_test 'https://fl-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Miami, Florida'
	speed_test 'https://wa-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Seattle, Washington'
	speed_test 'https://tx-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Dallas, Texas'
	speed_test 'https://sjo-ca-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Silicon Valley, CA'
	speed_test 'https://lax-ca-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Los Angeles, CA'
	speed_test 'https://syd-au-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Sydney, Australia'
	speed_test 'http://mirror.hk.leaseweb.net/speedtest/100mb.bin' 'Leaseweb, HongKong, CN'
	speed_test 'http://mirror.sg.leaseweb.net/speedtest/100mb.bin' 'Leaseweb, Singapore, SG'
#speed_test 'http://chi.testfiles.ubiquityservers.com/100mb.txt' 'Leaseweb, Chicago, US'
	speed_test 'http://mirror.wdc1.us.leaseweb.net/speedtest/100mb.bin' 'Leaseweb, Washington D.C., US'
	speed_test 'http://mirror.sfo12.us.leaseweb.net/speedtest/100mb.bin' 'Leaseweb, San Francisco, US'
	speed_test 'http://mirror.nl.leaseweb.net/speedtest/100mb.bin' 'Leaseweb, Netherlands, NL'
	speed_test 'http://proof.ovh.ca/files/100Mio.dat' 'OVH, Montreal, CA'
	speed_test 'http://119.147.227.50/dl.softmgr.qq.com/original/game/DuiZhanSetup1_8_4_2042_win10.exe' 'ChinaTelecom, Shantou, CN'
	speed_test 'http://119.147.83.151/dl.softmgr.qq.com/original/game/DuiZhanSetup1_8_4_2042_win10.exe' 'ChinaTelecom, Shenzhen, CN'
	speed_test 'http://125.94.49.50/dl.softmgr.qq.com/original/game/DuiZhanSetup1_8_4_2042_win10.exe' 'ChinaTelecom, Guangzhou, CN'
	speed_test 'http://180.163.68.13/dl.softmgr.qq.com/original/game/DuiZhanSetup1_8_4_2042_win10.exe' 'ChinaTelecom, Shanghai, CN'
	speed_test 'http://124.232.162.22/dl.softmgr.qq.com/original/game/DuiZhanSetup1_8_4_2042_win10.exe' 'ChinaTelecom, Changsha, CN'
#speed_test 'http://163.177.113.21/dl.softmgr.qq.com/original/game/DuiZhanSetup1_8_4_2042_win10.exe' 'ChinaUnicom, Huizhou, CN'
	speed_test 'http://210.22.248.178/dl.softmgr.qq.com/original/game/DuiZhanSetup1_8_4_2042_win10.exe' 'ChinaUnicom, Shanghai, CN'
	speed_test 'http://123.125.9.50/dl.softmgr.qq.com/original/game/DuiZhanSetup1_8_4_2042_win10.exe' 'ChinaUnicom, Beijing, CN'
	speed_test 'http://223.82.245.41/dl.softmgr.qq.com/original/game/DuiZhanSetup1_8_4_2042_win10.exe' 'ChinaMobile, Jiangxi, CN'
	speed_test 'http://223.111.153.176/dl.softmgr.qq.com/original/game/DuiZhanSetup1_8_4_2042_win10.exe' 'ChinaMobile, Jiangsu, CN'
	speed_test 'http://101.4.60.106/setup.exe' 'CERNET, Beijing, CN'
#speed_test 'http://mirrors.opencas.org/apache/ode/apache-ode-war-1.3.6.zip' 'CSTNET, Beijing, CN'
	speed_test 'http://tpdb.speed2.hinet.net/test_100m.zip' 'Hinet, Taiwan, TW'
	next
}

speed_cli_test(){
	if [[ $1 == '' ]]; then
		temp=$(python speedtest.py --share 2>&1)
		is_down=$(echo "$temp" | grep 'Download') 
		if [[ ${is_down} ]]; then
	        local REDownload=$(echo "$temp" | awk -F ':' '/Download/{print $2}')
	        local reupload=$(echo "$temp" | awk -F ':' '/Upload/{print $2}')
	        local relatency=$(echo "$temp" | awk -F ':' '/Hosted/{print $2}')
	        local nodeName=$2

	        printf "${YELLOW}%-17s${GREEN}%-18s${RED}%-20s${SKYBLUE}%-12s${PLAIN}\n" "${nodeName}" "${reupload}" "${REDownload}" "${relatency}"
		else
	        local cerror="ERROR"
		fi
	else
		temp=$(python speedtest.py --server $1 --share 2>&1)
		is_down=$(echo "$temp" | grep 'Download') 
		if [[ ${is_down} ]]; then
	        local REDownload=$(echo "$temp" | awk -F ':' '/Download/{print $2}')
	        local reupload=$(echo "$temp" | awk -F ':' '/Upload/{print $2}')
	        local relatency=$(echo "$temp" | awk -F ':' '/Hosted/{print $2}')
	        temp=$(echo "$relatency" | awk -F '.' '{print $1}')
        	if [[ ${temp} -gt 1000 ]]; then
            	relatency=" 000.000 ms"
        	fi
	        local nodeName=$2

	        printf "${YELLOW}%-17s${GREEN}%-18s${RED}%-20s${SKYBLUE}%-12s${PLAIN}\n" "${nodeName}" "${reupload}" "${REDownload}" "${relatency}"
		else
	        local cerror="ERROR"
		fi
	fi
}

speed_cli() {
	# install speedtest
	if  [ ! -e './speedtest.py' ]; then
	    wget https://raw.github.com/sivel/speedtest-cli/master/speedtest.py > /dev/null 2>&1
	fi
	chmod a+rx speedtest.py
	echo "===== SpeedTest Begin =====" | tee -a $logfile
	python speedtest.py --share | tee -a $logfile
	next
	printf "%-18s%-18s%-20s%-12s\n" "Node Name" "Upload Speed" "Download Speed" "Latency"
    speed_cli_test '' 'Normal Node 1st'
	speed_cli_test '' 'Normal Node 2nd'
	speed_cli_test '' 'Normal Node 3rd'
	speed_cli_test '10305' 'Guangxi  CT'
	speed_cli_test '3633' 'Shanghai  CT'
	speed_cli_test '4624' 'Chengdu   CT'
	speed_cli_test '4863' "Xi'an     CU"
	speed_cli_test '5083' 'Shanghai  CU'
	speed_cli_test '5726' 'Chongqing CU'
	speed_cli_test '5192' "Xi'an     CM"
	speed_cli_test '4665' 'Shanghai  CM'
	speed_cli_test '4575' 'Chengdu   CM'
	echo -e "===== SpeedTest End =====" | tee -a $logfile	 
	rm -rf speedtest.py
	next
}

mtrback(){
	echo "===== Start to test the route to [$2]  =====" | tee -a $logfile
	mtr -r -c 10 $1 | tee -a $logfile
	echo -e "=====  End to test the route to [$2]  =====" | tee -a $logfile	
}

backtracetest(){
	mtrback "180.163.68.13" "Shanghai China Telecom"
	mtrback "180.168.95.157" "Shanghai China Telecom(CN2 Optimized)"
	mtrback "139.226.20.124" "Shanghai China Unicom"
	mtrback "183.192.160.3" "Shanghai China Mobile"
	mtrback "210.51.45.1" "Shanghai China Netcom(CUII)"
	mtrback "219.141.225.1" "Beijing China Telecom"
	mtrback "125.33.55.33" "Beijing China Unicom"
        mtrback "113.65.124.1" "Guangzhou China Telecom"
	mtrback "36.36.97.16" "Shenzhen Topway"
	mtrback "183.60.137.161" "Shantou China Telecom"
	mtrback "14.29.70.1" "Foshan China Telecom"
	mtrback "163.177.152.1" "Foshan China Unicom"
	mtrback "112.90.49.1" "Zhoushan China Unicom"
	mtrback "223.82.245.41" "Jiangxi China Mobile"
	mtrback "101.4.60.106" "Beijing CERNET"
	mtrback "159.226.254.37" "Beijing CSTNET"
	mtrback "223.93.170.42" "Hangzhou China Mobile"
	next | tee -a $logfile
}
benchtest(){
	if ! wget -qc http://lamp.teddysun.com/files/UnixBench5.1.3.tgz; then
		echo "Fail to download UnixBench 5.1.3.tgz" && exit 1
	fi
	tar -xzf UnixBench5.1.3.tgz
	cd UnixBench/
	make
	echo "===== Start to test UnixBench =====" | tee -a ../${logfilename}
	./Run
	benchfile=$(ls results/ | grep -v '\.')
	cat results/${benchfile} >> ../${logfilename}
	echo "===== End to test UnixBench =====" | tee -a ../${logfilename}	
	cd ..
	rm -rf UnixBench5.1.3.tgz UnixBench
	next | tee -a $logfile
}
go(){
	check_sys
	Installation_dependency
	get_info
	system_info
	ioping
	io_test "io_test_1"
	io_test "io_test_2"
	speed_cli
	speed | tee -a $logfile
	backtracetest
	[[ ${action} == "a" ]] && benchtest
}
action=$1
go
