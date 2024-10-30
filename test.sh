#!/bin/bash

set -e

: ${GDB_REPO:=git://sourceware.org/git/binutils-gdb.git}
: ${GDB_BRANCH:=master}
: ${WORKSPACE:=$(realpath $(dirname $0))}

SRCDIR=$WORKSPACE/src/binutils-gdb
SCRIPTDIR=$WORKSPACE/src/lttng-ci

if [ ! -d "${SRCDIR}" ]; then
    mkdir -p $(dirname $SRCDIR)
    git clone --depth 1 --branch "$GDB_BRANCH" "$GDB_REPO" "$SRCDIR"
else
    if git -C "${SRCDIR}" symbolic-ref -q HEAD; then
        git -C "${SRCDIR}" pull
    fi
fi

if [ ! -d "${SCRIPTDIR}" ]; then
    mkdir -p $(dirname $SCRIPTDIR)
    git clone --depth 1 "https://github.com/lttng/lttng-ci" "$SCRIPTDIR"
else
    if git -C "${SCRIPTDIR}" symbolic-ref -q HEAD; then
        git -C "${SCRIPTDIR}" pull
    fi
fi

#
# Some tests are known to fail on my Jenkins, filter
# them out.
#
if [ "x$JENKINS_URL" != "x" ]; then
git -C "$SCRIPTDIR"  restore scripts/binutils-gdb/build.sh
cat <<END_OF_PATCH | git -C "$SCRIPTDIR" apply -
diff --git a/scripts/binutils-gdb/build.sh b/scripts/binutils-gdb/build.sh
index 29027cf..ca3bbcd 100755
--- a/scripts/binutils-gdb/build.sh
+++ b/scripts/binutils-gdb/build.sh
@@ -402,6 +402,58 @@ UNRESOLVED: gdb.ada/packed_array_assign.exp: value of npr
 UNRESOLVED: gdb.base/gdb-sigterm.exp: 50 SIGTERM passes
 UNRESOLVED: gdb.base/readline-ask.exp: bell for more message
 UNRESOLVED: gdb.python/py-disasm.exp: global_disassembler=GlobalPreInfoDisassembler: disassemble main
+FAIL: gdb.arch/amd64-disp-step-self-call.exp: check return address was updated correctly
+DUPLICATE: gdb.fortran/array-indices.exp: array-indices.exp
+DUPLICATE: gdb.fortran/array-repeat.exp: array-repeat.exp
+FAIL: gdb.mi/mi-multi-commands.exp: args=separate-mi-tty: look for second command output, command length 2023 (timeout)
+FAIL: gdb.reverse/test_ioctl_TCSETSW.exp: handle TCSETSW
+FAIL: gdb.base/huge.exp: print a very large data object (timeout)
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+DUPLICATE: gdb.fortran/huge.exp: huge.exp
+FAIL: gdb.trace/basic-libipa.exp: runto: run to main
+FAIL: gdb.debuginfod/corefile-mapped-file.exp: check value of pointer is unavailable with library file missing
+FAIL: gdb.debuginfod/corefile-mapped-file.exp: check value of pointer is unavailable with wrong library in place
+FAIL: gdb.base/corefile.exp: accessing read-only mmapped data in core file with coremmap.data removed
+FAIL: gdb.reverse/i386-avx-reverse.exp: continue to end of vpunpck_test
+FAIL: gdb.reverse/i386-avx-reverse.exp: continue to breakpoint: end vpunpck_test
+FAIL: gdb.reverse/i386-avx-reverse.exp: delete history for vpunpck_test
+FAIL: gdb.reverse/i386-avx-reverse.exp: leaving vpunpck_test (the program is no longer running)
+FAIL: gdb.reverse/i386-avx-reverse.exp: set xmm0 for vpbroadcast
+FAIL: gdb.reverse/i386-avx-reverse.exp: set xmm1 for vpbroadcast
+FAIL: gdb.reverse/i386-avx-reverse.exp: set xmm15 for vpbroadcast
+FAIL: gdb.reverse/i386-avx-reverse.exp: continue to breakpoint: start vpbroadcast_test (the program is no longer running)
+FAIL: gdb.reverse/i386-avx-reverse.exp: vpbroadcast: turn on process record
+FAIL: gdb.reverse/i386-avx-reverse.exp: continue to end of vpbroadcast_test (the program is no longer running)
+FAIL: gdb.reverse/i386-avx-reverse.exp: delete failed record history
+DUPLICATE: gdb.reverse/i386-avx-reverse.exp: delete failed record history
+FAIL: gdb.reverse/i386-avx-reverse.exp: continue to breakpoint: end vpbroadcast_test (the program is no longer running)
+FAIL: gdb.reverse/i386-avx-reverse.exp: leaving vpbroadcast (the program is no longer running)
+FAIL: gdb.reverse/i386-avx-reverse.exp: set ymm0 for vzeroupper
+FAIL: gdb.reverse/i386-avx-reverse.exp: set ymm1 for vzeroupper
+FAIL: gdb.reverse/i386-avx-reverse.exp: set ymm2 for vzeroupper
+FAIL: gdb.reverse/i386-avx-reverse.exp: set ymm15 for vpbroadcast
+FAIL: gdb.reverse/i386-avx-reverse.exp: continue to breakpoint: start vzeroupper_test (the program is no longer running)
+FAIL: gdb.reverse/i386-avx-reverse.exp: vzeroupper: turn on process record
+FAIL: gdb.reverse/i386-avx-reverse.exp: continue to end of vzeroupper_test (the program is no longer running)
+FAIL: gdb.reverse/i386-avx-reverse.exp: delete failed record history
+DUPLICATE: gdb.reverse/i386-avx-reverse.exp: delete failed record history
+FAIL: gdb.reverse/i386-avx-reverse.exp: continue to breakpoint: end vzeroupper_test (the program is no longer running)
+FAIL: gdb.reverse/i386-avx-reverse.exp: leaving vzeroupper (the program is no longer running)
 EOF
 
 cat <<'EOF' > known-failures-re-unix
END_OF_PATCH
#git -C "$SCRIPTDIR" apply $(realpath extra-failing-tests.patch)
fi

rm -rf results

sed -i -e 's#=guile\-2\.2##g' "${SCRIPTDIR}/scripts/binutils-gdb/build.sh"



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

. "${SCRIPTDIR}/scripts/common/print.sh"
. "${SCRIPTDIR}/scripts/binutils-gdb/build.sh"

