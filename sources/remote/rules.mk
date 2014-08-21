sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Synthesis
TARGET          := $(call SRC_2_BIN, $(d)/system)

# synthesis sources definition
SRC_$(d)				:= 

include $(d)/sources.mk

CONSTRAINTS_$(d)  := $(d)/synthesis/common.ucf $(d)/synthesis/v6_pcie_v1_7.ucf
# $(d)/synthesis/mig_v3_6.ucf 
	
	# $(d)/synthesis/mig_v3_6.ucf

# Fixed
TARGETS 				+= $(call GEN_TARGETS, $(TARGET))

$(TARGET).prj			: $(SRC_$(d))
$(TARGET).ucf			: $(CONSTRAINTS_$(d))
$(TARGET).xst			: $(d)/synthesis/system.xst

d               := $(dirstack_$(sp))
sp              := $(basename $(sp))
