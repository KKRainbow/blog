#!/bin/bash
git submodule update --init --recursive
cd ./themes-customs
find . -type f -exec ln -srf {} ../themes/next/{} \;
cd -
