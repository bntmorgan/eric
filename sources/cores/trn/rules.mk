sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Synthesis

SRC_$(d)				:= $(CORES_DIR)/psync/rtl/psync.v $(wildcard $(d)/rtl/trn_*.v)

# Isim simulations
# SIM							:= $(call SRC_2_BIN, $(d)/checker_memory)
# $(SIM).prj			: $(SRC_$(d)) $(d)/rtl/sim_checker_memory.v
# SIMS 						+= $(SIM).isim

# Icarus simulations

# SIM 			      := $(call SRC_2_BIN, $(d)/trn_top.sim)
# SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/trn_top.v
# $(SIM)					: $(SRC_SIM_$(d))
# $(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/sim/rtl/
# SIMS						+= $(SIM)

# Fixed
# TARGETS 				+= $(TARGET) 

# $(TARGET)				: $(SRC_$(d))

d               := $(dirstack_$(sp))
sp              := $(basename $(sp))
