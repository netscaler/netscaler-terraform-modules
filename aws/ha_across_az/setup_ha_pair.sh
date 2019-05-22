add_ha_node () {
# $1 Public NSIP
# $2 Password
# $3 other ha node private nsip

echo "Creating ha node $*"
curl \
--progress-bar \
-H "Content-Type: application/json" \
-H "X-NITRO-USER: nsroot" \
-H "X-NITRO-PASS: $2" \
-d "{\"hanode\": { \"id\": 1, \"ipaddress\": \"$3\", \"inc\": \"ENABLED\" }}" \
-k \
https://$1/nitro/v1/config/hanode
}

add_ipset () {
# $1 Public NSIP
# $2 Password
# $3 Ipset name

echo "add_ipset $*"
curl \
--progress-bar \
-H "Content-Type: application/json" \
-H "X-NITRO-USER: nsroot" \
-H "X-NITRO-PASS: $2" \
-d "{\"ipset\" : { \"name\": \"$3\" }}" \
-k \
https://$1/nitro/v1/config/ipset
}

bind_ipset_address () {
# $1 Public NSIP
# $2 Password
# $3 Ipset name
# $4 ip address

echo "bind_ipset_address $*"

curl \
--progress-bar \
-H "Content-Type: application/json" \
-H "X-NITRO-USER: nsroot" \
-H "X-NITRO-PASS: $2" \
-d "{\"ipset_nsip_binding\" : { \"name\": \"$3\", \"ipaddress\": \"$4\" }}" \
-k \
https://$1/nitro/v1/config/ipset_nsip_binding
}

add_vip () {
# $1 Public NSIP
# $2 Password
# $3 VIP
# $4 Netmask

echo "add_vip $*"

curl \
--progress-bar \
-H "Content-Type: application/json" \
-H "X-NITRO-USER: nsroot" \
-H "X-NITRO-PASS: $2" \
-d "{\"nsip\" : { \"ipaddress\": \"$3\", \"netmask\": \"$4\", \"type\": \"VIP\" }}" \
-k \
https://$1/nitro/v1/config/nsip
}

create_lbvserver (){
# $1 Public NSIP
# $2 Password
# $3 lb vserver name
# $4 lb vserver address
# $5 ipset name

echo "create_lbvserver $*"

curl \
--progress-bar \
-H "Content-Type: application/json" \
-H "X-NITRO-USER: nsroot" \
-H "X-NITRO-PASS: $2" \
-d "{\"lbvserver\" : { \"name\": \"$3\", \"ipv46\": \"$4\", \"port\": \"80\", \"servicetype\": \"HTTP\", \"ipset\": \"$5\" }}" \
-k \
https://$1/nitro/v1/config/lbvserver

}

add_route () {
# $1 Public NSIP
# $2 Password
# $3 Network
# $4 Netmask
# $5 Gateway

echo "add_route $*"

curl \
--progress-bar \
-H "Content-Type: application/json" \
-H "X-NITRO-USER: nsroot" \
-H "X-NITRO-PASS: $2" \
-d "{\"route\" : { \"network\": \"$3\", \"netmask\": \"$4\", \"gateway\": \"$5\" }}" \
-k \
https://$1/nitro/v1/config/route
}

save_config () {
# $1 Public NSIP
# $2 Password

echo "save_config $*"

curl \
--progress-bar \
-H "Content-Type: application/json" \
-H "X-NITRO-USER: nsroot" \
-H "X-NITRO-PASS: $2" \
-d "{\"nsconfig\":{}}" \
-k \
https://$1/nitro/v1/config/nsconfig?action=save
}

# Create ha pair

echo "Waiting for $INITIAL_WAIT_SEC seconds before running ADC configuration script"

sleep $INITIAL_WAIT_SEC

add_ha_node $PRIMARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID $SECONDARY_NODE_PRIVATE_NSIP

sleep 5

add_ha_node $SECONDARY_NODE_PUBLIC_NSIP $SECONDARY_NODE_INSTANCE_ID $PRIMARY_NODE_PRIVATE_NSIP

sleep 5

# Create ipset and bind address on primary
add_ipset $PRIMARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID $IPSET_NAME

sleep 5

add_vip $PRIMARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID $SECONDARY_NODE_PRIVATE_VIP $SERVER_SUBNET_MASK

sleep 5

bind_ipset_address $PRIMARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID $IPSET_NAME $SECONDARY_NODE_PRIVATE_VIP

# Add route for other server subnet
sleep 5
add_route $PRIMARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID $SECONDARY_NODE_SERVER_SUBNET $SERVER_SUBNET_MASK $PRIMARY_NODE_SNIP_GW

sleep 5
add_route $SECONDARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID $PRIMARY_NODE_SERVER_SUBNET $SERVER_SUBNET_MASK $SECONDARY_NODE_SNIP_GW

# Create ipset and bind address on secondary
sleep  5

add_ipset $SECONDARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID $IPSET_NAME

sleep 5

bind_ipset_address $SECONDARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID $IPSET_NAME $SECONDARY_NODE_PRIVATE_VIP

sleep 5

create_lbvserver  $PRIMARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID $LBVSERVER_NAME $PRIMARY_NODE_PRIVATE_VIP $IPSET_NAME

save_config $PRIMARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID
save_config $SECONDARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID
