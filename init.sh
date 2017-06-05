#!/bin/bash
git submodule update --init --recursive
cp ./_theme_config.yml ./themes/next/_config.yml
