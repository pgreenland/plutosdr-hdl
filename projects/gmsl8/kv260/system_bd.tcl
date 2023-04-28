source $ad_hdl_dir/projects/common/kv260/kv260_system_bd.tcl
source $ad_hdl_dir/projects/scripts/adi_pd.tcl

set mipi_phy_if_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if_0 ]

#Create instance: mipi_csi2_rx_subsyst_0, and set properties#
set mipi_csi2_rx_subsyst_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mipi_csi2_rx_subsystem:5.2 mipi_csi2_rx_subsyst_0 ]
  set_property -dict [ list \
   CONFIG.CLK_LANE_IO_LOC {D7} \
   CONFIG.CLK_LANE_IO_LOC_NAME {IO_L13P_T2L_N0_GC_QBC_66} \
   CONFIG.DPHYRX_BOARD_INTERFACE {som240_1_connector_mipi_csi_raspi} \
   CONFIG.CMN_NUM_LANES {2} \
   CONFIG.CMN_PXL_FORMAT {YUV422_8bit} \
   CONFIG.C_CLK_LANE_IO_POSITION {26} \
   CONFIG.C_CSI_EN_ACTIVELANES {false} \
   CONFIG.C_DATA_LANE0_IO_POSITION {28} \
   CONFIG.C_DATA_LANE1_IO_POSITION {30} \
   CONFIG.C_DPHY_LANES {2} \
   CONFIG.C_EN_BG0_PIN0 {false} \
   CONFIG.C_EN_BG1_PIN0 {false} \
   CONFIG.C_EN_CSI_V2_0 {false} \
   CONFIG.C_HS_SETTLE_NS {153} \
   CONFIG.DATA_LANE0_IO_LOC {E5} \
   CONFIG.DATA_LANE0_IO_LOC_NAME {IO_L14P_T2L_N2_GC_66} \
   CONFIG.DATA_LANE1_IO_LOC {G6} \
   CONFIG.DATA_LANE1_IO_LOC_NAME {IO_L15P_T2L_N4_AD11P_66} \
   CONFIG.DPY_LINE_RATE {456} \
   CONFIG.C_EN_CSI_V2_0 {false} \
   CONFIG.CMN_INC_VFB {true} \
   CONFIG.DPY_EN_REG_IF {true} \
   CONFIG.CSI_EMB_NON_IMG {false} \
   CONFIG.VFB_TU_WIDTH {2} \
   CONFIG.HP_IO_BANK_SELECTION {66} \
   CONFIG.SupportLevel {1} \
 ] $mipi_csi2_rx_subsyst_0

ad_ip_instance axi_vdma axi_vdma
ad_ip_parameter axi_vdma CONFIG.C_ADDR_WIDTH {32}
ad_ip_parameter axi_vdma CONFIG.C_INCLUDE_S2MM {1}
ad_ip_parameter axi_vdma CONFIG.C_M_AXI_S2MM_DATA_WIDTH {64}
ad_ip_parameter axi_vdma CONFIG.C_S2MM_MAX_BURST_LENGTH {64}
ad_ip_parameter axi_vdma CONFIG.C_S_AXIS_S2MM_TDATA_WIDTH {16}
ad_ip_parameter axi_vdma CONFIG.C_PRMRY_IS_ACLK_ASYNC {1}
ad_ip_parameter axi_vdma CONFIG.C_USE_S2MM_FSYNC {2}
ad_ip_parameter axi_vdma CONFIG.C_S2MM_GENLOCK_MODE {2}
ad_ip_parameter axi_vdma CONFIG.C_INCLUDE_S2MM_DRE {0}
ad_ip_parameter axi_vdma CONFIG.C_INCLUDE_MM2S {0}

connect_bd_intf_net -intf_net mipi_phy_if_0_1 [get_bd_intf_ports mipi_phy_if_0] [get_bd_intf_pins mipi_csi2_rx_subsyst_0/mipi_phy_if]

ad_ip_instance clk_wiz dphy_clk_generator
ad_ip_parameter dphy_clk_generator CONFIG.PRIMITIVE PLL
ad_ip_parameter dphy_clk_generator CONFIG.RESET_TYPE ACTIVE_LOW
ad_ip_parameter dphy_clk_generator CONFIG.USE_LOCKED false
ad_ip_parameter dphy_clk_generator CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 200.000
ad_ip_parameter dphy_clk_generator CONFIG.CLKOUT1_REQUESTED_PHASE 0.000
ad_ip_parameter dphy_clk_generator CONFIG.CLKOUT1_REQUESTED_DUTY_CYCLE 50.000
ad_ip_parameter dphy_clk_generator CONFIG.PRIM_SOURCE Global_buffer
ad_ip_parameter dphy_clk_generator CONFIG.CLKIN1_UI_JITTER 0
ad_ip_parameter dphy_clk_generator CONFIG.PRIM_IN_FREQ 250.000

ad_ip_instance axi_iic axi_iic_mipi
ad_ip_parameter axi_iic_mipi CONFIG.IIC_BOARD_INTERFACE {som240_1_connector_hda_iic_switch}
ad_ip_parameter axi_iic_mipi CONFIG.IIC_FREQ_KHZ 400

make_bd_intf_pins_external [get_bd_intf_pins axi_iic_mipi/IIC]

ad_connect dphy_clk_generator/clk_in1 $sys_dma_clk
ad_connect dphy_clk_generator/resetn $sys_dma_resetn

ad_connect mipi_csi2_rx_subsyst_0/video_aclk $sys_cpu_clk
ad_connect mipi_csi2_rx_subsyst_0/video_aresetn $sys_cpu_resetn
ad_connect mipi_csi2_rx_subsyst_0/lite_aclk $sys_cpu_clk
ad_connect mipi_csi2_rx_subsyst_0/lite_aresetn $sys_cpu_resetn
ad_connect mipi_csi2_rx_subsyst_0/dphy_clk_200M dphy_clk_generator/clk_out1

ad_connect mipi_csi2_rx_subsyst_0/video_out axi_vdma/S_AXIS_S2MM
ad_connect axi_vdma/s_axi_lite_aclk $sys_cpu_clk
ad_connect axi_vdma/m_axi_s2mm_aclk $sys_cpu_clk
ad_connect axi_vdma/s_axis_s2mm_aclk $sys_cpu_clk
ad_connect axi_vdma/axi_resetn $sys_cpu_resetn

ad_connect axi_iic_mipi/s_axi_aclk $sys_cpu_clk
ad_connect axi_iic_mipi/s_axi_aresetn $sys_cpu_resetn

ad_cpu_interconnect 0x44A00000  mipi_csi2_rx_subsyst_0
ad_cpu_interconnect 0x44A20000  axi_iic_mipi
ad_cpu_interconnect 0x44A40000  axi_vdma

ad_mem_hp1_interconnect $sys_cpu_clk sys_ps7/S_AXI_HP1
ad_mem_hp1_interconnect $sys_cpu_clk axi_vdma/M_AXI_S2MM

ad_cpu_interrupt ps-13 mb-12 mipi_csi2_rx_subsyst_0/csirxss_csi_irq
ad_cpu_interrupt ps-12 mb-11 axi_iic_mipi/iic2intc_irpt
ad_cpu_interrupt ps-11 mb-6 axi_vdma/s2mm_introut

#system ID
ad_ip_parameter axi_sysid_0 CONFIG.ROM_ADDR_BITS 9
ad_ip_parameter rom_sys_0 CONFIG.PATH_TO_FILE "[pwd]/mem_init_sys.txt"
ad_ip_parameter rom_sys_0 CONFIG.ROM_ADDR_BITS 9

sysid_gen_sys_init_file
