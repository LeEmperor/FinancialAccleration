#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
# 

if [ -z "$PATH" ]; then
  PATH=/home/wayne/xilinx/Vivado/2021.2/ids_lite/ISE/bin/lin64:/home/wayne/xilinx/Vivado/2021.2/bin
else
  PATH=/home/wayne/xilinx/Vivado/2021.2/ids_lite/ISE/bin/lin64:/home/wayne/xilinx/Vivado/2021.2/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=
else
  LD_LIBRARY_PATH=:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD='/home/wayne/FPGA/FinancialAccleration/FeedParser/vivado21_proj/feed_parser_rtl.runs/impl_1'
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

# pre-commands:
/bin/touch .init_design.begin.rst
EAStep vivado -log feed_parser.vdi -applog -m64 -product Vivado -messageDb vivado.pb -mode batch -source feed_parser.tcl -notrace


