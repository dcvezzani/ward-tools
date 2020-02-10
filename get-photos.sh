#!/bin/bash

lines=$(cat cookie.txt | perl -p -e 's# #\n#g' | grep 'ChurchSSO\|directory_access_token\|directory_refresh_token')
authorization_token=$(cat cookie.txt | perl -p -e 's#^.*authorization: Bearer ([^'"'"']*).*#\1#g')
refresh_token=$(cat cookie.txt | perl -p -e 's#^.*-H '"'"'x-refresh: ([^'"'"']*).*#\1#g')
#ChurchSSO=$(echo $lines | perl -p -e 's#^.*ChurchSSO=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
ChurchSSO=$(echo $lines | sed '/ChurchSSO=/!d' | perl -p -e 's#^.*ChurchSSO=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
# directory_access_token=$(echo $lines | perl -p -e 's#^.*directory_access_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
directory_access_token=$(echo $lines | sed '/directory_access_token=/!d' | perl -p -e 's#^.*directory_access_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
# directory_refresh_token=$(echo $lines | perl -p -e 's#^.*directory_refresh_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
directory_refresh_token=$(echo $lines | sed '/directory_refresh_token=/!d' | perl -p -e 's#^.*directory_refresh_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')

echo "authorization_token=\"${authorization_token}\""
echo "refresh_token=\"${refresh_token}\""
echo "ChurchSSO=\"${ChurchSSO}\""
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

# curl 'https://directory.churchofjesuschrist.org/api/v4/photos/'"${scope}"'/'"${uuid}"'?thumbnail='"${apply_thumbnails}"'' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.87 Safari/537.36' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-User: ?1' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Sec-Fetch-Site: none' -H 'Referer: https://ident.churchofjesuschrist.org/sso/UI/Login?realm=%2Fchurch&service=credentials&goto=https%3A%2F%2Fident.churchofjesuschrist.org%2Fsso%2Foauth2%2Fauthorize%3Fresponse_type%3Dcode%26redirect_uri%3Dhttps%253A%252F%252Fdirectory.churchofjesuschrist.org%252Flogin%26scope%3Dopenid%2520profile%26client_id%3DpJq1za99TNpQEp2x%26acr_values%3D200' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.9' -H $'Cookie: audience_split=21; _fbp=fb.1.1558727984750.576138409; WRUIDCD=1979799963828235; lds-preferred-lang-v2=eng; __CT_Data=gpv=18&ckp=tld&dm=churchofjesuschrist.org&apv_59_www11=19&cpv_59_www11=18&rpv_59_www11=18; ctm={\'pgv\':74967302419333|\'vst\':2542134181393777|\'vstr\':5589777858429154|\'intr\':1563820041606|\'v\':1|\'lvst\':304}; s_fid=10C2A7BB8E217B78-195A92D72803F241; _gcl_au=1.1.1161084623.1564161692; _ga=GA1.2.1976242211.1564161692; check=true; TS01b07831=01999b7023c71f1fcbeee5b7e9f36b7e495ab2d50362ac5c86a92081c79bf13d24993c1ba84cba1872b2094bf981ccc985e78737cc; audience_s_split=19; s_cc=true; TS011e50d7=01999b70239ad4936aae6a27f8fc2534ed10a9fcf756674f8faa9bd8bf281130f95734d06dc71f7f651922e434c0595ea3ec9cc549; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; s_sq=ldsall%3D%2526pid%253DWard%252520Directory%252520and%252520Map%2526pidt%253D1%2526oid%253Dhttps%25253A%25252F%25252Fdirectory.churchofjesuschrist.org%25252F13730%25252Fmembers%25252Fe64f8d40-0e12-4c6f-b50f-734b9ec64abf%2526ot%253DA; utag_main=v_id:016aeb6d84c7000c9febf6d43f4003079007407101788$_sn:95$_ss:0$_st:1566165035382$vapi_domain:churchofjesuschrist.org$dc_visit:95$_se:14$ses_id:1566161821505%3Bexp-session$_pn:3%3Bexp-session$dc_event:11%3Bexp-session$dc_region:us-east-1%3Bexp-session; mbox=PC#ff77b07984e6447e8ca81967c1376f11.28_19#1573944111|check#true#1566168171|session#1d138ce409f34be396eb5d4bfe3dbcab#1566169971; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=-227196251%7CMCIDTS%7C18127%7CMCMID%7C45993473060174549671353300097144335983%7CMCAAMLH-1566772910%7C9%7CMCAAMB-1566772910%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1566175310s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C3.1.2; TS01a096ec=01999b70239d48544a2580fdbc2aa08351787291802d97d40e36e17fc5e752f0f2e3cad70bb1d85249389faa3f07ac1339c1ad81f6; amlbcookie=75; t_ppv=Ward%20Directory%20and%20Map%2C100%2C100%2C836%2C17501448; TS0186bb65=01999b702318d027d5675eb0aecda473765aadc356766d6875ccfe9004c8364a0c412fb21ab95530281f2f0a37f9f1c89065459e56; ObSSOCookie='"${ObSSOCookie}"'; TS01289383=01999b70233e11290324e6a99fefece5cc28bde24ea69e9c74621f4a5a939985c80de58ac39452e46e10aa8e9386090fce6a381cb6; TS01b89640=01999b70233e11290324e6a99fefece5cc28bde24ea69e9c74621f4a5a939985c80de58ac39452e46e10aa8e9386090fce6a381cb6; lds-id=AQIC5wM2LY4Sfcy6Ofh_Xb8gtWD8v9Yqfm43UhjtuytG6Fk.*AAJTSQACMDIAAlNLABM4NDc5MjA1NDM5MzM4NzAzODI0AAJTMQACMDU.*; directory_access_token='"${directory_access_token}"'; directory_refresh_token='"${directory_refresh_token}" --compressed > "$filename"

# scope='members'
# uuid='ac47b0b6-8826-4712-bcb9-129972a5b844'
# apply_thumbnails='true'

# scope='members'
# uuid='e5545004-4ce1-4717-8cc2-eb52580c74a3'
# apply_thumbnails='true'

# curl 'https://directory.churchofjesuschrist.org/api/v4/photos/'"${scope}"'/'"${uuid}"'?thumbnail='"${apply_thumbnails}"'' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36' -H 'Accept: image/webp,image/apng,image/*,*/*;q=0.8' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-Mode: no-cors' -H 'Referer: https://directory.churchofjesuschrist.org/13730/households/8193d5f0-2363-4467-90cf-1ca1ea7428d0' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US' -H $'Cookie: audience_split=21; _fbp=fb.1.1558727984750.576138409; WRUIDCD=1979799963828235; lds-preferred-lang-v2=eng; s_fid=10C2A7BB8E217B78-195A92D72803F241; _ga=GA1.2.1976242211.1564161692; _cs_c=1; _cs_ex=1; aam_uuid=58837750016941287141775247194571768784; _CT_RS_=Recording; aam_sc=aamsc%3D751537%7C708195; __CT_Data=gpv=79&ckp=tld&dm=churchofjesuschrist.org&apv_59_www11=80&cpv_59_www11=79&rpv_59_www11=79; ctm={\'pgv\':1671447134779311|\'vst\':4659397996010721|\'vstr\':5589777858429154|\'intr\':1578887788899|\'v\':1|\'lvst\':21497}; ChurchSSO-int=wzBgxCgubHc4co1L7nMvZSsKKe0.*AAJTSQACMDIAAlNLABxZc3R0TTVkbndaNys0NGtrTjcrV1pMWE9HMmM9AAR0eXBlAANDVFMAAlMxAAIwMQ..*; Church-auth-jwt-int=eyJ0eXAiOiJKV1QiLCJraWQiOiJrVlR5NDVhb0JoUnVBcWJ2MnQwbWU2NVpIMEk9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiJiZDg2ZDQ0MC1kOGQyLTRjYjMtOTc3ZS0wYTA4ZDZmMDk5MmItMTA0NDc1MTYiLCJpc3MiOiJodHRwczovL2lkZW50LWludC5jaHVyY2hvZmplc3VzY2hyaXN0Lm9yZy9zc28vb2F1dGgyIiwidG9rZW5OYW1lIjoiaWRfdG9rZW4iLCJub25jZSI6IkJFOTc3NTVENTQ2MUZGQ0JDNEY1ODEyQkU4QjkyN0U2IiwiYXVkIjoibDE4MDI3IiwiYWNyIjoiMCIsInNfaGFzaCI6Ilp5MzEtcGlpWGNSOUZ1VS0zaG9sT3ciLCJhenAiOiJsMTgwMjciLCJhdXRoX3RpbWUiOjE1Nzk2NDQxMTAsImZvcmdlcm9jayI6eyJzc290b2tlbiI6Ind6Qmd4Q2d1YkhjNGNvMUw3bk12WlNzS0tlMC4qQUFKVFNRQUNNRElBQWxOTEFCeFpjM1IwVFRWa2JuZGFOeXMwTkd0clRqY3JWMXBNV0U5SE1tTTlBQVIwZVhCbEFBTkRWRk1BQWxNeEFBSXdNUS4uKiIsInN1aWQiOiJmMzY1OGM3Mi1lMjgyLTRiY2YtOGUxMy0yZTcxZmU2MzhhYzktMTAzMzMyNjcifSwicmVhbG0iOiIvY2h1cmNoIiwiZXhwIjoxNTc5Njg3MzEwLCJ0b2tlblR5cGUiOiJKV1RUb2tlbiIsImlhdCI6MTU3OTY0NDExMCwiYWdlbnRfcmVhbG0iOiIvY2h1cmNoIn0.BiWwTjRX6BMZ4Nyeq3fX49DU36cxiYqkP9h0EKWqLY4x73TRatdZ4_rDhETFWxog75rWXtyCn21l84sw8ueP6GutKCgwHysJlFoBnpn2_BHPGsitdpDPo8AfrZSEEfnOvRVO6vPFUkD7WuxwTErfbZ-CNs_5Lm_JLonAY4CAP43St6gq-aeqK_cFZcsG4_ARbk2uX4BGZgYDXIHUxGZZZ6LWX7YuPBiSIWqYq9LsgNoTwgu2foHIf1Q_VQI7g0nY8HhJdt2UjHm312VaEk6aMZ3t3-Zyi_lOxVqsuOVyGHyqCSxTgL2lOeuNkMXvKi11_AHQhWr5IL-hIOwN4e7YCg; check=true; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; audience_s_split=74; s_cc=true; TS01b07831=01999b70239f8d3c15fe7bb56e832f735ecb59dfa3809782e3ecd3405397b369368c479be387201e3b1a950c11ac4ea94a3946e73b; ADRUM=s=1579825962969&r=https%3A%2F%2Fwww.churchofjesuschrist.org%2F%3F479231918; RT="z=1&dm=churchofjesuschrist.org&si=d35cd4ef-57f0-4ed4-8a5d-dec2214a0714&ss=k5rfk3p0&sl=2&tt=6bp&obo=1&bcn=%2F%2F173e2548.akstat.io%2F&ld=11hh&nu=08b89d78d40e90b8b126f7a10960d4e4&cl=12x9&ul=12xn&hd=13f1"; TS01a096ec=01999b7023f962af0b95544d7ea951d0dac619e2fcf70032c859dbad548e18bc6f59a1efa460369ab9d55d0b22c33e35ef2535e546; ChurchSSO='"${ChurchSSO}"'; Church-auth-jwt-prod=eyJ0eXAiOiJKV1QiLCJraWQiOiJDK2g4T1diR0IrMnV0L0xQQ0RlTEUwMXAzUjQ9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiIwNWFkMmEyZi04NTNiLTRkMzMtODYzZC1jZGRlODI5M2ZhMzctMzc2NjQ4NzYxIiwiaXNzIjoibnVsbDovL2lkZW50LXByb2QuY2h1cmNob2ZqZXN1c2NocmlzdC5vcmc6NDQzL3Nzby9vYXV0aDIiLCJ0b2tlbk5hbWUiOiJpZF90b2tlbiIsIm5vbmNlIjoiRjE0Rjg4RkI4M0JGOERERkUyREFDQjk2OUQyN0MzOUMiLCJhdWQiOiJsMTgzODUiLCJhY3IiOiIwIiwiYXpwIjoibDE4Mzg1IiwiYXV0aF90aW1lIjoxNTc5ODI2MDU0LCJmb3JnZXJvY2siOnsic3NvdG9rZW4iOiJoTXFQUWsyLVduQVByeFJSTHVrMGVqLW1zTXMuKkFBSlRTUUFDTURJQUFsTkxBQnhSZDJSQlVITXlNWG80U1Vaa2JsQmllRXhSU2tKaGVVNXJaMUU5QUFSMGVYQmxBQU5EVkZNQUFsTXhBQUl3TVEuLioiLCJzdWlkIjoiNzkwOTExNGEtZDE2Ny00NGY0LWJhZWQtNzIzMTNiM2M0OGJmLTM3MjU1MDIyOSJ9LCJyZWFsbSI6Ii9jaHVyY2giLCJleHAiOjE1Nzk4NjkyNTcsInRva2VuVHlwZSI6IkpXVFRva2VuIiwiaWF0IjoxNTc5ODI2MDU3LCJhZ2VudF9yZWFsbSI6Ii9jaHVyY2gifQ.KdZ_QVU5EbL241q2uxbrhqO2JQB8MRojb4NGQHJrN6HU6-HIhY5aSoMI5KMqrE4nhpmwe4dtIEe7lCrbiCLvbxCfgRcQZ4shelWT9NbkEwJlsLT_swSgLWRnq8xmnGZ9vslPxUSaI9hWDtjKuYfxyx7YSoYfBdk-z_lJ_Mw4BmQKm6dVJMl_mbHrm488HBY4sNdk64hlhZmsFepDLAYtAOHs6m9PtkMR0PFGwT63WlAjav-LJhMJnQ58kB6tCbZDgn_mbknNTQE1OMWVzcSyet4EDl-YKjR3wA3wvDzB43metAV1DvWyIDklO02VmlYQdeuASrMcSXzjoj9xzDgARA; directory_access_token='"${directory_access_token}"'; directory_refresh_token='"${directory_refresh_token}"'; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=-330454231%7CMCIDTS%7C18280%7CMCMID%7C45993473060174549671353300097144335983%7CMCAAMLH-1580434689%7C9%7CMCAAMB-1580434689%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1579837089s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C3.1.2; mboxEdgeCluster=28; TS0186bb65=01999b70238cc977f396b552ec0cf1981205323e818688446da1eaf9a3489237ac0b5a1df10cb62a971e41175c752904ba15622f07; mbox=PC#ff77b07984e6447e8ca81967c1376f11.28_0#1643075372|session#c2983b608c5f46c4875b95c6dfd7f5e3#1579831430; s_sq=%5B%5BB%5D%5D; utag_main=v_id:016aeb6d84c7000c9febf6d43f4003079007407101788$_sn:226$_ss:0$_st:1579832373045$vapi_domain:churchofjesuschrist.org$dc_visit:226$_se:3$ses_id:1579827934751%3Bexp-session$_pn:9%3Bexp-session$dc_event:24%3Bexp-session$dc_region:us-east-1%3Bexp-session; t_ppv=Ward%20Directory%20and%20Map%2C100%2C100%2C451%2C4209; ADRUM_BTa=R:95|g:35e6175a-2277-4c84-b457-1c4899dda9f1|n:customer1_acb14d98-cf8b-4f6d-8860-1c1af7831070; ADRUM_BT1=R:95|i:22764|e:424|d:3280' -H 'policy-cn: dcvezzani' -H 'lds-account-id: 1562cace-a0ad-4df9-a868-54f2bfe5f9cc' --compressed > "$filename"

curl 'https://directory.churchofjesuschrist.org/api/v4/photos/'"${scope}"'/'"${uuid}"'?thumbnail='"${apply_thumbnails}"'' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36' -H 'Sec-Fetch-User: ?1' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' -H 'Sec-Fetch-Site: none' -H 'Sec-Fetch-Mode: navigate' -H 'Referer: https://directory.churchofjesuschrist.org/13730/households/ce99854a-4a4a-4e48-b6e0-caef97bcff7b' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US' -H $'Cookie: audience_split=21; _fbp=fb.1.1558727984750.576138409; WRUIDCD=1979799963828235; lds-preferred-lang-v2=eng; s_fid=10C2A7BB8E217B78-195A92D72803F241; _ga=GA1.2.1976242211.1564161692; _cs_c=1; _cs_ex=1; aam_sc=aamsc%3D751537%7C708195; aam_uuid=58837750016941287141775247194571768784; amlbcookie-int=01; ORIG_URL=/sso?realm=/church&service=OktaOIDC&goto=https%3A%2F%2Frecovery-test.churchofjesuschrist.org%3A443%2Fagent%2Fcustom-login-response%3Fstate%3D816bf7c0-bd29-83ba-527c-9961f7b430d5%26realm%3D%252Fchurch%26service%3DOktaOIDC&original_request_url=https%3A%2F%2Frecovery-test.churchofjesuschrist.org%3A443%2F&authIndexType=service&authIndexValue=OktaOIDC; NTID=mCZIerHXQoW74H0AxNi5IkA8FHLSCk8w; OAUTH_LOGOUT_URL=; ChurchSSO-int=gSBvaYM8bzrBTSe3a4s52vUDSi0.*AAJTSQACMDIAAlNLABxzcXhVUDRFcjFXaVlOQ1FvZVNSZGhUcS9sNFE9AAR0eXBlAANDVFMAAlMxAAIwMQ..*; Church-auth-jwt-int=eyJ0eXAiOiJKV1QiLCJraWQiOiJrVlR5NDVhb0JoUnVBcWJ2MnQwbWU2NVpIMEk9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiJlNGM0N2IyMy00NjYyLTQ3ODUtOGIwNi01NDE3ODU4MmY2YWItMTA4MjM2NyIsImlzcyI6Imh0dHBzOi8vaWRlbnQtaW50LmNodXJjaG9mamVzdXNjaHJpc3Qub3JnL3Nzby9vYXV0aDIiLCJ0b2tlbk5hbWUiOiJpZF90b2tlbiIsIm5vbmNlIjoiRjM1NzJCQjBEMEM3QTM3QjkxODM1QUNBMzQwREI2MkEiLCJhdWQiOiJsMTgwMjYiLCJhY3IiOiIwIiwic19oYXNoIjoid2Zwa1N0ZXBkWG9SSHJUSTFJMjFodyIsImF6cCI6ImwxODAyNiIsImF1dGhfdGltZSI6MTU4MTExMzc2NCwiZm9yZ2Vyb2NrIjp7InNzb3Rva2VuIjoiZ1NCdmFZTThienJCVFNlM2E0czUydlVEU2kwLipBQUpUU1FBQ01ESUFBbE5MQUJ4emNYaFZVRFJGY2pGWGFWbE9RMUZ2WlZOU1pHaFVjUzlzTkZFOUFBUjBlWEJsQUFORFZGTUFBbE14QUFJd01RLi4qIiwic3VpZCI6ImUzODljZWEwLTJlNDgtNGRlNi1hMTk2LWY4MTVlMzIwOTg2ZC0xMTQ5NzQyIn0sInJlYWxtIjoiL2NodXJjaCIsImV4cCI6MTU4MTE1Njk2NCwidG9rZW5UeXBlIjoiSldUVG9rZW4iLCJpYXQiOjE1ODExMTM3NjQsImFnZW50X3JlYWxtIjoiL2NodXJjaCJ9.Noaz_JG8xz2xavp5Q8pRuPktedVQgFf21fRyDVLWyQvqd8MGiohsrr8AXVPKQZrcbQieH0OzHqDzpRqv_9PJ7lLOeqc6SYaOrmzU3cj-JBUP1hAeEB3Vwsb-0d6YFv0-Z4cvuJIbPQXSuj2ku6NRQRF5V95xtQMVloKYzGRe_HNRG4NG7D9ud5fryq7YlQsqQe5NKoo6sJ1A2hjiUjt4own4tBqvuA_HCPWExvnHJ1uGcro-0Gxm6AsFQoHuVj_zjvMHILHddgAZb2xq_i8K8HDqlHNycf7eKSMpnoP5M3yYrIEZq9X4vPf2_bNmpzigv_KKCarg0QTs_Ass9RT1rQ; check=true; audience_s_split=64; s_cc=true; _CT_RS_=Recording; __CT_Data=gpv=80&ckp=tld&dm=churchofjesuschrist.org&apv_59_www11=81&cpv_59_www11=80&rpv_59_www11=80; ADRUM=s=1581303202963&r=https%3A%2F%2Fwww.churchofjesuschrist.org%2F%3F479231918; ctm={\'pgv\':1350636977909173|\'vst\':7385663247553829|\'vstr\':5589777858429154|\'intr\':1581303204375|\'v\':1|\'lvst\':40257}; RT="z=1&dm=churchofjesuschrist.org&si=4b6bde0e-30a3-4c02-a935-10ee036a655a&ss=k6fv39vp&sl=1&tt=3xk&bcn=%2F%2F17c8edca.akstat.io%2F&ld=3xv&nu=265aa681196d3099ae5db03a5201bc77&cl=aem&ul=af3&hd=chh"; TS01b07831=01999b702368a61c83c814648324cf1d39b577e9f29e339971a112868a38dfb670410b394611b9f686b1f98ef296160de0bfc66d0e; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; ChurchSSO='"${ChurchSSO}"'; Church-auth-jwt-prod=eyJ0eXAiOiJKV1QiLCJraWQiOiJDK2g4T1diR0IrMnV0L0xQQ0RlTEUwMXAzUjQ9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiIxMDc3ZWM5MC0xODVkLTQ0MGQtODAxZS0zMGM1ZWZiNmYwNWMtMjE2NTI5NTUyIiwiaXNzIjoibnVsbDovL2lkZW50LXByb2QuY2h1cmNob2ZqZXN1c2NocmlzdC5vcmc6NDQzL3Nzby9vYXV0aDIiLCJ0b2tlbk5hbWUiOiJpZF90b2tlbiIsIm5vbmNlIjoiRTIzRUMxRDFDMEIyMzUxOUE2OTA5QjM4Q0FGQUZCNTkiLCJhdWQiOiJsMTgzODIiLCJhY3IiOiIwIiwiYXpwIjoibDE4MzgyIiwiYXV0aF90aW1lIjoxNTgxMzAzMjQxLCJmb3JnZXJvY2siOnsic3NvdG9rZW4iOiJHOFcxaENObWZkZThQQW5zb3JjM3l5OGJsemMuKkFBSlRTUUFDTURJQUFsTkxBQnhsYWk5RWVtTnFUbWR0Vm1sNFlsRTFNekZCVWxWUFdUQkhUbFU5QUFSMGVYQmxBQU5EVkZNQUFsTXhBQUl3TVEuLioiLCJzdWlkIjoiN2VhMWY4YzAtYjVkYy00MDBhLTg0OWEtZWYzZWZlZDdhZTNhLTU0NDk3MDcxMyJ9LCJyZWFsbSI6Ii9jaHVyY2giLCJleHAiOjE1ODEzNDY0NDIsInRva2VuVHlwZSI6IkpXVFRva2VuIiwiaWF0IjoxNTgxMzAzMjQyLCJhZ2VudF9yZWFsbSI6Ii9jaHVyY2gifQ.mQRId_nTAncB65XMlvzuzLiLQzF6arGm8qk41mtDlrRG_YdHMz_8fJwXLHjENzfL1VBAy_nuN9CXfpS_o0yBmW3Qwc7AJapSwJeBcL_bAMv9JJ_kvvZ7_v5UJvuxvNj6dK_iCF68Wc8D5MHxnqKTTNTM0IuBP27yB9Z4VoxB7gkQocYfdq-_xKqXoNWHdq6GRGAK_uX3wgxO8h-MSleDeDEtS1lOjH8TP6C-TBEdnyXMYF4LKBQ5thSiAxAUlAMF--Q8pxWB0yI5MEQyQ5jOpOI0I2yJRjNQmbMljfyS3kzphxaFYXGFjwH2tXaAmfFL4VNgCAhDDPp9tTFTYSNSxg; TS0186bb65=01999b7023284f1d056b3030a4b06366f52919db1d6bf8244d914d8a8baf026c4b6419fc9c04d11c686fe4784ecf5ba98c4aa17cbe; directory_access_token=75YLE-o9XC9z5NWKJVKHmRlPdjo; directory_refresh_token=ZcpRpxoVWj31O4-Rl-VeeVfDkE4; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=-330454231%7CMCIDTS%7C18303%7CMCMID%7C45993473060174549671353300097144335983%7CMCAAMLH-1581910689%7C9%7CMCAAMB-1581910689%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1581313089s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C3.1.2; mbox=PC#ff77b07984e6447e8ca81967c1376f11.28_0#1644550691|session#2d8bd0374b7147cb86c3b15127f8eca8#1581305965; mboxEdgeCluster=28; s_sq=ldsall%3D%2526pid%253DWard%252520Directory%252520and%252520Map%2526pidt%253D1%2526oid%253Dfunctionbr%252528%252529%25257B%25257D%2526oidt%253D2%2526ot%253DA; utag_main=v_id:016aeb6d84c7000c9febf6d43f4003079007407101788$_sn:243$_ss:0$_st:1581307701381$vapi_domain:churchofjesuschrist.org$dc_visit:243$_se:3$ses_id:1581303192943%3Bexp-session$_pn:11%3Bexp-session$dc_event:29%3Bexp-session$dc_region:us-east-1%3Bexp-session; t_ppv=Ward%20Directory%20and%20Map%2C100%2C100%2C1114%2C16760; ADRUM_BTa=R:95|g:fe329695-1cde-432f-ad7c-ed8cb4e068ed|n:customer1_acb14d98-cf8b-4f6d-8860-1c1af7831070; ADRUM_BT1=R:95|i:22765|e:1093|d:444' -H 'lds-account-id: 1562cace-a0ad-4df9-a868-54f2bfe5f9cc' --compressed  > "$filename"

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
