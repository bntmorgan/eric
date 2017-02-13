sp 		:= $(sp).x
dirstack_$(sp)	:= $(d)
d		:= $(dir)

# dir	:= $(d)/checker
# include	$(dir)/rules.mk

dir	:= $(d)/aes_ctr_256
include	$(dir)/rules.mk
#
#dir	:= $(d)/tiny_aes
#include	$(dir)/rules.mk

dir	:= $(d)/mpu
include	$(dir)/rules.mk

dir	:= $(d)/hm
include	$(dir)/rules.mk

dir	:= $(d)/trn
include	$(dir)/rules.mk
 
# dir	:= $(d)/fml_ddr3
# include	$(dir)/rules.mk
# 
# dir	:= $(d)/csr_ddr3
# include	$(dir)/rules.mk

d		:= $(dirstack_$(sp))
sp		:= $(basename $(sp))
