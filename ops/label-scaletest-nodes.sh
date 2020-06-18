#!/bin/bash
#Like label-nodes but aimed at the "scaletest" deployment pattern

num_nodes=$(kubectl get Node --no-headers | wc -l)
if (( num_nodes < 40 )); then
	scrapat='.*'
elif (( num_nodes < 400 )); then
	scrapat='etcd|api|ctrl|mgmt|data|base|lbpip|comp[0-9]*0$'
else
	scrapat='etcd|api|ctrl|mgmt|data|base|lbpip|comp[0-9]*[147]0$'
fi
kubectl get node --no-headers -o custom-columns=Name:.metadata.name | while read nodename; do
	if egrep "$scrapat" <<<"$nodename" > /dev/null; then
		kubectl annotate --overwrite Node $nodename prometheus.io/scrape=true
	fi
	if false; then
		:
	elif egrep 'ctrl[0-9]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/kctrl=true
		kubectl label --overwrite Node $nodename kos-role/kapi=true
		kubectl annotate --overwrite Node $nodename prometheus.io/scrape-etcd=true
		kubectl label --overwrite Node $nodename kos-role/ketcd=true

	elif egrep 'mgmt[0-9]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/data=true
		kubectl label --overwrite Node $nodename kos-role/netcd=true
		kubectl label --overwrite Node $nodename kos-role/napi=true
		kubectl label --overwrite Node $nodename kos-role/nctrl=true kos-role/netcd-op=true

	elif egrep 'comp[0-9]+$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/comp=true

	else
		:
	fi
done
