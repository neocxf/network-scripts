PREFIX=/usr
BINDIR=$(PREFIX)/bin

CC=gcc
INSTALL=ginstall

all:	simpletun
distclean:	clean

clean:
	rm simpletun


install: all
	$(INSTALL) -D simpletun $(DESTDIR)$(BINDIR)/simpletun

simpletun:
	$(CC) simpletun.c -o simpletun
