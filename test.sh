#!/bin/bash

set -e

: ${GDB_REPO:=git://sourceware.org/git/binutils-gdb.git}
: ${GDB_BRANCH:=master}
: ${WORKSPACE:=$(pwd)}

SRCDIR=$WORKSPACE/src/binutils-gdb
SCRIPTDIR=$WORKSPACE/src/lttng-ci

if [ ! -d "${SRCDIR}" ]; then
    mkdir -p $(dirname $SRCDIR)
    git clone --depth 1 --branch "$GDB_BRANCH" "$GDB_REPO" "$SRCDIR"
fi

if [ ! -d "${SCRIPTDIR}" ]; then
    mkdir -p $(dirname $SCRIPTDIR)
    git clone --depth 1 "https://github.com/lttng/lttng-ci" "$SCRIPTDIR"
fi

sed -i -e 's#=guile\-2\.2##g' "${SCRIPTDIR}/scripts/binutils-gdb/build.sh"
. "${SCRIPTDIR}/scripts/binutils-gdb/build.sh"

