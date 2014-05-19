sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Synthesis

# MPU_SRC
SRC_MPU_$(d) 		:= $(wildcard $(CORES_DIR)/mpu/rtl/mpu*.v)
SRC_HM_$(d) 		:= $(wildcard $(CORES_DIR)/hm/rtl/hm*.v) \
	$(CORES_DIR)/hm/rtl/dummy_hm_memory.v

# TARGET          := $(call SRC_2_BIN, $(d)/checker.bin)
SRC_$(d)				:= $(wildcard $(d)/rtl/checker_*.v) $(SRC_MPU_$(d)) \
	$(SRC_HM_$(d)) \
	$(d)/rtl/dummy_checker_memory.v \
	$(d)/rtl/dummy_checker_host_memory.v

# Isim simulations
# SIM							:= $(call SRC_2_BIN, $(d)/checker_memory)
# $(SIM).prj			: $(SRC_$(d)) $(d)/rtl/sim_checker_memory.v
# SIMS 						+= $(SIM).isim

# Icarus simulations

SIM 			      := $(call SRC_2_BIN, $(d)/checker.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_csr.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/mpu/rtl \
 -I$(CORES_DIR)/hm/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/checker_ctlif.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_ctlif.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/mpu/rtl \
 -I$(CORES_DIR)/hm/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/checker_dummy.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_dummy.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/mpu/rtl \
 -I$(CORES_DIR)/hm/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/checker_memory.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_memory.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/mpu/rtl \
 -I$(CORES_DIR)/hm/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/checker_wb_to_ram.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_wb_to_ram.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/mpu/rtl \
 -I$(CORES_DIR)/hm/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/checker_mpu_to_ram.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_mpu_to_ram.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/mpu/rtl \
 -I$(CORES_DIR)/hm/rtl
SIMS						+= $(SIM)

SIM 			      := $(call SRC_2_BIN, $(d)/checker_single.sim)
SRC_SIM_$(d)		:= $(SRC_$(d)) $(d)/rtl/sim_checker_single.v
$(SIM)					: $(SRC_SIM_$(d))
$(SIM)					: SIM_CFLAGS := -I$(d)/rtl -I$(CORES_DIR)/mpu/rtl \
 -I$(CORES_DIR)/hm/rtl
SIMS						+= $(SIM)

# Fixed
# TARGETS 				+= $(TARGET) 

# $(TARGET)				: $(SRC_$(d))

d               := $(dirstack_$(sp))
sp              := $(basename $(sp))
