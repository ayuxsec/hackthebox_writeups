1. Port discovery

```console
$ rustscan -a twomillion.htb -t 5000 -b 1000 -- -sV | tee rustscan.out
PORT   STATE SERVICE REASON  VERSION
22/tcp open  ssh     syn-ack OpenSSH 8.9p1 Ubuntu 3ubuntu0.1 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    syn-ack nginx
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

2. Port 80 analysis

```console
$ curl -I http://twomillion.htb
HTTP/1.1 301 Moved Permanently
Server: nginx
Date: Thu, 26 Feb 2026 04:33:14 GMT
Content-Type: text/html
Content-Length: 162
Connection: keep-alive
Location: http://2million.htb/

$ cat /etc/hosts
10.129.229.66 twomillion.htb 2million.htb

$ curl -X GET -I http://2million.htb
HTTP/1.1 200 OK
Server: nginx
Date: Thu, 26 Feb 2026 04:34:58 GMT
Content-Type: text/html; charset=UTF-8
Transfer-Encoding: chunked
Connection: keep-alive
Set-Cookie: PHPSESSID=tdr8cjv16t0e8pvjv7qrllqs77; path=/
Expires: Thu, 19 Nov 1981 08:52:00 GMT
Cache-Control: no-store, no-cache, must-revalidate
Pragma: no-cache

$ ffuf -u "http://2million.htb/FUZZ" -w ~/Desktop/wordlists/raft-large-words.txt -ac -c

login                   [Status: 200, Size: 3704, Words: 1365, Lines: 81, Duration: 306ms]
register                [Status: 200, Size: 4527, Words: 1512, Lines: 95, Duration: 283ms]
invite                  [Status: 200, Size: 3859, Words: 1363, Lines: 97, Duration: 197ms]
...

$ curl -I -X GET http://2million.htb/register
HTTP/1.1 200 OK

$ curl -X GET http://2million.htb/invite
....
    <!-- scripts -->
    <script src="/js/htb-frontend.min.js"></script>
    <script defer src="/js/inviteapi.min.js"></script>
    <script defer>
        $(document).ready(function() {
            $('#verifyForm').submit(function(e) {
                e.preventDefault();

                var code = $('#code').val();
                var formData = { "code": code };

                $.ajax({
                    type: "POST",
                    dataType: "json",
                    data: formData,
                    url: '/api/v1/invite/verify',
                    success: function(response) {
                        if (response[0] === 200 && response.success === 1 && response.data.message === "Invite code is valid!") {
                            // Store the invite code in localStorage
                            localStorage.setItem('inviteCode', code);

                            window.location.href = '/register';
                        } else {
                            alert("Invalid invite code. Please try again.");
                        }
                    },
                    error: function(response) {
                        alert("An error occurred. Please try again.");
                    }
                });
            });
        });
    </script>

$ curl -X GET http://2million.htb/js/inviteapi.min.js
eval(function(p,a,c,k,e,d){e=function(c){return c.toString(36)};if(!''.replace(/^/,String)){while(c--){d[c.toString(a)]=k[c]||c.toString(a)}k=[function(e){return d[e]}];e=function(){return'\\w+'};c=1};while(c--){if(k[c]){p=p.replace(new RegExp('\\b'+e(c)+'\\b','g'),k[c])}}return p}('1 i(4){h 8={"4":4};$.9({a:"7",5:"6",g:8,b:\'/d/e/n\',c:1(0){3.2(0)},f:1(0){3.2(0)}})}1 j(){$.9({a:"7",5:"6",b:\'/d/e/k/l/m\',c:1(0){3.2(0)},f:1(0){3.2(0)}})}',24,24,'response|function|log|console|code|dataType|json|POST|formData|ajax|type|url|success|api/v1|invite|error|data|var|verifyInviteCode|makeInviteCode|how|to|generate|verify'.split('|'),0,{}))
```

goto https://thanhle.io.vn/de4js/ -> deobfuscate javascript through eval

```js
function verifyInviteCode(code) {
    var formData = {
        "code": code
    };
    $.ajax({
        type: "POST",
        dataType: "json",
        data: formData,
        url: '/api/v1/invite/verify',
        success: function (response) {
            console.log(response)
        },
        error: function (response) {
            console.log(response)
        }
    })
}

function makeInviteCode() {
    $.ajax({
        type: "POST",
        dataType: "json",
        url: '/api/v1/invite/how/to/generate',
        success: function (response) {
            console.log(response)
        },
        error: function (response) {
            console.log(response)
        }
    })
}
```

```console
$ curl -X POST http://2million.htb/api/v1/invite/how/to/generate -s | jq .
{
  "0": 200,
  "success": 1,
  "data": {
    "data": "Va beqre gb trarengr gur vaivgr pbqr, znxr n CBFG erdhrfg gb /ncv/i1/vaivgr/trarengr",
    "enctype": "ROT13"
  },
  "hint": "Data is encrypted ... We should probbably check the encryption type in order to decrypt it..."
}

$ echo "Va beqre gb trarengr gur vaivgr pbqr, znxr n CBFG erdhrfg gb /ncv/i1/vaivgr/trarengr" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
In order to generate the invite code, make a POST request to /api/v1/invite/generate

$ curl -X POST http://2million.htb/api/v1/invite/generate -s | jq .
{
  "0": 200,
  "success": 1,
  "data": {
    "code": "V0lORlYtUEwyTVotQlk1RzMtMEVBSkM=",
    "format": "encoded"
  }
}

$ echo "V0lORlYtUEwyTVotQlk1RzMtMEVBSkM=" | base64 -d
WINFV-PL2MZ-BY5G3-0EAJC
```



