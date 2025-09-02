##install frr
```bash
vim /etc/frr/frr.conf
# default to using syslog. /etc/rsyslog.d/45-frr.conf places the log
# in /var/log/frr/frr.log
log syslog informational
!
! FRR v7 BGP configuration for server 192.168.20.212
! Peers: Calico nodes 192.168.20.153 & 192.168.20.154
!

! Enable BGP
router bgp 64512
 bgp router-id 192.168.20.212

 ! Define Calico node peers
 neighbor 192.168.20.153 remote-as 64512
 neighbor 192.168.20.152 remote-as 64512

 ! IPv4 unicast address family
 address-family ipv4 unicast
 exit-address-family
!
```
## makesure those parameter stated yes

```bash
vim /etc/frr/daemons
zebra=yes
bgpd=yes
vtysh_enable=yes
```
## enable and restart frr
```bash
systemctl enable frr
systemctl restart frr
```
## now enable the connectivity from firewall (optional)
```bash
sudo ufw allow from 192.168.20.153 to any port 179
sudo ufw allow from 192.168.20.152 to any port 179
```
## Check the connectivity and ping any pod
```bash
vtysh -c "show ip bgp summary"
Output

IPv4 Unicast Summary:
BGP router identifier 192.168.20.212, local AS number 64512 vrf-id 0
BGP table version 2
RIB entries 3, using 552 bytes of memory
Peers 2, using 41 KiB of memory

Neighbor        V         AS MsgRcvd MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd
192.168.20.152  4      64512      36      31        0    0    0 00:28:15            1
192.168.20.153  4      64512      35      31        0    0    0 00:28:15            1

Total number of neighbors 2

ping any pod
root@build-server2:~# ping 10.224.126.13
PING 10.224.126.13 (10.224.126.13) 56(84) bytes of data.
64 bytes from 10.224.126.13: icmp_seq=1 ttl=63 time=0.780 ms
64 bytes from 10.224.126.13: icmp_seq=2 ttl=63 time=0.657 ms
64 bytes from 10.224.126.13: icmp_seq=3 ttl=63 time=0.623 ms
^C
--- 10.224.126.13 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2055ms
rtt min/avg/max/mdev = 0.623/0.686/0.780/0.067 ms

```
