#!/bin/bash

set -e

TO=gdb-patches@sourceware.org
REPO="$(git rev-parse --show-toplevel)"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PATCHDIR="${REPO}/.git/submissions/$(basename ${BRANCH})"

PUSH=no # 'no' means submitt patch for review
        # 'yes' means sending "pushed" email after the patch
        # was accepted.

function error() {
    echo "ERROR: $1"
    exit $2
}

for arg
do
    shift
    case "$arg" in
        --pushed|--push)
            if [ ! -z "$PATCHVER" ]; then
                error "Cannot use --pushed together with -v<NUM>"
            fi
            PUSH=yes
            PATCHVER="-pushed"
            set -- "$@" "--subject-prefix=pushed" "-N"
            ;;
        -v*)
            if [ "$PUSH" == "yes" ]; then
                error "Cannot use --pushed together with -v<NUM>"
            fi
            PATCHVER="$arg"
            set -- "$@" "$arg"
            ;;
        *)
            set -- "$@" "$arg"
            ;;
    esac
done

if [ -z "$PATCHVER" ]; then
    PATCHVER=-v1
fi

if [ -e "${PATCHDIR}${PATCHVER}" ]; then
    error "submission directory already exists: ${PATCHDIR}${PATCHVER}"
fi

git fetch origin
git rebase --ignore-date origin/master

git format-patch ${1+"$@"} \
       --to "${TO}" \
       -o "${PATCHDIR}${PATCHVER}" \
       origin/master

cat <<END
Patches:

$(ls -1 ${PATCHDIR}${PATCHVER})

To review patches (use ':n' and ':p' to move to next / prev patch)

       less $(realpath --relative-to=. ${PATCHDIR}${PATCHVER})/*00*.patch

END

if [ "$PUSH" == "yes" ]; then
    cat <<END
Once you're happy:

 1. test again!

 2. push to upstream ang hope everything is going to be all right...

    git push origin ${BRANCH}:master

 3. send "pushed" email to ${TO}:

    git send-email --to '${TO}' ${PATCHDIR}${PATCHVER}

END
else
    cat <<END
Once you're happy, send patches to ${TO}:

    git send-email --to '${TO}' ${PATCHDIR}${PATCHVER}

END
fi
