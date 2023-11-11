#!/bin/bash

# Collect system information using various commands

# Get kernel and system information
arc=$(uname -a)

# Count the number of physical CPUs
pcpu_count=$(grep "physical id" /proc/cpuinfo | sort | uniq | wc -l)

# Count the total number of virtual CPUs
vcpu_count=$(grep "^processor" /proc/cpuinfo | wc -l)

# Get total system memory in megabytes
fram=$(free -m | awk '$1 == "Mem:" {print $2}')

# Get used system memory in megabytes
uram=$(free -m | awk '$1 == "Mem:" {print $3}')

# Calculate the percentage of used system memory
pram=$(free | awk '$1 == "Mem:" {printf("%.2f"), $3/$2*100}')

# Get the total disk space on all mounted partitions
adisk=$(df -Bg | grep '^/dev/' | grep -v '/boot$' | awk '{ft += $2} END {print ft}')

# Get the used disk space on all mounted partitions
udisk=$(df -Bm | grep '^/dev/' | grep -v '/boot$' | awk '{ut += $3} END {print ut}')

# Calculate the percentage of used disk space
pdisk=$(df -Bm | grep '^/dev/' | grep -v '/boot$' | awk '{ut += $3} {ft+= $2} END {printf("%d"), ut/ft*100}')

# Get the CPU usage percentage
cpul=$(top -bn1 | grep '^%Cpu' | cut -c 9- | xargs | awk '{printf("%.1f%%"), $1 + $3}')

# Get the system boot time
lb=$(who -b | awk '$1 == "system" {print $3 " " $4}')

# Count the number of logical volume management (LVM) devices
lvmt=$(lsblk | grep "lvm" | wc -l)

# Determine if LVM is in use on the system
lvmu=$(if [ $lvmt -eq 0 ]; then echo no; else echo yes; fi)

# Count the number of established TCP connections
ctcp=$(cat /proc/net/sockstat{,6} | awk '$1 == "TCP:" {print $3}')

# Count the number of logged-in users
ulog=$(users | wc -w)

# Get the IP address of the system
ip=$(hostname -I)

# Get the MAC address of the network interface
mac=$(ip link show | awk '$1 == "link/ether" {print $2}')

# Count the number of sudo commands executed (requires sudo privileges)
cmds=$(journalctl _COMM=sudo | grep COMMAND | wc -l)

# Broadcast our system information on all terminals
wall "	#Architecture: $arc
	#CPU physical: $pcpu_count
	#vCPU: $vcpu_count
	#Memory Usage: $uram/${fram}MB ($pram%)
	#Disk Usage: $udisk/${adisk}Gb ($pdisk%)
	#CPU load: $cpul
	#Last boot: $lb
	#LVM use: $lvmu
	#Connexions TCP: $ctcp ESTABLISHED
	#User log: $ulog
	#Network: IP $ip ($mac)
	#Sudo: $cmds cmd"
