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

HOST_MNT=${HOST_MNT:-$BWD/mnt}
GUEST_MNT=${GUEST_MNT:-$BWD/mnt}

DOCKER_RUN_ARGS+=( -v $GUEST_MNT/var/run/sshd:/var/run/sshd )
DOCKER_RUN_ARGS+=( -v $GUEST_MNT/root/.ssh:/root/.ssh )
DOCKER_RUN_ARGS+=( -v $GUEST_MNT/etc/ssh/sshd_config:/etc/ssh/sshd_config )
DOCKER_RUN_ARGS+=( -v $HOST_MNT:/mnt/host )

mkdir -p $GUEST_MNT/etc/ssh $GUEST_MNT/var/run/sshd || true

for algo in rsa dsa ecdsa ed25519; do
	file="/etc/ssh/ssh_host_${algo}_key"
	[ -f "$GUEST_MNT/$file" ] || ssh-keygen -t $algo -f "$GUEST_MNT/$file" -N ''
	DOCKER_RUN_ARGS+=( -v $GUEST_MNT/$file:$file )
done

docker update --restart=no $NAME || true
docker stop $NAME || true
docker system prune -f
docker run -d -it --restart=always "${DOCKER_RUN_ARGS[@]}" --name $NAME $RUN_IMAGE:$VERSION "$@"

echo "To attach to container run 'docker attach $NAME'. To detach CTRL-P CTRL-Q."
[ "$DOCKER_ATTACH" != "true" ] || docker attach $NAME
