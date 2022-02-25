all:
	odin run main.odin -out=mandelbulb -o:speed -show-timings -keep-temp-files -extra-linker-flags:"/ENTRY:mainCRTStartup /SUBSYSTEM:WINDOWS"