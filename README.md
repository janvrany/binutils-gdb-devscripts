# GDB development scripts

A set of personal scripts to ease (my) GDB development.

## `release.sh`

[release.sh][1] is a bash script to build GDB for general use. By default,
it builds [modified GDB][2] with (my) not-yet-upstreamed patches but this
can be changed by setting `GDB_REPO` and `GDB_BRANCH` to different values.
Once build finished, downloadable `.zip` archives with GDB can be found
in `binutils-gdb/release` subdirectory.

### Building on Windows

[release.sh][1] can be used to build GDB for Windows. Resulting `.zip` archive
is portable, that is, it can be unpacked and used without installing anything.

Working [MSYS2][4] build environment is required in order to build on GDB
on Windows.

## `test.sh`

[test.sh][1] is a bash script to build GDB and run GDB testsuite using copy of
[scripts from LTTng][5]. (Probably only) useful for GDB development.


[1]: https://github.com/janvrany/binutils-gdb-devscripts/blob/master/release.sh
[2]: https://github.com/janvrany/binutils-gdb.git
[3]: https://github.com/janvrany/binutils-gdb-devscripts/blob/master/test.sh
[4]: https://www.msys2.org/
[5]: https://github.com/lttng/lttng-ci/tree/5a969023c2dd469751ed1af2231c2d1ac54a773d