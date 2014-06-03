PREFIX = /usr/local
SBIN   = $(PREFIX)/sbin
SYSTEM = $(PREFIX)/lib/systemd/system

UNITS = systemd/corridor-data.service \
        systemd/corridor-init-forwarding.service \
        systemd/corridor-init-logged.service \
        systemd/corridor-init-snat.service \
        systemd/corridor.target

systemd-units: $(UNITS)

%.service: %.service.in
	sed 's:SBIN/:$(SBIN)/:' $< >$@

install: systemd-units
	install -d $(DESTDIR)$(SBIN) $(DESTDIR)/etc/corridor.d
	install corridor-* $(DESTDIR)$(SBIN)
	install -m 644 corridor.d/* $(DESTDIR)/etc/corridor.d
	if pkg-config systemd; then install -d $(DESTDIR)$(SYSTEM) && install -m 644 $(UNITS) $(DESTDIR)$(SYSTEM); fi

clean:
	rm -f systemd/*.service
