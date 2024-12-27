'testterm.exe' is a custom serial terminal for playing test scripts of MoT commands. 
Your scripts are an important part of testing code you've written to demonstrate the functions your project implements.

The format of a test script is very simple:
	- comment-lines are used to describe what the command that follows will do. Comment lines must start with '#' in the first column;
	- commands to be sent to MoT must start in the first column with ':' and are should be the only entry on the line.
	(see testscript_demo.txt)

Starting testterm.exe requires that you know the COM port where the Nucleo board is connected, you have a test script, the board is connected, your project is connected and running, and that no other programs except the Eclipse debugger are using the serial port. 
See the example of a testerm console history below.

=======================================
====== example console history ========
=======================================

D:\_umd\2024-01-01\ENEE440_S24\_homework\HW05\BlinkyMoT_ws1\PC_code>testterm COM5 test_devices1-3.txt
Starting testterm.exe
See '_readme_testterm.txt' and 'test_script_demo.txt' for more info
Attempting connection to target on \\.\COM5; testing with test_devices1-3.txt
serial port \\.\COM5 is ready
serial parameter settings successful
       Baudrate = 115200
       ByteSize = 8
       StopBits = 0
       Parity   = 0
Serial timeout settings successful

Script information messages starting with '#'  will display one line at a time
Hit 'Enter' to advance to each next message or command operation
IMPORTANT: in order to avoid disrupting operation of testterm you must wait for a
'bytes received' message before proceeding with the next step in the script.

Beginning test script 'test_devices1-3.txt'
# testscript_demo.txt wmh 2024-02-26 : demo for sending commands to MoT devices. Hit 'Enter' to advance through the instructions
#       Comment lines in the script are printed to the system console but ignored by the program.
#       Lines that aren't comments are sent as strings to the serial port when the user hits 'Enter'.
#   Demonstrations of some commands follow:
#
# device1, the 'green LED' command demonstration
# Command ':0100FF' initializes the green LED device. Hit 'Enter' to send the command
        8 bytes sent.
        txmsg= :0100FF

        25 bytes received.
        rxmsg= userLED is initialized

#":0101FE" turns it on. Hit 'Enter' to send the command
        8 bytes sent.
        txmsg= :0101FE

        18 bytes received.
        rxmsg= userLED is 'ON'

#":0104FB" reports its state. Hit 'Enter' to send the command
        8 bytes sent.
        txmsg= :0104FB

        18 bytes received.
        rxmsg= userLED is 'ON'

#":0102FD" turns it off. Hit 'Enter' to send the command
        8 bytes sent.
        txmsg= :0102FD

        19 bytes received.
        rxmsg= userLED is 'OFF'

#":0103FFFF0000FE" starts a blinking task. Hit 'Enter' to send the command
        16 bytes sent.
        txmsg= :0103FFFF0000FE

        22 bytes received.
        rxmsg= userLED is BLINKING

#":0104FB" reports its instantaneous state. Hit 'Enter' to send the command
        8 bytes sent.
        txmsg= :0104FB

        19 bytes received.
        rxmsg= userLED is 'OFF'

#":0105FA" installs 'skip' task and ends blinking. Hit 'Enter' to send the command
        8 bytes sent.
        txmsg= :0105FA

        0 bytes received.
        rxmsg=
# device1 demo is done.
#
# device2, the 'blue Button' inter-device command demo
#":0200FE" initializes PC13 for input from blue Button
        8 bytes sent.
        txmsg= :0200FE

        28 bytes received.
        rxmsg= blueBUTTON is initialized

#":0201FD" sends a command to device1 to turn green LED 'ON'
        8 bytes sent.
        txmsg= :0201FD

        37 bytes received.
        rxmsg= userLED is 'ON'
 userLED is 'OFF'

#":0202FC" sends a command to device1 to turn green LED 'OFF'
        8 bytes sent.
        txmsg= :0202FC

        37 bytes received.
        rxmsg= userLED is 'OFF'
 userLED is 'ON'

#":0203FB" starts a task which monitors blue Button and send commands to device1 to turns green LED 'On' 'OFF'
        8 bytes sent.
        txmsg= :0203FB

        26 bytes received.
        rxmsg= blueBUTTON is monitored

#":0204FA" stops the blue Button monitor task
        8 bytes sent.
        txmsg= :0204FA

        211 bytes received.
        rxmsg= userLED is 'ON'
 userLED is 'OFF'
 u│)♫¬◄üis 'ON'
 userLED is 'OFF'
 userLED is 'ON'
 userLED is 'OFF'
 userLED is 'ON'
 userLED is 'OFF'
 u│)▲*◄üis 'ON'
 userLED is 'OFF'
 blueBUTTON is initialized

# device2 demo is done.
#
# device3 demo, a test of sending inter-device commands
#":03000DF0000000" starts a task which oscillates every 0x0000F00D task cycles and sends an ON or OFF command to device1
        16 bytes sent.
        txmsg= :03000DF0000000

        276 bytes received.
        rxmsg= u│)♫¬◄üis 'ON'
 userLED is 'OFF'
 u│)♫*◄üis 'ON'
 userLED is 'OFF'
 u│)▲¬◄üis 'ON'
 userLED is 'OFF'
 ╡╗)♫¬◄üis 'ON'
 userLED is 'OFF'
 userLED is 'ON'
 userLED is 'OFF'
 userLED is 'ON'
 userLED is 'OFF'
 ╡╗)♫¬◄üis 'ON'
 userLED is 'OFF'
 device3 has started

#":0301FC" pauses device3 commands being sent to device1
        8 bytes sent.
        txmsg= :0301FC

        600 bytes received.
        rxmsg= device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCL
#":0302FB" resumes device3 commands to device1
        8 bytes sent.
        txmsg= :0302FB

        600 bytes received.
        rxmsg= ES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is
#":0303FA" is a nop which is ignored (better demo would be to change frequency of oscillation)
        8 bytes sent.
        txmsg= :0303FA

        600 bytes received.
        rxmsg= odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3 has paused
 device3 has resumed
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is '
#":0301FC" again pauses device3 so no more commands will be sent to device1
        8 bytes sent.
        txmsg= :0301FC

        600 bytes received.
        rxmsg= OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 devic
# device3 demo is done
#
# device4, device5, and device6 are empty stubs for homework assignments
# Each command will display a 'not implemented' message.
#":0400FC" runs device 4
        8 bytes sent.
        txmsg= :0400FC

        456 bytes received.
        rxmsg= e3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3_CYCLES count is even
 userLED is 'OFF'
 device3_CYCLES count is odd
 userLED is 'ON'
 device3 has paused

#":0500FB" runs device 5
        8 bytes sent.
        txmsg= :0500FB

        0 bytes received.
        rxmsg=
#":0600FA" runs device 6
        8 bytes sent.
        txmsg= :0600FA

        0 bytes received.
        rxmsg=
# device4, device5, and device6 stubs are done
#
# Testing is ended -- there are no more commands to demonstrate. Hit 'Enter' to quit
# Note : any blank lines in the test script _after_ this point will be interpreted as commands
#       and testterm will send a sequence of messages "0 bytes received." at 10 second intervals,
#       one for each blank line

D:\_umd\2024-01-01\ENEE440_S24\_homework\HW05\BlinkyMoT_ws1\PC_code>
D:\_umd\2024-01-01\ENEE440_S24\_homework\HW05\BlinkyMoT_ws1\PC_code>
D:\_umd\2024-01-01\ENEE440_S24\_homework\HW05\BlinkyMoT_ws1\PC_code>
D:\_umd\2024-01-01\ENEE440_S24\_homework\HW05\BlinkyMoT_ws1\PC_code>
D:\_umd\2024-01-01\ENEE440_S24\_homework\HW05\BlinkyMoT_ws1\PC_code>
D:\_umd\2024-01-01\ENEE440_S24\_homework\HW05\BlinkyMoT_ws1\PC_code>
D:\_umd\2024-01-01\ENEE440_S24\_homework\HW05\BlinkyMoT_ws1\PC_code>