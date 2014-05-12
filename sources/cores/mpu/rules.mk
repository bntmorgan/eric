sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Synthesis
# TARGET          := $(call SRC_2_BIN, $(d)/mpu.bit)
SRC_$(d)				:= $(d)/rtl/mpu_top.v $(d)/rtl/mpu_counter.v \
	$(d)/rtl/mpu_alu.v $(d)/rtl/mpu_decoder.v $(d)/rtl/mpu_execution.v \
	$(d)/rtl/mpu_registers.v $(d)/rtl/dummy_mpu_memory.v \

# Simulation
SIM 			      := $(call SRC_2_BIN, $(d)/mpu_ip.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_mpu_counter.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/mpu_alu.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_mpu_alu.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/mpu_decoder.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_mpu_decoder.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/mpu_registers.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_mpu_registers.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/mpu_execution.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_mpu_execution.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/mpu_memory.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_mpu_memory.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/mpu_top.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_mpu_top.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl
SIMS						+= $(SIM)

# Fixed
# TARGETS 				+= $(TARGET) 

# $(TARGET)				: $(SRC_$(d))

d               := $(dirstack_$(sp))
sp              := $(basename $(sp))
