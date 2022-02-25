# GDB development scripts

A set of personal scripts to ease (my) GDB development.

## `build.sh`

[build.sh][1] is a bash script to build GDB. By default, it builds [modified
GDB][2] suitable for [VDB frontend][3], but this can be changed by setting
`GDB_REPO` and `GDB_BRANCH` to different values. Once build finished,
downloadable `.zip` archives with GDB can be found in `binutils-gdb/release`
subdirectory. 

### Building on Windows

[build.sh][1] can be used to build GDB for Windows. Resulting `.zip` archive
is portable, that is, it can be unpacked and used without installing anything.

Working [MSYS2][4] build environment is required in order to build on GDB
on Windows.

[1]: https://github.com/janvrany/binutils-gdb-devscripts/blob/master/build.sh
[2]: https://github.com/janvrany/binutils-gdb.git
[3]: https://swing.fit.cvut.cz/hg/jv-vdb/file/tip/README.md#l1
[4]: https://www.msys2.org/