PREFIX = /usr/local
SBIN   = $(PREFIX)/sbin

corridor:

install:
	install -d $(DESTDIR)$(SBIN)
	install corridor-* $(DESTDIR)$(SBIN)
