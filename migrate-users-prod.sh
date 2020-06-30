#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "Illegal number of parameters"
    echo
    echo "migrate-users.sh [auth_service_base_url] [keycloak_base_url]"
    echo
    echo "Example:"
    echo "migrate-users.sh http://localhost:9017/as http://localhost:8080"
    exit 2
fi

# Read the arguments
AUTH_SERVICE_BASE_URL=$1
KEYCLOAK_BASE_URL=$2

echo
echo "########################"
echo "### Pre - Requisites ###"
echo "########################"
echo
echo "1. Create a user in keycloak (Realm master) "
echo "   - username: system"
echo "   - password: 5ystm_123!"
echo "2. Assign the role admin to user system"
echo "3. Install jq (https://stedolan.github.io/jq/download/)"

echo
echo "#####################"
echo "### Configuration ###"
echo "#####################"
echo
# Default batch size is 300
BATCH_SIZE=1000
echo "BATCH_SIZE: $BATCH_SIZE"

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
echo "##############################"
echo "### Keycloak Configuration ###"
echo "##############################"
echo
KEYCLOAK_REALM="veea"
KEYCLOAK_ALGORITHM="veea-password"
KEYCLOAK_USER="system"
KEYCLOAK_PASSWORD="January-123!"

echo "KEYCLOAK_BASE_URL: $KEYCLOAK_BASE_URL"
echo "KEYCLOAK_REALM: $KEYCLOAK_REALM"
echo "KEYCLOAK_ALGORITHM: $KEYCLOAK_ALGORITHM"
echo "KEYCLOAK_USER: $KEYCLOAK_USER"
echo "KEYCLOAK_PASSWORD: $KEYCLOAK_PASSWORD"

echo
echo "##########################################################"
echo "### Gets the number of users in Authentication Service ###"
echo "##########################################################"
echo
AUTH_REQUEST_GET_LIST_OF_USERS="${AUTH_SERVICE_BASE_URL}/userManagement/user?pageSize=1"
AUTH_RESPONSE_GET_LIST_OF_USERS=$(curl --location \
                                       --request GET "${AUTH_REQUEST_GET_LIST_OF_USERS}" \
                                       --header "${SERVICE_TOKEN_HEADER}: ${SERVICE_TOKEN_VALUE}" \
                                       -w "\n%{http_code}")

AUTH_RESPONSE_GET_LIST_OF_USERS=(${AUTH_RESPONSE_GET_LIST_OF_USERS[@]})
HTTP_STATUS_CODE=${AUTH_RESPONSE_GET_LIST_OF_USERS[-1]}

# Checking if the http status code is 200
if [[ ${HTTP_STATUS_CODE} -eq 200 ]]
then
  # Getting the Body
  BODY=${AUTH_RESPONSE_GET_LIST_OF_USERS[@]::${#AUTH_RESPONSE_GET_LIST_OF_USERS[@]}-1}
  # Getting the number of users of the body using jq
  AUTH_NUMBER_OF_USERS=$(echo "${BODY}" | jq '.total')
  echo "Number Of Users in Auth: ${AUTH_NUMBER_OF_USERS}"
  # Calculating the number of batches (number of users / batch size) + (number of users % batch size > 0)
  NUMBERS_OF_BATCHES=$(( (AUTH_NUMBER_OF_USERS / BATCH_SIZE) + (AUTH_NUMBER_OF_USERS % BATCH_SIZE > 0) ))
  echo "Number Of Batches: ${NUMBERS_OF_BATCHES}"

  echo
  echo "###############################################################"
  echo "### Migrating users from Authentication Service to keycloak ###"
  echo "###############################################################"
  echo

  for BATCH in $(seq 1 $NUMBERS_OF_BATCHES);
  do
    # Calling the endpoint POST /userManagement/user/migrate to migrate the users from auth to keycloak
    AUTH_REQUEST_MIGRATE_USERS="${AUTH_SERVICE_BASE_URL}/userManagement/user/migrate?pageSize=$BATCH_SIZE&pageNumber=$BATCH"
    echo "AUTH_REQUEST_MIGRATE_USERS: $AUTH_REQUEST_MIGRATE_USERS"

    curl --location \
         --request POST "${AUTH_REQUEST_MIGRATE_USERS}" \
         --header "Content-Type: application/json" \
         --header "${SERVICE_TOKEN_HEADER}: ${SERVICE_TOKEN_VALUE}" \
         --data-raw '{
           "baseUrl": "'$KEYCLOAK_BASE_URL'",
           "realm": "'$KEYCLOAK_REALM'",
           "algorithm": "'$KEYCLOAK_ALGORITHM'",
           "username": "'$KEYCLOAK_USER'",
           "password": "'$KEYCLOAK_PASSWORD'",
           "grantType": "password",
           "clientId": "admin-cli"
         }' | \
    jq '.'

    echo
  done
else
  echo "Mistakes getting the list of users in Authentication Service"
fi