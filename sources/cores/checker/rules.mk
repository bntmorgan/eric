sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Synthesis

# MPU_SRC
SRC_MPU_$(d) 		:= $(wildcard $(CORES_DIR)/mpu/rtl/mpu*.v) \
	$(wildcard $(CORES_DIR)/mpu/rtl/dummy*.v) \

# TARGET          := $(call SRC_2_BIN, $(d)/checker.bin)
SRC_$(d)				:= $(d)/rtl/checker.v $(d)/rtl/checker_ctlif.v \
	$(d)/rtl/checker_dummy.v $(d)/rtl/checker_single.v $(SRC_MPU_$(d))

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
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/mpu/rtl

d               := $(dirstack_$(sp))
sp              := $(basename $(sp))
