# docker-sshd

To connect to container via ssh add a public key:
```
if [ -f ~/.ssh/id_rsa.pub ]; then
	mkdir -p /tmp/$$/fs/root/.ssh
	chmod og-rwx /tmp/$$/fs/root/.ssh
	cp ~/.ssh/id_rsa.pub /tmp/$$/fs/root/.ssh
    docker cp -a /tmp/$$/. sshd:/
fi
```

