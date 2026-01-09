#!/bin/bash
#
# Copyright (C) 2021 Michael Jeanson <mjeanson@efficios.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -exu

mktemp_compat() {
    case "$platform" in
        macos*)
            # On MacOSX, mktemp doesn't respect TMPDIR in the same way as many
            # other systems. Use the final positional argument to force the
            # tempfile or tempdir to be created inside $TMPDIR, which must
            # already exist.
            if [ -n "${TMPDIR}" ] ; then
                mktemp "${@}" "${TMPDIR}/tmp.XXXXXXXXXX"
            else
                mktemp "${@}"
            fi
        ;;
        *)
            mktemp "${@}"
        ;;
    esac
}

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

failed_configure() {
    # Assume we are in the configured build directory
    echo "#################### BEGIN config.log ####################"
    cat config.log
    echo "#################### END config.log ####################"
    exit 1
}

# Required variables
WORKSPACE=${WORKSPACE:-}

platform=${platform:-}
conf=${conf:-}
build=${build:-}
target_board=${target_board:-unix}


SRCDIR="$WORKSPACE/src/binutils-gdb"
TMPDIR="$WORKSPACE/tmp"
PREFIX="/build"

function use_ccache()
{
    case "$platform" in
    macos-*)
        return 1
        ;;
    *)
        return 0
        ;;
    esac
}

# Create tmp directory
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"


CFLAGS="-O2 -g -fsanitize=address "
CXXFLAGS="-O2 -g -fsanitize=address -D_GLIBCXX_DEBUG=1 "
LDFLAGS="-fsanitize=address"
CC="cc"
CXX="c++"

# Add compiler-specific flags if needed
major=$($CC -dumpversion | sed -e 's#\..*$##g')
if [ "$major" -ge 14 ]; then
    CFLAGS+="-Wno-error=array-bounds -Wno-error=nonnull"
    CXXFLAGS+="-Wno-error=array-bounds -Wno-error=nonnull"
fi

if use_ccache; then
    CC="ccache $CC"
    CXX="ccache $CXX"
fi

# Exports
export TMPDIR
export CFLAGS
export CXXFLAGS
export LDFLAGS
export CC
export CXX

# To make GDB find libcc1.so
export LD_LIBRARY_PATH="/usr/lib/gcc/x86_64-linux-gnu/11:${LD_LIBRARY_PATH:-}"

# Set platform variables
export TAR=tar
export MAKE=make

case "$platform" in
macos-*)
    export NPROC="getconf _NPROCESSORS_ONLN"
    export PATH="/opt/local/bin:/opt/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    export CPPFLAGS="-I/opt/local/include"
    export LDFLAGS="-L/opt/local/lib"
    export PYTHON="python3.9"
    export PYTHON_CONFIG="python3.9-config"
    ;;
*)
    export NPROC=nproc
    ;;
esac

# Print build env details
print_header "Build environment details"
print_hardware || true
print_os || true
print_tooling || true

if use_ccache; then
    ccache -c
fi

# This job has been seen generating cores in /tmp, filling and and causing
# problems.  Remove any leftover core from a previous job.
rm /tmp/core.* || true

# Enter the source directory
cd "$SRCDIR"

# Install pre-commit and run pre-commit check.
venv=$(mktemp_compat -d "venv.XXXXXXXXXX")
python3 -m virtualenv "$venv"
"$venv/bin/pip" install pre-commit
failed_pre_commit=0
"$venv/bin/pre-commit" run --all-files || failed_pre_commit=1

# Set configure options and environment variables for each build
# configuration.
CONF_OPTS=("--prefix=$PREFIX")

case "$conf" in
*)
    echo "Standard configuration"

    # Use system tools
    CONF_OPTS+=("--disable-binutils" "--disable-ld" "--disable-gold" "--disable-gas" "--disable-sim" "--disable-gprof" "--disable-gprofng")

    # Use system libs
    CONF_OPTS+=("--with-system-readline" "--with-system-zlib")

    # Enable optional features
    CONF_OPTS+=("--enable-targets=all" "--with-expat=yes" "--with-python=python3" "--with-guile" "--enable-libctf")

    # More optional features
    CONF_OPTS+=("--with-debuginfod" "--with-separate-debug-dir=/usr/lib/debug" "--enable-unit-tests")

    # Warnings and sanitizers
    CONF_OPTS+=("--enable-build-warnings" "--enable-gdb-build-warnings" "--enable-ubsan")

    ;;
esac

case "$platform" in
macos-*)
    CONF_OPTS+=("--disable-werror")
    ;;
esac

# Build type
# oot     : out-of-tree build
# dist    : build via make dist
# oot-dist: build via make dist out-of-tree
# *       : normal tree build
#
# Make sure to move to the build directory and run configure
# before continuing.
case "$build" in
*)
    echo "Out of tree build"

    # Create and enter a temporary build directory
    builddir=$(mktemp_compat -d)
    cd "$builddir"

    "$SRCDIR/configure" "${CONF_OPTS[@]}" || failed_configure
    ;;
esac

# We are now inside a configured build directory

# BUILD!
$MAKE -j "$($NPROC)" V=1 MAKEINFO=true

# Install in the workspace
$MAKE install DESTDIR="$WORKSPACE" MAKEINFO=true

# Run tests, don't fail now, we know that "make check" is going to fail,
# since some tests don't pass.
$MAKE -C gdb/testsuite site.exp
# shellcheck disable=SC2016
echo 'set gdb_test_timeout [expr 10 * $timeout]' >> gdb/testsuite/site.exp
$MAKE -j "$($NPROC)" -C gdb --keep-going check RUNTESTFLAGS="--target_board=$target_board" || true

# Copy the dejagnu test results for archiving before cleaning the build dir
mkdir "${WORKSPACE}/results"
cp gdb/testsuite/gdb.log "${WORKSPACE}/results/"
cp gdb/testsuite/gdb.sum "${WORKSPACE}/results/"

# Filter out some known failures.  There is one file per target board.
cat <<'EOF' > known-failures-unix
FAIL: gdb.base/attach-deleted-exec.exp: attach to inferior
FAIL: gdb.reverse/test_ioctl_TCSETSW.exp: handle TCSETSW
FAIL: gdb.base/corefile.exp: warn about coremmap.data missing
FAIL: gdb.base/corefile.exp: accessing read-only mmapped data in core file with coremmap.data removed
FAIL: gdb.base/corefile2.exp: renamed binfile: load core file without having first loaded binfile
FAIL: gdb.debuginfod/corefile-mapped-file.exp: load corefile with library file missing
FAIL: gdb.debuginfod/corefile-mapped-file.exp: check value of pointer is unavailable with library file missing
FAIL: gdb.debuginfod/corefile-mapped-file.exp: check value of pointer is unavailable with wrong library in place
EOF

cat <<'EOF' > known-failures-re-unix
^(FAIL|DUPLICATE): gdb.replay/missing-thread.exp: .*$
EOF

cat <<'EOF' > known-failures-native-gdbserver
EOF

cat <<'EOF' > known-failures-re-native-gdbserver
EOF

cat <<'EOF' > known-failures-native-extended-gdbserver
EOF

cat <<'EOF' > known-failures-re-native-extended-gdbserver
EOF

cat <<'EOF' > known-failures-cc-with-debug-names
EOF

cat <<'EOF' > known-failures-re-cc-with-debug-names
EOF

cat <<'EOF' > known-failures-cc-with-gdb-index
EOF

cat <<'EOF' > known-failures-re-cc-with-gdb-index
EOF

cat <<'EOF' > known-failures-debug-types
EOF

cat <<'EOF' > known-failures-re-debug-types
EOF

cat <<'EOF' > known-failures-cc-with-dwz
EOF

cat <<'EOF' > known-failures-re-cc-with-dwz
EOF

cat <<'EOF' > known-failures-cc-with-dwz-m
EOF

cat <<'EOF' > known-failures-re-cc-with-dwz-m
EOF

cat <<'EOF' > known-failures-fission
EOF

cat <<'EOF' > known-failures-re-fission
EOF

cat <<'EOF' > known-failures-fission-dwp
EOF

cat <<'EOF' > known-failures-re-fission-dwp
EOF

#
# Add extra known failures from file. This is useful when one is only interested
# in not introducing regression compared to some reference ("master" build)
#
if [ -f "${WORKSPACE}/known-failures-${target_board}" ]; then
    cat "${WORKSPACE}/known-failures-${target_board}" >> "known-failures-${target_board}"
fi

known_failures_file="known-failures-${target_board}"
known_failures_re_file="known-failures-re-${target_board}"
grep --invert-match --fixed-strings --file="$known_failures_file" "${WORKSPACE}/results/gdb.sum" | \
    grep --invert-match --extended-regexp --file="$known_failures_re_file" > "${WORKSPACE}/results/gdb.filtered.sum"
grep --extended-regexp --regexp="^(FAIL|XPASS|UNRESOLVED|DUPLICATE|ERROR):" "${WORKSPACE}/results/gdb.filtered.sum" > "${WORKSPACE}/results/gdb.fail.sum" || true

# For informational purposes: check if some known failure lines did not appear
# in the gdb.sum.
echo "Known failures that don't appear in gdb.sum:"
while read -r line; do
    if ! grep --silent --fixed-strings "$line" "${WORKSPACE}/results/gdb.sum"; then
        echo "$line"
    fi
done < "$known_failures_file" > "${WORKSPACE}/results/known-failures-not-found.sum"

failed_tests=0
if [[ -s "${WORKSPACE}/results/gdb.fail.sum" ]]; then
    failed_tests=1
fi

# Exit with failure if pre-commit or any of the tests failed.
exit $((failed_pre_commit || failed_tests))

# EOF
