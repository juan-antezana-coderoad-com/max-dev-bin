#!/bin/bash
if [[ $# -ne 3 ]]; then
    echo "Illegal number of parameters"
    echo
    echo "impersonate-user.sh [keycloak base url] [your username] [your password] [impersonated user email]"
    echo
    echo "Example:"
    echo "impersonate-user.sh https://auth.veea.co support.user@veea.com verysecretuserpassword impersonated.user@omnicorp.com"
    exit 2
fi
# Read the arguments
KEYCLOAK_BASE_URL=$1
USERNAME=$2
PASSWORD=$3
IMPERSONATED_USER_EMAIL=$4

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
if [[ "${USER_ACCESS_TOKEN}" != "null" ]]
then
  echo "Your access token is: ${USER_ACCESS_TOKEN}"

  echo
  echo "####################################"
  echo "### Getting the user id by email ###"
  echo "####################################"
  echo
  KEYCLOAK_REQUEST_GET_USER_BY_EMAIL="${KEYCLOAK_BASE_URL}/auth/admin/realms/${KEYCLOAK_REALM}/users?email=${IMPERSONATED_USER_EMAIL}"
  GET_USER_BY_EMAIL_RESPONSE=$(curl -s \
                                    --request GET "${KEYCLOAK_REQUEST_GET_USER_BY_EMAIL}" \
                                    --header "Authorization: Bearer ${USER_ACCESS_TOKEN}")
  USER_ID=$(echo "${GET_USER_BY_EMAIL_RESPONSE}" | jq -r '.[0].id')
  if [[ "${USER_ID}" != "null" ]]
  then
    echo "The user id for ${IMPERSONATED_USER_EMAIL} is: ${USER_ID}"
    echo
    echo "####################################"
    echo "### Exchanging token on Keycloak ###"
    echo "####################################"
    echo
    echo "Getting the access token for ${IMPERSONATED_USER_EMAIL}"
    echo "KEYCLOAK_REQUEST_GET_TOKEN: ${KEYCLOAK_REQUEST_GET_TOKEN}"
    echo
    IMPERSONATED_USER_TOKEN_RESPONSE=$(curl -s \
                                            --request POST "${KEYCLOAK_REQUEST_GET_TOKEN}" \
                                            --header 'Content-Type: application/x-www-form-urlencoded' \
                                            --data-urlencode "client_id=${KEYCLOAK_CLIENT}" \
                                            --data-urlencode 'grant_type=urn:ietf:params:oauth:grant-type:token-exchange' \
                                            --data-urlencode "requested_subject=${USER_ID}" \
                                            --data-urlencode "subject_token=${USER_ACCESS_TOKEN}")
    IMPERSONATED_USER_ACCESS_TOKEN=$(echo "${IMPERSONATED_USER_TOKEN_RESPONSE}" | jq -r '.access_token')
    if [[ "${IMPERSONATED_USER_ACCESS_TOKEN}" != "null" ]]
    then
      echo "IMPERSONATED_USER_ACCESS_TOKEN: ${IMPERSONATED_USER_ACCESS_TOKEN}"
    else
      echo "There was an error getting impersonated user token for user: ${IMPERSONATED_USER_EMAIL}, token response: ${IMPERSONATED_USER_TOKEN_RESPONSE}"
    fi
  else
    echo "There was an error getting impersonated user id for user: ${IMPERSONATED_USER_EMAIL}, token response: ${GET_USER_BY_EMAIL_RESPONSE}"
  fi
else
  echo "There was an error getting the token for your user: ${USERNAME}, token response: ${USER_TOKEN_RESPONSE}"
fi