
###############################################################################
# User Physical Constraints
###############################################################################


###############################################################################
# Pinout and Related I/O Constraints
###############################################################################

#
# SYS reset (input) signal.  The sys_reset_n signal should be
# obtained from the PCI Express interface if possible.  For
# slot based form factors, a system reset signal is usually
# present on the connector.  For cable based form factors, a
# system reset signal may not be available.  In this case, the
# system reset signal must be generated locally by some form of
# supervisory circuit.  You may change the IOSTANDARD and LOC
# to suit your requirements and VCCO voltage banking rules.
# Some 7 series devices do not have 3.3 V I/Os available.
# Therefore the appropriate level shift is required to operate
# with these devices that contain only 1.8 V banks.
#

set_property PULLUP true [get_ports sys_rst_n]

###############################################################################
# Physical Constraints
###############################################################################
#
# SYS clock 100 MHz (input) signal. The sys_clk_p and sys_clk_n
# signals are the PCI Express reference clock. Virtex-7 GT
# Transceiver architecture requires the use of a dedicated clock
# resources (FPGA input pins) associated with each GT Transceiver.
# To use these pins an IBUFDS primitive (refclk_ibuf) is
# instantiated in user's design.
# Please refer to the Virtex-7 GT Transceiver User Guide
# (UG) for guidelines regarding clock resource selection.
#


###############################################################################
# Timing Constraints
###############################################################################
#
create_clock -period 10.000 -name sys_clk [get_ports sys_clk_p]

#
#
##############################################################################
# Tandem Configuration Constraints
###############################################################################

set_false_path -from [get_ports sys_rst_n]

###############################################################################
# End
###############################################################################


set_property IOSTANDARD LVCMOS33 [get_ports sys_rst_n]
set_property PACKAGE_PIN AB12 [get_ports sys_rst_n]

set_property LOC IBUFDS_GTE2_X0Y5 [get_cells refclk_ibuf]
set_property PACKAGE_PIN AA6 [get_ports sys_clk_p]
set_property PACKAGE_PIN AA5 [get_ports sys_clk_n]


set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS18} [get_ports CLK_50M]
#create_clock -period 20.000 -waveform {0.000 10.000} [get_ports CLK_50M]

set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS18} [get_ports PL_KEY1]
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS18} [get_ports PL_KEY2]

set_property -dict {PACKAGE_PIN AC19 IOSTANDARD LVTTL} [get_ports PL_LED1]
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVTTL} [get_ports PL_LED2]
set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVTTL} [get_ports PL_LED3]
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVTTL} [get_ports PL_LED4]
set_property -dict {PACKAGE_PIN AA19 IOSTANDARD LVTTL} [get_ports PL_LED5]
set_property -dict {PACKAGE_PIN AB19 IOSTANDARD LVTTL} [get_ports PL_LED6]

set_property LOC GTXE2_CHANNEL_X0Y8 [get_cells {pcie_7x_0_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN AD7 [get_ports {pci_exp_rxn[3]}]
set_property PACKAGE_PIN AD8 [get_ports {pci_exp_rxp[3]}]
set_property PACKAGE_PIN AF7 [get_ports {pci_exp_txn[3]}]
set_property PACKAGE_PIN AF8 [get_ports {pci_exp_txp[3]}]
set_property LOC GTXE2_CHANNEL_X0Y9 [get_cells {pcie_7x_0_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN AE5 [get_ports {pci_exp_rxn[2]}]
set_property PACKAGE_PIN AE6 [get_ports {pci_exp_rxp[2]}]
set_property PACKAGE_PIN AF3 [get_ports {pci_exp_txn[2]}]
set_property PACKAGE_PIN AF4 [get_ports {pci_exp_txp[2]}]
set_property LOC GTXE2_CHANNEL_X0Y10 [get_cells {pcie_7x_0_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN AC5 [get_ports {pci_exp_rxn[1]}]
set_property PACKAGE_PIN AC6 [get_ports {pci_exp_rxp[1]}]
set_property PACKAGE_PIN AE1 [get_ports {pci_exp_txn[1]}]
set_property PACKAGE_PIN AE2 [get_ports {pci_exp_txp[1]}]
set_property LOC GTXE2_CHANNEL_X0Y11 [get_cells {pcie_7x_0_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN AD3 [get_ports {pci_exp_rxn[0]}]
set_property PACKAGE_PIN AD4 [get_ports {pci_exp_rxp[0]}]
set_property PACKAGE_PIN AC1 [get_ports {pci_exp_txn[0]}]
set_property PACKAGE_PIN AC2 [get_ports {pci_exp_txp[0]}]

#set_false_path -from [get_clocks -of_objects [get_pins pll/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins pcie_7x_0_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT3]]
#set_false_path -from [get_clocks -of_objects [get_pins pcie_7x_0_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT3]] -to [get_clocks -of_objects [get_pins pll/inst/mmcm_adv_inst/CLKOUT0]]

#set_false_path -from [get_clocks -of_objects [get_pins pcie_7x_0_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT3]] -to [get_clocks -of_objects [get_pins zynq7035/design_zynq_i/mig_7series_0/u_design_zynq_mig_7series_0_0_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]

set_false_path -from [get_clocks -of_objects [get_pins zynq7035/design_zynq_i/clk_wiz_0/inst/plle2_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins pcie_7x_0_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT3]]
set_false_path -from [get_clocks -of_objects [get_pins pcie_7x_0_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT3]] -to [get_clocks -of_objects [get_pins zynq7035/design_zynq_i/clk_wiz_0/inst/plle2_adv_inst/CLKOUT0]]