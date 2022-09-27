#!/bin/bash

resource_group=$(terraform output -raw openshift_resource_group)
vnet_name=$(terraform output -raw openshift_vnet_name)
worker_subnet=$(terraform output -raw openshift_worker_subnet)
master_subnet=$(terraform output -raw openshift_master_subnet)
route_table=$(terraform output -raw ha_route_table_id)

option="create"
while getopts o: flag
do
    case "${flag}" in
        o) option=${OPTARG};;
    esac
done

if [ "$option" = "delete" ] ; then
  echo "Removing Configuration"
  az network vnet subnet update -n $master_subnet --vnet-name $vnet_name -g $resource_group --remove routeTable
  az network vnet subnet update -n $worker_subnet --vnet-name $vnet_name -g $resource_group --remove routeTable
  echo "Configuration Removed"
else
  echo "Doing Configuration"
  az network vnet subnet update -n $master_subnet --vnet-name $vnet_name -g $resource_group --route-table $route_table
  az network vnet subnet update -n $worker_subnet --vnet-name $vnet_name -g $resource_group --route-table $route_table
  workers_name=$(az network nic list -g $resource_group --query "[?contains(name,'worker')].name")
  for i in $workers_name; do
    if [[ $i =~ "worker" ]]; then
      i=`echo $i | tr -d "\""`
      i=`echo $i | tr -d "\,"`
      az network nic update -n $i -g $resource_group --ip-forwarding true
    fi
  done
  echo "Configuration Done"
fi
