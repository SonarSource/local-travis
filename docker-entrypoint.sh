#!/bin/bash

set -e

groupadd --gid $DEV_GID travis
useradd --uid $DEV_UID --gid $DEV_GID --home-dir /home/travis travis
chown travis:travis /home/travis

exec gosu travis "$@"
