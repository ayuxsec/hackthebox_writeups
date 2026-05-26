https://medium.com/@abubakr.ezalden.nasir/easy-peasy-dbc35ba1cd91

nmap commnad used:

```
nmap -sC -sV 10.48.146.223 -p- --min-rate 1000 -T4
```

hash cracked via: https://md5hashing.net/hash/md5

2nd cracked via command:

```
john --wordlist=easypeasy_1596838725703.txt --format=gost hash.txt
```

ssh uname and password hidden inside image

```
 steghide extract -sf Untitled
```

then escalated the privlege via cron job
