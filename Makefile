# Makefile for Lab03-Blinky, ELEC424 Fall 2014
# Authors: Jie Liao, Abeer Javed, Steven Arroyo. Rice University 
# Derived from the crazyflie-firmware Makefile

# Filename defination
FILENAME = $(notdir $(CURDIR))

# Path Definitions
PRO_ROOT = .
STM_ROOT = $(PRO_ROOT)/STM32F10x_StdPeriph_Lib_V3.5.0
STM_LIB =  $(STM_ROOT)/Libraries
STARTUP_PATH = $(STM_LIB)/CMSIS/CM3/DeviceSupport/ST/STM32F10x/startup/TrueSTUDIO
DEV_LIB = $(STM_LIB)/STM32F10x_StdPeriph_Driver
SYS_LIB = $(STM_LIB)/CMSIS/CM3/DeviceSupport/ST/STM32F10x
CORE_LIB = $(STM_LIB)/CMSIS/CM3/CoreSupport
PRO_SRC = $(PRO_ROOT)/src
PRO_INC = $(PRO_ROOT)/inc
PRO_BIN = $(PRO_ROOT)/bin
PRO_LIB = $(PRO_ROOT)/lib
PRO_LINK = $(PRO_ROOT)/linker_script

#VPATH for searching files
# VPATH += $(STARTUP_PATH)  $(DEV_LIB)/src $(SYS_LIB)

# Compiler 
CC = arm-none-eabi-gcc

# Particular processor
PROCESSOR = -mcpu=cortex-m3 -mthumb

# Directories of used header files
INCLUDE = -I$(PRO_INC) -I$(DEV_LIB)/inc -I$(SYS_LIB) -I$(CORE_LIB)

# Static Library

# STM chip specific flags
STFLAGS = -DSTM32F10X_MD -include $(PRO_ROOT)/stm32f10x_conf.h

#Application specific flags
APPFLAGS = -DPROCISE_DELAY

# Define the compiler flags
CFLAGS = -O0 -g3 $(PROCESSOR) $(INCLUDE) $(STFLAGS) -Wl,--gc-sections -T $(PRO_LINK)/stm32_flash.ld

# object files
OBJS = $(STARTUP_PATH)/startup_stm32f10x_md.s \
	$(PRO_SRC)/scheduling.c \
	$(PRO_SRC)/blinky.c\
	$(PRO_SRC)/sys_clk_init.c\
	$(PRO_LIB)/lab04_tasks.a\
	$(DEV_LIB)/src/stm32f10x_rcc.c \
	$(DEV_LIB)/src/stm32f10x_gpio.c \
	$(DEV_LIB)/src/stm32f10x_tim.c \
	$(DEV_LIB)/src/misc.c \
	$(SYS_LIB)/system_stm32f10x.c

ELF_FILE = $(PRO_BIN)/$(FILENAME).elf
# Build all relevant files and create .elf
all: compile flash

compile:
	@$(CC) $(CFLAGS) $(CLIBS) $(OBJS) -o $(ELF_FILE)

# Program .elf into Crazyflie flash memory via the busblaster
OCDFLAG =  -d0 -f interface/busblaster.cfg -f target/stm32f1x.cfg -c init -c targets -c "reset halt" 
flash:
	@openocd $(OCDFLAG) -c "flash write_image erase $(ELF_FILE)" -c "verify_image $(ELF_FILE)" -c "reset run" -c shutdown

# Runs OpenOCD, opens GDB terminal, and establishes connection with Crazyflie
debug:
	openocd $(OCDFLAG) &
	arm-none-eabi-gdb -tui $(ELF_FILE) --eval-command="target remote:3333" 
	ps ax | grep openocd |grep -v grep | awk '{print "kill " $$1}' | sh

#Kill openocd when for some reason openocd haven't closed automatically
kill:
	@ps ax | grep openocd |grep -v grep | awk '{print "kill " $$1}' | sh

#stop the current running process
stop:
	@make kill
	@openocd $(OCDFLAG) -c shutdown

# Remove all files generated by target 'all'
clean:
	rm -f *~ $(ELF_FILE)
