#!/bin/sh

set -e

wget --spider -q http://localhost:9000/

exit $?