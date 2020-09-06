ARG REPO
ARG NAME
ARG VERSION
ARG LAST_LAYER

FROM $REPO/centos-7:latest

COPY fs /

RUN /tmp/configure_sshd.sh || exit $?

EXPOSE 22/tcp

