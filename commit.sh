#!/bin/bash

set -e

git pull --no-edit
git branch -u origin/master
git pull --no-edit
git submodule update
git submodule > submodules.txt
git checkout -p
./bin/run_tests.dart
git pull --no-edit
git cl land
git pull --no-edit
