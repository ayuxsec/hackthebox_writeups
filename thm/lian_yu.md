- https://7s26simon.wordpress.com/2020/05/23/lian-yu-write-up/

gobuster command to fuzz:

```
gobuster dir -u 10.10.13.232/island -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
```

after downloading files from ftp the header from `leave_me_alone.png` was wrong

```
$ xxd -l 16 Leave_me_alone.png
00000000: 5845 6fae 0a0d 1a0a 0000 000d 4948 4452 XEo.........IHDR
```

A valid PNG file should start with the 8-byte PNG signature

fixed via (or just edit in a text editor):

```
printf '\x89\x50\x4E\x47\x0D\x0A\x1A\x0A' | dd of=Leave_me_alone.png bs=1 seek=0 count=8 conv=notrunc
```

```
steghide info aa.jpeg
```

reveals the image is hiding some data via steganography

extracted using

```
steghide extract -sf aa.jpg
```

in ftp `cd ..` and `ls` revealed a user slade
