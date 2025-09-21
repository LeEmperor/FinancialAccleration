#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
# 

if [ -z "$PATH" ]; then
  PATH=/home/wayne/xilinx/vivado_install/2025.1/Vitis/bin:/home/wayne/xilinx/vivado_install/2025.1/Vivado/ids_lite/ISE/bin/lin64:/home/wayne/xilinx/vivado_install/2025.1/Vivado/bin
else
  PATH=/home/wayne/xilinx/vivado_install/2025.1/Vitis/bin:/home/wayne/xilinx/vivado_install/2025.1/Vivado/ids_lite/ISE/bin/lin64:/home/wayne/xilinx/vivado_install/2025.1/Vivado/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=
else
  LD_LIBRARY_PATH=:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD='/home/wayne/FPGA_stuff/FinancialAccleration/TestEnvironments/orderbook_test1/vivado_proj/launch_folder/synth_1'
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

EAStep vivado -log orderbook.vds -m64 -product Vivado -mode batch -messageDb vivado.pb -notrace -source orderbook.tcl
