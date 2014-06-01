PREFIX = /usr/local
SBIN   = $(PREFIX)/sbin

corridor:

install:
	install -d $(DESTDIR)$(SBIN) $(DESTDIR)/etc/corridor.d
	install corridor-* $(DESTDIR)$(SBIN)
	install -m 644 corridor.d/* $(DESTDIR)/etc/corridor.d
