#!/bin/bash

set -e

: ${GDB_REPO:=https://github.com/janvrany/binutils-gdb.git}
: ${GDB_BRANCH:=users/jv/vdb}
: ${WORKSPACE:=$(dirname $0)}
: ${BUILD_ID:=_${USER}}


if [ "x$OS" == "xWindows_NT" ]; then
    WORKSPACE=$(cygpath -a $WORKSPACE)
else
    WORKSPACE=$(realpath $WORKSPACE)
fi

SRC_DIR="$WORKSPACE/src/binutils-gdb"
TMPDIR="$WORKSPACE/tmp"

mkdir -p "${TMPDIR}"
export TMPDIR

if [ ! -d "${SRC_DIR}" ]; then
    mkdir -p $(dirname $SRC_DIR)
    git clone --depth 1 --branch "$GDB_BRANCH" "$GDB_REPO" "$SRC_DIR"
fi

if [ -z "$target" ]; then
    target=$($SRC_DIR/config.guess)
    if [ "$target" == "x86_64-pc-msys" ]; then
        target=x86_64-w64-mingw32
    fi
fi

if [ -z "$target" ]; then
    echo "No \\$target variable defined!"
    exit 1
fi

BLD_DIR="${SRC_DIR}/build/${target}"
REL_DIR="${SRC_DIR}/release/gdb_${target}_$(date +%Y-%m-%d)_$(git -C ${SRC_DIR} rev-parse --short HEAD)${BUILD_ID}"

export PATH=/mingw64/bin:$PATH

mkdir -p "$BLD_DIR"
mkdir -p "$REL_DIR"

pushd "$BLD_DIR"

# On Windows, use system (MSYS2) readline, works much better.
if [ "x$OS" == "xWindows_NT" ]; then
    with_system_readline=--with-system-readline
fi

# On Linux and Windows, enable all targets (as these are likelty
# to be used as dev workstations). On all other targets, enable only
# (default) native target
if [ "$(uname)" == "Linux" ]; then
    enable_targets=--enable-targets=all
elif [ "x$OS" == "xWindows_NT" ]; then
    enable_targets=--enable-targets=all
fi

../../configure --prefix=$REL_DIR \
                            --build=$target \
                            --disable-binutils \
                            --disable-gold \
                            --disable-ld \
                            --disable-gprof \
                            --disable-gprofng \
                            --disable-gas \
                            --disable-sim \
                            --disable-guile \
                            --enable-64-bit-bfd \
                            --enable-silent-rules \
                            --disable-werror \
                            --with-python=$(which python3) \
                            $with_system_readline $enable_targets

make -j$(nproc)
make install
popd

# As a courtesy to Windows users, make .zip archive self-contained,
# that is, include all required libraries and replace python with
# embedable version.

if [ "x$OS" == "xWindows_NT" ]; then
        for dll in $(ldd $REL_DIR/bin/gdb.exe | grep mingw | cut -d ' ' -f 3); do
                cp $dll $REL_DIR/bin
        done
        # Now, re-bundle it with embedable Pythom
        pymaj=$(python3 -c 'import sys; print("%d" % sys.version_info[0])')
        pymin=$(python3 -c 'import sys; print("%d" % sys.version_info[1])')
        pyver=$(python3 -c 'import sys; print("%d.%d.%d" % sys.version_info[0:3])')
        pyurl="https://www.python.org/ftp/python/${pyver}/python-${pyver}-embed-amd64.zip"
        wget -O "$BLD_DIR/python.zip" "${pyurl}"
        unzip -d "$REL_DIR/bin" "$BLD_DIR/python.zip"
        pushd $REL_DIR/bin
        rm -f "libpython${pymaj}.${pymin}.dll"
        mv "python${pymaj}${pymin}.dll" "libpython${pymaj}.${pymin}.dll"
        mv "python${pymaj}${pymin}.zip" "libpython${pymaj}.${pymin}.zip"

        for exe in *.exe; do
                icacls $exe //grant Everyone:RX
        done
        popd
fi

# Not all files in bin are binaries...
set +e
for f in $(/usr/bin/find $REL_DIR -wholename \\*/bin/\\* -o -name *.dll -o -name *.so -o -name *.a); do
    echo -n "Stripping $f..."
    strip $f;
    echo done
done
set -e

pushd $(dirname $REL_DIR)
zip -r $(basename $REL_DIR).zip  $(basename $REL_DIR)
popd
