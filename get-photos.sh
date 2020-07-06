#!/bin/bash

lines=$(cat cookie.txt | perl -p -e 's# #\n#g' | grep 'ChurchSSO\|Church-auth-jwt-prod\|directory_access_token\|directory_refresh_token')
authorization_token=$(cat cookie.txt | perl -p -e 's#^.*authorization: Bearer ([^'"'"']*).*#\1#g')
refresh_token=$(cat cookie.txt | perl -p -e 's#^.*-H '"'"'x-refresh: ([^'"'"']*).*#\1#g')
#ChurchSSO=$(echo $lines | perl -p -e 's#^.*ChurchSSO=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
ChurchSSO=$(echo $lines | sed '/ChurchSSO=/!d' | perl -p -e 's#^.*ChurchSSO=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
ChurchAuthJwtProd=$(echo $lines | sed '/Church-auth-jwt-prod=/!d' | perl -p -e 's#^.*Church-auth-jwt-prod=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
# directory_access_token=$(echo $lines | perl -p -e 's#^.*directory_access_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
directory_access_token=$(echo $lines | sed '/directory_access_token=/!d' | perl -p -e 's#^.*directory_access_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
# directory_refresh_token=$(echo $lines | perl -p -e 's#^.*directory_refresh_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
directory_refresh_token=$(echo $lines | sed '/directory_refresh_token=/!d' | perl -p -e 's#^.*directory_refresh_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')

# echo "authorization_token=\"${authorization_token}\""
# echo "refresh_token=\"${refresh_token}\""
echo "ChurchSSO=\"${ChurchSSO}\""
echo "ChurchAuthJwtProd=\"${ChurchAuthJwtProd}\""
echo "directory_access_token=\"${directory_access_token}\""
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

curl 'https://directory.churchofjesuschrist.org/api/v4/photos/'"${scope}"'/'"${uuid}"'?thumbnail='"${apply_thumbnails}"'' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36' -H 'Sec-Fetch-User: ?1' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' -H 'Sec-Fetch-Site: none' -H 'Sec-Fetch-Mode: navigate' -H 'Referer: https://directory.churchofjesuschrist.org/api/v4/photos/'"${scope}"'/'"${uuid}"'' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US' -H $'Cookie: audience_split=21; _fbp=fb.1.1558727984750.576138409; WRUIDCD=1979799963828235; lds-preferred-lang-v2=eng; s_fid=10C2A7BB8E217B78-195A92D72803F241; _ga=GA1.2.1976242211.1564161692; _cs_c=1; _cs_ex=1; aam_sc=aamsc%3D751537%7C708195; aam_uuid=58837750016941287141775247194571768784; amlbcookie-int=01; ORIG_URL=/sso?realm=/church&service=OktaOIDC&goto=https%3A%2F%2Frecovery-test.churchofjesuschrist.org%3A443%2Fagent%2Fcustom-login-response%3Fstate%3D816bf7c0-bd29-83ba-527c-9961f7b430d5%26realm%3D%252Fchurch%26service%3DOktaOIDC&original_request_url=https%3A%2F%2Frecovery-test.churchofjesuschrist.org%3A443%2F&authIndexType=service&authIndexValue=OktaOIDC; NTID=mCZIerHXQoW74H0AxNi5IkA8FHLSCk8w; OAUTH_LOGOUT_URL=; ChurchSSO-int=gSBvaYM8bzrBTSe3a4s52vUDSi0.*AAJTSQACMDIAAlNLABxzcXhVUDRFcjFXaVlOQ1FvZVNSZGhUcS9sNFE9AAR0eXBlAANDVFMAAlMxAAIwMQ..*; Church-auth-jwt-int=eyJ0eXAiOiJKV1QiLCJraWQiOiJrVlR5NDVhb0JoUnVBcWJ2MnQwbWU2NVpIMEk9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiJlNGM0N2IyMy00NjYyLTQ3ODUtOGIwNi01NDE3ODU4MmY2YWItMTA4MjM2NyIsImlzcyI6Imh0dHBzOi8vaWRlbnQtaW50LmNodXJjaG9mamVzdXNjaHJpc3Qub3JnL3Nzby9vYXV0aDIiLCJ0b2tlbk5hbWUiOiJpZF90b2tlbiIsIm5vbmNlIjoiRjM1NzJCQjBEMEM3QTM3QjkxODM1QUNBMzQwREI2MkEiLCJhdWQiOiJsMTgwMjYiLCJhY3IiOiIwIiwic19oYXNoIjoid2Zwa1N0ZXBkWG9SSHJUSTFJMjFodyIsImF6cCI6ImwxODAyNiIsImF1dGhfdGltZSI6MTU4MTExMzc2NCwiZm9yZ2Vyb2NrIjp7InNzb3Rva2VuIjoiZ1NCdmFZTThienJCVFNlM2E0czUydlVEU2kwLipBQUpUU1FBQ01ESUFBbE5MQUJ4emNYaFZVRFJGY2pGWGFWbE9RMUZ2WlZOU1pHaFVjUzlzTkZFOUFBUjBlWEJsQUFORFZGTUFBbE14QUFJd01RLi4qIiwic3VpZCI6ImUzODljZWEwLTJlNDgtNGRlNi1hMTk2LWY4MTVlMzIwOTg2ZC0xMTQ5NzQyIn0sInJlYWxtIjoiL2NodXJjaCIsImV4cCI6MTU4MTE1Njk2NCwidG9rZW5UeXBlIjoiSldUVG9rZW4iLCJpYXQiOjE1ODExMTM3NjQsImFnZW50X3JlYWxtIjoiL2NodXJjaCJ9.Noaz_JG8xz2xavp5Q8pRuPktedVQgFf21fRyDVLWyQvqd8MGiohsrr8AXVPKQZrcbQieH0OzHqDzpRqv_9PJ7lLOeqc6SYaOrmzU3cj-JBUP1hAeEB3Vwsb-0d6YFv0-Z4cvuJIbPQXSuj2ku6NRQRF5V95xtQMVloKYzGRe_HNRG4NG7D9ud5fryq7YlQsqQe5NKoo6sJ1A2hjiUjt4own4tBqvuA_HCPWExvnHJ1uGcro-0Gxm6AsFQoHuVj_zjvMHILHddgAZb2xq_i8K8HDqlHNycf7eKSMpnoP5M3yYrIEZq9X4vPf2_bNmpzigv_KKCarg0QTs_Ass9RT1rQ; check=true; audience_s_split=64; s_cc=true; _CT_RS_=Recording; __CT_Data=gpv=80&ckp=tld&dm=churchofjesuschrist.org&apv_59_www11=81&cpv_59_www11=80&rpv_59_www11=80; ADRUM=s=1581303202963&r=https%3A%2F%2Fwww.churchofjesuschrist.org%2F%3F479231918; ctm={\'pgv\':1350636977909173|\'vst\':7385663247553829|\'vstr\':5589777858429154|\'intr\':1581303204375|\'v\':1|\'lvst\':40257}; RT="z=1&dm=churchofjesuschrist.org&si=4b6bde0e-30a3-4c02-a935-10ee036a655a&ss=k6fv39vp&sl=1&tt=3xk&bcn=%2F%2F17c8edca.akstat.io%2F&ld=3xv&nu=265aa681196d3099ae5db03a5201bc77&cl=aem&ul=af3&hd=chh"; TS01b07831=01999b702368a61c83c814648324cf1d39b577e9f29e339971a112868a38dfb670410b394611b9f686b1f98ef296160de0bfc66d0e; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; ChurchSSO='"${ChurchSSO}"'; Church-auth-jwt-prod='"${ChurchAuthJwtProd}"'; TS0186bb65=01999b7023284f1d056b3030a4b06366f52919db1d6bf8244d914d8a8baf026c4b6419fc9c04d11c686fe4784ecf5ba98c4aa17cbe; directory_access_token='"${directory_access_token}"'; directory_refresh_token='"${directory_refresh_token}"'; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=-330454231%7CMCIDTS%7C18303%7CMCMID%7C45993473060174549671353300097144335983%7CMCAAMLH-1581910689%7C9%7CMCAAMB-1581910689%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1581313089s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C3.1.2; mbox=PC#ff77b07984e6447e8ca81967c1376f11.28_0#1644550691|session#2d8bd0374b7147cb86c3b15127f8eca8#1581305965; mboxEdgeCluster=28; s_sq=ldsall%3D%2526pid%253DWard%252520Directory%252520and%252520Map%2526pidt%253D1%2526oid%253Dfunctionbr%252528%252529%25257B%25257D%2526oidt%253D2%2526ot%253DA; utag_main=v_id:016aeb6d84c7000c9febf6d43f4003079007407101788$_sn:243$_ss:0$_st:1581307701381$vapi_domain:churchofjesuschrist.org$dc_visit:243$_se:3$ses_id:1581303192943%3Bexp-session$_pn:11%3Bexp-session$dc_event:29%3Bexp-session$dc_region:us-east-1%3Bexp-session; t_ppv=Ward%20Directory%20and%20Map%2C100%2C100%2C1114%2C16760; ADRUM_BTa=R:95|g:fe329695-1cde-432f-ad7c-ed8cb4e068ed|n:customer1_acb14d98-cf8b-4f6d-8860-1c1af7831070; ADRUM_BT1=R:95|i:22765|e:1093|d:444' --compressed  > "$filename"

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
