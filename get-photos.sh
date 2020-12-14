#!/bin/bash

lines=$(cat cookie.txt | perl -p -e 's# #\n#g' | grep 'ChurchSSO\|Church-auth-jwt-prod\|directory_access_token\|directory_refresh_token\|directory_identity_token')
authorization_token=$(cat cookie.txt | perl -p -e 's#^.*authorization: Bearer ([^'"'"']*).*#\1#g')
refresh_token=$(cat cookie.txt | perl -p -e 's#^.*-H '"'"'x-refresh: ([^'"'"']*).*#\1#g')
#ChurchSSO=$(echo $lines | perl -p -e 's#^.*ChurchSSO=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
ChurchSSO=$(echo $lines | sed '/ChurchSSO=/!d' | perl -p -e 's#^.*ChurchSSO=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
ChurchAuthJwtProd=$(echo $lines | sed '/Church-auth-jwt-prod=/!d' | perl -p -e 's#^.*Church-auth-jwt-prod=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
# directory_access_token=$(echo $lines | perl -p -e 's#^.*directory_access_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
directory_access_token=$(echo $lines | sed '/directory_access_token=/!d' | perl -p -e 's#^.*directory_access_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
directory_identity_token=$(echo $lines | sed '/directory_identity_token=/!d' | perl -p -e 's#^.*directory_identity_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
# directory_refresh_token=$(echo $lines | perl -p -e 's#^.*directory_refresh_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
directory_refresh_token=$(echo $lines | sed '/directory_refresh_token=/!d' | perl -p -e 's#^.*directory_refresh_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')

# echo "authorization_token=\"${authorization_token}\""
# echo "refresh_token=\"${refresh_token}\""
echo "ChurchSSO=\"${ChurchSSO}\""
echo "ChurchAuthJwtProd=\"${ChurchAuthJwtProd}\""
echo "directory_access_token=\"${directory_access_token}\""
echo "directory_identity_token=\"${directory_identity_token}\""
echo "directory_refresh_token=\"${directory_refresh_token}\""

# s/Church-auth-jwt-prod[^;]*;/Church-auth-jwt-prod='"${ChurchAuthJwtProd}"';/gc

read cont

echo "fetching elder data"

eldersData=$(jq -n 'inputs | {"object": . , "filename": input_filename, "lineNumber": input_line_number}' directory.json members-with-callings.json eq-cleaned.json | jq -ns 'inputs' | jq '. as $all | $all | map(select(.filename == "eq-cleaned.json"))[0].object | map(.name) as $targetMembers | $all | map(select(.filename == "directory.json"))[0].object | map(. as $household | .members | map(select([.name] as $targetMember | $targetMembers | contains($targetMember))) | map({name, uuid, district: ($household | .district), address: $household.address, email, phone})[0]) as $elderDetails | $elderDetails | map(select(.uuid != null) | .uuid) as $uuids | $all | map(select(.filename == "directory.json"))[0].object | map(.members | map(. as $targetMember | $targetMember | select($uuids | contains([$targetMember | .uuid])))) | flatten | map({uuid, householdUuid, name, district: (.name as $mName | $elderDetails | map(select(.name == $mName))[0].district)})')
# sleep 2

echo "writing yearbook data"

echo "$eldersData" | perl -p -e "s#'##g" | jq 'map(. as $elder | $elder | (.name | gsub("[., -]+"; "-") | ascii_downcase) as $namePath | "/photos/" as $path | $elder + {"elderPhoto": ($path + $namePath + ".png"), "familyPhoto": ($path + $namePath + "-family.png")})' > yearbook.json

photo_exists () {
  local filename="$1"
  local ignore="$2"
  local check_filesize=$(stat -f%z "$filename" | xargs)

  local ignore_placeholder=false
  local ignore_emptyfile=false
  local ignore_filenotexist=false

  # ignore="placeholders,emptyfile,filenotexist"
  echo ",$ignore," | grep ',placeholders,' &> /dev/null
  retVal="$?"
  if [ "$retVal" == "0" ]; then
      ignore_placeholder=true
  fi
  echo ",$ignore," | grep ',emptyfile,' &> /dev/null
  retVal="$?"
  if [ "$retVal" == "0" ]; then
      ignore_emptyfile=true
  fi
  echo ",$ignore," | grep ',filenotexist,' &> /dev/null
  retVal="$?"
  if [ "$retVal" == "0" ]; then
      ignore_filenotexist=true
  fi

  # report false if file exists and is empty
  if [[ "$ignore_emptyfile" != "true" && -f "$filename" && ! -s "$filename" ]]; then 
    return 1; 
  # report false if file doesn't exist
  elif [[ "$ignore_filenotexist" != "true" && ! -e "$filename" ]]; then
    return 1; 
  # report false if file is a placeholder
  elif [[ "$ignore_placeholder" != "true" && "$check_filesize" == "17688" ]]; then
    return 1; 
  else
    # report false if photo file is json
    bytes1=$(grep "404 Not Found" "$filename" | wc -c)
    bytes2=$(grep "Bad Request" "$filename" | wc -c)
    bytes2=$(grep "error-page" "$filename" | wc -c)
    bytes2=$(grep "502 Bad Gateway" "$filename" | wc -c)
    bytes3=$(grep "timestamp" "$filename" | wc -c)
    return $(($bytes1+$bytes2+$bytes3))
  fi
}

fetch_photo () {
  local scope="$1"
  local uuid="$2"
  local filename="photos/$3.png"
  local apply_thumbnails="$4"

  #if [ -e "$filename" ]; then
  #  return 1
  #fi

  if [ "$apply_thumbnails" == "" ]; then
      apply_thumbnails=true
  fi

  echo "fetching image for $uuid > $filename =" 'https://directory.churchofjesuschrist.org/api/v4/photos/'"${scope}"'/'"${uuid}"'?thumbnail='"${apply_thumbnails}"''

# scope='members'
# uuid='ac47b0b6-8826-4712-bcb9-129972a5b844'
# apply_thumbnails='true'

# scope='members'
# uuid='e5545004-4ce1-4717-8cc2-eb52580c74a3'
# apply_thumbnails='true'

curl 'https://directory.churchofjesuschrist.org/api/v4/photos/'"${scope}"'/'"${uuid}"'?thumbnail='"${apply_thumbnails}"'' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36' -H 'Sec-Fetch-User: ?1' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' -H 'Sec-Fetch-Site: none' -H 'Sec-Fetch-Mode: navigate' -H 'Referer: https://directory.churchofjesuschrist.org/api/v4/photos/'"${scope}"'/'"${uuid}"'' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US' -H $'Cookie: s_fid=4FE92280892D59F4-244F569B8EFFD7D3; _gcl_au=1.1.724578249.1603295117; _fbp=fb.1.1603295117725.1977565753; _ga=GA1.2.313675188.1603295118; audience_split=9; PFpreferredHomepage=COJC; tisLocale=en; check=true; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; audience_s_split=5; s_cc=true; notice_behavior=implied|us; ADRUM=s=1607376266764&r=https%3A%2F%2Fwww.churchofjesuschrist.org%2Fsi%2FgetImage%2Fsmall%3F482895523; at_check=true; s_tp=1046; s_ips=1046; s_plt=2.24; s_pltp=following%20person%20list; s_ppv=following%2520person%2520list%2C100%2C100%2C1046%2C1%2C1; ChurchSSO-int=tG0RYvlchLWckX6q448sQAqk56g.*AAJTSQACMDIAAlNLABxIZDE5WlZDdnM3LytCZytZb2pheU9qb1RlMHc9AAR0eXBlAANDVFMAAlMxAAIwMQ..*; Church-auth-jwt-int=eyJ0eXAiOiJKV1QiLCJraWQiOiJrVlR5NDVhb0JoUnVBcWJ2MnQwbWU2NVpIMEk9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiIzNzgzZGM5Ni1lMGRlLTQ3YWQtOGEzOC1mNzJiMWQzNDI1NGItMTI3MzE1IiwiaXNzIjoiaHR0cHM6Ly9pZGVudC1pbnQuY2h1cmNob2ZqZXN1c2NocmlzdC5vcmcvc3NvL29hdXRoMiIsInRva2VuTmFtZSI6ImlkX3Rva2VuIiwibm9uY2UiOiI0NzNGREJBRTVFQzVFQzRFMzUxNzYwRkQxQzcxQ0YzNyIsImF1ZCI6ImwxODM3NiIsImFjciI6IjAiLCJhenAiOiJsMTgzNzYiLCJhdXRoX3RpbWUiOjE2MDczODU3NjYsImZvcmdlcm9jayI6eyJzc290b2tlbiI6InRHMFJZdmxjaExXY2tYNnE0NDhzUUFxazU2Zy4qQUFKVFNRQUNNRElBQWxOTEFCeElaREU1V2xaRGRuTTNMeXRDWnl0WmIycGhlVTlxYjFSbE1IYzlBQVIwZVhCbEFBTkRWRk1BQWxNeEFBSXdNUS4uKiIsInN1aWQiOiIxZTIxZGFkNC0wN2FkLTQzMWEtODRmOS1lZTM1NWMyODFjMmUtMTIwMDYzIn0sInJlYWxtIjoiL2NodXJjaCIsImV4cCI6MTYwNzQyODk2NiwidG9rZW5UeXBlIjoiSldUVG9rZW4iLCJpYXQiOjE2MDczODU3NjYsImFnZW50X3JlYWxtIjoiL2NodXJjaCJ9.jgSL5xzWdr99kXbdog88EJ-3PoPYiZg4cn92oc-_9H3v_vGrUtgOBWnB3t6KUnpy3ZII9b7eN7RvJ7sUDh7h4Ea6m7NpUrlr-9CdbmaJI1SjcUOv0UB3ankEl60GmXreXWdo1pbx3ZGwIurJ0K_OyIe6CSt1UH6KcF1SEHY3y7HfGa5Gl4rzVwFuJ20wVg5F9HQLL0-d2LvSRb4H8ZpxF4OCgusJszR4m4EXhYtNtyc5ypXLc3QmXLOfCdPbWTlmNdZrN58uR7GITqQ7sONwjMZ_N1S2CGsC4Ch_PxuctQAbYDe6NS82fXwHiwiG8dbSWKtNYUGbYIzxzY9wb3YERg; RT="z=1&dm=churchofjesuschrist.org&si=4e06de69-20c1-4c90-893b-02a7c3bc28a8&ss=kif2aguf&sl=0&tt=0&bcn=%2F%2F34089f75.akstat.io%2F"; amlbcookie-prod=01; ChurchSSO='"${ChurchSSO}"'; directory_access_token='"${directory_access_token}"'; directory_identity_token='"${directory_identity_token}"'; directory_refresh_token='"${directory_refresh_token}"'; SameSite=None; TS01b07831=01999b70237c4b534c3b379d5be8df73359727d590944741c4636f2b956968035c41eab50bf0d8213f0db34bf322e136408f1cddd1; sat_track=true; Church-auth-jwt-prod=eyJ0eXAiOiJKV1QiLCJraWQiOiJDK2g4T1diR0IrMnV0L0xQQ0RlTEUwMXAzUjQ9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiI0NTQ5Zjk3Yi1iMTFjLTQwNWUtYjU3YS0xMTc0MGEzN2M5MGYtMzkyOTUxMDgyOSIsImlzcyI6Im51bGw6Ly9pZGVudC1wcm9kLmNodXJjaG9mamVzdXNjaHJpc3Qub3JnOjQ0My9zc28vb2F1dGgyIiwidG9rZW5OYW1lIjoiaWRfdG9rZW4iLCJub25jZSI6IjUyMTlERjJFMTRFNkNBOUREMUJENTNERDU2NUIxODI3IiwiYXVkIjoibDE4Mzg0IiwiYWNyIjoiMCIsImF6cCI6ImwxODM4NCIsImF1dGhfdGltZSI6MTYwNzM5OTUxNCwiZm9yZ2Vyb2NrIjp7InNzb3Rva2VuIjoiVzhaNGpXZ3V2RkFjWVlwUndOTGxYMU5udEdVLipBQUpUU1FBQ01ESUFBbE5MQUJ4TmNrWkpabEJHV1hsamRteFJiR3MyTVM5b2VsQTRZbWt6U0UwOUFBUjBlWEJsQUFORFZGTUFBbE14QUFJd01RLi4qIiwic3VpZCI6IjhjZGQ4ZTU3LTRiOGMtNDMzYi05YmI1LTBmOWI5ZDUxNzBjYS0zOTMyMjY4NTAxIn0sInJlYWxtIjoiL2NodXJjaCIsImV4cCI6MTYwNzQ0MjcxNiwidG9rZW5UeXBlIjoiSldUVG9rZW4iLCJpYXQiOjE2MDczOTk1MTYsImFnZW50X3JlYWxtIjoiL2NodXJjaCJ9.e8dinu1LFdxRFLImaAgXJzctb86-gxVlwWxG6GQPXk5a2OUiPRoT8yWYobUNOpIm4nnnAC3gZ-g3dXruMadRkBg5f3DuWhs7Gsi6gwSFWM9uITMrjElGf4-uLyXifL3LTFhg8DoEOXPPSThJKoKPDJTPfrWh0EM4rCOoFjrybbdtJwrPeHuDWmJyLO_tpRgR92Lw2DBJQX5n5V5Egup2Mmo_maxfSHBW0XyhGIfGFhV5N4p7gXabVPS_0SySW4UC3gpI0zW9CuunuXFeGTBoswBl0s5t60GMGAOf456icekocwuPn-NigWn7g6_Tea_7qN0sTPfXMJELIT38ui3GkA; mboxEdgeCluster=35; s_sq=ldschurchofjesuschristtemp%3D%2526c.%2526a.%2526activitymap.%2526page%253Dhttps%25253A%25252F%25252Fdirectory.churchofjesuschrist.org%25252F13730%2526link%253DLeader%252520and%252520Clerk%252520Resources%2526region%253DprefBoxLinks%2526.activitymap%2526.a%2526.c%2526pid%253Dhttps%25253A%25252F%25252Fdirectory.churchofjesuschrist.org%25252F13730%2526oid%253Dhttps%25253A%25252F%25252Flcr.churchofjesuschrist.org%25252F%25253Flang%25253Deng%2526ot%253DA; facade=authenticated_user%23b17423e7; ADRUM_BTa=R:42|g:086cb7bf-11aa-4302-845e-f65acf2cbf9e|n:customer1_acb14d98-cf8b-4f6d-8860-1c1af7831070; ADRUM_BT1=R:42|i:22765|e:558|d:46; TS0186bb65=01999b70231e8a7a898a07f5cbf2e7d0f83deac22fc970d305f2828b2daacbb0945083665736ef03505e2febb2fc38ead3dd38c2db; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=-637568504%7CMCIDTS%7C18604%7CMCMID%7C48999871123819039183592053418035371457%7CMCAAMLH-1608004270%7C9%7CMCAAMB-1608004270%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1607406670s%7CNONE%7CvVersion%7C5.1.1%7CMCAID%7CNONE%7CMCSYNCSOP%7C411-18605; mbox=PC#f2d8761633bd4be987e53a94405dfc07.35_0#1670644271|session#bf8e5a08681d40d78ef8ed50f11fd00a#1607401304; t_ppv=undefined%2C0%2C100%2C1114%2C2977; utag_main=v_id:01754bd5f9ab003473ced2ad980803078006607001788$_sn:60$_ss:0$_st:1607401270702$dc_visit:60$vapi_domain:churchofjesuschrist.org$ses_id:1607399443790%3Bexp-session$_pn:3%3Bexp-session$dc_event:5%3Bexp-session$dc_region:us-east-1%3Bexp-session' --compressed  > "$filename"

sleep 2

  # photo_exists "$filename"
  # if [ $? != 0 ]; then
  #   echo "Unable to download photo for $scope, $uuid, $filename; applying placeholder"
  #   cp profile-placeholder.png "$filename"
  # fi

  return 0
}

apply_placeholder () {
  for file in $(ls ./photos -1 | xargs); do
    filename="photos/$file"
    photo_exists "$filename" ignore,placeholders
    retVal="$?"
    echo "retVal: $retVal"
    if [ "$retVal" != "0" ]; then
      echo "missing photo for $filename; copying placeholder"
      cp profile-placeholder.png "$filename"
    fi
  done
  return 0
}

download_missing_photos () {
  local scope="$1"
  local uuid="$2"
  local name="$3"
  local apply_thumbnails="$4"
  local filename="photos/$3.png"

  # photo_exists "$filename" ignore,placeholders,emptyfile,filenotexist
  photo_exists "$filename" ignore,placeholders,emptyfile
  retVal="$?"
  echo "retVal: $retVal"
  if [ "$retVal" != "0" ]; then
    echo "missing photo for $filename ($uuid); attempting to download again"
    fetch_photo "$scope" "$uuid" "$name" "$apply_thumbnails"
  fi
  return 0
}

all_elders () {
  for data in $(echo "$eldersData" | perl -p -e "s#'##g" | jq -r '. | map(.uuid + ":" + (.name | gsub("[., -]+"; "-") | ascii_downcase)) | join("\n")'); do
    name=$(echo "${data#*:}" | xargs)
    uuid=$(echo "${data%:*}" | xargs)
    fetch_photo members "$uuid" "$name" false
  done
}

all_families () {
  for data in $(echo "$eldersData" | perl -p -e "s#'##g" | jq -r '. | map(.householdUuid + ":" + (.name | gsub("[., -]+"; "-") | ascii_downcase + "-family")) | join("\n")'); do
    name=$(echo "${data#*:}" | xargs)
    uuid=$(echo "${data%:*}" | xargs)
    echo "$uuid" "$name"
    fetch_photo households "$uuid" "$name" false
  done
}

retry_elders () {
  for data in $(echo "$eldersData" | perl -p -e "s#'##g" | jq -r '. | map(.uuid + ":" + (.name | gsub("[., -]+"; "-") | ascii_downcase)) | join("\n")'); do
    name=$(echo "${data#*:}" | xargs)
    uuid=$(echo "${data%:*}" | xargs)
    download_missing_photos members "$uuid" "$name" false
  done
}

retry_families () {
  for data in $(echo "$eldersData" | perl -p -e "s#'##g" | jq -r '. | map(.householdUuid + ":" + (.name | gsub("[., -]+"; "-") | ascii_downcase + "-family")) | join("\n")'); do
    name=$(echo "${data#*:}" | xargs)
    uuid=$(echo "${data%:*}" | xargs)
    download_missing_photos households "$uuid" "$name" false
  done
}

# fetch_photo members 33e0da38-3af9-4ecc-bbef-8a0d2ee10787 tucker-jared-lee false
# fetch_photo members 00aa57bf-adc6-448c-a594-df5f25085231 rees-dallan-family false
# fetch_photo members d15eee46-d054-4247-abe4-e7d1dcf4ccf9 janson-tyler-family false

retry_elders
retry_families
apply_placeholder
