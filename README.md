**This is a very early release. HERE BE DRAGONS! Not affiliated with the Tor Project.**

# corridor, a Tor traffic whitelisting gateway

There are several transparently torifying gateways. They suffer from the same problems:

- It's tricky to isolate circuits and issue NEWNYM signals, especially if multiple client computers are involved.
- Any garbage software can pump identifiers into "anonymous" circuits, and get itself exploited by malicious exit nodes.
- Trust is centralized to the gateway, which is bad enough when used by one person, and just inappropriate when shared with strangers.

**corridor takes a different approach. It allows only connections to Tor relays to pass through (no clearnet leaks!), but client computers are themselves responsible for torifying their own traffic.** In other words, it is a filtering gateway, not a proxying gateway.

You can think of it as defense in depth for your vanilla TBB or Tails, for your beautiful scary experimental Qubes proxying schemes, etc. Or invite the hood to use your WiFi without getting into trouble. Connections *between* client computers are blocked by default.


## Principle of operation

1. Either run the corridor-data-consensus daemon script, which opens a Tor control connection and subscribes to NEWCONSENSUS events (announcements listing all public relays), or pipe any number of "Bridge" lines into corridor-data-bridges.
2. That data is used to atomically update a Linux ipset (a list of IP-address:TCP-port entries accessible in constant time) named corridor_relays containing all *acceptable* relays along with their ORPort. When using corridor-data-consensus, acceptable means the relays have a Valid flag and a Guard or Authority flag. When using corridor-data-bridges, acceptable refers to your bridge relays.
3. iptables rules refuse to forward packets unless they are going to / coming from one of the relays inside the ipset.


## Pitfalls

- **To be secure, corridor needs two separate network interfaces**, like two Ethernet NICs, or one WiFi radio and one DSL modem. One is to receive incoming traffic from client computers, the other one is to pass the filtered traffic towards the global internet, **and they need to be on different network address spaces**: Clients must not be able to take a shortcut via DHCP, DNS, ICMP Redirect requests, and who knows what else.

- corridor cannot prevent **malware** on a client computer from **directly contacting a colluding relay to find out your clearnet IP address**. The part of your client system that can open outside TCP connections must be in a trustworthy state! (Whonix and Qubes-TorVM are well-designed in this respect.) Discussion:
	- https://lists.torproject.org/pipermail/tor-talk/2014-February/032153.html
	- https://lists.torproject.org/pipermail/tor-talk/2014-February/032163.html

- The optional **logging of prevented leaks has several limitations**:
	- Consider the role of DNS:
		- If leaky client software tries connecting to a server by its IP address, you see that in the log.
		- If it tries resolving a hostname through a hardcoded DNS server, you see a *failed connection to that DNS server* in the log.
		- If it tries resolving a hostname but the client system does not know any DNS server, *there is no connection* that could be logged.
	- Clients can spoof their source IP address.
	- The kernel shows MAC addresses in the log lines, maybe you don't want that.

## Example usage

```
export PATH="$PATH:/path/to/corridor"

# Set up the iptables CORRIDOR chain.
corridor-init-filter

# Enable IPv4 forwarding, disable IPv6 forwarding.
corridor-init-forward

# Set up Source NAT with iptables.
# If a line has a second argument, SNAT --to-source.
# Otherwise, MASQUERADE.
corridor-init-snat <<-END
	10.0.0.0/8 192.168.1.254
END

# Start the daemon that keeps track of public Tor relays.
TOR_CONTROL_COOKIE_AUTH_FILE=/var/run/tor/control.authcookie \
corridor-data-consensus &

# Or use bridges instead.
corridor-data-bridges <<-END
	Bridge [transport] IP:ORPort [fingerprint]
	...
END

# Log attempted leaks from these clients. (Syntax: ipset(8) hash:net)
# This command will block until corridor_relays gets populated!
corridor-init-logged <<-END
	10.1.0.1-10.1.0.9
	10.2.0.0/16
	10.2.0.5 nomatch
END
```


## How does corridor-data-consensus open a Tor control connection?

If $TOR_CONTROL_SOCKET is nonempty (e.g. /var/run/tor/control), use it.
Otherwise, connect to $TOR_CONTROL_HOST (defaults to localhost) on port $TOR_CONTROL_PORT (defaults to 9051).

If $TOR_CONTROL_COOKIE_AUTH_FILE is nonempty (e.g. /var/run/tor/control.authcookie), use it.
Otherwise, pass $TOR_CONTROL_PASSWD (defaults to an empty password).


## Dependencies so far

- ipset, iptables, sysctl
- socat (to open control connections)
- sh, grep, sed, sleep, test, echo
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
- Build a WiFi/Ethernet portal that allows access to torproject.org so people can download TBB:
	- Configure hostapd
	- Configure a DHCP server
	- DNS recurser restricted to torproject.org (maybe also tails.boum.org, guardianproject.info, f-droid.org)
	- Transparently proxy requests to only their IPs:443 through Tor
	- MITM redirect (all?) requests to port 80 to (an info page linking to?) https://torproject.org
- Bundle it all up (docker?) for Raspberry Pi / BeagleBone Black


## Redistribution

corridor is in the public domain.
