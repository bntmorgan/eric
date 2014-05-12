sp 		:= $(sp).x
dirstack_$(sp)	:= $(d)
d		:= $(dir)

dir	:= $(d)/checker
include	$(dir)/rules.mk

dir	:= $(d)/mpu
include	$(dir)/rules.mk

dir	:= $(d)/hm
include	$(dir)/rules.mk

d		:= $(dirstack_$(sp))
sp		:= $(basename $(sp))
