PREFIX = /usr/local
SBIN   = $(PREFIX)/sbin
SYSTEM = $(PREFIX)/lib/systemd/system
MAN    = $(PREFIX)/share/man

UNITS = systemd/corridor-data.service \
        systemd/corridor-init-forwarding.service \
        systemd/corridor-init-logged.service \
        systemd/corridor-init-snat.service \
        systemd/corridor.target

systemd-units: $(UNITS)

%.service: %.service.in
	sed 's:SBIN/:$(SBIN)/:' $< >$@

%.8: %.8.ronn
	ronn -r $<

install: man/corridor.8
	install -d $(DESTDIR)$(SBIN) $(DESTDIR)$(MAN)/man8 $(DESTDIR)/etc/corridor.d $(DESTDIR)/var/lib/corridor
	install sbin/* $(DESTDIR)$(SBIN)
	install -m 644 man/corridor.8 $(DESTDIR)$(MAN)/man8
	for f in sbin/*; do ln -sf corridor.8 $(DESTDIR)$(MAN)/man8/$${f##*/}.8; done
	install -m 644 corridor.d/* $(DESTDIR)/etc/corridor.d

install-systemd: systemd-units
	install -d $(DESTDIR)$(SYSTEM)
	install -m 644 $(UNITS) $(DESTDIR)$(SYSTEM)

install-qubes:
	install -d $(DESTDIR)/etc/corridor.d $(DESTDIR)$(SYSTEM)
	install -m 644 qubes/corridor.d/* $(DESTDIR)/etc/corridor.d
	umask 022 && cp -RP qubes/systemd/* $(DESTDIR)$(SYSTEM)

clean:
	rm -f systemd/*.service
