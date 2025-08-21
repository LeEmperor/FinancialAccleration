# // alias design_comp="vsim -c -do \"vlog -reportprogress 300 -sv -work work \"+incdir+$windows_SRC_DIRECTORY\" C:/FPGA_stuff/test_project_1/src/code_ALU_v1.sv; quit\""

# // vlog -sv -work work "+incdir+C:/FPGA_stuff/ChesapeakeArchitecture/riscv_core/src" C:/FPGA_stuff/ChesapeakeArchitecture/riscv_core/src/ALU_v1.sv ;

# // vlog -sv -incr "+incdir+C:/FPGA_stuff/ChesapeakeArchitecture/riscv_core/src" C:/FPGA_stuff/ChesapeakeArchitecture/riscv_core/src/ALU_v1.sv ;

# // vlog -sv "+incdir+C:/FPGA_stuff/ChesapeakeArchitecture/riscv_core/src" C:/FPGA_stuff/ChesapeakeArchitecture/riscv_core/src/ALU_v1.sv ;

# // vlog -sv C:/FPGA_stuff/ChesapeakeArchitecture/riscv_core/src/ALU_v1.sv ;

vlog -sv -incr \
  ../src/cutthrough_v1.sv \
    \
  ../testbenches/transfer_tb_v1.sv ;
quit ; 

