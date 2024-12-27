This project archive contains the code and a pre-compiled build (Project.elf) for the G49 MoT system. Additionally a Maintainers Manual and a User Manual is attached to ease the transition into using the system, both developer- and user wise. For a demonstration of the system, look into the testscript.txt. The file 04testterm115200.c in the folder 'Utility' can be compiled and used to run the testscript.txt if operating on Windows.

To generate command strings, the utility software hex2MoT01.c should be compiled and used - a MacOS build is already contained in the 'Utility' folder; h2m.

h2m, how to:
Run the software via terminal with any necessary arguments. See the method described in either the Maintainers Manual or the Users Manual. Example for MacOS: ./h2m 03 00, this generates a command string for Device 3, command 0.

MIT License

Copyright (c) 2017 Marco Paland

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.