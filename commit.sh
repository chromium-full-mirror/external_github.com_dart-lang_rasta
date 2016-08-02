#!/bin/bash

set -e

git pull --no-edit
git branch -u origin/master
git pull --no-edit
git submodule update
git submodule > submodules.txt
git checkout -p
dart -c test/testa.dart
git pull --no-edit
git cl land
git pull --no-edit
