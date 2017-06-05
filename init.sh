#!/bin/bash
if [ $TRAVIS ];then
CP_FUNC="cp -f"
else
CP_FUNC="ln -srf"
fi
THEME_DIR=../themes/next
git submodule update --init --recursive
cd ./themes-customs
find . -type f -exec rm ${THEME_DIR}/{} -f \; -exec ${CP_FUNC} {} ${THEME_DIR}/{} \;
cd -
