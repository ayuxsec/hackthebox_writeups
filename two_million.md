1. Port discovery

```console
$ rustscan -a twomillion.htb -t 5000 -b 1000 -- -sV | tee rustscan.out
PORT   STATE SERVICE REASON  VERSION
22/tcp open  ssh     syn-ack OpenSSH 8.9p1 Ubuntu 3ubuntu0.1 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    syn-ack nginx
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

2. Port 80 analysis

```console
$ curl -I http://twomillion.htb
HTTP/1.1 301 Moved Permanently
Server: nginx
Date: Thu, 26 Feb 2026 04:33:14 GMT
Content-Type: text/html
Content-Length: 162
Connection: keep-alive
Location: http://2million.htb/

$ cat /etc/hosts
10.129.229.66 twomillion.htb 2million.htb

$ curl -X GET -I http://2million.htb
HTTP/1.1 200 OK
Server: nginx
Date: Thu, 26 Feb 2026 04:34:58 GMT
Content-Type: text/html; charset=UTF-8
Transfer-Encoding: chunked
Connection: keep-alive
Set-Cookie: PHPSESSID=tdr8cjv16t0e8pvjv7qrllqs77; path=/
Expires: Thu, 19 Nov 1981 08:52:00 GMT
Cache-Control: no-store, no-cache, must-revalidate
Pragma: no-cache
```
