################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_UPPER_SRCS += \
../Src/MoT_devices/LL_device_support/stm32G491RE_MoT_DAC1.S \
../Src/MoT_devices/LL_device_support/stm32G491RE_MoT_SPI2.S \
../Src/MoT_devices/LL_device_support/stm32G491RE_MoT_TIM2.S \
../Src/MoT_devices/LL_device_support/stm32G491RE_MoT_TIM4.S 

OBJS += \
./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_DAC1.o \
./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_SPI2.o \
./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_TIM2.o \
./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_TIM4.o 

S_UPPER_DEPS += \
./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_DAC1.d \
./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_SPI2.d \
./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_TIM2.d \
./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_TIM4.d 


# Each subdirectory must supply rules for building sources it contributes
Src/MoT_devices/LL_device_support/%.o: ../Src/MoT_devices/LL_device_support/%.S Src/MoT_devices/LL_device_support/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m4 -g3 -DDEBUG -c -I"/Users/sorengraae/Desktop/ENEE440 FINAL PROJECT/FinalProject_ws1/Project/Inc" -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

clean: clean-Src-2f-MoT_devices-2f-LL_device_support

clean-Src-2f-MoT_devices-2f-LL_device_support:
	-$(RM) ./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_DAC1.d ./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_DAC1.o ./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_SPI2.d ./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_SPI2.o ./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_TIM2.d ./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_TIM2.o ./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_TIM4.d ./Src/MoT_devices/LL_device_support/stm32G491RE_MoT_TIM4.o

.PHONY: clean-Src-2f-MoT_devices-2f-LL_device_support

