sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Synthesis
# TARGET          := $(call SRC_2_BIN, $(d)/checker.bin)
SRC_$(d)				:= $(d)/rtl/checker.v $(d)/rtl/checker_ctlif.v $(d)/rtl/checker_dummy.v

# Simulation
# SIM 			      := $(call SRC_2_BIN, $(d)/checker.sim)
# SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_csr.v
SIM 			      := $(call SRC_2_BIN, $(d)/checker_ctlif.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_ctlif.v
# SIM 			      := $(call SRC_2_BIN, $(d)/checker_dummy.sim)
# SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_dummy.v
# SIM 			      := $(call SRC_2_BIN, $(d)/checker.sim)
# SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_csr.v

# Fixed
# TARGETS 				+= $(TARGET) 
SIMS						+= $(SIM)

# $(TARGET)				: $(SRC_$(d))
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl

d               := $(dirstack_$(sp))
sp              := $(basename $(sp))
