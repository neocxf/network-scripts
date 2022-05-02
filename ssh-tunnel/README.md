# ssh 


# ssh reverse tunnel

refer: 
1. [ssh reverse tunnel security](http://arlimus.github.io/articles/ssh.reverse.tunnel.security/)

```bash
vagrant ssh client1
ssh -N -T -R *:8080:localhost:80 192.168.60.123
sudo nc -l -p 80
```


```bash
vagrant ssh saucy
nc localhost 8080

# show the service status
rc-status -l
# restart sshd service
rc-service sshd restart
```