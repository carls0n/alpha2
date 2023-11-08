# alpha2.sh
* Bash based parallel SSH/HTTP login hacker.<br>
* Includes directory enumeration mode for HTTP<br>
* Try all possible combinations of x number of alphanumeric characters<br>
* Option to use a password file instead.<br>
* Updates every five minutes with time elapsed.<br>
* Support for SOCKS5 proxies for HTTP attacks<br>
* New! Now supports both SSH and HTTP bruteforce attacks.
***
One of the security features of OpenSSH is MaxStartups which sets limits on the number of simultaneous connections allowed. When MaxStartups limits are reached, OpenSSH begins dropping connections, which will of course affect the results of the attack. In my sshd_config, the default is set at 10:30:100. So in order to conduct a successful attack, you will need to limit the number of threads on an SSH attack to 8 threads.
***
