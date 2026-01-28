#!/bin/bash
#
set -e

GDB_SRC=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
GDB_BLD=$(pwd)

while getopts "h:s:b:" o; do
    case "${o}" in
    	h)
		;;
        s)
		GDB_SRC=${OPTARG}
		;;
        b)
        	GDB_BLD=${OPTARG}
        	;;
    esac
done
shift $((OPTIND-1))

test -d "${GDB_SRC}" || error "No such GDB source directory: ${GDB_SRC}"
test -f "${GDB_SRC}/gdb/MAINTAINERS" || error "Not a GDB source directory: ${GDB_SRC}"

: ${CC:="$(which ccache > /dev/null && echo 'ccache ')gcc"}
: ${CXX:="$(which ccache > /dev/null && echo 'ccache ')g++"}
: ${CFLAGS:="-fno-inline -g -O0 -fvar-tracking-assignments -fdiagnostics-color=always -fmax-errors=1 -Wno-error=calloc-transposed-args"}
: ${CXXFLAGS:="${CFLAGS} -fdiagnostics-all-candidates -D_GLIBCXX_DEBUG=1 -D_GLIBCXX_DEBUG_PEDANTIC=1 -D_GLIBCXX_SANITIZE_VECTOR=1"}
: ${LDFLAGS:=""}

src=$(realpath "${GDB_SRC}" --relative-to="${GDB_BLD}")
mkdir -p "${GDB_BLD}"

(cd "${GDB_BLD}" && \
	"${src}/configure"  \
		"CC=${CC}" "CXX=${CXX}" "CFLAGS=$CFLAGS" "CXXFLAGS=$CXXFLAGS" "LDFLAGS=${LDFLAGS}" \
		"--prefix=$(mktemp -d)" \
		'--disable-binutils' \
		'--disable-gold' \
		'--disable-ld' \
		'--disable-sim' \
		'--disable-gprof' \
		'--disable-gprofng' \
		'--disable-gas' \
		'--disable-guile' \
		"--with-python=${HOME}/Projects/gdb/cpython/build/install/bin/python3" \
		'--with-debuginfod' \
		'--with-separate-debug-dir=/usr/lib/debug' \
		'--enable-silent-rules' \
		'--enable-werror' \
		'--enable-build-warnings' \
		'--enable-gdb-build-warnings' \
		'--enable-targets=all' \
		'--enable-unit-tests' \
		'--enable-ubsan')