**This is an early release. HERE BE DRAGONS? Not affiliated with the Tor Project.**

# corridor, a Tor traffic whitelisting gateway

There are several transparently torifying gateways. They suffer from the same problems:

- It's tricky to isolate circuits and issue NEWNYM signals, especially if multiple client computers are involved.
- Any garbage software can pump identifiers into "anonymous" circuits, and get itself exploited by malicious exit nodes.
- Trust is centralized to the gateway, which is bad enough when used by one person, and just inappropriate when shared with strangers.

**corridor takes a different approach. It allows only connections to Tor relays to pass through (no clearnet leaks!), but client computers are themselves responsible for torifying their own traffic.** In other words, it is a filtering gateway, not a proxying gateway.

You can think of it as a fail-safe for your vanilla Tor Browser or Tails, for your beautiful scary experimental Qubes proxying schemes, etc. Or invite the hood to use your WiFi without getting into trouble.


## Principle of operation

1. The corridor-data script opens a Tor control connection and subscribes to NEWCONSENSUS events (announcements listing all public relays), unless you inform it of any bridges to use instead.
2. That data is used to atomically update a Linux ipset (a list of IP-address:TCP-port entries accessible in constant time) named corridor_relays containing either all your bridges or all *acceptable* relays along with their ORPort. Acceptable means the relays have a Valid flag and a Guard or Authority flag.
3. iptables rules refuse to forward packets unless they are going to / coming from one of the relays inside the ipset.


## Pitfalls

- **To be safe, corridor needs two separate network interfaces**, like two Ethernet NICs, or one WiFi radio and one DSL modem. One is to receive incoming traffic from client computers, the other one is to pass the filtered traffic towards the global internet, **and they need to be on different network address spaces**: Clients must not be able to take a shortcut via DHCP, DNS, ICMP Redirect requests, and who knows what else.

- corridor cannot prevent **malware** on a client computer from **finding out your clearnet IP address**, e.g. by sending the `GETINFO address` command to any Tor control port on the network (incl. the one on the client computer itself). **corridor is not a replacement for using a well-designed operating system on your client computers**, like Qubes with TorVM/Whonix.

- The optional **logging of prevented leaks has several limitations**:
	- Consider the role of DNS:
		- If leaky client software tries connecting to a server by its IP address, you see that in the log.
		- If it tries resolving a hostname through a hardcoded DNS server, you see a *failed connection to that DNS server* in the log.
		- If it tries resolving a hostname but the client system does not know any DNS server, *there is no connection* that could be logged.
	- Clients can spoof their source IP address.
	- The kernel shows MAC addresses in the log lines, maybe you don't want that.


## Installation

```
# Install to the default location /usr/local/sbin.
make install

# Edit the configuration.
$EDITOR /etc/corridor.d/*
```


## Usage

```
# Set up IP traffic forwarding.
corridor-init-forwarding

# Set up Source NAT with iptables.
corridor-init-snat

# Keep track of acceptable Tor relays.
corridor-data &

# Log attempted leaks from selected clients.
# This command will block until corridor_relays gets populated!
corridor-init-logged
```


## systemd

```
# If you use something other than systemd-networkd to bring up your
# network interfaces (make sure that whatever it is correctly orders
# itself after network-pre.target!), you must add a dependency:
mkdir /etc/systemd/some.service.d
cat  >/etc/systemd/some.service.d/corridor.conf <<-END
	[Unit]
	Require=corridor-init-forwarding.service
END

# Start corridor
systemctl start corridor.target

# Start corridor when booting
systemctl enable corridor.target
```


## torrc

You may want to add the line

```
DirPort 127.0.0.1:9030
```

to /etc/tor/torrc to always keep the relay list up to date, even when there's no local activity and tor would otherwise suspend itself.


## How does corridor-data open a Tor control connection?

If $TOR_CONTROL_SOCKET is nonempty (e.g. /var/run/tor/control), use it.
Otherwise, connect to $TOR_CONTROL_HOST (defaults to localhost) on port $TOR_CONTROL_PORT (defaults to 9051).

If $TOR_CONTROL_COOKIE_AUTH_FILE is nonempty (e.g. /var/run/tor/control.authcookie), use it.
Otherwise, pass $TOR_CONTROL_PASSWD (defaults to an empty password).


## Dependencies so far

- ipset, iptables, sysctl
- socat (to open control connections)
- sh, make, grep, sed, sleep, sort, test, echo
- perl (to convert control cookies to hex, easily replacable)
- Linux kernel:
	- CONFIG_IP_SET_HASH_IPPORT
	- CONFIG_IP_SET_HASH_NET
	- CONFIG_IP_NF_TARGET_MASQUERADE
	- CONFIG_IP_NF_TARGET_REJECT
	- CONFIG_NETFILTER_XT_TARGET_LOG
	- CONFIG_NF_CONNTRACK_IPV4


## Todo

- Allow IPv6 connections to Tor relays instead of blocking all IPv6 traffic
- Build a WiFi/Ethernet portal that allows people to download Tor Browser:
	- Configure hostapd as an open AP
	- Configure dnsmasq
		- as a DHCP server
		- as a DNS proxy restricted to
			- torproject.org
			- maybe also guardianproject.info
			- maybe also tails.boum.org if they start to offer https for their ISOs
	- Transparently torify connections to only those domains' IP addresses on port 443
	- Configure publicfile to serve an info page linking to https://www.torproject.org
	- MITM all requests to port 80 into a HTTP 302 redirect to that info page
- Bundle it all up (docker?) for Raspberry Pi / BeagleBone Black


## Redistribution

corridor is ISC licensed, see the LICENSE file for details.

## Version

Git master is supposed to stay usable and permanent, with experimental stuff going into other branches.

Version number equal ISO 8601 timestamps. To find out what the latest version number of the master branch is you could run the following command.

```
git show --no-patch --pretty=format:%ai master | tr -dc 0-9 | cut -b 1-14
```
