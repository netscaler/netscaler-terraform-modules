wait_for_adc() {
    sleep ${WAIT_PERIOD}
}

reset_password() {
curl \
-H "Content-Type: application/json" \
-d "{\"login\": { \"username\": \"${USERNAME}\", \"password\": \"${OLD_PASSWORD}\", \"new_password\": \"${NEW_PASSWORD}\"}}" \
-k \
https://${NSIP}/nitro/v1/config/login
}

if [[ $DO_RESET == "true" ]] ; then
wait_for_adc
reset_password
else
echo "Skipping first time password reset"
fi
