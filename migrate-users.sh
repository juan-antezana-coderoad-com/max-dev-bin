#!/bin/bash

# Prerequisitos
# - https://stedolan.github.io/jq/


echo
echo "#####################"
echo "### Configuration ###"
echo "#####################"
echo
BATCH_SIZE=100
echo "BATCH_SIZE: $BATCH_SIZE"

echo
echo "####################################"
echo "### Authentication Configuration ###"
echo "####################################"
echo
AUTH_BASE_URL="http://localhost:9017/as"
SERVICE_TOKEN_HEADER="X-Scene-Service-Token-Header"
SERVICE_TOKEN_VALUE="BSS:SERVICE:TOKEN:DEV:001"

echo "AUTH_BASE_URL: $AUTH_BASE_URL"
echo "SERVICE_TOKEN_HEADER: $SERVICE_TOKEN_HEADER"
echo "SERVICE_TOKEN_VALUE: $SERVICE_TOKEN_VALUE"

echo
echo "##############################"
echo "### Keycloak Configuration ###"
echo "##############################"
echo
KEYCLOAK_BASE_URL="http://localhost:8080"
KEYCLOAK_REALM="veea"
KEYCLOAK_ALGORITHM="veea-password"
KEYCLOAK_USER="system"
KEYCLOAK_PASSWORD="5ystm_123!"

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
AUTH_REQUEST_GET_LIST_OF_USERS="${AUTH_BASE_URL}/userManagement/user?pageSize=1"
AUTH_RESPONSE_GET_LIST_OF_USERS=$(curl --location \
                                       --request GET "${AUTH_REQUEST_GET_LIST_OF_USERS}" \
                                       --header "${SERVICE_TOKEN_HEADER}: ${SERVICE_TOKEN_VALUE}" \
                                       -w "\n%{http_code}")

AUTH_RESPONSE_GET_LIST_OF_USERS=(${AUTH_RESPONSE_GET_LIST_OF_USERS[@]})
HTTP_STATUS_CODE=${AUTH_RESPONSE_GET_LIST_OF_USERS[-1]}

if [[ ${HTTP_STATUS_CODE} -eq 200 ]]
then
  BODY=${AUTH_RESPONSE_GET_LIST_OF_USERS[@]::${#AUTH_RESPONSE_GET_LIST_OF_USERS[@]}-1}
  AUTH_NUMBER_OF_USERS=$(echo "${BODY}" | jq '.total')
  echo "Number Of Users in Auth: ${AUTH_NUMBER_OF_USERS}"
  NUMBERS_OF_BATCHES=$(( AUTH_NUMBER_OF_USERS / BATCH_SIZE ))
  echo "Number Of Batches: ${NUMBERS_OF_BATCHES}"

  for BATCH in $(seq 1 $NUMBERS_OF_BATCHES);
  do
    AUTH_REQUEST_MIGRATE_USERS="${AUTH_BASE_URL}/userManagement/user/migrate?pageSize=$BATCH_SIZE&pageNumber=$BATCH"
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