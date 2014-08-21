sp 		:= $(sp).x
dirstack_$(sp)	:= $(d)
d		:= $(dir)

dir	:= $(d)/cores
include	$(dir)/rules.mk
dir	:= $(d)/remote
include	$(dir)/rules.mk
dir	:= $(d)/mig_39_2
include	$(dir)/rules.mk
dir	:= $(d)/mig_v3_6
include	$(dir)/rules.mk

d		:= $(dirstack_$(sp))
sp		:= $(basename $(sp))
