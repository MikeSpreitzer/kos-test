#!/bin/bash

if (( $# != 1 )); then
	echo Usage: $0 clustername >&2
	exit 1
fi

echo "[${1}_L1]" > "/etc/ansible/hosts/${1}_L1"
kubectl get Node -o $'jsonpath={range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address} {.metadata.name}\n{end}' | while read ip nodename rest; do
	echo -n "$ip" "nodename=$nodename"
	if false; then
		:
	elif egrep 'kapi[0-9]$' <<<"$nodename" > /dev/null; then
		echo " kos_role_ketcd=yes"
		echo " kos_role_kapi=yes"
	elif egrep 'kctrl[0-9]$' <<<"$nodename" > /dev/null; then
		echo " kos_role_kctrl=yes"

	elif egrep 'netcd[0-9]$' <<<"$nodename" > /dev/null; then
		echo " kos_role_netcd=yes"
	elif egrep 'napi[0-9]$' <<<"$nodename" > /dev/null; then
		echo " kos_role_napi=yes"
	elif egrep 'nctrl[0-9]$' <<<"$nodename" > /dev/null; then
		echo " kos_role_nctrl=yes kos_role_netcd-op=yes"

	elif egrep 'comp[0-9]+$' <<<"$nodename" > /dev/null; then
		echo " kos_role_comp=yes"
	elif egrep 'data[0-9]+$' <<<"$nodename" > /dev/null; then
		echo " kos_role_data=yes"
	else
		echo
	fi
done >> "/etc/ansible/hosts/${1}_L1"
