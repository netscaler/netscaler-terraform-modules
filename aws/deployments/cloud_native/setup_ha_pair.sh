########################################################################################
#
#  Copyright (c) 2019 Citrix Systems, Inc.
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#      * Redistributions of source code must retain the above copyright
#        notice, this list of conditions and the following disclaimer.
#      * Redistributions in binary form must reproduce the above copyright
#        notice, this list of conditions and the following disclaimer in the
#        documentation and/or other materials provided with the distribution.
#      * Neither the name of the Citrix Systems, Inc. nor the
#        names of its contributors may be used to endorse or promote products
#        derived from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL Citrix Systems, Inc. BE LIABLE FOR ANY
#  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
########################################################################################

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

add_snip_cic () {
# $1 Public NSIP
# $2 Password
# $3 CIC SNIP
# $4 Netmask

echo "add_snip_cic $*"

curl \
--progress-bar \
-H "Content-Type: application/json" \
-H "X-NITRO-USER: nsroot" \
-H "X-NITRO-PASS: $2" \
-d "{\"nsip\" : { \"ipaddress\": \"$3\", \"netmask\": \"$4\", \"type\": \"SNIP\", \"mgmtaccess\": \"ENABLED\" }}" \
-k \
https://$1/nitro/v1/config/nsip
}

add_snip () {
# $1 Public NSIP
# $2 Password
# $3 Server SNIP
# $4 Server Subnet Netmask

echo "add_snip $*"

curl \
--progress-bar \
-H "Content-Type: application/json" \
-H "X-NITRO-USER: nsroot" \
-H "X-NITRO-PASS: $2" \
-d "{\"nsip\" : { \"ipaddress\": \"$3\", \"netmask\": \"$4\", \"type\": \"SNIP\" }}" \
-k \
https://$1/nitro/v1/config/nsip
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

reset_password() {
# $1 nsip
# $2 old password
# $3 new password
curl \
-H "Content-Type: application/json" \
-d "{\"login\": { \"username\": \"nsroot\", \"password\": \"${2}\", \"new_password\": \"${3}\"}}" \
-k \
https://${1}/nitro/v1/config/login
}

# Create ha pair

echo "Waiting for $INITIAL_WAIT_SEC seconds before running ADC configuration script"
sleep $INITIAL_WAIT_SEC

if [[ $DO_RESET == "true" ]] ; then

reset_password $PRIMARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID $NEW_PASSWORD
reset_password $SECONDARY_NODE_PUBLIC_NSIP $SECONDARY_NODE_INSTANCE_ID $NEW_PASSWORD
sleep 10

add_ha_node $PRIMARY_NODE_PUBLIC_NSIP $NEW_PASSWORD $SECONDARY_NODE_PRIVATE_NSIP
sleep 5

add_ha_node $SECONDARY_NODE_PUBLIC_NSIP $NEW_PASSWORD $PRIMARY_NODE_PRIVATE_NSIP
sleep 5

export ACTUAL_PASSWORD="$NEW_PASSWORD"

else

add_ha_node $PRIMARY_NODE_PUBLIC_NSIP $PRIMARY_NODE_INSTANCE_ID $SECONDARY_NODE_PRIVATE_NSIP
sleep 5

add_ha_node $SECONDARY_NODE_PUBLIC_NSIP $SECONDARY_NODE_INSTANCE_ID $PRIMARY_NODE_PRIVATE_NSIP
sleep 5

export ACTUAL_PASSWORD="$PRIMARY_NODE_INSTANCE_ID"

fi

# Create ipset and bind address on primary
add_ipset $PRIMARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD $IPSET_NAME

sleep 5

add_vip $PRIMARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD $PRIMARY_NODE_PRIVATE_VIP $SERVER_SUBNET_MASK

sleep 5

add_vip $PRIMARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD $SECONDARY_NODE_PRIVATE_VIP $SERVER_SUBNET_MASK

sleep 5

bind_ipset_address $PRIMARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD $IPSET_NAME $SECONDARY_NODE_PRIVATE_VIP

# Configure Server Side SNIP on both Primary and Secondary

sleep 5
add_snip $PRIMARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD $PRIMARY_NODE_SNIP $SERVER_SUBNET_MASK

sleep 5
add_snip $SECONDARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD $SECONDARY_NODE_SNIP $SERVER_SUBNET_MASK

# Add route for other server subnet
sleep 5
add_route $PRIMARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD $SECONDARY_NODE_SERVER_SUBNET $SERVER_SUBNET_MASK $PRIMARY_NODE_SNIP_GW

sleep 5
add_route $SECONDARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD $PRIMARY_NODE_SERVER_SUBNET $SERVER_SUBNET_MASK $SECONDARY_NODE_SNIP_GW

# Add SNIP for CIC Configuration on both the Primary and Secondary

sleep 5
add_snip_cic $PRIMARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD $CIC_PRIVATE_SNIP $CIC_PRIVATE_SNIP_SUBNET_MASK

sleep 5
add_snip_cic $SECONDARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD $CIC_PRIVATE_SNIP $CIC_PRIVATE_SNIP_SUBNET_MASK

# Create ipset and bind address on secondary

sleep 5

add_vip $SECONDARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD $SECONDARY_NODE_PRIVATE_VIP $SERVER_SUBNET_MASK

sleep  5

add_ipset $SECONDARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD $IPSET_NAME

sleep 5

bind_ipset_address $SECONDARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD $IPSET_NAME $SECONDARY_NODE_PRIVATE_VIP

sleep 5

save_config $PRIMARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD
save_config $SECONDARY_NODE_PUBLIC_NSIP $ACTUAL_PASSWORD
