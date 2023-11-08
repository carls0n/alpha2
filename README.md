# alpha2.sh
* Bash based parallel SSH/HTTP login hacker.<br>
* Includes directory enumeration mode for HTTP<br>
* Try all possible combinations of x number of alphanumeric characters<br>
* Option to use a password file instead.<br>
* Updates every five minutes with time elapsed.<br>
* Support for SOCKS5 proxies for HTTP attacks<br>
* New! Now supports both SSH and HTTP bruteforce attacks.
<hr>
One of the security features of SSH is MaxStartups which sets limits on simultaneous connections. When MaxStartups limits are reached, SSH begins dropping connections, which will of course affect the results of the attack. In my sshd_config, the default is set at 10:30:100. So in order to conduct a successful attack, one need to limit the number of threads to 8.
