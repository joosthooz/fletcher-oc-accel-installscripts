#!/bin/bash

if [ $# != 2 ]; then
  echo "Usage: $0 <vivado installer> <vivado install config file>"
  exit -1
fi

extractiondir=$(dirname $1)/vivado_installer

$1 --noexec --target ${extractiondir}
${extractiondir}/xsetup -b AuthTokenGen
${extractiondir}/xsetup --agree XilinxEULA,3rdPartyEULA,WebTalkTerms --batch Install --config $2
