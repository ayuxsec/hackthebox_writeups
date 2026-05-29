downloaded image from frosted flake blog and flag was inside image

```
$ strings be2sOV9.jpg
THM{Tony_Sure_Loves_Frosted_Flakes}
```

---

rce

https://github.com/joaomatosf/jexboss

priv esc

```
cmnatic@thm-java-deserial:/home/jboss$ cat note
Hey JBoss!
<!--snip-->
Password: likeaboss
<!--snip-->
```

after logging as jboss user through ssh we get `find` command as allowed to be run as sudo 
