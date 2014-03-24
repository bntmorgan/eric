# BOARD_SPECIFIC
SRC_$(d) += $(wildcard $(d)/rtl/*.v) $(d)/rtl/gen_capabilities.v

# ASFIFO_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/asfifo/rtl/*.v)
# CONBUS_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/conbus/rtl/*.v)
# LM32_SRC
SRC_$(d) +=							\
	$(CORES_DIR)/lm32/rtl/lm32_include.v			\
	$(CORES_DIR)/lm32/rtl/lm32_cpu.v			\
	$(CORES_DIR)/lm32/rtl/lm32_instruction_unit.v		\
	$(CORES_DIR)/lm32/rtl/lm32_decoder.v			\
	$(CORES_DIR)/lm32/rtl/lm32_load_store_unit.v		\
	$(CORES_DIR)/lm32/rtl/lm32_adder.v			\
	$(CORES_DIR)/lm32/rtl/lm32_addsub.v			\
	$(CORES_DIR)/lm32/rtl/lm32_logic_op.v			\
	$(CORES_DIR)/lm32/rtl/lm32_shifter.v			\
	$(CORES_DIR)/lm32/rtl/lm32_multiplier.v	\
	$(CORES_DIR)/lm32/rtl/lm32_mc_arithmetic.v		\
	$(CORES_DIR)/lm32/rtl/lm32_interrupt.v			\
	$(CORES_DIR)/lm32/rtl/lm32_ram.v			\
	$(CORES_DIR)/lm32/rtl/lm32_dp_ram.v			\
	$(CORES_DIR)/lm32/rtl/lm32_icache.v			\
	$(CORES_DIR)/lm32/rtl/lm32_dcache.v			\
	$(CORES_DIR)/lm32/rtl/lm32_top.v			\
	$(CORES_DIR)/lm32/rtl/lm32_debug.v			\
	$(CORES_DIR)/lm32/rtl/lm32_jtag.v			\
	$(CORES_DIR)/lm32/rtl/jtag_cores.v			\
	$(CORES_DIR)/lm32/rtl/jtag_tap_spartan6.v
# CHECKER_SRC
SRC_$(d) +=							\
	$(CORES_DIR)/checker/rtl/checker.v			\
	$(CORES_DIR)/checker/rtl/checker.vh			\
	$(CORES_DIR)/checker/rtl/checker_ctlif.v			\
	$(CORES_DIR)/checker/rtl/checker_dummy.v			
# FMLARB_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/fmlarb/rtl/*.v)
# FMLBRG_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/fmlbrg/rtl/*.v)
# CSRBRG_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/csrbrg/rtl/*.v)
# NORFLASH_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/norflash16/rtl/*.v)
# UART_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/uart/rtl/*.v)
# SYSCTL_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/sysctl/rtl/*.v)
# HPDMC_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/hpdmc_ddr32/rtl/*.v) $(wildcard $(CORES_DIR)/hpdmc_ddr32/rtl/spartan6/*.v)
# VGAFB_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/vgafb/rtl/*.v)
# MEMCARD_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/memcard/rtl/*.v)
# AC97_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/ac97/rtl/*.v)
# PFPU_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/pfpu/rtl/*.v)
# TMU_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/tmu2/rtl/*.v)
# ETHERNET_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/minimac2/rtl/*.v)
# FMLMETER_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/fmlmeter/rtl/*.v)
# VIDEOIN_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/bt656cap/rtl/*.v)
# IR_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/rc5/rtl/*.v)
# DMX_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/dmx/rtl/*.v)
# USB_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/softusb/rtl/*.v)
# MEMTEST_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/memtest/rtl/*.v)
# MONITOR_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/monitor/rtl/*.v)

# HARD_PCIE_SRC
# SRC_$(d) +=$(wildcard $(BOARD_DIR)/pcie_ep_ml605_XXX/rtl/*.v) $(wildcard $(BOARD_DIR)/v6_pcie_v1_7/*.v)
# HARD_ETHERNET_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/wb_emac/rtl/*.v) $(wildcard $(d)/rtl/v6_emac_v1_6/*.v)
# BRAM_SRC
SRC_$(d) +=$(wildcard $(CORES_DIR)/bram/rtl/*.v)
