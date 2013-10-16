Plasma/CS/PlasmaLoaderApp

Windows application for transmitting a file to the Plasma Microprocessor.
After transmission completes a terminal is opened to communicate with the
device.

Usage: PlasmaBootLoader [options...] [file]
Options:
         -b <baudRate>, default = 460800
         -c <comPort>,  default = COM10
         -l <logFile>
         -s    = silent mode
         -?    = print this information
         -Help = same as -?

Omitting the [file] parameter will open a console without sending anything.

Example: PlasmaBootLoader -b 115200 -c COM9 -l log.txt test.axf
