sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Synthesis
# TARGET          := $(call SRC_2_BIN, $(d)/mpu.bit)
SRC_$(d)				:= $(d)/rtl/mpu_top.v $(d)/rtl/mpu_counter.v \
	$(d)/rtl/mpu_alu.v $(d)/rtl/mpu_decoder.v $(d)/rtl/mpu_execution.v \
  $(d)/rtl/mpu_registers.v

# Simulation
# SIM 			      := $(call SRC_2_BIN, $(d)/mpu_top.sim)
# SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_mpu_top.v
# SIM 			      := $(call SRC_2_BIN, $(d)/mpu_ip.sim)
# SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_mpu_counter.v
SIM 			      := $(call SRC_2_BIN, $(d)/mpu_alu.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_mpu_alu.v
# SIM 			      := $(call SRC_2_BIN, $(d)/mpu_decoder.sim)
# SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_mpu_decoder.v

# Fixed
# TARGETS 				+= $(TARGET) 
SIMS						+= $(SIM)

# $(TARGET)				: $(SRC_$(d))
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl

d               := $(dirstack_$(sp))
sp              := $(basename $(sp))
