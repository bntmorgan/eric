sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Synthesis
# TARGET          := $(call SRC_2_BIN, $(d)/mpu.bit)
SRC_$(d)				:= $(d)/rtl/aes_256.v $(d)/rtl/round.v $(d)/rtl/table.v

# Simulation
SIM 			      := $(call SRC_2_BIN, $(d)/aes_256.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/testbench/test_aes_256.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/sim/rtl
SIMS						+= $(SIM)

# Fixed
# TARGETS 				+= $(TARGET) 

# $(TARGET)				: $(SRC_$(d))

d               := $(dirstack_$(sp))
sp              := $(basename $(sp))
