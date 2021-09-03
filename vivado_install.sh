#!/bin/bash

if [ $# != 2 ]; then
  echo "Usage: $0 <vivado install config file>
  exit -1
fi

/opt/Xilinx_Vivado_2019.2_1106_2127/xsetup --agree XilinxEULA,3rdPartyEULA,WebTalkTerms --batch Install --config $1
