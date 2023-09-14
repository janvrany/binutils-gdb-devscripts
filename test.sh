#!/bin/bash

set -e

: ${GDB_REPO:=git://sourceware.org/git/binutils-gdb.git}
: ${GDB_BRANCH:=master}
: ${WORKSPACE:=$(dirname $0)}

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
@@ -402,6 +402,12 @@ UNRESOLVED: gdb.ada/packed_array_assign.exp: value of npr
 UNRESOLVED: gdb.base/gdb-sigterm.exp: 50 SIGTERM passes
 UNRESOLVED: gdb.base/readline-ask.exp: bell for more message
 UNRESOLVED: gdb.python/py-disasm.exp: global_disassembler=GlobalPreInfoDisassembler: disassemble main
+FAIL: gdb.arch/amd64-disp-step-self-call.exp: check return address was updated correctly
+DUPLICATE: gdb.fortran/array-indices.exp: array-indices.exp
+DUPLICATE: gdb.fortran/array-repeat.exp: array-repeat.exp
+FAIL: gdb.mi/mi-multi-commands.exp: args=separate-mi-tty: look for second command output, command length 2023 (timeout)
+FAIL: gdb.reverse/test_ioctl_TCSETSW.exp: handle TCSETSW
+FAIL: gdb.base/huge.exp: print a very large data object (timeout)
 EOF
 
 cat <<'EOF' > known-failures-re-unix
END_OF_PATCH
#git -C "$SCRIPTDIR" apply $(realpath extra-failing-tests.patch)
fi

rm -rf results

sed -i -e 's#=guile\-2\.2##g' "${SCRIPTDIR}/scripts/binutils-gdb/build.sh"
. "${SCRIPTDIR}/scripts/binutils-gdb/build.sh"

