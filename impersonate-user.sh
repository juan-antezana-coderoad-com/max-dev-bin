#!/bin/bash

if [[ $# -ne 5 ]]; then
    echo "Illegal number of parameters"
    echo
    echo "impersonate-user.sh [keycloak_base_url] [support username] [support password] [impersonated user email] [realm]"
    echo
    echo "Example:"
    echo "impersonate-user.sh http://localhost:8080 support@veea.com support123! juan.antezana@veea.co veea"
    exit 2
fi

# Read the arguments
KEYCLOAK_BASE_URL=$1
KEYCLOAK_SUPPORT_USERNAME=$2
KEYCLOAK_SUPPORT_PASSWORD=$3
KEYCLOAK_IMPERSONATED_USER_EMAIL=$4
KEYCLOAK_REALM=$5

echo
echo "##############################"
echo "### Keycloak Configuration ###"
echo "##############################"
echo
KEYCLOAK_CLIENT="veeahub-cli"
echo "KEYCLOAK_BASE_URL: $KEYCLOAK_BASE_URL"
echo "KEYCLOAK_SUPPORT_USERNAME: $KEYCLOAK_SUPPORT_USERNAME"
echo "KEYCLOAK_SUPPORT_PASSWORD: $KEYCLOAK_SUPPORT_PASSWORD"
echo "KEYCLOAK_IMPERSONATED_USER_EMAIL: $KEYCLOAK_IMPERSONATED_USER_EMAIL"
echo "KEYCLOAK_REALM: $KEYCLOAK_REALM"
echo "KEYCLOAK_CLIENT: $KEYCLOAK_CLIENT"

echo
echo "##########################################"
echo "### Getting the token for support user ###"
echo "##########################################"
echo
KEYCLOAK_REQUEST_GET_TOKEN="${KEYCLOAK_BASE_URL}/auth/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token"
echo "KEYCLOAK_REQUEST_GET_TOKEN: $KEYCLOAK_REQUEST_GET_TOKEN"

KEYCLOAK_RESPONSE_SUPPORT_GET_TOKEN=$(curl --location \
                                           --request POST "${KEYCLOAK_REQUEST_GET_TOKEN}" \
                                           --header 'Content-Type: application/x-www-form-urlencoded' \
                                           --data-urlencode "username=${KEYCLOAK_SUPPORT_USERNAME}" \
                                           --data-urlencode "password=${KEYCLOAK_SUPPORT_PASSWORD}" \
                                           --data-urlencode 'grant_type=password' \
                                           --data-urlencode "client_id=${KEYCLOAK_CLIENT}" \
                                           -w "\n%{http_code}")
KEYCLOAK_RESPONSE_SUPPORT_GET_TOKEN=(${KEYCLOAK_RESPONSE_SUPPORT_GET_TOKEN[@]})
HTTP_STATUS_CODE=${KEYCLOAK_RESPONSE_SUPPORT_GET_TOKEN[-1]}

# Checking if the http status code is 200
if [[ ${HTTP_STATUS_CODE} -eq 200 ]]
then
  BODY=${KEYCLOAK_RESPONSE_SUPPORT_GET_TOKEN[@]::${#KEYCLOAK_RESPONSE_SUPPORT_GET_TOKEN[@]}-1}
  SUPPORT_ACCESS_TOKEN=$(echo "${BODY}" | jq -r '.access_token')
  echo "SUPPORT_ACCESS_TOKEN: ${SUPPORT_ACCESS_TOKEN}"

  echo
  echo "####################################"
  echo "### Exchanging token on Keycloak ###"
  echo "####################################"
  echo
  echo "Getting the acces token for ${KEYCLOAK_IMPERSONATED_USER_EMAIL}"
  echo "KEYCLOAK_REQUEST_GET_TOKEN: $KEYCLOAK_REQUEST_GET_TOKEN"
  KEYCLOAK_RESPONSE_IMPERSONATED_USER_GET_TOKEN=$(curl --location \
                                                       --request POST "${KEYCLOAK_REQUEST_GET_TOKEN}" \
                                                       --header 'Content-Type: application/x-www-form-urlencoded' \
                                                       --data-urlencode "client_id=${KEYCLOAK_CLIENT}" \
                                                       --data-urlencode 'grant_type=urn:ietf:params:oauth:grant-type:token-exchange' \
                                                       --data-urlencode "requested_subject=${KEYCLOAK_IMPERSONATED_USER_EMAIL}" \
                                                       --data-urlencode "subject_token=${SUPPORT_ACCESS_TOKEN}" \
                                                       -w "\n%{http_code}")
  KEYCLOAK_RESPONSE_IMPERSONATED_USER_GET_TOKEN=(${KEYCLOAK_RESPONSE_IMPERSONATED_USER_GET_TOKEN[@]})
  HTTP_STATUS_CODE=${KEYCLOAK_RESPONSE_IMPERSONATED_USER_GET_TOKEN[-1]}

  if [[ ${HTTP_STATUS_CODE} -eq 200 ]]
  then
    BODY=${KEYCLOAK_RESPONSE_IMPERSONATED_USER_GET_TOKEN[@]::${#KEYCLOAK_RESPONSE_IMPERSONATED_USER_GET_TOKEN[@]}-1}
    IMPERSONATED_USER_ACCESS_TOKEN=$(echo "${BODY}" | jq -r '.access_token')
    echo "IMPERSONATED_USER_ACCESS_TOKEN: ${IMPERSONATED_USER_ACCESS_TOKEN}"
  else
    echo "Mistakes exchanging token for ${KEYCLOAK_IMPERSONATED_USER_EMAIL}"
  fi
else
  echo "Mistakes getting the token for suppor user"
fi



