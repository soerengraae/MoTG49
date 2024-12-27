################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Src/MoT_main.c \
../Src/mpaland_printf.c \
../Src/mpaland_printf_services.c \
../Src/syscalls--left_in_to_quiet_warnings.c 

S_UPPER_SRCS += \
../Src/HW_userCOM05.S \
../Src/SysTick_definitions.S \
../Src/SystemClock_init2.S \
../Src/snprintf_from_asm.S 

OBJS += \
./Src/HW_userCOM05.o \
./Src/MoT_main.o \
./Src/SysTick_definitions.o \
./Src/SystemClock_init2.o \
./Src/mpaland_printf.o \
./Src/mpaland_printf_services.o \
./Src/snprintf_from_asm.o \
./Src/syscalls--left_in_to_quiet_warnings.o 

S_UPPER_DEPS += \
./Src/HW_userCOM05.d \
./Src/SysTick_definitions.d \
./Src/SystemClock_init2.d \
./Src/snprintf_from_asm.d 

C_DEPS += \
./Src/MoT_main.d \
./Src/mpaland_printf.d \
./Src/mpaland_printf_services.d \
./Src/syscalls--left_in_to_quiet_warnings.d 


# Each subdirectory must supply rules for building sources it contributes
Src/%.o: ../Src/%.S Src/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m4 -g3 -DDEBUG -c -I"/Users/sorengraae/Desktop/ENEE440 FINAL PROJECT/FinalProject_ws1/Project/Inc" -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"
Src/%.o Src/%.su Src/%.cyclo: ../Src/%.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DDEBUG -DSTM32 -DSTM32G491RETx -DSTM32G4 -c -I"/Users/sorengraae/Desktop/ENEE440 FINAL PROJECT/FinalProject_ws1/Project/Inc" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-Src

clean-Src:
	-$(RM) ./Src/HW_userCOM05.d ./Src/HW_userCOM05.o ./Src/MoT_main.cyclo ./Src/MoT_main.d ./Src/MoT_main.o ./Src/MoT_main.su ./Src/SysTick_definitions.d ./Src/SysTick_definitions.o ./Src/SystemClock_init2.d ./Src/SystemClock_init2.o ./Src/mpaland_printf.cyclo ./Src/mpaland_printf.d ./Src/mpaland_printf.o ./Src/mpaland_printf.su ./Src/mpaland_printf_services.cyclo ./Src/mpaland_printf_services.d ./Src/mpaland_printf_services.o ./Src/mpaland_printf_services.su ./Src/snprintf_from_asm.d ./Src/snprintf_from_asm.o ./Src/syscalls--left_in_to_quiet_warnings.cyclo ./Src/syscalls--left_in_to_quiet_warnings.d ./Src/syscalls--left_in_to_quiet_warnings.o ./Src/syscalls--left_in_to_quiet_warnings.su

.PHONY: clean-Src

