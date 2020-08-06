#!/usr/bin/env bash

set -e

CFLAGS=${CFLAGS:-""}
CONFIGURE_OPTS=${CONFIGURE_OPTS:-""}
CRAN_MIRROR_URL=${CRAN_MIRROR_URL:-"https://cloud.r-project.org"}
MAKE_OPTS=${MAKE_OPTS:-"-j"}

def_dest="."
def_version=""
def_source="$CRAN_MIRROR_URL/src/base/R-latest.tar.gz"

function show_help() {
    echo "Usage: $(basename $0) [-d PATH ] [-s URL ] [-v VERSION ]"
    echo
    echo "where:"
    echo
    echo "  -d PATH      to install R to (defaults to $def_dest)"
    echo "  -s URL       to get R from (defaults to $def_source)"
    echo "  -v VERSION   of R to install"
    echo
}

dest=$def_dest
source=$def_source
version=$def_version

while getopts "h?d:s:v:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    d)  dest=$OPTARG
        ;;
    s)  source=$OPTARG
        ;;
    v)  version=$OPTARG
        source="$CRAN_MIRROR_URL/src/base/R-${version:0:1}/R-$version.tar.gz"
        ;;
    esac
done

echo "Installing R from $source into $dest"

set -o xtrace

pushd . > /dev/null

[ -d "$dest" ] || mkdir -p "$dest"
dest="$(realpath "$dest")"

cd "$dest"

curl -fsSL $source | tar --strip 1 -xzf -

export CPPFLAGS="-g3 -O2 -ggdb3"
export CFLAGS="-g3 -O2 -ggdb3"
export R_KEEP_PKG_SOURCE=yes
export CXX="g++"

./configure --prefix="$(pwd)" \
    --with-blas --with-lapack --without-ICU --with-x \
    --with-tcltk --without-aqua --with-recommended-packages \
    --without-internal-tzcode --with-included-gettext \
    --disable-byte-compiled-packages \
    "$CONFIGURE_OPTS"

make "$MAKE_OPTS"
make "$MAKE_OPTS" install
make "$MAKE_OPTS" install-tests

popd
