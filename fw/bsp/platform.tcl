# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\hpdh0\workspace\nvme_sys_0323\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\hpdh0\workspace\nvme_sys_0323\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {nvme_sys_0323}\
-hw {C:\Users\hpdh0\Desktop\NVME_0323\top.xsa}\
-proc {ps7_cortexa9_0} -os {standalone} -out {C:/Users/hpdh0/workspace}

platform write
platform generate -domains 
platform active {nvme_sys_0323}
platform generate
platform generate
platform generate
platform generate
platform generate
platform generate
platform generate
platform generate
platform generate
platform generate
platform generate
platform generate
platform generate
platform clean
platform generate
platform generate
platform generate
platform generate
platform generate
platform generate
platform generate
platform generate
platform clean
platform generate
platform clean
platform generate
platform clean
platform generate
platform clean
platform generate
platform clean
platform generate
platform clean
