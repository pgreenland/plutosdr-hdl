set_property -dict {PACKAGE_PIN B10} [get_ports sfp_ref_clk_p]

set_property -dict {PACKAGE_PIN E4 } [get_ports sfp_tx_p]
set_property -dict {PACKAGE_PIN D2 } [get_ports sfp_rx_p]

set_property -dict {PACKAGE_PIN K20 IOSTANDARD LVCMOS33} [get_ports pl_i2c1_scl]
set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports pl_i2c1_sda]
