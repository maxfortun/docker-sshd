#!/bin/bash -ex

pushd "$(dirname $0)"
SWD=$(pwd)
BWD=$(dirname "$SWD")

. $SWD/setenv.sh

docker update --restart=no $NAME || true
docker stop $NAME || true
