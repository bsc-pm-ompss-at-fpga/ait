#!/bin/bash -e

PREFIX=$1
BASE_DIR=$(
  pushd `dirname ${BASH_SOURCE[0]}` >/dev/null &&
  pwd -P &&
  popd >/dev/null
)

print_msg() {
  echo "[AIT install] $1"
}

if ! ls $BASE_DIR/backend/* >/dev/null 2>&1; then
  print_msg "Folder 'backend' is empty. No support for vendor backend detected."
  exit 1
fi

print_usage() {
  echo -e "USAGE:\t$0 <prefix> <backend>"
  echo -e "  <prefix> path where the AIT files will be installed"
  echo -e "  <backend> supported values: all, `ls -m $BASE_DIR/backend/`"
}

if [ "$#" -ne "2" ]; then
  print_usage
  exit 1
fi

rm -rf $PREFIX/*
mkdir -p $PREFIX
cp -f $BASE_DIR/LICENSE $PREFIX/

# Update the VERSION_COMMIT value before compiling the code
pushd $BASE_DIR >/dev/null
VERSION_COMMIT=$(git describe --tags --exact-match HEAD 2>/dev/null || true)
if [ "$VERSION_COMMIT" == "" ]; then
  VERSION_COMMIT=$(git show -s --format=%h 2>/dev/null || true)
fi
#NOTE: The VERSION_COMMIT will be '' if the installation is being done outside a git repo
if [ "$VERSION_COMMIT" != "" ]; then
  git diff --quiet HEAD || VERSION_COMMIT="$VERSION_COMMIT-dirty"
  sed -i "s~VERSION_COMMIT = .*~VERSION_COMMIT = '$VERSION_COMMIT'~" $BASE_DIR/scripts/config.py
fi
popd >/dev/null

# Compile the scripts folder and copy the binary files
find $BASE_DIR -iname *.pyc -delete
python3 -OO -m compileall -d $PREFIX/scripts -l $BASE_DIR/scripts
mkdir -p $PREFIX/scripts
pushd $BASE_DIR/scripts/__pycache__/ >/dev/null
for f in *.pyc; do
  ls $f | sed -e 'p;s/\([^.]*\)\(\.[^.]*\)\+\.pyc/\1\.pyc/' | xargs -n2 mv
done
popd >/dev/null
rsync -am $BASE_DIR/scripts/__pycache__/ $PREFIX/scripts/ --filter='-! *.pyc'
echo '#!/bin/bash' >$PREFIX/ait
echo 'SCRIPTS_DIR=$(pushd `dirname ${BASH_SOURCE[0]}`/scripts/ >/dev/null && pwd -P && popd >/dev/null)' >>$PREFIX/ait
echo 'python3 -OO $SCRIPTS_DIR/ait.pyc "$@"' >>$PREFIX/ait
chmod +x $PREFIX/ait

old_IFS=$IFS
IFS=','
for i in $2; do
  if [ "$i" == "all" ]; then
    backends=`ls $BASE_DIR/backend/`
    break
  else
    backends=`echo $backends $i`
  fi
done
IFS=${old_IFS}

backends=`echo $backends | xargs`

if [ -z "$backends" ]; then
  print_msg "No backend selected. Please select one or check the AIT sources for the available ones."
  exit
else
  for backend in $backends; do
    print_msg "Installing support for $backend backend"

    python3 -OO -m compileall -d $PREFIX/backend/$backend/scripts $BASE_DIR/backend/$backend/scripts/
    pushd $BASE_DIR/backend/$backend/scripts/__pycache__/ >/dev/null
    for f in *.pyc; do
      ls $f | sed -e 'p;s/\([^.]*\)\(\.[^.]*\)\+\.pyc/\1\.pyc/' | xargs -n2 mv
    done
    popd >/dev/null
    mv $BASE_DIR/backend/$backend/scripts/__pycache__/*.pyc $BASE_DIR/backend/$backend/scripts/

    for s in `ls -d $BASE_DIR/backend/$backend/scripts/* | egrep /[0-9]{2}-*`; do
      pushd $s/__pycache__/ >/dev/null
      for f in *.pyc; do
        ls $f | sed -e 'p;s/\([^.]*\)\(\.[^.]*\)\+\.pyc/\1\.pyc/' | xargs -n2 mv
      done
      popd >/dev/null
      mv $s/__pycache__/*.pyc $s/
    done

    # Create IP cache directory
    mkdir -p $PREFIX/backend/$backend/IP_cache

    # Copy basic templates, scripts and ipdefs
    mkdir -p $PREFIX/backend/$backend/templates
    mkdir -p $PREFIX/backend/$backend/scripts
    mkdir -p $PREFIX/backend/$backend/IPs
    rsync -am $BASE_DIR/backend/$backend/templates/ $PREFIX/backend/$backend/templates/
    rsync -am $BASE_DIR/backend/$backend/scripts/ $PREFIX/backend/$backend/scripts/ --filter='+ */' --filter='+ *.pyc' --filter='- *.py*'
    rsync -am $BASE_DIR/backend/$backend/IPs/ $PREFIX/backend/$backend/IPs/

    # Copy basic HLS sources, IPs and templates
    mkdir -p $PREFIX/backend/$backend/HLS/src
    rsync -am $BASE_DIR/backend/$backend/HLS/src/ $PREFIX/backend/$backend/HLS/src/

    mkdir -p $PREFIX/backend/$backend/board
    pushd $BASE_DIR/backend/$backend/board >/dev/null
    rsync -am $BASE_DIR/backend/$backend/board/ $PREFIX/backend/$backend/board/$BOARD
  done
fi

# Remove bytecode files
find $BASE_DIR -iname *.pyc -delete
find . -type d -iname __pycache__ -delete

print_msg "Installation done in '$PREFIX'"
