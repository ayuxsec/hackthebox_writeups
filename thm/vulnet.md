Missed

1. Sending `/` gave a base64 cookie
2. We can change it's value and the response was reflected which suggests some internal parsing
3. Upon more inpsection it was found vulnerable to nodejs deserialisation [payload](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Insecure%20Deserialization/Node.md):

```
{"rce":"_$$ND_FUNC$$_function(){require('child_process').exec('ls /', function(error,stdout, stderr) { console.log(stdout) });}()"}
```
