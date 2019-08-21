#!/bin/bash

lines=$(cat cookie.txt | perl -p -e 's# #\n#g' | grep 'ObSSOCookie\|directory_access_token\|directory_refresh_token')
authorization_token=$(cat cookie.txt | perl -p -e 's#^.*authorization: Bearer ([^'"'"']*).*#\1#g')
refresh_token=$(cat cookie.txt | perl -p -e 's#^.*-H '"'"'x-refresh: ([^'"'"']*).*#\1#g')
ObSSOCookie=$(echo $lines | perl -p -e 's#^.*ObSSOCookie=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
directory_access_token=$(echo $lines | perl -p -e 's#^.*directory_access_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
directory_refresh_token=$(echo $lines | perl -p -e 's#^.*directory_refresh_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')

echo "authorization_token=\"${authorization_token}\""
echo "refresh_token=\"${refresh_token}\""
echo "ObSSOCookie=\"${ObSSOCookie}\""
echo "directory_access_token=\"${directory_access_token}\""
echo "directory_refresh_token=\"${directory_refresh_token}\""

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
    bytes3=$(grep "timestamp" "$filename" | wc -c)
    return $(($bytes1+$bytes2+$bytes3))
  fi
}

fetch_photo () {
  local scope="$1"
  local uuid="$2"
  local filename="photos/$3.png"
  local apply_thumbnails="$4"

  if [ "$apply_thumbnails" == "" ]; then
      apply_thumbnails=true
  fi

  echo "fetching image for $uuid > $filename =" 'https://directory.churchofjesuschrist.org/api/v4/photos/'"${scope}"'/'"${uuid}"'?thumbnail='"${apply_thumbnails}"''

  curl 'https://directory.churchofjesuschrist.org/api/v4/photos/'"${scope}"'/'"${uuid}"'?thumbnail='"${apply_thumbnails}"'' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.87 Safari/537.36' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-User: ?1' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Sec-Fetch-Site: none' -H 'Referer: https://ident.churchofjesuschrist.org/sso/UI/Login?realm=%2Fchurch&service=credentials&goto=https%3A%2F%2Fident.churchofjesuschrist.org%2Fsso%2Foauth2%2Fauthorize%3Fresponse_type%3Dcode%26redirect_uri%3Dhttps%253A%252F%252Fdirectory.churchofjesuschrist.org%252Flogin%26scope%3Dopenid%2520profile%26client_id%3DpJq1za99TNpQEp2x%26acr_values%3D200' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.9' -H $'Cookie: audience_split=21; _fbp=fb.1.1558727984750.576138409; WRUIDCD=1979799963828235; lds-preferred-lang-v2=eng; __CT_Data=gpv=18&ckp=tld&dm=churchofjesuschrist.org&apv_59_www11=19&cpv_59_www11=18&rpv_59_www11=18; ctm={\'pgv\':74967302419333|\'vst\':2542134181393777|\'vstr\':5589777858429154|\'intr\':1563820041606|\'v\':1|\'lvst\':304}; s_fid=10C2A7BB8E217B78-195A92D72803F241; _gcl_au=1.1.1161084623.1564161692; _ga=GA1.2.1976242211.1564161692; check=true; TS01b07831=01999b7023c71f1fcbeee5b7e9f36b7e495ab2d50362ac5c86a92081c79bf13d24993c1ba84cba1872b2094bf981ccc985e78737cc; audience_s_split=19; s_cc=true; TS011e50d7=01999b70239ad4936aae6a27f8fc2534ed10a9fcf756674f8faa9bd8bf281130f95734d06dc71f7f651922e434c0595ea3ec9cc549; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; s_sq=ldsall%3D%2526pid%253DWard%252520Directory%252520and%252520Map%2526pidt%253D1%2526oid%253Dhttps%25253A%25252F%25252Fdirectory.churchofjesuschrist.org%25252F13730%25252Fmembers%25252Fe64f8d40-0e12-4c6f-b50f-734b9ec64abf%2526ot%253DA; utag_main=v_id:016aeb6d84c7000c9febf6d43f4003079007407101788$_sn:95$_ss:0$_st:1566165035382$vapi_domain:churchofjesuschrist.org$dc_visit:95$_se:14$ses_id:1566161821505%3Bexp-session$_pn:3%3Bexp-session$dc_event:11%3Bexp-session$dc_region:us-east-1%3Bexp-session; mbox=PC#ff77b07984e6447e8ca81967c1376f11.28_19#1573944111|check#true#1566168171|session#1d138ce409f34be396eb5d4bfe3dbcab#1566169971; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=-227196251%7CMCIDTS%7C18127%7CMCMID%7C45993473060174549671353300097144335983%7CMCAAMLH-1566772910%7C9%7CMCAAMB-1566772910%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1566175310s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C3.1.2; TS01a096ec=01999b70239d48544a2580fdbc2aa08351787291802d97d40e36e17fc5e752f0f2e3cad70bb1d85249389faa3f07ac1339c1ad81f6; amlbcookie=75; t_ppv=Ward%20Directory%20and%20Map%2C100%2C100%2C836%2C17501448; TS0186bb65=01999b702318d027d5675eb0aecda473765aadc356766d6875ccfe9004c8364a0c412fb21ab95530281f2f0a37f9f1c89065459e56; ObSSOCookie='"${ObSSOCookie}"'; TS01289383=01999b70233e11290324e6a99fefece5cc28bde24ea69e9c74621f4a5a939985c80de58ac39452e46e10aa8e9386090fce6a381cb6; TS01b89640=01999b70233e11290324e6a99fefece5cc28bde24ea69e9c74621f4a5a939985c80de58ac39452e46e10aa8e9386090fce6a381cb6; lds-id=AQIC5wM2LY4Sfcy6Ofh_Xb8gtWD8v9Yqfm43UhjtuytG6Fk.*AAJTSQACMDIAAlNLABM4NDc5MjA1NDM5MzM4NzAzODI0AAJTMQACMDU.*; directory_access_token='"${directory_access_token}"'; directory_refresh_token='"${directory_refresh_token}" --compressed > "$filename"
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

  photo_exists "$filename" ignore,placeholders,emptyfile,filenotexist
  retVal="$?"
  echo "retVal: $retVal"
  if [ "$retVal" != "0" ]; then
    echo "missing photo for $filename; attempting to download again"
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

# apply_placeholder
