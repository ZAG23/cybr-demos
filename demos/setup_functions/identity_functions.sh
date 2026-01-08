#!/bin/bash
set -euo pipefail

get_identity_token() {
  # $1 isp_id, $2 client_id, $3 client_secret
  if [ $# -ne 3 ]; then
      echo "Usage: get_identity_token client_id, client_secret, isp_id"
      return 1
  fi

access_token=$(curl --silent --location "https://$1.id.cyberark.cloud/oauth2/platformtoken" \
  --header 'X-IDAP-NATIVE-CLIENT: true' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=client_credentials' \
  --data-urlencode "client_id=$2" \
  --data-urlencode "client_secret=$3" | jq -r .access_token)

  # Check if access_token is empty or null
  if [ -z "$access_token" ] || [ "$access_token" == "null" ]; then
    printf "\nERROR: Get Identity Token failed. Access token is empty or null.\n" >&2
    exit 1
  fi

  #Return the token to the caller via stdout
  printf '%s' "$access_token"
}

set_user_lock_state() {
  # $1 isp_id, $2 identity_token, $3 user_id, $4 lock_flag (true|false)
  if [ $# -ne 4 ]; then
    echo "Usage: set_cloud_lock isp_id identity_token user_email lock_flag"
    return 1
  fi

  local isp_id="$1"
  local identity_token="$2"
  local user_id="$3"
  local lock_flag="$4"

  echo "Updating lock state fo $user_id to $lock_flag"

  response=$(curl --silent --request POST \
    --location "https://${isp_id}.id.cyberark.cloud/UserMgmt/SetCloudLock?user=${user_id}&lockUser=${lock_flag}" \
    --header "authorization: Bearer ${identity_token}" \
    --header "content-type: application/json" \
    --data '{}'
  )

  local user_uuid="abc-e2e-123"
  curl --request POST \
    --location "https://${isp_id}.id.cyberark.cloud/CDirectoryService/ChangeUserState" \
    --header 'Accept: */*' \
    --header "authorization: Bearer ${identity_token}" \
    --header 'Content-Type: application/json' \
    --data "{\"ID\": \"$user_uuid\",\"state\": \"true\"}"

  # Basic failure detection
  if [ -z "$response" ]; then
    printf "\nERROR: SetLock failed. Empty response.\n" >&2
  fi

  # Validate expected success shape: {"success":true,"Result":true,...}
  success=$(printf '%s' "$response" | jq -r '.success // empty' 2>/dev/null)
  result=$(printf '%s' "$response" | jq -r '.Result // empty' 2>/dev/null)

  if [ "$success" != "true" ] || [ "$result" != "true" ]; then
    printf "\nERROR: SetLock failed. success=%s result=%s errorCode=%s message=%s\nResponse: %s\n"
    printf '%s' "$response"
  fi

}

