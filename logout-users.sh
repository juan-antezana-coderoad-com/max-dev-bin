#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Illegal number of parameters"
    echo
    echo "logout-users.sh [auth_service_base_url]"
    echo
    echo "Example:"
    echo "logout-users.sh http://localhost:9017/as"
    exit 2
fi

# Read the arguments
AUTH_SERVICE_BASE_URL=$1

echo
echo "####################################"
echo "### Authentication Configuration ###"
echo "####################################"
echo
SERVICE_TOKEN_HEADER="X-Scene-Service-Token-Header"
SERVICE_TOKEN_VALUE="BSS:SERVICE:TOKEN:DEV:001"

echo "AUTH_SERVICE_BASE_URL: $AUTH_SERVICE_BASE_URL"
echo "SERVICE_TOKEN_HEADER: $SERVICE_TOKEN_HEADER"
echo "SERVICE_TOKEN_VALUE: $SERVICE_TOKEN_VALUE"

echo
echo "###############################################"
echo "### Log out users on Authentication Service ###"
echo "###############################################"
echo

MAX_USER_ID=12000

for USER_ID in $(seq 1 $MAX_USER_ID);
do
  AUTH_REQUEST_LOGOUT_USERS="${AUTH_SERVICE_BASE_URL}/userManagement/session/current"
  echo "AUTH_REQUEST_LOGOUT_USERS: $AUTH_REQUEST_LOGOUT_USERS"
  echo "X-Scene-User: ${USER_ID}"

  curl --location \
       --request DELETE "${AUTH_REQUEST_LOGOUT_USERS}" \
       --header 'Content-Type: application/json; charset=utf-8' \
       --header "${SERVICE_TOKEN_HEADER}: ${SERVICE_TOKEN_VALUE}" \
       --header "X-Scene-User: ${USER_ID}" \
      --header 'X-Scene-Device-Context: *' | \
  jq '.'
done
