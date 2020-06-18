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
	elif egrep 'ctrl[0-9]$' <<<"$nodename" > /dev/null; then
		echo -n " kos_role_kctrl=yes"
		echo -n " kos_role_ketcd=yes"
		echo -n " kos_role_kapi=yes"
		echo -n " kos_role_data=yes"
		echo
	elif egrep 'comp[0-9]+$' <<<"$nodename" > /dev/null; then
		echo -n " kos_role_comp=yes"
		echo -n " kos_role_netcd=yes"
		echo -n " kos_role_napi=yes"
		echo -n " kos_role_nctrl=yes kos_role_netcd-op=yes"
		echo
	else
		echo
	fi
done >> "/etc/ansible/hosts/${1}_L1"
