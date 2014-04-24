sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Synthesis

# MPU_SRC
# XXX Remove dummies
SRC_MPU_$(d) 		:= $(wildcard $(CORES_DIR)/mpu/rtl/mpu*.v) \
	$(wildcard $(CORES_DIR)/mpu/rtl/dummy_mpu_host_memory.v)

# TARGET          := $(call SRC_2_BIN, $(d)/checker.bin)
SRC_$(d)				:= $(d)/rtl/checker_top.v $(d)/rtl/checker_ctlif.v \
	$(d)/rtl/checker_dummy.v $(d)/rtl/checker_single.v $(d)/rtl/checker_memory.v \
	$(d)/rtl/checker_wb_to_ram.v $(SRC_MPU_$(d))

# Isim simulations
SIM							:= $(call SRC_2_BIN, $(d)/checker_memory)
$(SIM).prj			: $(SRC_$(d)) $(d)/rtl/sim_checker_memory.v
SIMS 						+= $(SIM).isim

# Icarus simulations
SIM 			      := $(call SRC_2_BIN, $(d)/checker.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_csr.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/mpu/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/checker_ctlif.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_ctlif.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/mpu/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/checker_dummy.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_dummy.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/mpu/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/checker_memory.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_memory.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/mpu/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/checker_wb_to_ram.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_wb_to_ram.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/mpu/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/checker_single.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_single.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/mpu/rtl
SIMS						+= $(SIM)

# Fixed
# TARGETS 				+= $(TARGET) 

# $(TARGET)				: $(SRC_$(d))

d               := $(dirstack_$(sp))
sp              := $(basename $(sp))
