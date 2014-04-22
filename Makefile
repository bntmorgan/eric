################################## COLORS ######################################

NO_COLOR=\x1b[0m
OK_COLOR=\x1b[32;01m
ERROR_COLOR=\x1b[31;01m
WARN_COLOR=\x1b[33;01m

################################## FUNCTIONS ###################################

define SRC_2_OBJ
  $(foreach src,$(1),$(patsubst sources/%,build/%,$(src)))
endef

define SRC_2_BIN
  $(foreach src,$(1),$(patsubst sources/%,binary/%,$(src)))
endef

define SIM_2_RUN
  $(foreach src,$(1),$(patsubst %.sim,%.run,$(src)))
endef

define RUN_2_SIM
  $(foreach src,$(1),$(patsubst %.run,./%.sim,$(src)))
endef

################################## STARTING RULE ###############################

all: targets simulations

################################## GLOBALS  ####################################

XILINX := /home/bmorgan/Xilinx/14.7/ISE_DS/ISE
XILINX_SIM := $(XILINX)/verilog/src/simprims
XILINX_LIB := $(XILINX)/verilog/src/XilinxCoreLib
CORES_DIR := ./sources/cores

################################## INCLUDES ####################################

# Overriden in rules.mk
TARGETS :=
SIMS :=

dir	:= sources
include	$(dir)/rules.mk

################################## RULES #######################################

targets: $(TARGETS)

simulations: $(SIMS)

%.sim:
	@mkdir -p $(dir $@)
	@echo [VLG] $@
	@iverilog -o $@ $^ $(SIM_CFLAGS) -D__DUMP_FILE__=\"$(abspath $@).vcd\"

%.isim: %.prj
	@mkdir -p $(dir $@)
	@echo [ISM] $@
	@cd $(dir $(realpath $@)) && fuse -prj $(realpath $^) work.main -o $(abspath \
		$@) -d __DUMP_FILE__=\"$(abspath $@).vcd\"


%.bit: %.routed.ncd
	@mkdir -p $(dir $@)
	@echo [BIT] $@
	@cd $(dir $@) && bitgen -g LCK_cycle:6 -g Binary:Yes -g DriveDone:Yes \
		-w $(realpath $^) $(abspath $@) > /dev/null

%.routed.ncd: %.ncd 
	@mkdir -p $(dir $@)
	@echo [RTE] $@ \> $@.out
	@cd $(dir $@) && par -ol high -w $(realpath $^) $(abspath $@) > $(abspath \
		$@).out

%.ncd: %.ngd
	@mkdir -p $(dir $@)
	@echo [NCD] $@ \> $@.out
	@cd $(dir $@) && map -ol high -t 20 -w $(realpath $^) > $(abspath $@).out

%.ngd: %.ucf %.ngc
	@mkdir -p $(dir $@)
	@echo [NGD] $@ \> $@.out
	@cd $(dir $@) && ngdbuild -uc $(realpath $^) > $(abspath $@).out

%.ngc: %.prj %.xst
	@mkdir -p $(dir $@)
	@echo [NGC] $@ \> $@.out
	@cd $(dir $@) && xst -ifn ./system.xst > $(abspath $@).out

%.prj:
	@mkdir -p $(dir $@)
	@echo [PRJ] $@
	@rm -f $@
	@for i in `echo $^`; do \
		echo "verilog work `pwd`/$$i" >> $@; \
	done

%.xst:
	@mkdir -p $(dir $@)
	@echo [XST] $@
	@cp $^ $@

%.ucf:
	@mkdir -p $(dir $@)
	@echo [UCF] $@
	@cat $^ > $@

load: binary/remote/system.bit
	@echo [LOD] $<
	@./impact.sh $(dir $<)impact.batch $(realpath $<) && cd $(dir $<) && impact \
		-batch impact.batch > impact.batch.out

run_simulations: $(call SIM_2_RUN, $(SIMS)) 

%.run: %.sim
	@echo [RUN] $< ">" $<.out
	@cd $(dir $@) && $(realpath $<) > $(realpath $<).out

info:
	@echo TARGETS [$(TARGETS)]
	@echo SIMS [$(SIMS)]

clean:
	@echo [CLR] $(dir $(TARGETS))
	@echo [CLR] $(SIMS)
	@rm -fr $(dir $(TARGETS)) $(SIMS)

mr-proper: mr-proper-vim

mr-proper-vim:
	@echo [CLR] *.swp
	@find . | grep .swp | xargs rm -f
