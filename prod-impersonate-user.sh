#!/bin/bash
if [[ $# -ne 3 ]]; then
    echo "Illegal number of parameters"
    echo
    echo "impersonate-user.sh [your username] [your password] [impersonated user email]"
    echo
    echo "Example:"
    echo "impersonate-user.sh support.user@veea.com verysecretuserpassword impersonated.user@omnicorp.com"
    exit 2
fi
# Read the arguments
USERNAME=$1
PASSWORD=$2
IMPERSONATED_USER_EMAIL=$3
KEYCLOAK_BASE_URL="https://auth.veea.co"
KEYCLOAK_REALM="veea"
KEYCLOAK_CLIENT="veeahub-cli"
echo
echo "##########################################"
echo "### Getting the token for support user ###"
echo "##########################################"
echo
KEYCLOAK_REQUEST_GET_TOKEN="${KEYCLOAK_BASE_URL}/auth/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token"
echo "KEYCLOAK_REQUEST_GET_TOKEN: $KEYCLOAK_REQUEST_GET_TOKEN"
USER_TOKEN_RESPONSE=$(curl -s \
                           --request POST "${KEYCLOAK_REQUEST_GET_TOKEN}" \
                           --header 'Content-Type: application/x-www-form-urlencoded' \
                           --data-urlencode "username=${USERNAME}" \
                           --data-urlencode "password=${PASSWORD}" \
                           --data-urlencode 'grant_type=password' \
                           --data-urlencode "client_id=${KEYCLOAK_CLIENT}")
USER_ACCESS_TOKEN=$(echo "${USER_TOKEN_RESPONSE}" | jq -r '.access_token')
# Checking if the http status code is 200
if [[ "${USER_ACCESS_TOKEN}" != "null" ]]
then
  echo "Your access token is: ${USER_ACCESS_TOKEN}"
  echo
  echo "####################################"
  echo "### Exchanging token on Keycloak ###"
  echo "####################################"
  echo
  echo "Getting the acces token for ${KEYCLOAK_IMPERSONATED_USER_EMAIL}"
  echo "KEYCLOAK_REQUEST_GET_TOKEN: $KEYCLOAK_REQUEST_GET_TOKEN"
  IMPERSONATED_USER_TOKEN_RESPONSE=$(curl -s \
                                          --request POST "${KEYCLOAK_REQUEST_GET_TOKEN}" \
                                          --header 'Content-Type: application/x-www-form-urlencoded' \
                                          --data-urlencode "client_id=${KEYCLOAK_CLIENT}" \
                                          --data-urlencode 'grant_type=urn:ietf:params:oauth:grant-type:token-exchange' \
                                          --data-urlencode "requested_subject=${IMPERSONATED_USER_EMAIL}" \
                                          --data-urlencode "subject_token=${USER_ACCESS_TOKEN}")
  IMPERSONATED_USER_ACCESS_TOKEN=$(echo "${IMPERSONATED_USER_TOKEN_RESPONSE}" | jq -r '.access_token')
  if [[ "${IMPERSONATED_USER_ACCESS_TOKEN}" != "null" ]]
  then
    echo "IMPERSONATED_USER_ACCESS_TOKEN: ${IMPERSONATED_USER_ACCESS_TOKEN}"
  else
    echo "There was an error getting impersonated user token for user: ${IMPERSONATED_USER_EMAIL}, token response ${IMPERSONATED_USER_TOKEN_RESPONSE}"
  fi
else
  echo "There was an error getting the token for your user: ${USERNAME}, token response: ${USER_TOKEN_RESPONSE}"
fi