# set this to point to your eCos "install" directory:

export PATH += :/opt/ecos/gnutools/i386-elf/bin

PWD  = $(shell pwd)
ECOS = $(realpath build-ecos/install)

$(info using ECOS installation at "$(ECOS)")

# get commands and options used to build stuff
-include $(ECOS)/include/pkgconf/ecos.mak

export XAR           = $(ECOS_COMMAND_PREFIX)ar
export XRANLIB       = $(ECOS_COMMAND_PREFIX)ranlib
export XSTRIP        = $(ECOS_COMMAND_PREFIX)strip
export XCC           = $(ECOS_COMMAND_PREFIX)gcc
export XLD           = $(ECOS_COMMAND_PREFIX)ld
export DEFINES       = -D__ECOS
export INCLUDES      =  -I$(ECOS)/include
export CXXFLAGS      = $(filter-out -fvtable-gc, $(ECOS_GLOBAL_CFLAGS)) -Werror
export CXXFLAGS      = $(filter-out -fvtable-gc, $(ECOS_GLOBAL_CFLAGS)) -Werror 
export CFLAGS        = $(filter-out -fno-rtti, $(CXXFLAGS)) -Wall
export LDFLAGS       = $(ECOS_GLOBAL_LDFLAGS)
export LIBS          = -L$(ECOS)/lib -Ttarget.ld -nostdlib
export XCXX          = $(XCC)

INCLUDES += -I$(PWD)

%.hex: %
	$(XOBJCOPY) -O ihex $< $@

%.srec: %.hex
	$(XOBJCOPY) -I ihex -O srec $< $@

%.bin: %
	$(XOBJCOPY) -O binary $< $@

%.o: %.c
	$(XCC) -c -o $@ $(CFLAGS) $(DEFINES) $(INCLUDES) $<

%.o: %.cxx
	$(XCXX) -c -o $@ $(CXXFLAGS) $(DEFINES) $(INCLUDES) $<

%.o: %.S
	$(XCC) -c -o $@ $(CFLAGS) $(DEFINES) $(INCLUDES) $<

%.o: %.s
	$(XCC) $(CFLAGS))  -o $@ $<

all: hello.elf server.elf

server.elf: server.o $(ECOS)/lib/target.ld $(ECOS)/lib/libtarget.a
	$(XCC) -Wl,-Map,$@.map $(LDFLAGS) -o $@ server.o $(LIBS)

hello.elf: hello.o $(ECOS)/lib/target.ld $(ECOS)/lib/libtarget.a
	$(XCC) -Wl,-Map,$@.map $(LDFLAGS) -o $@ hello.o $(LIBS)

qemu-%: %.elf
	$(MAKE) && ./runit.sh $<

clean:
	rm -f *.o *.elf *.map *~

cleanall:
	make clean
	rm -rf build-redboot build-ecos

index.html: Readme.txt
	asciidoc -a data-uri -a toc -a max-width=42em  -o index.html Readme.txt
