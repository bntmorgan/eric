sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

SRC_FMLBRG_$(d) 		:= $(wildcard $(CORES_DIR)/fmlbrg/rtl/fmlbrg*.v)
SRC_FMLARB_$(d) 		:= $(wildcard $(CORES_DIR)/fmlarb/rtl/fmlarb*.v)

# Synthesis
# TARGET          := $(call SRC_2_BIN, $(d)/fml_ddr3.bit)
SRC_$(d)				:= $(d)/rtl/fml_ddr3_top.v $(d)/rtl/fml_ddr3_ctlif.v \
	$(d)/rtl/fml_ddr3_psync.v

# Simulation
SIM 			      := $(call SRC_2_BIN, $(d)/fml_ddr3_ctlif.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_fml_ddr3_ctlif.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/fml_ddr3_top.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_fml_ddr3_top.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/fml_ddr3_system.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_fml_ddr3_system.v \
	$(SRC_FMLBRG_$(d)) $(SRC_FMLARB_$(d))
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl
SIMS						+= $(SIM)

# Fixed
# TARGETS 				+= $(TARGET) 

# $(TARGET)				: $(SRC_$(d))

d               := $(dirstack_$(sp))
sp              := $(basename $(sp))
