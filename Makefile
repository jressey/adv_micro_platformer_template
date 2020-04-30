# Pico-8 Project Makefile

LUASOURCE=source.lua
OUTPUT=output.p8
GFXSFX=gfxsfx.p8
PARSEOPTIONS=

output: parse.py head $(LUASOURCE) $(GFXSFX)
	cat head >$(OUTPUT)
	./parse.py $(LUASOURCE) $(PARSEOPTIONS) >>$(OUTPUT)
	cat $(GFXSFX) | awk '/__gfx__/ {seen= 1 } seen {print}' >>$(OUTPUT)

clean:
	$(RM) $(OUTPUT)
