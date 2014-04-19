PREFIX = /usr/local
SBIN   = $(DESTDIR)$(PREFIX)/sbin

corridor:

install:
	install -d $(SBIN)
	install corridor-* $(SBIN)
