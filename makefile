all:
	odin run main.odin -out=mandelbrot -o:speed -show-timings -keep-temp-files -extra-linker-flags:"/ENTRY:mainCRTStartup /SUBSYSTEM:WINDOWS"