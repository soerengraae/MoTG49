REM  make_libSystemClock_STM32G491.bat wmh 2024-08-128 : 
echo off

REM using GNU arm-none-eabi-gcc acquired with CubeIDE installation
REM adjust the following to where you put the compiler
set path=.\;D:\_software_installs\ST\STM32CubeIDE_1.16.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.12.3.rel1.win32_1.0.200.202406191623\tools\bin

pause

echo creating library of private functions libSystemClock_STM32G491.a
arm-none-eabi-ar rcs  libSystemClock_STM32G491.a SystemClock_init2.o SysTick_definitions.o

arm-none-eabi-strip --strip-debug libSystemClock_STM32G491.a
arm-none-eabi-objdump --syms libSystemClock_STM32G491.a >libSystemClock_STM32G491.symbols

pause
 
 
 
