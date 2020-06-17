#!/bin/bash

num_nodes=$(kubectl get Node --no-headers | wc -l)
if (( num_nodes < 40 )); then
	scrapat='.*'
elif (( num_nodes < 400 )); then
	scrapat='etcd|api|ctrl|data|base|lbpip|comp[0-9]*0$'
else
	scrapat='etcd|api|ctrl|data|base|lbpip|comp[0-9]*[147]0$'
fi
kubectl get node --no-headers -o custom-columns=Name:.metadata.name | while read nodename; do
	if egrep "$scrapat" <<<"$nodename" > /dev/null; then
		kubectl annotate --overwrite Node $nodename prometheus.io/scrape=true
	fi
	if false; then
		:
	elif egrep 'ketcd[0-9]$' <<<"$nodename" > /dev/null; then
		kubectl annotate --overwrite Node $nodename prometheus.io/scrape-etcd=true
		kubectl label --overwrite Node $nodename kos-role/ketcd=true
	elif egrep 'kapi[0-9]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/kapi=true
	elif egrep 'kctrl[0-9]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/kctrl=true

	elif egrep 'netcd[0-9]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/netcd=true
	elif egrep 'napi[0-9]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/napi=true
	elif egrep 'nctrl[0-9]$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/nctrl=true kos-role/netcd-op=true

	elif egrep 'comp[0-9]+$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/comp=true
	elif egrep 'data[0-9]+$' <<<"$nodename" > /dev/null; then
		kubectl label --overwrite Node $nodename kos-role/data=true
	else
		:
	fi
done
