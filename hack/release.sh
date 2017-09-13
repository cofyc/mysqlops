#!/bin/bash

tree=${1:-master}

git checkout $tree
if [ $? -ne 0 ]; then
    echo "error."
    exit
fi

name=$(basename "$(pwd -P)")
tmpdir=$name-$tree

## build
test -d $tmpdir || mkdir $tmpdir
cp -r cluster $tmpdir/

## tar
tar -cjf "$name-$tree.tar.bz2" $tmpdir

## zip
zip -r -9 $name-$tree.zip $tmpdir

## clean
rm -r $tmpdir
