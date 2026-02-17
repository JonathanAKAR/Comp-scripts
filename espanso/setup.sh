#!/bin/bash

if [ $UID -ne 0 ]; then
	echo "Run me as root"
	exit 1
fi

mkdir -p /usr/share/espanso
cp -R ./config_files /usr/share/espanso
cp -R ./clipboard /usr/share/espanso
cp ncae.yaml /usr/share/espanso

echo "Config file located at: /usr/share/espanso/ncae.yaml"
echo "Add the following to your Espanso file:"
echo "'''"
echo "imports:
  - \"/usr/share/espanso/ncae.yaml\""
echo "'''"
