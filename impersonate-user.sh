#!/bin/bash

_get_access_token_from_response() {
  local _access_token=$(echo "$1" | jq -r '.access_token')
  echo $_access_token
}

die() {
  echo >&2 "$*"
  exit 1
}

_get_impersonated_user_token() {
  local _username=$1
  local _password=$2
  local _impersonated_user_email=$3
  local _auth_base_url=$4
  local _realm=$5
  local _client_id="veeahub-cli"
  local _get_access_token_url="${_auth_base_url}/auth/realms/${_realm}/protocol/openid-connect/token"

  local _user_token_response=$(curl --silent \
                                    --request POST "$_get_access_token_url" \
                                    --header "Content-Type: application/x-www-form-urlencoded" \
                                    --data-urlencode "client_id=$_client_id" \
                                    --data-urlencode "grant_type=password" \
                                    --data-urlencode "username=$_username" \
                                    --data-urlencode "password=$_password")

  local _user_access_token=$(_get_access_token_from_response "$_user_token_response")

  if [[ "$_user_access_token" == "null" ]]
  then
    die "There was an error getting the token for your user: $_username, token response: $_user_token_response"
  fi

  local _get_user_id_by_email_url="$_auth_base_url/auth/admin/realms/$_realm/users?email=$_impersonated_user_email"
  local _user_id_by_email_response=$(curl --silent \
                                          --request GET "$_get_user_id_by_email_url" \
                                          --header "Authorization: Bearer $_user_access_token")
  local _impersonated_user_id=$(echo "$_user_id_by_email_response" | jq -r '.[0].id')

  if [[ "$_impersonated_user_id" == "null" ]]
  then
    die "There was an error getting impersonated user id for user: $_impersonated_user_email, response: $_user_id_by_email_response"
  fi

  local _impersonated_user_token_response=$(curl --silent \
                                                 --request POST "$_get_access_token_url" \
                                                 --header "Content-Type: application/x-www-form-urlencoded" \
                                                 --data-urlencode "client_id=$_client_id" \
                                                 --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
                                                 --data-urlencode "requested_subject=$_impersonated_user_id" \
                                                 --data-urlencode "subject_token=$_user_access_token")

  local _impersonated_user_access_token=$(_get_access_token_from_response "$_impersonated_user_token_response")

  if [[ "$_impersonated_user_access_token" == "null" ]]
  then
    die "There was an error getting impersonated user token for user: $_impersonated_user_email, token response: $_impersonated_user_token_response"
  fi

  echo $_impersonated_user_access_token
}

get_user_id_from_token() {
  local _token_payload=$(echo $1 | cut -d'.' -f2 | base64 --decode)
  if jq -e . >/dev/null 2>&1 <<<"$_token_payload"; then
    _token_payload="$_token_payload"
  else
    _token_payload="$_token_payload}"
  fi
  local _user_id=$(echo $_token_payload | jq ".user_id")
  echo $_user_id
}
