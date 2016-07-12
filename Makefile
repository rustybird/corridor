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

install: systemd-units man/corridor.8
	install -d $(DESTDIR)$(SBIN) $(DESTDIR)$(MAN)/man8 $(DESTDIR)/etc/corridor.d $(DESTDIR)/var/lib/corridor
	install corridor-* $(DESTDIR)$(SBIN)
	install -m 644 man/corridor.8 $(DESTDIR)$(MAN)/man8
	for f in corridor-*; do ln -sf corridor.8 $(DESTDIR)$(MAN)/man8/$$f.8; done
	install -m 644 corridor.d/* $(DESTDIR)/etc/corridor.d
	if pkg-config systemd; then install -d $(DESTDIR)$(SYSTEM) && install -m 644 $(UNITS) $(DESTDIR)$(SYSTEM); fi

clean:
	rm -f systemd/*.service
