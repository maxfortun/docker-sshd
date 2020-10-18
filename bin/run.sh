#!/bin/bash -ex

pushd "$(dirname $0)"
SWD=$(pwd)
BWD=$(dirname "$SWD")

. $SWD/setenv.sh

RUN_IMAGE="$REPO/$NAME"

DOCKER_RUN_ARGS=( -e container=docker )

# Publish exposed ports
imageId=$(docker images --format="{{.Repository}} {{.ID}}"|grep "^$RUN_IMAGE "|awk '{ print $2 }')
while read port; do
	hostPort=$DOCKER_PORT_PREFIX${port%%/*}
	[ ${#hostPort} -gt 5 ] && hostPort=${hostPort:${#hostPort}-5}
	DOCKER_RUN_ARGS+=( -p $hostPort:$port )
done < <(docker image inspect -f '{{json .Config.ExposedPorts}}' $imageId|jq -r 'keys[]')

MNT=${MNT:-$BWD/mnt}
HOST_MNT=${HOST_MNT:-$BWD/mnt}

DOCKER_RUN_ARGS+=( -v $HOST_MNT/var/run/sshd:/var/run/sshd )
DOCKER_RUN_ARGS+=( -v $HOST_MNT/root/.ssh/authorized_keys:/root/.ssh/authorized_keys )
DOCKER_RUN_ARGS+=( -v $HOST_MNT/etc/ssh/sshd_config:/etc/ssh/sshd_config )
DOCKER_RUN_ARGS+=( -v $MNT:/mnt/data )

mkdir -p $HOST_MNT/etc/ssh $HOST_MNT/var/run/sshd || true

for algo in rsa dsa ecdsa ed25519; do
	file="/etc/ssh/ssh_host_${algo}_key"
	[ -f "$HOST_MNT/$file" ] || ssh-keygen -t $algo -f "$HOST_MNT/$file" -N ''
	DOCKER_RUN_ARGS+=( -v $HOST_MNT/$file:$file )
done

docker stop $NAME || true
docker system prune -f
docker run -d -it "${DOCKER_RUN_ARGS[@]}" --name $NAME $RUN_IMAGE:$VERSION "$@"

echo "To attach to container run 'docker attach $NAME'. To detach CTRL-P CTRL-Q."
[ "$DOCKER_ATTACH" != "true" ] || docker attach $NAME
