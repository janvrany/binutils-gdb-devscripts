#!/bin/bash

set -e

: ${GDB_REPO:=git://sourceware.org/git/binutils-gdb.git}
: ${GDB_BRANCH:=master}
: ${GDB_TEST_TIMEOUT_FACTOR:=10}
: ${WORKSPACE:=$(realpath $(dirname $0))}

SRCDIR=$WORKSPACE/src/binutils-gdb
SCRIPTDIR=$WORKSPACE

if [ ! -d "${SRCDIR}" ]; then
    mkdir -p $(dirname $SRCDIR)
    git clone --depth 1 --branch "$GDB_BRANCH" "$GDB_REPO" "$SRCDIR"
else
    if git -C "${SRCDIR}" symbolic-ref -q HEAD; then
        git -C "${SRCDIR}" pull
    fi
fi

rm -rf results

print_header() {
    set +x

    local message=" $1 "
    local message_len
    local padding_len

    message_len="${#message}"
    padding_len=$(( (80 - (message_len)) / 2 ))

    printf '\n'; printf -- '#%.0s' {1..80}; printf '\n'
    printf -- '-%.0s' {1..80}; printf '\n'
    printf -- '#%.0s' $(seq 1 $padding_len); printf '%s' "$message"; printf -- '#%.0s' $(seq 1 $padding_len); printf '\n'
    printf -- '-%.0s' {1..80}; printf '\n'
    printf -- '#%.0s' {1..80}; printf '\n\n'

    set -x
}

function mktemp() {
    if [ $1 == '-d' ]; then
        mkdir -p "$TMPDIR/0000"
        echo "$TMPDIR/0000"
    else
	/usr/bin/mktemp "${@}"
    fi
}

timeout_factor=$GDB_TEST_TIMEOUT_FACTOR

. "${SCRIPTDIR}/scripts/common/print.sh"
. "${SCRIPTDIR}/scripts/binutils-gdb/build.sh"