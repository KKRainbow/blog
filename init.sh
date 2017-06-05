#!/bin/bash
git submodule update --init --recursive
ln -srf ./_theme_config.yml ./themes/next/_config.yml
