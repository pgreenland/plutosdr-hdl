source $ad_hdl_dir/projects/common/zc706/zc706_system_bd.tcl
source ../common/adrv9001_bd.tcl
source $ad_hdl_dir/projects/scripts/adi_pd.tcl

set mem_init_sys_path [get_env_param ADI_PROJECT_DIR ""]mem_init_sys.txt;

#system ID
ad_ip_parameter axi_sysid_0 CONFIG.ROM_ADDR_BITS 9
ad_ip_parameter rom_sys_0 CONFIG.PATH_TO_FILE "[pwd]/$mem_init_sys_path"
ad_ip_parameter rom_sys_0 CONFIG.ROM_ADDR_BITS 9

if {$ad_project_params(CMOS_LVDS_N) == 0} {
    set sys_cstring "LVDS"
} else {
    set sys_cstring "CMOS"
}

sysid_gen_sys_init_file $sys_cstring
