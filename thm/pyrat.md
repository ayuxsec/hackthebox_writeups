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
$ 
```
