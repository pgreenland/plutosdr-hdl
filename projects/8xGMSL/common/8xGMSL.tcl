create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sfp_ref_clk_0
set_property CONFIG.FREQ_HZ 156250000 [get_bd_intf_ports /sfp_ref_clk_0]

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 sfp_txr
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 pl_iic

ad_ip_instance axi_gpio axi_gpio_qpllreset
ad_ip_parameter axi_gpio_qpllreset CONFIG.C_IS_DUAL 0
ad_ip_parameter axi_gpio_qpllreset CONFIG.C_GPIO_WIDTH 1

ad_ip_instance axi_iic axi_pl_iic

ad_ip_instance xxv_ethernet ethernet_sfp
ad_ip_parameter ethernet_sfp CONFIG.ADD_GT_CNTRL_STS_PORTS {0}
ad_ip_parameter ethernet_sfp CONFIG.BASE_R_KR {BASE-R}
ad_ip_parameter ethernet_sfp CONFIG.CORE {Ethernet MAC+PCS/PMA 64-bit}
ad_ip_parameter ethernet_sfp CONFIG.DATA_PATH_INTERFACE {AXI Stream}
ad_ip_parameter ethernet_sfp CONFIG.ENABLE_PREEMPTION {0}
ad_ip_parameter ethernet_sfp CONFIG.ENABLE_TIME_STAMPING {1}
ad_ip_parameter ethernet_sfp CONFIG.SYS_CLK {10000}
ad_ip_parameter ethernet_sfp CONFIG.GT_GROUP_SELECT {Quad_X1Y3}
ad_ip_parameter ethernet_sfp CONFIG.GT_LOCATION {1}
ad_ip_parameter ethernet_sfp CONFIG.INCLUDE_AXI4_INTERFACE {1}
ad_ip_parameter ethernet_sfp CONFIG.INCLUDE_USER_FIFO {1}
ad_ip_parameter ethernet_sfp CONFIG.LANE1_GT_LOC {X1Y12}

ad_ip_instance ptp_1588_timer_syncer ptp_timer_syncer_0
ad_ip_parameter ptp_timer_syncer_0 CONFIG.AXI4LITE_FREQ {100}
ad_ip_parameter ptp_timer_syncer_0 CONFIG.TS_CLK_PERIOD {10.000}

# CORE_MODE                      => Timer_Syncer
# TS_CLK_PERIOD                  => 10.000
# ENABLE_EXT_TOD_BUS             => 0
# TIMER_FORMAT                   => Time_of_Day
# NUM_PORTS                      => 1
# CORE_MODE_INT                  => 2
# TIMER_FORMAT_INT               => 2
# AXI4LITE_CLK_PERIOD            => 10.0000
# TS_CLK_PERIOD_NS               => 1e-8
# TS_CLK_PERIOD_SCALED_2E48_INT  => 2814749767106560
# THIRTY_MILLISEC_COUNT_INT      => 3000000
# THIRTY_MILLISEC_COUNT_FAST_INT => 3000

ad_ip_instance axi_dma dma_sfp
ad_ip_parameter dma_sfp CONFIG.c_include_sg 1
ad_ip_parameter dma_sfp CONFIG.c_include_mm2s 1
ad_ip_parameter dma_sfp CONFIG.c_m_axi_mm2s_data_width 64
ad_ip_parameter dma_sfp CONFIG.c_m_axis_mm2s_tdata_width 64
ad_ip_parameter dma_sfp CONFIG.c_include_mm2s_dre 1
ad_ip_parameter dma_sfp CONFIG.c_mm2s_burst_size 16
ad_ip_parameter dma_sfp CONFIG.c_include_s2mm 1
ad_ip_parameter dma_sfp CONFIG.c_include_s2mm_dre 1
ad_ip_parameter dma_sfp CONFIG.c_s2mm_burst_size 16
ad_ip_parameter dma_sfp CONFIG.c_sg_include_stscntrl_strm 0

ad_ip_instance axis_data_fifo rx_stream_fifo
ad_ip_parameter rx_stream_fifo CONFIG.FIFO_DEPTH 32768
ad_ip_parameter rx_stream_fifo CONFIG.FIFO_MODE 2
ad_ip_parameter rx_stream_fifo CONFIG.IS_ACLK_ASYNC 0
ad_ip_parameter rx_stream_fifo CONFIG.FIFO_MEMORY_TYPE auto

ad_ip_instance axis_data_fifo tx_stream_fifo
ad_ip_parameter tx_stream_fifo CONFIG.FIFO_DEPTH 32768
ad_ip_parameter tx_stream_fifo CONFIG.FIFO_MODE 2
ad_ip_parameter tx_stream_fifo CONFIG.IS_ACLK_ASYNC 0
ad_ip_parameter tx_stream_fifo CONFIG.FIFO_MEMORY_TYPE auto

ad_ip_instance util_vector_logic util_not_0
ad_ip_parameter util_not_0 CONFIG.C_SIZE 1
ad_ip_parameter util_not_0 CONFIG.C_OPERATION not

ad_ip_instance util_vector_logic util_not_1
ad_ip_parameter util_not_1 CONFIG.C_SIZE 1
ad_ip_parameter util_not_1 CONFIG.C_OPERATION not

ad_ip_instance util_vector_logic util_not_2
ad_ip_parameter util_not_2 CONFIG.C_SIZE 1
ad_ip_parameter util_not_2 CONFIG.C_OPERATION not

ad_ip_instance util_vector_logic util_not_3
ad_ip_parameter util_not_3 CONFIG.C_SIZE 1
ad_ip_parameter util_not_3 CONFIG.C_OPERATION not

ad_ip_instance util_vector_logic util_not_4
ad_ip_parameter util_not_4 CONFIG.C_SIZE 1
ad_ip_parameter util_not_4 CONFIG.C_OPERATION not

ad_ip_instance xlconstant constant_101b
ad_ip_parameter constant_101b CONFIG.CONST_WIDTH {3}
ad_ip_parameter constant_101b CONFIG.CONST_VAL {5}

ad_ip_instance xlconstant const_2
ad_ip_parameter const_2 CONFIG.CONST_WIDTH 56
ad_ip_parameter const_2 CONFIG.CONST_VAL 0

#

ad_connect axi_gpio_qpllreset/gpio_io_o ethernet_sfp/qpllreset_in_0
ad_connect axi_pl_iic/IIC pl_iic

ad_connect tx_stream_fifo/m_axis ethernet_sfp/axis_tx_0
ad_connect tx_stream_fifo/s_axis dma_sfp/M_AXIS_MM2S

ad_connect rx_stream_fifo/m_axis dma_sfp/S_AXIS_S2MM
ad_connect rx_stream_fifo/s_axis ethernet_sfp/axis_rx_0

ad_connect ethernet_sfp/tx_clk_out_0 tx_stream_fifo/s_axis_aclk
ad_connect ethernet_sfp/rx_clk_out_0 rx_stream_fifo/s_axis_aclk
ad_connect ethernet_sfp/tx_clk_out_0 dma_sfp/m_axi_mm2s_aclk
ad_connect ethernet_sfp/rx_clk_out_0 dma_sfp/m_axi_s2mm_aclk
ad_connect sys_cpu_clk dma_sfp/m_axi_sg_aclk

ad_connect util_not_1/op1 ethernet_sfp/user_tx_reset_0
ad_connect util_not_1/res tx_stream_fifo/s_axis_aresetn

ad_connect util_not_2/op1 ethernet_sfp/user_rx_reset_0
ad_connect util_not_2/res rx_stream_fifo/s_axis_aresetn

ad_connect sfp_ref_clk_0 ethernet_sfp/gt_ref_clk

ad_connect sfp_txr ethernet_sfp/gt_serial_port

ad_connect const_2/dout ethernet_sfp/tx_preamblein_0

ad_connect sys_ps8/pl_resetn0 util_not_0/op1
ad_connect util_not_0/res ethernet_sfp/gtwiz_reset_tx_datapath_0
ad_connect util_not_0/res ethernet_sfp/gtwiz_reset_rx_datapath_0

ad_connect dma_sfp/s2mm_prmry_reset_out_n util_not_3/Op1
ad_connect util_not_3/Res ethernet_sfp/rx_reset_0

ad_connect dma_sfp/mm2s_prmry_reset_out_n util_not_4/Op1
ad_connect util_not_4/Res ethernet_sfp/tx_reset_0

ad_connect sys_cpu_clk ethernet_sfp/dclk
ad_connect sys_cpu_reset ethernet_sfp/sys_reset

ad_connect constant_101b/dout ethernet_sfp/rxoutclksel_in_0
ad_connect constant_101b/dout ethernet_sfp/txoutclksel_in_0

ad_connect ethernet_sfp/rx_core_clk_0 ethernet_sfp/rx_clk_out_0

# PTP timer syncer

ad_connect sys_cpu_reset ptp_timer_syncer_0/ts_rst
ad_connect sys_cpu_clk ptp_timer_syncer_0/ts_clk

ad_connect ethernet_sfp/tx_period_ns_0 ptp_timer_syncer_0/core_tx0_period_0
ad_connect ethernet_sfp/rx_period_ns_0 ptp_timer_syncer_0/core_rx0_period_0

ad_connect ethernet_sfp/tx_clk_out_0 ptp_timer_syncer_0/tx_phy_clk_0
ad_connect ethernet_sfp/rx_clk_out_0 ptp_timer_syncer_0/rx_phy_clk_0

ad_connect ethernet_sfp/user_tx_reset_0 ptp_timer_syncer_0/tx_phy_rst_0
ad_connect ethernet_sfp/user_rx_reset_0 ptp_timer_syncer_0/rx_phy_rst_0

create_bd_port -dir O -from 47 -to 0 tx_tod_sec_0
create_bd_port -dir O -from 31 -to 0 tx_tod_ns_0
create_bd_port -dir O -from 47 -to 0 rx_tod_sec_0
create_bd_port -dir O -from 31 -to 0 rx_tod_ns_0

ad_connect ptp_timer_syncer_0/tx_tod_sec_0 tx_tod_sec_0
ad_connect ptp_timer_syncer_0/tx_tod_ns_0 tx_tod_ns_0
ad_connect ptp_timer_syncer_0/rx_tod_sec_0 rx_tod_sec_0
ad_connect ptp_timer_syncer_0/rx_tod_ns_0 rx_tod_ns_0

create_bd_port -dir I -from 79 -to 0 ctl_tx_systemtimerin_0
create_bd_port -dir I -from 79 -to 0 ctl_rx_systemtimerin_0

ad_connect ethernet_sfp/ctl_tx_systemtimerin_0 ctl_tx_systemtimerin_0
ad_connect ethernet_sfp/ctl_rx_systemtimerin_0 ctl_rx_systemtimerin_0

#

ad_cpu_interconnect 0x82100000 ethernet_sfp
ad_cpu_interconnect 0x82200000 dma_sfp
ad_cpu_interconnect 0x82300000 ptp_timer_syncer_0
ad_cpu_interconnect 0x82400000 axi_gpio_qpllreset
ad_cpu_interconnect 0x82500000 axi_pl_iic

ad_cpu_interrupt ps-0 mb-0 dma_sfp/mm2s_introut
ad_cpu_interrupt ps-1 mb-1 dma_sfp/s2mm_introut
ad_cpu_interrupt ps-2 mb-2 ptp_timer_syncer_0/tod_intr
ad_cpu_interrupt ps-3 mb-3 axi_pl_iic/iic2intc_irpt

ad_mem_hp0_interconnect sys_cpu_clk sys_ps7/S_AXI_HP0
ad_mem_hp0_interconnect sys_cpu_clk dma_sfp/M_AXI_SG
ad_mem_hp0_interconnect ethernet_sfp/tx_clk_out_0 dma_sfp/M_AXI_MM2S
ad_mem_hp0_interconnect ethernet_sfp/rx_clk_out_0 dma_sfp/M_AXI_S2MM
