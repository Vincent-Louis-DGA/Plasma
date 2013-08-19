Plasma/CS/PlasmaLoaderApp

Use this windows application to load programs in to the Plasma microprocessor using the PlasmaBootLoader.

See Plasma/C/PlasmaBootLoader for more information no the boot loader.

Usage: PlasmaBootLoader [options] <sourceFile>

Options: -b <baudRate>\n\t -c <comPort>\n\t -o <bootOffset>

Example: PlasmaBootLoader -b 460800 -c COM10 -o 0x40000000 -l log.dat "..\..\..\..\C\Example\Example.bin"