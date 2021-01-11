#!/usr/bin/env bash
set -xEeuo pipefail

rm -rf public
git clone git@github.com:agracey/agracey.github.io.git public 

hugo -D

pushd public

git add .
git commit -am "publishing"
git push

popd
