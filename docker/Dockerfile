FROM alpine:edge

RUN echo https://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories

RUN apk add --update openssh rsync && \
	mkdir /root/.ssh && \
	chmod -R og-rwx /root/.ssh && \
	sed -i -e 's/^root:!:/root::/' /etc/shadow

EXPOSE 22

CMD [ "/usr/sbin/sshd", "-D" ]

