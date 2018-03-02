#!/bin/bash
if [ $TRAVIS ];then
CP_FUNC="cp -f"
else
CP_FUNC="ln -sf"
fi
CP_FUNC="cp -f"
THEME_DIR=../themes/next
git submodule update --init --recursive
cd ./themes-customs
find . -type f -exec echo {} \; -exec rm -f ${THEME_DIR}/{} \; -exec ${CP_FUNC} {} ${THEME_DIR}/{} \;
cd -
