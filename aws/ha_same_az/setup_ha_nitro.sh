
add_ha_node () {
curl \
-H "Content-Type: application/json" \
-H "X-NITRO-USER: nsroot" \
-H "X-NITRO-PASS: $2" \
-d "{\"hanode\": { \"id\": 1, \"ipaddress\": \"$3\"}}" \
-k \
https://$1/nitro/v1/config/hanode
}

save_config () {
curl \
-H "Content-Type: application/json" \
-H "X-NITRO-USER: nsroot" \
-H "X-NITRO-PASS: $2" \
-d "{\"nsconfig\":{}}" \
-k \
https://$1/nitro/v1/config/nsconfig?action=save
}

sleep 5

add_ha_node $PRIMARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID $SECONDARY_NODE_PRIVATE_NSIP

sleep 5

add_ha_node $SECONDARY_NODE_PUBLIC_NSIP $SECONDARY_NODE_INSTANCE_ID $PRIMARY_NODE_PRIVATE_NSIP

sleep 5

save_config $PRIMARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID
