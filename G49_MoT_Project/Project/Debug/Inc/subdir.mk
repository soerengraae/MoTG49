################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_UPPER_SRCS += \
../Inc/bit-op_macros.S \
../Inc/sine.S 

OBJS += \
./Inc/bit-op_macros.o \
./Inc/sine.o 

S_UPPER_DEPS += \
./Inc/bit-op_macros.d \
./Inc/sine.d 


# Each subdirectory must supply rules for building sources it contributes
Inc/%.o: ../Inc/%.S Inc/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m4 -g3 -DDEBUG -c -I"/Users/sorengraae/Desktop/ENEE440 FINAL PROJECT/FinalProject_ws1/Project/Inc" -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

clean: clean-Inc

clean-Inc:
	-$(RM) ./Inc/bit-op_macros.d ./Inc/bit-op_macros.o ./Inc/sine.d ./Inc/sine.o

.PHONY: clean-Inc

