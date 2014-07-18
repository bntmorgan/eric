sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Synthesis

SRC_$(d)				:= $(wildcard $(d)/rtl/hm_*.v) $(d)/rtl/dummy_hm_memory.v

# Isim simulations
# SIM							:= $(call SRC_2_BIN, $(d)/checker_memory)
# $(SIM).prj			: $(SRC_$(d)) $(d)/rtl/sim_checker_memory.v
# SIMS 						+= $(SIM).isim

# Icarus simulations

SIM 			      := $(call SRC_2_BIN, $(d)/hm_mr.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_hm_mr.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/sim/rtl/
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/hm_top.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_hm_top.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/sim/rtl/
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/hm_tx.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_hm_tx.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/sim/rtl/
SIMS						+= $(SIM)

# Fixed
# TARGETS 				+= $(TARGET) 

# $(TARGET)				: $(SRC_$(d))

d               := $(dirstack_$(sp))
sp              := $(basename $(sp))
