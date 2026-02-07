#!/bin/bash

set -e

: ${GDB_REPO:=git://sourceware.org/git/binutils-gdb.git}
: ${GDB_BRANCH:=}
: ${GDB_TEST_BOARD:=unix}
: ${GDB_TEST_TIMEOUT_FACTOR:=10}
: ${WORKSPACE:=$(realpath $(dirname $0))}

while getopts ":s:b:" o; do
    case "${o}" in
        s)
            d=${OPTARG}
            if [ ! -d "$d" ]; then
            	echo "ERROR: not a local GDB repository: $d"
            	exit 1
            fi
            if [ ! -e "$d/.git" ]; then
            	echo "ERROR: not a local GDB repository: $d"
            	exit 1
            fi
            if [ ! -f "$d/gdb/MAINTAINERS" ]; then
            	echo "ERROR: not a local GDB repository: $d"
            	exit 1
            fi
            GDB_REPO="$(realpath $d)"
            GDB_BRANCH=
            ;;
       	b)
       		GDB_TEST_BOARD=${OPTARG}
       		;;
    esac
done
shift $((OPTIND-1))

SRCDIR=$WORKSPACE/src/binutils-gdb
SCRIPTDIR=$WORKSPACE

#
# Fetch the source code
#
if [ ! -d "${SRCDIR}" ]; then
    mkdir -p $(dirname $SRCDIR)
    git init $SRCDIR
fi
git -C "$SRCDIR" fetch --depth 1 "$GDB_REPO" $GDB_BRANCH
git -C "$SRCDIR" checkout -f FETCH_HEAD

#
# Delete leftover results
#
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

target_board=$GDB_TEST_BOARD
timeout_factor=$GDB_TEST_TIMEOUT_FACTOR

. "${SCRIPTDIR}/scripts/common/print.sh"
. "${SCRIPTDIR}/scripts/binutils-gdb/build.sh"
