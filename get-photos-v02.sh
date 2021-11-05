#!/bin/bash

function loadCookies() {
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

echo "Load these cookies? (Enter=yes; Ctrl-C=no)"
read cont
}

# s/Church-auth-jwt-prod[^;]*;/Church-auth-jwt-prod='"${ChurchAuthJwtProd}"';/gc

echo "Get copy of LCR curl; paste in ./cookies.txt"
read cont
loadCookies

echo "fetching elder data"

# eldersData=$(jq -n 'inputs | {"object": . , "filename": input_filename, "lineNumber": input_line_number}' directory.json members-with-callings.json eq-cleaned.json | jq -ns 'inputs' | jq '. as $all | $all | map(select(.filename == "eq-cleaned.json"))[0].object | map(.name) as $targetMembers | $all | map(select(.filename == "directory.json"))[0].object | map(. as $household | .members | map(select([.name] as $targetMember | $targetMembers | contains($targetMember))) | map({name, id, district: ($household | .district), address: $household.address, email, phone})[0]) as $elderDetails | $elderDetails | map(select(.id != null) | .id) as $ids | $all | map(select(.filename == "directory.json"))[0].object | map(.members | map(. as $targetMember | $targetMember | select($ids | contains([$targetMember | .id])))) | flatten | map({id, householdUuid, name, district: (.name as $mName | $elderDetails | map(select(.name == $mName))[0].district)})')

eldersData=$(cat eq-cleaned.json | jq 'map({id, name, district})')

  # {
  #   "id": "5d17243a-d98e-4e7f-a1e1-7ba20e1e430a",
  #   "name": "Woolf, Kasey",
  #   "district": "01-alloy-m"
  # }

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

fetch_photo_using_tokenurl () {

  local id="$1"
  local filename="$2"
  local imageTokenUrl="$3"

  chkPhotoExists=$(echo "$imageTokenUrl" | perl -n -e ' print if m/nophoto|nohousehold/')

  if [[ "$chkPhotoExists" != "" ]]; then
    echo "Photo does not seem to exist; id: $id, token: $imageTokenUrl; applying a profile placeholder..."
    cp profile-placeholder.png "$filename"
    return
  fi
  
  # echo "fetching image for $imageTokenUrl > $filename =" ''"${imageTokenUrl}"'/MEDIUM'
  echo "fetching image for $id, $imageTokenUrl > $filename"
curl ''"${imageTokenUrl}"'/MEDIUM' \
  -H 'Connection: keep-alive' \
  -H 'Cache-Control: max-age=0' \
  -H 'sec-ch-ua: " Not;A Brand";v="99", "Google Chrome";v="91", "Chromium";v="91"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'Sec-Fetch-Site: same-site' \
  -H 'Sec-Fetch-Mode: navigate' \
  -H 'Sec-Fetch-User: ?1' \
  -H 'Sec-Fetch-Dest: document' \
  -H 'Referer: https://lcr.churchofjesuschrist.org/' \
  -H 'Accept-Language: en-US' \
  -H 'Cookie: ChurchSSO='"${ChurchSSO}"'' \
  --compressed > "$filename"

sleep 2
}

fetch_individual_photo () {
  local id="$1"
  local filename="$2"

  echo "fetching image token for $id > imageTokenUrl =" 'https://lcr.churchofjesuschrist.org/services/photos/manage-photos/approved-image-individual/'"${id}"'?lang=eng'
payload=$(curl 'https://lcr.churchofjesuschrist.org/services/photos/manage-photos/approved-image-individual/'"${id}"'?lang=eng' \
  -H 'Connection: keep-alive' \
  -H 'Pragma: no-cache' \
  -H 'Cache-Control: no-cache' \
  -H 'sec-ch-ua: "Google Chrome";v="95", "Chromium";v="95", ";Not A Brand";v="99"' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Referer: https://lcr.churchofjesuschrist.org/records/member-profile/3676616600?lang=eng&unitNumber=13730' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Cookie: ChurchSSO='"${ChurchSSO}"'' \
  --compressed)

# echo "image token payload: $payload"
imageTokenUrl=$(echo "$payload" | jq -r '.image.tokenUrl')

# sleep 1

fetch_photo_using_tokenurl "$id" "$filename" "$imageTokenUrl"

}

fetch_household_photo () {
  local id="$1"
  local filename="$2"

  echo "fetching image token for $id > imageTokenUrl =" 'https://lcr.churchofjesuschrist.org/services/photos/manage-photos/approved-image-household/'"${id}"'?lang=eng&type=HOUSEHOLD'
imageTokenUrl=$(curl 'https://lcr.churchofjesuschrist.org/services/photos/manage-photos/approved-image-household/'"${id}"'?lang=eng&type=HOUSEHOLD' \
  -H 'Connection: keep-alive' \
  -H 'sec-ch-ua: " Not;A Brand";v="99", "Google Chrome";v="91", "Chromium";v="91"' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Referer: https://lcr.churchofjesuschrist.org/records/member-profile/'"${id}"'?lang=eng' \
  -H 'Accept-Language: en-US' \
  -H 'Cookie: ChurchSSO='"${ChurchSSO}"'' \
  --compressed | jq -r '.image.tokenUrl')

# sleep 1

  fetch_photo_using_tokenurl "$id" "$filename" "$imageTokenUrl"
}

fetch_photo () {
  local scope="$1"
  local id="$2"
  local filename="photos/$3.png"

  #if [ -e "$filename" ]; then
  #  return 1
  #fi

  # echo "fetching image for $scope, $id > $filename"
  
  if [ "$scope" == "members" ]; then
      fetch_individual_photo "$id" "$filename"
  fi

  if [ "$scope" == "households" ]; then
      fetch_household_photo "$id" "$filename"
  fi

  # photo_exists "$filename"
  # if [ $? != 0 ]; then
  #   echo "Unable to download photo for $scope, $uuid, $filename; applying placeholder"
  #   cp profile-placeholder.png "$filename"
  # fi

  return 0
}

apply_placeholder () {
  echo
  echo "Applying placeholders for elders and families without photos..."
  for file in $(ls -1 ./photos | xargs); do
    filename="photos/$file"
    photo_exists "$filename" ignore,placeholders
    retVal="$?"
    # echo "retVal: $retVal"
    printf "."
    if [ "$retVal" != "0" ]; then
      echo "missing photo for $filename; copying placeholder"
      cp profile-placeholder.png "$filename"
    fi
  done
  return 0
}

download_missing_photos () {
  local scope="$1"
  local id="$2"
  local name="$3"
  local apply_thumbnails="$4"
  local filename="photos/$3.png"

  # photo_exists "$filename" ignore,placeholders,emptyfile,filenotexist
  photo_exists "$filename" ignore,placeholders,emptyfile
  retVal="$?"
  # echo "retVal: $retVal"
  printf "."
  if [ "$retVal" != "0" ]; then
    echo "missing photo for $filename ($id); attempting to download again"
    fetch_photo "$scope" "$id" "$name" "$apply_thumbnails"
  fi
  return 0
}

all_elders () {
  for data in $(echo "$eldersData" | perl -p -e "s#'##g" | jq -r '. | map((.id | tostring) + ":" + (.name | gsub("[., -]+"; "-") | ascii_downcase)) | join("\n")'); do
    name=$(echo "${data#*:}" | xargs)
    id=$(echo "${data%:*}" | xargs)
    fetch_photo members "$id" "$name" false
  done
}

all_families () {
  for data in $(echo "$eldersData" | perl -p -e "s#'##g" | jq -r '. | map((.id | tostring) + ":" + (.name | gsub("[., -]+"; "-") | ascii_downcase + "-family")) | join("\n")'); do
    name=$(echo "${data#*:}" | xargs)
    id=$(echo "${data%:*}" | xargs)
    echo "$id" "$name"
    fetch_photo households "$id" "$name" false
  done
}

retry_elders () {
  echo
  echo "Retry getting photos for elders..."
  for data in $(echo "$eldersData" | perl -p -e "s#'##g" | jq -r '. | map((.id | tostring) + ":" + (.name | gsub("[., -]+"; "-") | ascii_downcase)) | join("\n")'); do
    name=$(echo "${data#*:}" | xargs)
    id=$(echo "${data%:*}" | xargs)
    # echo "name: ${name}, id: ${id}"
    download_missing_photos members "$id" "$name" false
  done
}

retry_families () {
  echo
  echo "Retry getting photos for elder families..."
  for data in $(echo "$eldersData" | perl -p -e "s#'##g" | jq -r '. | map((.id | tostring) + ":" + (.name | gsub("[., -]+"; "-") | ascii_downcase + "-family")) | join("\n")'); do
    name=$(echo "${data#*:}" | xargs)
    id=$(echo "${data%:*}" | xargs)
    download_missing_photos households "$id" "$name" false
  done
}

# fetch_photo members 3694966261 lastname-firstname false
# fetch_photo households 3694966261 lastname-firstname-family false

# fetch_photo households 9788020985 farmer-kade-family
fetch_photo households 43938146779 burmer-tom-family

# retry_elders
# retry_families
# apply_placeholder

# filename="photos/burmer-tom.png"
# photo_exists "$filename" ignore,placeholders
#     retVal="$?"
#     echo "retVal: $retVal"
#     if [ "$retVal" != "0" ]; then
#       echo "missing photo for $filename; copying placeholder"
#       cp profile-placeholder.png "$filename"
#     fi

