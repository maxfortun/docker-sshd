#!/bin/bash -ex

pushd "$(dirname $0)"
SWD=$(pwd)
BWD=$(dirname "$SWD")

. $SWD/setenv.sh

RUN_IMAGE="$REPO/$NAME-run"

imageId=$(docker images --format="{{.Repository}} {{.ID}}"|grep "^$RUN_IMAGE "|awk '{ print $2 }')
DOCKER_PORT_ARGS=()
while read port; do
	hostPort=$DOCKER_PORT_PREFIX${port%%/*}
	[ ${#hostPort} -gt 5 ] && hostPort=${hostPort:${#hostPort}-5}
	DOCKER_PORT_ARGS+=( -p $hostPort:$port )
done < <(docker image inspect -f '{{json .Config.ExposedPorts}}' $imageId|jq -r 'keys[]')


OPENVPN_PUBLIC_PORT=${DOCKER_PORT_PREFIX}1194
[ ${#OPENVPN_PUBLIC_PORT} -gt 5 ] &&OPENVPN_PUBLIC_PORT=${OPENVPN_PUBLIC_PORT:${#OPENVPN_PUBLIC_PORT}-5}

OPENVPN_PRIVATE_SUBNETS=$(ifconfig -a|egrep 'inet (10|172.16|192.168)'|awk '{print $6, $4}' | tr '[a-f]' '[A-F]' | while read subnet netmask; do netmask=${netmask#0x}; netmask=$(dc -e 16i2o${netmask}p); netmask=${netmask%%0*}; echo $subnet/${#netmask}; done|xargs)
DOCKER_RUN_ARGS+=( -e container=docker )
DOCKER_RUN_ARGS+=( -e OPENVPN_PUBLIC_PORT=$OPENVPN_PUBLIC_PORT )
DOCKER_RUN_ARGS+=( -e "OPENVPN_PRIVATE_SUBNETS=$OPENVPN_PRIVATE_SUBNETS" )

[ -d $BWD/sharedfs ] || mkdir $BWD/sharedfs

docker stop $NAME || true
docker system prune -f
docker run -d -it --privileged --cap-add=NET_ADMIN --cap-add=MKNOD --tmpfs /run -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v $BWD/sharedfs:/mnt/sharedfs ${DOCKER_PORT_ARGS[*]} "${DOCKER_RUN_ARGS[@]}" --name $NAME $RUN_IMAGE:$VERSION $*

echo "Attaching to container. To detach CTRL-P CTRL-Q."
docker attach $NAME
