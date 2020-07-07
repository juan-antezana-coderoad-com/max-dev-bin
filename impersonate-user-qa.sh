#!/bin/bash
source "impersonate-user.sh"

get_impersonated_user_token() {
  local _auth_base_url="https://qa-auth.veea.co"
  local _realm="veea"
  echo $(_get_impersonated_user_token "$1" "$2" "$3" "$_auth_base_url" "$_realm")
}

case "${@:-}" in
  ":")
    ;;
  *)
    if [[ $# -ne 3 ]]; then
        echo "Wrong number of agruments were passed!"
        echo "$0 [your username] [your password] [impersonated user email]"
        echo
        echo "Example:"
        echo "$0 support.user@veea.com verysecretuserpassword impersonated.user@omnicorp.com"
        exit 1
    fi
    echo $(get_impersonated_user_token "$1" "$2" "$3")
    ;;
esac
