# =======================
function dividerLine {
echo "________________________________"
}

# =======================
function generateReport {
dividerLine
echo "crunching report data"
yarn start

cat ministering-assignments-print-out.json | jq '. | map(select(.districtName == "district-01"))[0] | .companionships | map(.ministers) | flatten' > ministering-assignments-district-01.json
cat ministering-assignments-print-out.json | jq '. | map(select(.districtName == "district-02"))[0] | .companionships | map(.ministers) | flatten' > ministering-assignments-district-02.json
cat ministering-assignments-print-out.json | jq '. | map(select(.districtName == "district-03"))[0] | .companionships | map(.ministers) | flatten' > ministering-assignments-district-03.json

echo "generating report"

cat report.json | jq '.' > report-final.json
sleep 2

echo "generating summary"

# cat report-final.json| jq '.by_district | to_entries | map({key, value: (.value | map({ name, age: .actualAge }))}) | from_entries' > report-summary.json
cat report-final.json| jq --sort-keys '{ministering_brothers: .ministering_brothers.by_district | to_entries | map({key, value: (.value | map(.name + " (" + (.actualAge | tostring) + ")") | sort)}) | from_entries, ministering_families: .ministering_families.by_district | to_entries | map({key, value: (.value | map(.name) | sort)}) | from_entries}' > report-summary.json
cat report-summary.json | jq '.'
}

# =======================
function transformDirectoryVersions {
dividerLine
echo "export directory versions"

cat directory.json | jq 'map(.members) | flatten | map(.name)' > directory-names.json
cat directory.json | jq 'map(. as $household | $household | {phone, email, address, district, neighborhood} as $hdata | $household.members | map({name, phone: (if (.phone | length) > 0 then .phone else $hdata.phone end), email: (if (.email | length) > 0 then .email else $hdata.email end), address: $hdata.address, district: $hdata.district, neighborhood: $hdata.neighborhood })) | flatten' > directory-contact-info.json
sleep 2
}

# =======================
function transformMinisteringAssignments {
dividerLine
echo "transforming ministering assignments"

# cat ministering-eq.json | jq '.props.pageProps.initialState.ministeringData.elders | reduce .[] as $district ([]; . + ($district.companionships | reduce .[] as $companionship ([]; . + $companionship.ministers | map(. * {hasCompanion: (if(($companionship.ministers | length) > 1) then (1) else (0) end), count: ($companionship.ministers | length), ministers: $companionship.ministers})))) | sort_by(.name)' > ministering-brothers.json

# cat ministering-eq.json | jq '.props.pageProps.initialState.ministeringData.elders | reduce .[] as $district ([]; . + ($district.companionships | reduce .[] as $companionship ([]; . + $companionship.ministers))) | sort_by(.name)' > ministering-brothers.json

# include boolean flag indicating if there are more than 1 elder in a companionship
# if there is only 1 elder assigned, include him in the list of brothers who need a ministering companion
# hasCompanion: (1 - 2 or more; 0 - 1 or less) brothers assigned to companionship
cat ministering-eq.json | jq '.props.pageProps.initialState.ministeringData.elders | reduce .[] as $district ([]; $district.districtName as $districtName | . + ((if ($district.companionships) then ($district.companionships) else ([]) end) | reduce .[] as $companionship ([]; . + ($companionship.ministers as $ministers | $ministers | map(. as $elder | (if (($ministers | length) > 1) then (1) else (0) end) as $hasCompanion | $elder * {companionshipMembersSize: ($ministers | length), districtName: $districtName, hasCompanion: $hasCompanion}))))) | sort_by(.name)' > ministering-brothers.json

cat ministering-eq.json | jq '.props.pageProps.initialState.ministeringData.elders | reduce .[] as $district ([]; $district.districtName as $districtName | . + ((if ($district.companionships) then ($district.companionships) else ([]) end) | reduce .[] as $companionship ([]; . + ($companionship.assignments | reduce .[] as $assignment ([]; . + [$assignment * {districtName: $districtName}]))))) | sort_by(.name)' > ministering-families.json

compileMinisteringAndDirectoryData

sleep 2
}

# =======================
function compileMinisteringAndDirectoryData {

#   {
#     "phone": "801-471-5269",
#     "email": "jiggajka@yahoo.com",
#     "address": "140 S Dry Creek Ln\nVineyard, Utah 84059-5680",
#     "name": "Ahlmann, Justin",
#     "companionshipId": 1
#   },
  
local findIndividualContactInfo=$(cat <<-'EOL'
def findIndividualContactInfo(directoryData; name): 
name as $name | 
directoryData as $directoryData | 
($directoryData | map(select((isempty(.) == false) and (.name == $name))) | first) as $memberContactInfoResult | 
if ($memberContactInfoResult) then ({phone: $memberContactInfoResult.phone, email: $memberContactInfoResult.email, address: ($memberContactInfoResult.address | gsub("\n"; "\\n")), name: $memberContactInfoResult.name}) else ({}) end
EOL
)

local payload=$(jq -n 'inputs | {"object": . , "filename": input_filename, "lineNumber": input_line_number}' ministering-eq.json directory-contact-info.json | 
jq -ns 'inputs' | 
jq -r "${findIndividualContactInfo};"'. as $all | 
$all | map(select(.filename == "ministering-eq.json")) | first as $ministering | 
$all | map(select(.filename == "directory-contact-info.json")) | first as $directory | 
$ministering.object | 
.props.pageProps.initialState.ministeringData.elders | map(select(. | has("companionships"))) | 
map(. as $districtEntry | ($districtEntry.companionships | 
  to_entries |
  reduce .[] as $companionship ([]; ($companionship.key + 1) as $companionshipId | . + 
    (
      $companionship.value.ministers |
      map(
        findIndividualContactInfo($directory.object; .name)
        * {companionshipId: $companionshipId}
      )
    )
  )) as $districtCompanionships | 
  {district: $districtEntry.districtName, companionships: $districtCompanionships}
)
')

# echo "$payload"
for district in $(echo "$payload" | jq -r '. | map(.district) | join(" ")'); do
  filename="./ministering-assignments-${district}.json"
  printf "Writing to file: ${filename}..."
  echo "$payload" | jq '. | (map(select(.district == "'"$district"'")) | first) | .companionships' > "$filename"
  echo "DONE!"
done


# jq -n 'inputs | {"object": . , "filename": input_filename, "lineNumber": input_line_number}' ministering-eq.json directory-cleaned.json | 
# jq -ns 'inputs' | 
# jq ""'. as $all | 
# $all | map(select(.filename == "ministering-eq.json")) | first as $ministering | 
# $all | map(select(.filename == "directory-cleaned.json")) | first as $directory | 
# $directory.object as $directoryData | 
# "Ahlmann, Justin" as $name | 
# ($directoryData | map(select((isempty(.) == false) and (.name == $name))) | first) as $memberContactInfoResult | 
# if ($memberContactInfoResult) then ({phone: $memberContactInfoResult.phone, email: $memberContactInfoResult.email, address: $memberContactInfoResult.address, name: $memberContactInfoResult.name}) else ({}) end'

}


# =======================
function loadCookies() {
dividerLine
echo "loading cookies"

lines=$(cat cookie.txt | perl -p -e 's# #\n#g' | grep 'ChurchSSO\|Church-auth-jwt-prod\|directory_access_token\|directory_refresh_token')
authorization_token=$(cat cookie.txt | sed '/authorization: Bearer/!d' | perl -p -e 's#^.*authorization: Bearer ([^'"'"']*).*#\1#g')
refresh_token=$(cat cookie.txt | sed '/x-refresh/!d' | perl -p -e 's#^.*-H '"'"'x-refresh: ([^'"'"']*).*#\1#g')
#ChurchSSO=$(echo $lines | perl -p -e 's#^.*ChurchSSO=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
ChurchSSO=$(echo $lines | sed '/ChurchSSO=/!d' | perl -p -e 's#^.*ChurchSSO=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
ChurchAuthJwtProd=$(echo $lines | sed '/Church-auth-jwt-prod=/!d' | perl -p -e 's#^.*Church-auth-jwt-prod=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
# directory_access_token=$(echo $lines | perl -p -e 's#^.*directory_access_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
directory_access_token=$(echo $lines | sed '/directory_access_token=/!d' | perl -p -e 's#^.*directory_access_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
# directory_refresh_token=$(echo $lines | perl -p -e 's#^.*directory_refresh_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')
directory_refresh_token=$(echo $lines | sed '/directory_refresh_token=/!d' | perl -p -e 's#^.*directory_refresh_token=([^ ;]*).*#\1#g' | perl -p -e 's#^[^=]*=([^;]*).*#\1#g')

echo "authorization_token=\"${authorization_token}\""
echo "refresh_token=\"${refresh_token}\""
echo "ChurchSSO=\"${ChurchSSO}\""
echo "ChurchAuthJwtProd=\"${ChurchAuthJwtProd}\""
echo "directory_access_token=\"${directory_access_token}\""
echo "directory_refresh_token=\"${directory_refresh_token}\""
echo ""

echo "Load these cookies? (Enter=yes; Ctrl-C=no)"
read cont

# TODO: add these?
# aam_sc=aamsc%3D751537%7C708195; 
# ChurchSSO-int=wzBgxCgubHc4co1L7nMvZSsKKe0.*AAJTSQACMDIAAlNLABxZc3R0TTVkbndaNys0NGtrTjcrV1pMWE9HMmM9AAR0eXBlAANDVFMAAlMxAAIwMQ..*; 
# Church-auth-jwt-int=eyJ0eXAiOiJKV1QiLCJraWQiOiJrVlR5NDVhb0JoUnVBcWJ2MnQwbWU2NVpIMEk9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiJiZDg2ZDQ0MC1kOGQyLTRjYjMtOTc3ZS0wYTA4ZDZmMDk5MmItMTA0NDc1MTYiLCJpc3MiOiJodHRwczovL2lkZW50LWludC5jaHVyY2hvZmplc3VzY2hyaXN0Lm9yZy9zc28vb2F1dGgyIiwidG9rZW5OYW1lIjoiaWRfdG9rZW4iLCJub25jZSI6IkJFOTc3NTVENTQ2MUZGQ0JDNEY1ODEyQkU4QjkyN0U2IiwiYXVkIjoibDE4MDI3IiwiYWNyIjoiMCIsInNfaGFzaCI6Ilp5MzEtcGlpWGNSOUZ1VS0zaG9sT3ciLCJhenAiOiJsMTgwMjciLCJhdXRoX3RpbWUiOjE1Nzk2NDQxMTAsImZvcmdlcm9jayI6eyJzc290b2tlbiI6Ind6Qmd4Q2d1YkhjNGNvMUw3bk12WlNzS0tlMC4qQUFKVFNRQUNNRElBQWxOTEFCeFpjM1IwVFRWa2JuZGFOeXMwTkd0clRqY3JWMXBNV0U5SE1tTTlBQVIwZVhCbEFBTkRWRk1BQWxNeEFBSXdNUS4uKiIsInN1aWQiOiJmMzY1OGM3Mi1lMjgyLTRiY2YtOGUxMy0yZTcxZmU2MzhhYzktMTAzMzMyNjcifSwicmVhbG0iOiIvY2h1cmNoIiwiZXhwIjoxNTc5Njg3MzEwLCJ0b2tlblR5cGUiOiJKV1RUb2tlbiIsImlhdCI6MTU3OTY0NDExMCwiYWdlbnRfcmVhbG0iOiIvY2h1cmNoIn0.BiWwTjRX6BMZ4Nyeq3fX49DU36cxiYqkP9h0EKWqLY4x73TRatdZ4_rDhETFWxog75rWXtyCn21l84sw8ueP6GutKCgwHysJlFoBnpn2_BHPGsitdpDPo8AfrZSEEfnOvRVO6vPFUkD7WuxwTErfbZ-CNs_5Lm_JLonAY4CAP43St6gq-aeqK_cFZcsG4_ARbk2uX4BGZgYDXIHUxGZZZ6LWX7YuPBiSIWqYq9LsgNoTwgu2foHIf1Q_VQI7g0nY8HhJdt2UjHm312VaEk6aMZ3t3-Zyi_lOxVqsuOVyGHyqCSxTgL2lOeuNkMXvKi11_AHQhWr5IL-hIOwN4e7YCg; 
# TS01a096ec=01999b7023f962af0b95544d7ea951d0dac619e2fcf70032c859dbad548e18bc6f59a1efa460369ab9d55d0b22c33e35ef2535e546; 
}

# =======================
function fetchYM {
dividerLine
echo "fetching ym"

curl 'https://lcr.churchofjesuschrist.org/services/orgs/sub-orgs-with-callings?lang=eng&subOrgId=209075' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'Accept: application/json, text/plain, */*' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-Mode: cors' -H 'Referer: https://lcr.churchofjesuschrist.org/orgs/209075?lang=eng' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US' -H $'Cookie: audience_split=21; _fbp=fb.1.1558727984750.576138409; WRUIDCD=1979799963828235; lds-preferred-lang-v2=eng; s_fid=10C2A7BB8E217B78-195A92D72803F241; _ga=GA1.2.1976242211.1564161692; _cs_c=1; _cs_ex=1; cr-aths=shown; aam_sc=aamsc%3D751537%7C708195; aam_uuid=58837750016941287141775247194571768784; amlbcookie-int=01; ORIG_URL=/sso?realm=/church&service=OktaOIDC&goto=https%3A%2F%2Frecovery-test.churchofjesuschrist.org%3A443%2Fagent%2Fcustom-login-response%3Fstate%3D816bf7c0-bd29-83ba-527c-9961f7b430d5%26realm%3D%252Fchurch%26service%3DOktaOIDC&original_request_url=https%3A%2F%2Frecovery-test.churchofjesuschrist.org%3A443%2F&authIndexType=service&authIndexValue=OktaOIDC; NTID=mCZIerHXQoW74H0AxNi5IkA8FHLSCk8w; OAUTH_LOGOUT_URL=; ChurchSSO-int=gSBvaYM8bzrBTSe3a4s52vUDSi0.*AAJTSQACMDIAAlNLABxzcXhVUDRFcjFXaVlOQ1FvZVNSZGhUcS9sNFE9AAR0eXBlAANDVFMAAlMxAAIwMQ..*; Church-auth-jwt-int=eyJ0eXAiOiJKV1QiLCJraWQiOiJrVlR5NDVhb0JoUnVBcWJ2MnQwbWU2NVpIMEk9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiJlNGM0N2IyMy00NjYyLTQ3ODUtOGIwNi01NDE3ODU4MmY2YWItMTA4MjM2NyIsImlzcyI6Imh0dHBzOi8vaWRlbnQtaW50LmNodXJjaG9mamVzdXNjaHJpc3Qub3JnL3Nzby9vYXV0aDIiLCJ0b2tlbk5hbWUiOiJpZF90b2tlbiIsIm5vbmNlIjoiRjM1NzJCQjBEMEM3QTM3QjkxODM1QUNBMzQwREI2MkEiLCJhdWQiOiJsMTgwMjYiLCJhY3IiOiIwIiwic19oYXNoIjoid2Zwa1N0ZXBkWG9SSHJUSTFJMjFodyIsImF6cCI6ImwxODAyNiIsImF1dGhfdGltZSI6MTU4MTExMzc2NCwiZm9yZ2Vyb2NrIjp7InNzb3Rva2VuIjoiZ1NCdmFZTThienJCVFNlM2E0czUydlVEU2kwLipBQUpUU1FBQ01ESUFBbE5MQUJ4emNYaFZVRFJGY2pGWGFWbE9RMUZ2WlZOU1pHaFVjUzlzTkZFOUFBUjBlWEJsQUFORFZGTUFBbE14QUFJd01RLi4qIiwic3VpZCI6ImUzODljZWEwLTJlNDgtNGRlNi1hMTk2LWY4MTVlMzIwOTg2ZC0xMTQ5NzQyIn0sInJlYWxtIjoiL2NodXJjaCIsImV4cCI6MTU4MTE1Njk2NCwidG9rZW5UeXBlIjoiSldUVG9rZW4iLCJpYXQiOjE1ODExMTM3NjQsImFnZW50X3JlYWxtIjoiL2NodXJjaCJ9.Noaz_JG8xz2xavp5Q8pRuPktedVQgFf21fRyDVLWyQvqd8MGiohsrr8AXVPKQZrcbQieH0OzHqDzpRqv_9PJ7lLOeqc6SYaOrmzU3cj-JBUP1hAeEB3Vwsb-0d6YFv0-Z4cvuJIbPQXSuj2ku6NRQRF5V95xtQMVloKYzGRe_HNRG4NG7D9ud5fryq7YlQsqQe5NKoo6sJ1A2hjiUjt4own4tBqvuA_HCPWExvnHJ1uGcro-0Gxm6AsFQoHuVj_zjvMHILHddgAZb2xq_i8K8HDqlHNycf7eKSMpnoP5M3yYrIEZq9X4vPf2_bNmpzigv_KKCarg0QTs_Ass9RT1rQ; check=true; audience_s_split=64; s_cc=true; mboxEdgeCluster=28; _CT_RS_=Recording; __CT_Data=gpv=80&ckp=tld&dm=churchofjesuschrist.org&apv_59_www11=81&cpv_59_www11=80&rpv_59_www11=80; ADRUM=s=1581303202963&r=https%3A%2F%2Fwww.churchofjesuschrist.org%2F%3F479231918; ctm={\'pgv\':1350636977909173|\'vst\':7385663247553829|\'vstr\':5589777858429154|\'intr\':1581303204375|\'v\':1|\'lvst\':40257}; RT="z=1&dm=churchofjesuschrist.org&si=4b6bde0e-30a3-4c02-a935-10ee036a655a&ss=k6fv39vp&sl=1&tt=3xk&bcn=%2F%2F17c8edca.akstat.io%2F&ld=3xv&nu=265aa681196d3099ae5db03a5201bc77&cl=aem&ul=af3&hd=chh"; TS01b07831=01999b702368a61c83c814648324cf1d39b577e9f29e339971a112868a38dfb670410b394611b9f686b1f98ef296160de0bfc66d0e; JSESSIONID=0; __VCAP_ID__=da0a8fd4-87fa-4a73-7603-5f46; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; ChurchSSO='"${ChurchSSO}"'; Church-auth-jwt-prod='"${ChurchAuthJwtProd}"'; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=1099438348%7CMCIDTS%7C18303%7CMCMID%7C45993473060174549671353300097144335983%7CMCAAMLH-1581908208%7C9%7CMCAAMB-1581908208%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1581310608s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C2.1.0; mbox=PC#ff77b07984e6447e8ca81967c1376f11.28_0#1644548038|session#2d8bd0374b7147cb86c3b15127f8eca8#1581305625; utag_main=v_id:016aeb6d84c7000c9febf6d43f4003079007407101788$_sn:243$_ss:0$_st:1581305649963$vapi_domain:churchofjesuschrist.org$dc_visit:243$_se:3$ses_id:1581303192943%3Bexp-session$_pn:7%3Bexp-session$dc_event:19%3Bexp-session$dc_region:us-east-1%3Bexp-session; t_ppv=churchofjesuschrist.org%20%3A%20lcr%20%3A%20orgs%20%3A%20members-with-callings%2C66%2C53%2C676%2C198021; s_sq=ldsall%3D%2526pid%253Dchurchofjesuschrist.org%252520%25253A%252520lcr%252520%25253A%252520orgs%252520%25253A%252520members-with-callings%2526pidt%253D1%2526oid%253Dhttps%25253A%25252F%25252Flcr.churchofjesuschrist.org%25252Forgs%25252F209075%25253Flang%25253Deng%2526ot%253DA' -H 'lds-account-id: 1562cace-a0ad-4df9-a868-54f2bfe5f9cc' --compressed > ym.json

sleep 2

cat ym.json | jq '.[0].children | map(select(((.filterOffices | length) > 0))) | map(. as $head | $head.filterOffices | reduce .[] as $item ({}; . * ($item.codes | reduce .[] as $code ({}; . * ({ ($code|tostring): $item.name })))) | . as $officeMap | $head.members | map({ name, gender, birthDate, priesthood: $officeMap[(.priesthoodCode | tostring)], actualAge, nonMember, endowed, eligibleForHomeTeachingAssignment })) | reduce .[] as $quorum ([]; . + $quorum) | map(select(.eligibleForHomeTeachingAssignment == true))' > ym-cleaned.json
}

# =======================
function fetchSisters {
dividerLine
echo "fetching sisters"

curl 'https://lcr.churchofjesuschrist.org/services/orgs/sub-orgs-with-callings?lang=eng&subOrgId=209076' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'Accept: application/json, text/plain, */*' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-Mode: cors' -H 'Referer: https://lcr.churchofjesuschrist.org/orgs/209076?lang=eng' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US' -H $'Cookie: audience_split=21; _fbp=fb.1.1558727984750.576138409; WRUIDCD=1979799963828235; lds-preferred-lang-v2=eng; s_fid=10C2A7BB8E217B78-195A92D72803F241; _ga=GA1.2.1976242211.1564161692; _cs_c=1; _cs_ex=1; cr-aths=shown; aam_sc=aamsc%3D751537%7C708195; aam_uuid=58837750016941287141775247194571768784; amlbcookie-int=01; ORIG_URL=/sso?realm=/church&service=OktaOIDC&goto=https%3A%2F%2Frecovery-test.churchofjesuschrist.org%3A443%2Fagent%2Fcustom-login-response%3Fstate%3D816bf7c0-bd29-83ba-527c-9961f7b430d5%26realm%3D%252Fchurch%26service%3DOktaOIDC&original_request_url=https%3A%2F%2Frecovery-test.churchofjesuschrist.org%3A443%2F&authIndexType=service&authIndexValue=OktaOIDC; NTID=mCZIerHXQoW74H0AxNi5IkA8FHLSCk8w; OAUTH_LOGOUT_URL=; ChurchSSO-int=gSBvaYM8bzrBTSe3a4s52vUDSi0.*AAJTSQACMDIAAlNLABxzcXhVUDRFcjFXaVlOQ1FvZVNSZGhUcS9sNFE9AAR0eXBlAANDVFMAAlMxAAIwMQ..*; Church-auth-jwt-int=eyJ0eXAiOiJKV1QiLCJraWQiOiJrVlR5NDVhb0JoUnVBcWJ2MnQwbWU2NVpIMEk9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiJlNGM0N2IyMy00NjYyLTQ3ODUtOGIwNi01NDE3ODU4MmY2YWItMTA4MjM2NyIsImlzcyI6Imh0dHBzOi8vaWRlbnQtaW50LmNodXJjaG9mamVzdXNjaHJpc3Qub3JnL3Nzby9vYXV0aDIiLCJ0b2tlbk5hbWUiOiJpZF90b2tlbiIsIm5vbmNlIjoiRjM1NzJCQjBEMEM3QTM3QjkxODM1QUNBMzQwREI2MkEiLCJhdWQiOiJsMTgwMjYiLCJhY3IiOiIwIiwic19oYXNoIjoid2Zwa1N0ZXBkWG9SSHJUSTFJMjFodyIsImF6cCI6ImwxODAyNiIsImF1dGhfdGltZSI6MTU4MTExMzc2NCwiZm9yZ2Vyb2NrIjp7InNzb3Rva2VuIjoiZ1NCdmFZTThienJCVFNlM2E0czUydlVEU2kwLipBQUpUU1FBQ01ESUFBbE5MQUJ4emNYaFZVRFJGY2pGWGFWbE9RMUZ2WlZOU1pHaFVjUzlzTkZFOUFBUjBlWEJsQUFORFZGTUFBbE14QUFJd01RLi4qIiwic3VpZCI6ImUzODljZWEwLTJlNDgtNGRlNi1hMTk2LWY4MTVlMzIwOTg2ZC0xMTQ5NzQyIn0sInJlYWxtIjoiL2NodXJjaCIsImV4cCI6MTU4MTE1Njk2NCwidG9rZW5UeXBlIjoiSldUVG9rZW4iLCJpYXQiOjE1ODExMTM3NjQsImFnZW50X3JlYWxtIjoiL2NodXJjaCJ9.Noaz_JG8xz2xavp5Q8pRuPktedVQgFf21fRyDVLWyQvqd8MGiohsrr8AXVPKQZrcbQieH0OzHqDzpRqv_9PJ7lLOeqc6SYaOrmzU3cj-JBUP1hAeEB3Vwsb-0d6YFv0-Z4cvuJIbPQXSuj2ku6NRQRF5V95xtQMVloKYzGRe_HNRG4NG7D9ud5fryq7YlQsqQe5NKoo6sJ1A2hjiUjt4own4tBqvuA_HCPWExvnHJ1uGcro-0Gxm6AsFQoHuVj_zjvMHILHddgAZb2xq_i8K8HDqlHNycf7eKSMpnoP5M3yYrIEZq9X4vPf2_bNmpzigv_KKCarg0QTs_Ass9RT1rQ; check=true; audience_s_split=64; s_cc=true; mboxEdgeCluster=28; _CT_RS_=Recording; __CT_Data=gpv=80&ckp=tld&dm=churchofjesuschrist.org&apv_59_www11=81&cpv_59_www11=80&rpv_59_www11=80; ADRUM=s=1581303202963&r=https%3A%2F%2Fwww.churchofjesuschrist.org%2F%3F479231918; ctm={\'pgv\':1350636977909173|\'vst\':7385663247553829|\'vstr\':5589777858429154|\'intr\':1581303204375|\'v\':1|\'lvst\':40257}; RT="z=1&dm=churchofjesuschrist.org&si=4b6bde0e-30a3-4c02-a935-10ee036a655a&ss=k6fv39vp&sl=1&tt=3xk&bcn=%2F%2F17c8edca.akstat.io%2F&ld=3xv&nu=265aa681196d3099ae5db03a5201bc77&cl=aem&ul=af3&hd=chh"; TS01b07831=01999b702368a61c83c814648324cf1d39b577e9f29e339971a112868a38dfb670410b394611b9f686b1f98ef296160de0bfc66d0e; JSESSIONID=0; __VCAP_ID__=da0a8fd4-87fa-4a73-7603-5f46; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; ChurchSSO='"${ChurchSSO}"'; Church-auth-jwt-prod='"${ChurchAuthJwtProd}"'; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=1099438348%7CMCIDTS%7C18303%7CMCMID%7C45993473060174549671353300097144335983%7CMCAAMLH-1581908208%7C9%7CMCAAMB-1581908208%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1581310608s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C2.1.0; mbox=PC#ff77b07984e6447e8ca81967c1376f11.28_0#1644548038|session#2d8bd0374b7147cb86c3b15127f8eca8#1581305625; utag_main=v_id:016aeb6d84c7000c9febf6d43f4003079007407101788$_sn:243$_ss:0$_st:1581305565648$vapi_domain:churchofjesuschrist.org$dc_visit:243$_se:3$ses_id:1581303192943%3Bexp-session$_pn:7%3Bexp-session$dc_event:18%3Bexp-session$dc_region:us-east-1%3Bexp-session; t_ppv=churchofjesuschrist.org%20%3A%20lcr%20%3A%20orgs%20%3A%20members-with-callings%2C66%2C8%2C676%2C86030; s_sq=ldsall%3D%2526pid%253Dchurchofjesuschrist.org%252520%25253A%252520lcr%252520%25253A%252520orgs%252520%25253A%252520members-with-callings%2526pidt%253D1%2526oid%253Dhttps%25253A%25252F%25252Flcr.churchofjesuschrist.org%25252Forgs%25252F209076%25253Flang%25253Deng%2526ot%253DA' -H 'lds-account-id: 1562cace-a0ad-4df9-a868-54f2bfe5f9cc' --compressed > rs.json

sleep 2

rsWip=$(cat rs.json | jq '.[0] as $head | $head.filterOffices | reduce .[] as $item ({}; . * ($item.codes | reduce .[] as $code ({}; . * ({ ($code|tostring): $item.name })))) | . as $officeMap | $head.members | map({ name, id, gender, birthDate, birthDayFormatted, address, priesthood: $officeMap[(.priesthoodCode | tostring)], actualAge, nonMember, endowed, eligibleForHomeTeachingAssignment })')

echo "$rsWip" | jq ''"$jqNeighborhood"'; '"$jqDistrict"'; map(. as $orig | (.address | district) as $district | (.address | neighborhood) as $neighborhood | $orig + {$district} + {$neighborhood})' > rs-cleaned.json

echo "filtering for single sisters"

# filter directory for households that only have one .head == true (this may include brothers, but they will be filtered out later on) > $singleMembers
# pull all sisters from RS and inner join with $singleMembers
# lookup callings for $targetMember

jq -n 'inputs | {"object": . , "filename": input_filename, "lineNumber": input_line_number}' directory.json members-with-callings.json rs.json | jq -ns 'inputs' | jq '. as $all | $all | map(select(.filename == "directory.json"))[0].object | map(. as $household | $household | .members | map(select(.head == true)) as $heads | $household | select(($heads | length) == 1) ) as $directory | $directory | map(.members | map(select(.head == true))[0] | .name) as $singleMembers | $all | map(select(.filename == "members-with-callings.json"))[0].object | map({name, position, organization, unitName}) as $mwcInfo| $all | map(select(.filename == "rs.json"))[0].object[0].members | map(select([.name] as $targetMember | $singleMembers | contains($targetMember))) | map({name, district: (.name as $mName | $directory | map(select(.name == $mName))[0] | .district ), neighborhood: (.name as $mName | $directory | map(select(.name == $mName))[0] | .neighborhood ), age, address, phone, email, birthDayFormatted, positions: (.name as $mName | $mwcInfo | map(select(.name == $mName)) | reverse | map({unitName, organization, position}))})' > single-sisters.json

# incomplete; jq -n 'inputs | {"object": . , "filename": input_filename, "lineNumber": input_line_number}' directory.json rs.json | jq -ns 'inputs' | jq '. as $all | $all | map(select(.filename == "directory.json"))[0].object | map(select((.members | length) == 1)) | map(.name) as $singleMembers | $all | map(select(.filename == "rs.json"))[0].object[0].members | map(select([.name] as $targetMember | $singleMembers | contains($targetMember))) | map({name, age, address, phone, email, birthDayFormatted})' > single-sisters.json
}

# =======================
function fetchMembersWithCallings {
dividerLine
echo "fetching members with callings"

# curl 'https://lcr.churchofjesuschrist.org/services/report/members-with-callings?lang=eng&unitNumber=13730' -H 'Pragma: no-cache' -H 'Sec-Fetch-Site: same-origin' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.9' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.87 Safari/537.36' -H 'Sec-Fetch-Mode: cors' -H 'Accept: application/json, text/plain, */*' -H 'Cache-Control: no-cache' -H 'Referer: https://lcr.churchofjesuschrist.org/orgs/members-with-callings?lang=eng' -H $'Cookie: audience_split=21; _fbp=fb.1.1558727984750.576138409; WRUIDCD=1979799963828235; lds-preferred-lang-v2=eng; cr-aths=shown; __CT_Data=gpv=18&ckp=tld&dm=churchofjesuschrist.org&apv_59_www11=19&cpv_59_www11=18&rpv_59_www11=18; ctm={\'pgv\':74967302419333|\'vst\':2542134181393777|\'vstr\':5589777858429154|\'intr\':1563820041606|\'v\':1|\'lvst\':304}; s_fid=10C2A7BB8E217B78-195A92D72803F241; _gcl_au=1.1.1161084623.1564161692; _ga=GA1.2.1976242211.1564161692; check=true; TS01b07831=01999b7023f1259cf2ce3e665baf3405fe41d3abbdb4fee0587cfb20f21f96004082272dbb85d261fbe2b39e961acf7c68f780b070; audience_s_split=61; s_cc=true; TS011e50d7=01999b7023f4a9722d5d9696c23bb88cbb92310c692edc3721a508d7b7412e55bf9f1bded1887717428ba8abb8c24f42cc266abab6; JSESSIONID=0; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; ADRUM=s=1565466898295&r=https%3A%2F%2Fwww.churchofjesuschrist.org%2F%3F479231918; __VCAP_ID__=fd21059e-ff25-43e4-445b-2dc3; TS01a096ec=01999b70235e48864a88e7e2446ef0df8e1dafed0c72b4a756f890a2d3852b1d32353e1af08545c6d12ff192a4c2dafc8c3899d509; amlbcookie=76; TS01289383=01999b7023f185b5f5bc1655d91369277e8272794750e21e40f858a7c81b33c06e953233e1e907b876fd3c1b496b40ac843f05ea0b; TS01b89640=01999b7023f185b5f5bc1655d91369277e8272794750e21e40f858a7c81b33c06e953233e1e907b876fd3c1b496b40ac843f05ea0b; lds-id=AQIC5wM2LY4Sfcxvi6i9blXbjN4UtOjChDQ7XX-hlA8nZGM.*AAJTSQACMDIAAlNLABQtODEwMTkxMTY1ODg1MDM3ODY2OAACUzEAAjA2*; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=-330454231%7CMCIDTS%7C18119%7CMCMID%7C45993473060174549671353300097144335983%7CMCAAMLH-1566142218%7C9%7CMCAAMB-1566142218%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1565544618s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C3.1.2; mboxEdgeCluster=28; ChurchSSO='"${ChurchSSO}"'' -H 'Connection: keep-alive' --compressed > members-with-callings.json

#curl 'https://lcr.churchofjesuschrist.org/services/report/members-with-callings?lang=eng&unitNumber=13730' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'Accept: application/json, text/plain, */*' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-Mode: cors' -H 'Referer: https://lcr.churchofjesuschrist.org/orgs/members-with-callings?lang=eng' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US' -H $'Cookie: audience_split=21; _fbp=fb.1.1558727984750.576138409; WRUIDCD=1979799963828235; lds-preferred-lang-v2=eng; s_fid=10C2A7BB8E217B78-195A92D72803F241; _ga=GA1.2.1976242211.1564161692; _cs_c=1; aam_sc=aamsc%3D751537%7C708195; _cs_ex=1; cr-aths=shown; _CT_RS_=EventTriggeredRecording; aam_uuid=58837750016941287141775247194571768784; check=true; TS01b07831=01999b70235a94013e06efba0e13df8f99f4de277f496bba78432f5952b7d1d1a22c0fcbab05c1f5d1c9b686e6bee8dffe4e9301d3; audience_s_split=80; s_cc=true; JSESSIONID=0; __VCAP_ID__=fa1ecf02-ba91-4e9a-55f1-d822; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; mboxEdgeCluster=28; ADRUM=s=1575844376340&r=https%3A%2F%2Fwww.churchofjesuschrist.org%2F%3F479231918; RT="z=1&dm=churchofjesuschrist.org&si=1e3191cd-6cb8-4ce8-b5e8-2d080855e107&ss=k3xl1swp&sl=1&tt=2y4&bcn=%2F%2F17d98a5d.akstat.io%2F&ld=2ye&ul=5td&hd=6ir"; ChurchSSO=L1dT37j2DpIaiHuroczMnPg9t5I.*AAJTSQACMDIAAlNLABxGN3Nlc3hmQkdXRVpSWXA1NEx2YWVWd1VUTG89AAR0eXBlAANDVFMAAlMxAAIwMQ..*; Church-auth-jwt-prod=eyJ0eXAiOiJKV1QiLCJraWQiOiJDK2g4T1diR0IrMnV0L0xQQ0RlTEUwMXAzUjQ9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiJlYjAxNGVhZC0xYmI0LTQ4NzgtOTY5Yy0xZWI2NDVmN2JlYTAtMTQ3NDkyODYiLCJpc3MiOiJodHRwczovL2lkZW50LmNodXJjaG9mamVzdXNjaHJpc3Qub3JnL3Nzby9vYXV0aDIiLCJ0b2tlbk5hbWUiOiJpZF90b2tlbiIsIm5vbmNlIjoiRkQwQ0YyMTI3NTlDNDQyMTlFM0U3MTkyM0JCNTVCOUQiLCJhdWQiOiJsMTgwMzUiLCJhY3IiOiIwIiwic19oYXNoIjoiMEh3aUZLY3lxdkRJWDRxRmd1Z2JHUSIsImF6cCI6ImwxODAzNSIsImF1dGhfdGltZSI6MTU3NTg0NDM4OSwiZm9yZ2Vyb2NrIjp7InNzb3Rva2VuIjoiTDFkVDM3ajJEcElhaUh1cm9jek1uUGc5dDVJLipBQUpUU1FBQ01ESUFBbE5MQUJ4R04zTmxjM2htUWtkWFJWcFNXWEExTkV4MllXVldkMVZVVEc4OUFBUjBlWEJsQUFORFZGTUFBbE14QUFJd01RLi4qIiwic3VpZCI6ImE4YzM5ZWI0LTQ2ZjctNDdmMy1hMmQ1LTJlZTAxZWYyNDUxNC0xMTc1ODAwMCJ9LCJyZWFsbSI6Ii9jaHVyY2giLCJleHAiOjE1NzU4ODc3MzcsInRva2VuVHlwZSI6IkpXVFRva2VuIiwiaWF0IjoxNTc1ODQ0NTM3LCJhZ2VudF9yZWFsbSI6Ii9jaHVyY2gifQ.ZBnsB0GPAHjzLxktbCwUVsSV8iY0ibh_lwInRcIYQPkEuNrdJqyTRMyAOdtgCmErEEc4G9sQZGrX_FhZTaQppzVtbFVfiRaeMRunvmsBUW0nWB2rmZNZgwol5f3RK0eUO9W6uJ8zgC2YmiUEht4Nm7udh-9DtnHlpSnS_79qxgfO5IEh3r39uMG0qAGB4G-5NuXpHj8SaiuV4szOYqh-Kt9CJVDYdrZrMEwmN9jONp46I6NRH0kabFJYilPQr0Dxg7bcAWjIhfMZkfMOHU012BJiz71ru6rWdY0ymBguFcC-WiWIKnSLfB_NOi-WIhG28VDwPNAx6iKAIn0dbBRXDA; __CT_Data=gpv=47&ckp=tld&dm=churchofjesuschrist.org&apv_59_www11=48&cpv_59_www11=47&rpv_59_www11=47; ctm={\'pgv\':6847359844992304|\'vst\':3969812469415768|\'vstr\':5589777858429154|\'intr\':1575844779176|\'v\':1|\'lvst\':83}; ChurchSSO="${ChurchSSO}"' -H 'lds-account-id: 0168db20-c4d2-4d32-88c9-1192a4f897e9' --compressed

curl 'https://lcr.churchofjesuschrist.org/services/report/members-with-callings?lang=eng&unitNumber=13730' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'Accept: application/json, text/plain, */*' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-Mode: cors' -H 'Referer: https://lcr.churchofjesuschrist.org/orgs/members-with-callings?lang=eng' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US' -H $'Cookie: audience_split=21; _fbp=fb.1.1558727984750.576138409; WRUIDCD=1979799963828235; lds-preferred-lang-v2=eng; s_fid=10C2A7BB8E217B78-195A92D72803F241; _ga=GA1.2.1976242211.1564161692; _cs_c=1; _cs_ex=1; cr-aths=shown; aam_sc=aamsc%3D751537%7C708195; aam_uuid=58837750016941287141775247194571768784; amlbcookie-int=01; ORIG_URL=/sso?realm=/church&service=OktaOIDC&goto=https%3A%2F%2Frecovery-test.churchofjesuschrist.org%3A443%2Fagent%2Fcustom-login-response%3Fstate%3D816bf7c0-bd29-83ba-527c-9961f7b430d5%26realm%3D%252Fchurch%26service%3DOktaOIDC&original_request_url=https%3A%2F%2Frecovery-test.churchofjesuschrist.org%3A443%2F&authIndexType=service&authIndexValue=OktaOIDC; NTID=mCZIerHXQoW74H0AxNi5IkA8FHLSCk8w; OAUTH_LOGOUT_URL=; ChurchSSO-int=gSBvaYM8bzrBTSe3a4s52vUDSi0.*AAJTSQACMDIAAlNLABxzcXhVUDRFcjFXaVlOQ1FvZVNSZGhUcS9sNFE9AAR0eXBlAANDVFMAAlMxAAIwMQ..*; Church-auth-jwt-int=eyJ0eXAiOiJKV1QiLCJraWQiOiJrVlR5NDVhb0JoUnVBcWJ2MnQwbWU2NVpIMEk9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiJlNGM0N2IyMy00NjYyLTQ3ODUtOGIwNi01NDE3ODU4MmY2YWItMTA4MjM2NyIsImlzcyI6Imh0dHBzOi8vaWRlbnQtaW50LmNodXJjaG9mamVzdXNjaHJpc3Qub3JnL3Nzby9vYXV0aDIiLCJ0b2tlbk5hbWUiOiJpZF90b2tlbiIsIm5vbmNlIjoiRjM1NzJCQjBEMEM3QTM3QjkxODM1QUNBMzQwREI2MkEiLCJhdWQiOiJsMTgwMjYiLCJhY3IiOiIwIiwic19oYXNoIjoid2Zwa1N0ZXBkWG9SSHJUSTFJMjFodyIsImF6cCI6ImwxODAyNiIsImF1dGhfdGltZSI6MTU4MTExMzc2NCwiZm9yZ2Vyb2NrIjp7InNzb3Rva2VuIjoiZ1NCdmFZTThienJCVFNlM2E0czUydlVEU2kwLipBQUpUU1FBQ01ESUFBbE5MQUJ4emNYaFZVRFJGY2pGWGFWbE9RMUZ2WlZOU1pHaFVjUzlzTkZFOUFBUjBlWEJsQUFORFZGTUFBbE14QUFJd01RLi4qIiwic3VpZCI6ImUzODljZWEwLTJlNDgtNGRlNi1hMTk2LWY4MTVlMzIwOTg2ZC0xMTQ5NzQyIn0sInJlYWxtIjoiL2NodXJjaCIsImV4cCI6MTU4MTE1Njk2NCwidG9rZW5UeXBlIjoiSldUVG9rZW4iLCJpYXQiOjE1ODExMTM3NjQsImFnZW50X3JlYWxtIjoiL2NodXJjaCJ9.Noaz_JG8xz2xavp5Q8pRuPktedVQgFf21fRyDVLWyQvqd8MGiohsrr8AXVPKQZrcbQieH0OzHqDzpRqv_9PJ7lLOeqc6SYaOrmzU3cj-JBUP1hAeEB3Vwsb-0d6YFv0-Z4cvuJIbPQXSuj2ku6NRQRF5V95xtQMVloKYzGRe_HNRG4NG7D9ud5fryq7YlQsqQe5NKoo6sJ1A2hjiUjt4own4tBqvuA_HCPWExvnHJ1uGcro-0Gxm6AsFQoHuVj_zjvMHILHddgAZb2xq_i8K8HDqlHNycf7eKSMpnoP5M3yYrIEZq9X4vPf2_bNmpzigv_KKCarg0QTs_Ass9RT1rQ; check=true; audience_s_split=64; s_cc=true; mboxEdgeCluster=28; _CT_RS_=Recording; __CT_Data=gpv=80&ckp=tld&dm=churchofjesuschrist.org&apv_59_www11=81&cpv_59_www11=80&rpv_59_www11=80; ADRUM=s=1581303202963&r=https%3A%2F%2Fwww.churchofjesuschrist.org%2F%3F479231918; ctm={\'pgv\':1350636977909173|\'vst\':7385663247553829|\'vstr\':5589777858429154|\'intr\':1581303204375|\'v\':1|\'lvst\':40257}; RT="z=1&dm=churchofjesuschrist.org&si=4b6bde0e-30a3-4c02-a935-10ee036a655a&ss=k6fv39vp&sl=1&tt=3xk&bcn=%2F%2F17c8edca.akstat.io%2F&ld=3xv&nu=265aa681196d3099ae5db03a5201bc77&cl=aem&ul=af3&hd=chh"; TS01b07831=01999b702368a61c83c814648324cf1d39b577e9f29e339971a112868a38dfb670410b394611b9f686b1f98ef296160de0bfc66d0e; JSESSIONID=0; __VCAP_ID__=da0a8fd4-87fa-4a73-7603-5f46; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; ChurchSSO='"${ChurchSSO}"'; Church-auth-jwt-prod='"${ChurchAuthJwtProd}"'; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=1099438348%7CMCIDTS%7C18303%7CMCMID%7C45993473060174549671353300097144335983%7CMCAAMLH-1581908208%7C9%7CMCAAMB-1581908208%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1581310608s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C2.1.0; mbox=PC#ff77b07984e6447e8ca81967c1376f11.28_0#1644548038|session#2d8bd0374b7147cb86c3b15127f8eca8#1581305282; s_sq=ldsall%3D%2526pid%253Dchurchofjesuschrist.org%252520%25253A%252520lcr%252520%25253A%252520orgs%252520%25253A%2525205873015%2526pidt%253D1%2526oid%253Dhttps%25253A%25252F%25252Flcr.churchofjesuschrist.org%25252Forgs%25252Fmembers-with-callings%25253Flang%25253Deng%2526ot%253DA; utag_main=v_id:016aeb6d84c7000c9febf6d43f4003079007407101788$_sn:243$_ss:0$_st:1581305558718$vapi_domain:churchofjesuschrist.org$dc_visit:243$_se:3$ses_id:1581303192943%3Bexp-session$_pn:6%3Bexp-session$dc_event:16%3Bexp-session$dc_region:us-east-1%3Bexp-session; t_ppv=churchofjesuschrist.org%20%3A%20lcr%20%3A%20orgs%20%3A%205873015%2C66%2C8%2C676%2C343016; ADRUM_BTa=R:0|g:0a376329-7bc5-44a4-921c-16b5a44c4483|n:customer1_acb14d98-cf8b-4f6d-8860-1c1af7831070; ADRUM_BT1=R:0|i:14049|e:336' -H 'lds-account-id: 1562cace-a0ad-4df9-a868-54f2bfe5f9cc' --compressed | jq '.' > members-with-callings.json
sleep 2

compileMembersWithCallings
}

# =======================
function compileMembersWithCallings {
dividerLine
echo "compiling elders"

jq -n 'inputs | {"object": . , "filename": input_filename, "lineNumber": input_line_number}' directory.json members-with-callings.json eq-cleaned.json | jq -ns 'inputs' | jq '. as $all | $all | map(select(.filename == "eq-cleaned.json"))[0].object | map({name, age: .actualAge, birthDay: .birthDayFormatted}) as $eqInfo | $all | map(select(.filename == "members-with-callings.json"))[0].object | map({name, position, organization, unitName}) as $mwcInfo | map(select(.gender == "MALE" and ([.organization] as $organization | ((["Aaronic Priesthood Quorums", "Primary", "Bishopric", "High Council"] | contains($organization)) or (.organization | contains("Stake"))) ) )) | map(.name) as $targetMembers | $all | map(select(.filename == "directory.json"))[0].object | map(. as $household | .members | map(select([.name] as $targetMember | $targetMembers | contains($targetMember)))  | map({name, district: ($household | .district), neighborhood: ($household | .neighborhood), address: $household.address, email, phone, age: (.name as $mName | $eqInfo | map(select(.name == $mName))[0].age), birthDay: (.name as $mName | $eqInfo | map(select(.name == $mName))[0].birthDay), positions: (.name as $mName | $mwcInfo | map(select(.name == $mName)) | reverse | map({unitName, organization, position})) })[0]) | map(select((. == null | not) and (.age == null | not)))| sort_by(.district, .positions[0].organization, .name)' > eq-members-with-aux-positions.json

jq -n 'inputs | {"object": . , "filename": input_filename, "lineNumber": input_line_number}' directory.json members-with-callings.json eq-cleaned.json | jq -ns 'inputs' | jq '. as $all | $all | map(select(.filename == "eq-cleaned.json"))[0].object | map({name, age: .actualAge, birthDay: .birthDayFormatted}) as $eqInfo | $all | map(select(.filename == "members-with-callings.json"))[0].object | map({name, position, organization, unitName}) as $mwcInfo | map(select(.gender == "MALE" and ([.organization] as $organization | [.subOrgType] as $subOrgType | ((["Elders Quorum"] | contains($organization)) and (["ELDERS_QUORUM_PRESIDENCY"] | contains($subOrgType))) ) )) | map(.name) as $targetMembers | $all | map(select(.filename == "directory.json"))[0].object | map(. as $household | .members | map(select([.name] as $targetMember | $targetMembers | contains($targetMember)))  | map({name, district: ($household | .district), neighborhood: ($household | .neighborhood), address: $household.address, email, phone, age: (.name as $mName | $eqInfo | map(select(.name == $mName))[0].age), birthDay: (.name as $mName | $eqInfo | map(select(.name == $mName))[0].birthDay), positions: (.name as $mName | $mwcInfo | map(select(.name == $mName)) | reverse | map({unitName, organization, position})) })[0]) | map(select((. == null | not) and (.age == null | not)))| sort_by(.district, .positions[0].organization, .name)' > eq-pres-members.json
}

# =======================
function fetchElders {
dividerLine
echo "fetching elders"

curl 'https://lcr.churchofjesuschrist.org/services/orgs/sub-orgs-with-callings?lang=eng&subOrgId=5873015' -H 'authority: lcr.churchofjesuschrist.org' -H 'pragma: no-cache' -H 'cache-control: no-cache' -H 'accept: application/json, text/plain, */*' -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36' -H 'sec-fetch-site: same-origin' -H 'sec-fetch-mode: cors' -H 'referer: https://lcr.churchofjesuschrist.org/orgs/5873015?lang=eng' -H 'accept-encoding: gzip, deflate, br' -H 'accept-language: en-US' -H $'cookie: audience_split=21; _fbp=fb.1.1558727984750.576138409; WRUIDCD=1979799963828235; lds-preferred-lang-v2=eng; s_fid=10C2A7BB8E217B78-195A92D72803F241; _ga=GA1.2.1976242211.1564161692; _cs_c=1; _cs_ex=1; cr-aths=shown; aam_sc=aamsc%3D751537%7C708195; aam_uuid=58837750016941287141775247194571768784; amlbcookie-int=01; ORIG_URL=/sso?realm=/church&service=OktaOIDC&goto=https%3A%2F%2Frecovery-test.churchofjesuschrist.org%3A443%2Fagent%2Fcustom-login-response%3Fstate%3D816bf7c0-bd29-83ba-527c-9961f7b430d5%26realm%3D%252Fchurch%26service%3DOktaOIDC&original_request_url=https%3A%2F%2Frecovery-test.churchofjesuschrist.org%3A443%2F&authIndexType=service&authIndexValue=OktaOIDC; NTID=mCZIerHXQoW74H0AxNi5IkA8FHLSCk8w; OAUTH_LOGOUT_URL=; ChurchSSO-int=gSBvaYM8bzrBTSe3a4s52vUDSi0.*AAJTSQACMDIAAlNLABxzcXhVUDRFcjFXaVlOQ1FvZVNSZGhUcS9sNFE9AAR0eXBlAANDVFMAAlMxAAIwMQ..*; Church-auth-jwt-int=eyJ0eXAiOiJKV1QiLCJraWQiOiJrVlR5NDVhb0JoUnVBcWJ2MnQwbWU2NVpIMEk9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiJlNGM0N2IyMy00NjYyLTQ3ODUtOGIwNi01NDE3ODU4MmY2YWItMTA4MjM2NyIsImlzcyI6Imh0dHBzOi8vaWRlbnQtaW50LmNodXJjaG9mamVzdXNjaHJpc3Qub3JnL3Nzby9vYXV0aDIiLCJ0b2tlbk5hbWUiOiJpZF90b2tlbiIsIm5vbmNlIjoiRjM1NzJCQjBEMEM3QTM3QjkxODM1QUNBMzQwREI2MkEiLCJhdWQiOiJsMTgwMjYiLCJhY3IiOiIwIiwic19oYXNoIjoid2Zwa1N0ZXBkWG9SSHJUSTFJMjFodyIsImF6cCI6ImwxODAyNiIsImF1dGhfdGltZSI6MTU4MTExMzc2NCwiZm9yZ2Vyb2NrIjp7InNzb3Rva2VuIjoiZ1NCdmFZTThienJCVFNlM2E0czUydlVEU2kwLipBQUpUU1FBQ01ESUFBbE5MQUJ4emNYaFZVRFJGY2pGWGFWbE9RMUZ2WlZOU1pHaFVjUzlzTkZFOUFBUjBlWEJsQUFORFZGTUFBbE14QUFJd01RLi4qIiwic3VpZCI6ImUzODljZWEwLTJlNDgtNGRlNi1hMTk2LWY4MTVlMzIwOTg2ZC0xMTQ5NzQyIn0sInJlYWxtIjoiL2NodXJjaCIsImV4cCI6MTU4MTE1Njk2NCwidG9rZW5UeXBlIjoiSldUVG9rZW4iLCJpYXQiOjE1ODExMTM3NjQsImFnZW50X3JlYWxtIjoiL2NodXJjaCJ9.Noaz_JG8xz2xavp5Q8pRuPktedVQgFf21fRyDVLWyQvqd8MGiohsrr8AXVPKQZrcbQieH0OzHqDzpRqv_9PJ7lLOeqc6SYaOrmzU3cj-JBUP1hAeEB3Vwsb-0d6YFv0-Z4cvuJIbPQXSuj2ku6NRQRF5V95xtQMVloKYzGRe_HNRG4NG7D9ud5fryq7YlQsqQe5NKoo6sJ1A2hjiUjt4own4tBqvuA_HCPWExvnHJ1uGcro-0Gxm6AsFQoHuVj_zjvMHILHddgAZb2xq_i8K8HDqlHNycf7eKSMpnoP5M3yYrIEZq9X4vPf2_bNmpzigv_KKCarg0QTs_Ass9RT1rQ; check=true; audience_s_split=64; s_cc=true; mboxEdgeCluster=28; _CT_RS_=Recording; __CT_Data=gpv=80&ckp=tld&dm=churchofjesuschrist.org&apv_59_www11=81&cpv_59_www11=80&rpv_59_www11=80; ADRUM=s=1581303202963&r=https%3A%2F%2Fwww.churchofjesuschrist.org%2F%3F479231918; ctm={\'pgv\':1350636977909173|\'vst\':7385663247553829|\'vstr\':5589777858429154|\'intr\':1581303204375|\'v\':1|\'lvst\':40257}; agent-authn-tx=eAGtjU0KwyAQRu8yawccjUYDuUFvULoYdUIWaRPyQwshd6+7XqC798Hje/cTtp13gQ68xEgSIhbyCT0PAVlzQpNLSy56nXQDCo51qvLt3fd1PGUf54J5LvWBFIzCRdYNuvNSsJQFutcxTQrkU5FcIKttIH+pX9ayd8Y0GW2QiJTtgMwxYzLis0sucav/kw3X4wtahUVo; RT="z=1&dm=churchofjesuschrist.org&si=4b6bde0e-30a3-4c02-a935-10ee036a655a&ss=k6fv39vp&sl=1&tt=3xk&bcn=%2F%2F17c8edca.akstat.io%2F&ld=3xv&nu=265aa681196d3099ae5db03a5201bc77&cl=aem&ul=af3&hd=chh"; TS01b07831=01999b702368a61c83c814648324cf1d39b577e9f29e339971a112868a38dfb670410b394611b9f686b1f98ef296160de0bfc66d0e; JSESSIONID=0; __VCAP_ID__=da0a8fd4-87fa-4a73-7603-5f46; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; ChurchSSO='"${ChurchSSO}"'; Church-auth-jwt-prod='"${ChurchAuthJwtProd}"'; mbox=PC#ff77b07984e6447e8ca81967c1376f11.28_0#1644548038|session#2d8bd0374b7147cb86c3b15127f8eca8#1581305268; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=1099438348%7CMCIDTS%7C18303%7CMCMID%7C45993473060174549671353300097144335983%7CMCAAMLH-1581908208%7C9%7CMCAAMB-1581908208%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1581310608s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C2.1.0; s_sq=ldsall%3D%2526pid%253Dchurchofjesuschrist.org%252520%25253A%252520lcr%252520%25253A%252520%2526pidt%253D1%2526oid%253Dhttps%25253A%25252F%25252Flcr.churchofjesuschrist.org%25252Forgs%25252F5873015%25253Flang%25253Deng%2526ot%253DA; utag_main=v_id:016aeb6d84c7000c9febf6d43f4003079007407101788$_sn:243$_ss:0$_st:1581305211710$vapi_domain:churchofjesuschrist.org$dc_visit:243$_se:3$ses_id:1581303192943%3Bexp-session$_pn:5%3Bexp-session$dc_event:13%3Bexp-session$dc_region:us-east-1%3Bexp-session; t_ppv=churchofjesuschrist.org%20%3A%20lcr%20%3A%20%2C66%2C56%2C676%2C15152; ADRUM_BTa=R:0|g:623f5d35-0215-4173-aaf6-fd2567f760ed|n:customer1_acb14d98-cf8b-4f6d-8860-1c1af7831070; ADRUM_BT1=R:0|i:14049|e:223' -H 'lds-account-id: 1562cace-a0ad-4df9-a868-54f2bfe5f9cc' --compressed > eq.json

sleep 2

eqWip=$(cat eq.json | jq '.[0] as $head | $head.filterOffices | reduce .[] as $item ({}; . * ($item.codes | reduce .[] as $code ({}; . * ({ ($code|tostring): $item.name })))) | . as $officeMap | $head.members | map({ name, id, gender, birthDate, birthDayFormatted, address, priesthood: $officeMap[(.priesthoodCode | tostring)], actualAge, nonMember, endowed, eligibleForHomeTeachingAssignment })')

echo "$eqWip" | jq ''"$jqNeighborhood"'; '"$jqDistrict"'; map(. as $orig | (.address | district) as $district | (.address | neighborhood) as $neighborhood | $orig + {$district} + {$neighborhood})' > eq-cleaned.json
}

# =======================
function transformDirectory {
dividerLine
echo "transforming directory (e.g., reduce strings, alloy buildings)"

jqNeighborhood='def neighborhood: 
if (. | test( "Dry Creek"; "i" )) then "dry-creek" 
elif (. | test( "Quivira"; "i" )) then "quivira" 
elif (. | test( "Silver Oak"; "i" )) then "silver-oak" 
elif (. | test( "Sterling"; "i" )) then "sterling-loop" 
elif (. | test( "Unity M"; "i" )) then "alloy-m" 
elif (. | test( "Unity N"; "i" )) then "alloy-n" 
elif (. | test( "Unity P"; "i" )) then "alloy-p" 
elif (. | test( "Unity Q"; "i" )) then "alloy-q" 
elif (. | test( "Unit M"; "i" )) then "alloy-m" 
elif (. | test( "Unit N"; "i" )) then "alloy-n" 
elif (. | test( "Unit P"; "i" )) then "alloy-p" 
elif (. | test( "Unit Q"; "i" )) then "alloy-q" 
elif (. | test( "Apt M"; "i" )) then "alloy-m" 
elif (. | test( "Apt N"; "i" )) then "alloy-n" 
elif (. | test( "Apt P"; "i" )) then "alloy-p" 
elif (. | test( "Apt Q"; "i" )) then "alloy-q" 
elif (. | test( "Unt M"; "i" )) then "alloy-m" 
elif (. | test( "Unt N"; "i" )) then "alloy-n" 
elif (. | test( "Unt P"; "i" )) then "alloy-p" 
elif (. | test( "Unt Q"; "i" )) then "alloy-q" 
elif (. | test( " 20 W"; "i" )) then "waters-edge" 
else "z-not-available" end'

jqDistrict='def district: 
if (. | test( "Dry Creek"; "i" )) then "district-02" 
elif (. | test( "Quivira"; "i" )) then "district-02" 
elif (. | test( "Silver Oak"; "i" )) then (
  . | split(" ")[0] | tonumber | if(. <= 49) then ("district-03") else ("district-02") end
)
elif (. | test( "Sterling"; "i" )) then "district-03" 
elif (. | test( "Unity M"; "i" )) then "district-01" 
elif (. | test( "Unity N"; "i" )) then "district-01" 
elif (. | test( "Unity P"; "i" )) then "district-01" 
elif (. | test( "Unity Q"; "i" )) then "district-01" 
elif (. | test( "Unit M"; "i" )) then "district-01" 
elif (. | test( "Unit N"; "i" )) then "district-01" 
elif (. | test( "Unit P"; "i" )) then "district-01" 
elif (. | test( "Unit Q"; "i" )) then "district-01" 
elif (. | test( "Apt M"; "i" )) then "district-01" 
elif (. | test( "Apt N"; "i" )) then "district-01" 
elif (. | test( "Apt P"; "i" )) then "district-01" 
elif (. | test( "Apt Q"; "i" )) then "district-01" 
elif (. | test( "Unt M"; "i" )) then "district-01" 
elif (. | test( "Unt N"; "i" )) then "district-01" 
elif (. | test( "Unt P"; "i" )) then "district-01" 
elif (. | test( "Unt Q"; "i" )) then "district-01" 
elif (. | test( " 20 W"; "i" )) then "district-01" 
else "district-unassigned" end'

cat directory-orig.json | jq ''"$jqNeighborhood"'; '"$jqDistrict"'; map(. as $orig | (.address | district) as $district | (.address | neighborhood) as $neighborhood | $orig + {$district} + {$neighborhood})' > directory.json

######## Commented notes

# echo "fetching directory contact info"
# 
# cat directory.json | jq 'map(.members) | flatten | map(.name)' > directory-names.json
# cat directory.json | jq 'map(. as $household | $household | {phone, email, address, district} as $hdata | $household.members | map({name, phone: (if (.phone | length) > 0 then .phone else $hdata.phone end), email: (if (.email | length) > 0 then .email else $hdata.email end), address: $hdata.address, district: $hdata.district })) | flatten' > directory-contact-info.json

# elif (. | test( "Hackberry"; "i" )) then "02-hackberry" 
# elif (. | test( "Samara"; "i" )) then "02-samara" 
# elif (. | test( "Sicula"; "i" )) then "02-sicula" 
# elif (. | test( "Serrata"; "i" )) then "02-serrata" 
# elif (. | test( "Syracuse"; "i" )) then "02-syracuse" 
# elif (. | test( "Drupe"; "i" )) then "02-drupe" 

# elif (. | test( "Silver Oak"; "i" )) then "03-silver-oak" 
# if (. | test( "Dry Creek"; "i" )) then "02-dry-creek" 
# if (. | test( "Dry Creek"; "i" )) then (if (. | split(" ")[0] | tonumber | if(. == 124 or . == 132 or . == 140) then ("03-dry-creek") else ("02-dry-creek") end)) 
# if (. | test( "Dry Creek"; "i" )) then (if (. | split(" ")[0] | tonumber | if([.] | contains([124, 132, 140])) then ("03-dry-creek") else ("02-dry-creek") end)) 


# cat directory.json | jq 'def neighborhood: if (. | test( "Dry Creek"; "i" )) then "03-dry-creek" elif (. | test( "Quivira"; "i" )) then "03-quivira" elif (. | test( "Hackberry"; "i" )) then "02-hackberry" elif (. | test( "Samara"; "i" )) then "02-samara" elif (. | test( "Serrata"; "i" )) then "02-serrata" elif (. | test( "Silver Oak"; "i" )) then "03-silver-oak" elif (. | test( "Sterling"; "i" )) then "01-sterling-loop" elif (. | test( "Syracuse"; "i" )) then "02-syracuse" elif (. | test( "Drupe"; "i" )) then "02-drupe" elif (. | test( "Unity M"; "i" )) then "01-alloy-m" elif (. | test( "Unity N"; "i" )) then "01-alloy-n" elif (. | test( "Unity P"; "i" )) then "01-alloy-p" elif (. | test( "Unity Q"; "i" )) then "01-alloy-q" elif (. | test( "Unit M"; "i" )) then "01-alloy-m" elif (. | test( "Unit N"; "i" )) then "01-alloy-n" elif (. | test( "Unit P"; "i" )) then "01-alloy-p" elif (. | test( "Unit Q"; "i" )) then "01-alloy-q" elif (. | test( "Apt M"; "i" )) then "01-alloy-m" elif (. | test( "Apt N"; "i" )) then "01-alloy-n" elif (. | test( "Apt P"; "i" )) then "01-alloy-p" elif (. | test( "Apt Q"; "i" )) then "01-alloy-q" elif (. | test( "Unt M"; "i" )) then "01-alloy-m" elif (. | test( "Unt N"; "i" )) then "01-alloy-n" elif (. | test( "Unt P"; "i" )) then "01-alloy-p" elif (. | test( "Unt Q"; "i" )) then "01-alloy-q" else "n/a" end; reduce .[] as $entry ([]; . + (($entry.address | neighborhood) as $district | $entry.members | map({uuid, name, phone, email, address: $entry.address, $district, members: $entry.members})))'

# cat directory.json | jq '. | reduce .[] as $entry ([]; . + (($entry.address | district) as $district | $entry.members | map({uuid, name, phone, email, address: $entry.address, $district, members: $entry.members})))' > directory-cleaned.json
# cat directory.json | jq '. | reduce .[] as $entry ([]; . + ($entry.members | map({uuid, name, phone, email, address: $entry.address, district: $entry.district})))' > directory-cleaned.json
}

# =======================
function fetchDirectory {
dividerLine
echo "fetching directory"

# curl 'https://directory.churchofjesuschrist.org/api/v4/households?unit=13730' -H 'Sec-Fetch-Mode: cors' -H 'Referer: https://directory.churchofjesuschrist.org/13730' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.87 Safari/537.36' -H 'x-refresh: '"${refresh_token}" -H 'Accept-Language: en' -H 'authorization: Bearer '"${authorization_token}" --compressed > directory.json

# curl 'https://directory.churchofjesuschrist.org/api/v4/households?unit=13730' -H 'Pragma: no-cache' -H 'Sec-Fetch-Site: same-origin' -H 'Accept-Encoding: gzip, deflate, br' -H 'x-refresh: '"${refresh_token}" -H 'Accept-Language: en' -H 'authorization: Bearer '"${authorization_token}" -H 'Sec-Fetch-Mode: cors' -H 'Accept: */*' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.87 Safari/537.36' -H 'Cache-Control: no-cache' -H 'Referer: https://directory.churchofjesuschrist.org/13730' -H $'Cookie: audience_split=21; _fbp=fb.1.1558727984750.576138409; WRUIDCD=1979799963828235; lds-preferred-lang-v2=eng; __CT_Data=gpv=18&ckp=tld&dm=churchofjesuschrist.org&apv_59_www11=19&cpv_59_www11=18&rpv_59_www11=18; ctm={\'pgv\':74967302419333|\'vst\':2542134181393777|\'vstr\':5589777858429154|\'intr\':1563820041606|\'v\':1|\'lvst\':304}; s_fid=10C2A7BB8E217B78-195A92D72803F241; _gcl_au=1.1.1161084623.1564161692; _ga=GA1.2.1976242211.1564161692; check=true; TS01b07831=01999b7023c71f1fcbeee5b7e9f36b7e495ab2d50362ac5c86a92081c79bf13d24993c1ba84cba1872b2094bf981ccc985e78737cc; audience_s_split=19; s_cc=true; amlbcookie=75; TS011e50d7=01999b70239ad4936aae6a27f8fc2534ed10a9fcf756674f8faa9bd8bf281130f95734d06dc71f7f651922e434c0595ea3ec9cc549; TS01289383=01999b7023d7031d746945126d75fbff49a7f86caf2fec06593658c45137b3c7c05eb6bc7d6b75684a25a95acf5d8e555eeb1eb0a9; TS01b89640=01999b7023d7031d746945126d75fbff49a7f86caf2fec06593658c45137b3c7c05eb6bc7d6b75684a25a95acf5d8e555eeb1eb0a9; lds-id=AQIC5wM2LY4SfcyoeEs99rFEQLtwfAu3ZqjszOKZxswJsU0.*AAJTSQACMDIAAlNLABM3NTMzMzY1MTg3NzQ0MTk2NTY0AAJTMQACMDU.*; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; directory_access_token='"${directory_access_token}"'; directory_refresh_token='"${directory_refresh_token}"'; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=-330454231%7CMCIDTS%7C18127%7CMCMID%7C45993473060174549671353300097144335983%7CMCAAMLH-1566759798%7C9%7CMCAAMB-1566759798%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1566162198s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C3.1.2; mboxEdgeCluster=28; TS0186bb65=01999b70239503f9df1ebbb3ce2aadb5c0b92e85d0e6b1ac1ca716c7c86269465d084df560d46ff8a04f523a86c65823c30e243a29; ChurchSSO='"${ChurchSSO}"'; mbox=PC#ff77b07984e6447e8ca81967c1376f11.28_135#1629400550|session#247ef7c58e434df686291204eec534fb#1566156147; s_sq=%5B%5BB%5D%5D; t_ppv=Ward%20Directory%20and%20Map%2C0%2C100%2C447%2C3295; utag_main=v_id:016aeb6d84c7000c9febf6d43f4003079007407101788$_sn:94$_ss:0$_st:1566157551162$vapi_domain:churchofjesuschrist.org$dc_visit:94$_se:14$ses_id:1566154276880%3Bexp-session$_pn:4%3Bexp-session$dc_event:13%3Bexp-session$dc_region:us-east-1%3Bexp-session' -H 'Connection: keep-alive' --compressed > directory.json

curl 'https://directory.churchofjesuschrist.org/api/v4/households?unit=13730' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'authorization: Bearer '"${authorization_token}" -H 'x-refresh: '"${refresh_token}" -H 'Accept-Language: en-US' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36' -H 'Accept: */*' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-Mode: cors' -H 'Referer: https://directory.churchofjesuschrist.org/13730' -H 'Accept-Encoding: gzip, deflate, br' -H $'Cookie: audience_split=21; _fbp=fb.1.1558727984750.576138409; WRUIDCD=1979799963828235; lds-preferred-lang-v2=eng; s_fid=10C2A7BB8E217B78-195A92D72803F241; _ga=GA1.2.1976242211.1564161692; _cs_c=1; _cs_ex=1; aam_uuid=58837750016941287141775247194571768784; _CT_RS_=Recording; aam_sc=aamsc%3D751537%7C708195; __CT_Data=gpv=79&ckp=tld&dm=churchofjesuschrist.org&apv_59_www11=80&cpv_59_www11=79&rpv_59_www11=79; ctm={\'pgv\':1671447134779311|\'vst\':4659397996010721|\'vstr\':5589777858429154|\'intr\':1578887788899|\'v\':1|\'lvst\':21497}; ChurchSSO-int=wzBgxCgubHc4co1L7nMvZSsKKe0.*AAJTSQACMDIAAlNLABxZc3R0TTVkbndaNys0NGtrTjcrV1pMWE9HMmM9AAR0eXBlAANDVFMAAlMxAAIwMQ..*; Church-auth-jwt-int=eyJ0eXAiOiJKV1QiLCJraWQiOiJrVlR5NDVhb0JoUnVBcWJ2MnQwbWU2NVpIMEk9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiJiZDg2ZDQ0MC1kOGQyLTRjYjMtOTc3ZS0wYTA4ZDZmMDk5MmItMTA0NDc1MTYiLCJpc3MiOiJodHRwczovL2lkZW50LWludC5jaHVyY2hvZmplc3VzY2hyaXN0Lm9yZy9zc28vb2F1dGgyIiwidG9rZW5OYW1lIjoiaWRfdG9rZW4iLCJub25jZSI6IkJFOTc3NTVENTQ2MUZGQ0JDNEY1ODEyQkU4QjkyN0U2IiwiYXVkIjoibDE4MDI3IiwiYWNyIjoiMCIsInNfaGFzaCI6Ilp5MzEtcGlpWGNSOUZ1VS0zaG9sT3ciLCJhenAiOiJsMTgwMjciLCJhdXRoX3RpbWUiOjE1Nzk2NDQxMTAsImZvcmdlcm9jayI6eyJzc290b2tlbiI6Ind6Qmd4Q2d1YkhjNGNvMUw3bk12WlNzS0tlMC4qQUFKVFNRQUNNRElBQWxOTEFCeFpjM1IwVFRWa2JuZGFOeXMwTkd0clRqY3JWMXBNV0U5SE1tTTlBQVIwZVhCbEFBTkRWRk1BQWxNeEFBSXdNUS4uKiIsInN1aWQiOiJmMzY1OGM3Mi1lMjgyLTRiY2YtOGUxMy0yZTcxZmU2MzhhYzktMTAzMzMyNjcifSwicmVhbG0iOiIvY2h1cmNoIiwiZXhwIjoxNTc5Njg3MzEwLCJ0b2tlblR5cGUiOiJKV1RUb2tlbiIsImlhdCI6MTU3OTY0NDExMCwiYWdlbnRfcmVhbG0iOiIvY2h1cmNoIn0.BiWwTjRX6BMZ4Nyeq3fX49DU36cxiYqkP9h0EKWqLY4x73TRatdZ4_rDhETFWxog75rWXtyCn21l84sw8ueP6GutKCgwHysJlFoBnpn2_BHPGsitdpDPo8AfrZSEEfnOvRVO6vPFUkD7WuxwTErfbZ-CNs_5Lm_JLonAY4CAP43St6gq-aeqK_cFZcsG4_ARbk2uX4BGZgYDXIHUxGZZZ6LWX7YuPBiSIWqYq9LsgNoTwgu2foHIf1Q_VQI7g0nY8HhJdt2UjHm312VaEk6aMZ3t3-Zyi_lOxVqsuOVyGHyqCSxTgL2lOeuNkMXvKi11_AHQhWr5IL-hIOwN4e7YCg; check=true; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; audience_s_split=74; s_cc=true; TS01b07831=01999b70239f8d3c15fe7bb56e832f735ecb59dfa3809782e3ecd3405397b369368c479be387201e3b1a950c11ac4ea94a3946e73b; ADRUM=s=1579825962969&r=https%3A%2F%2Fwww.churchofjesuschrist.org%2F%3F479231918; RT="z=1&dm=churchofjesuschrist.org&si=d35cd4ef-57f0-4ed4-8a5d-dec2214a0714&ss=k5rfk3p0&sl=2&tt=6bp&obo=1&bcn=%2F%2F173e2548.akstat.io%2F&ld=11hh&nu=08b89d78d40e90b8b126f7a10960d4e4&cl=12x9&ul=12xn&hd=13f1"; TS01a096ec=01999b7023f962af0b95544d7ea951d0dac619e2fcf70032c859dbad548e18bc6f59a1efa460369ab9d55d0b22c33e35ef2535e546; ChurchSSO='"${ChurchSSO}"'; Church-auth-jwt-prod='"${ChurchAuthJwtProd}"'; TS0186bb65=01999b70235336f0c67a0f3216747f586fb6c09c2f76aa8d8d9e8501146d5753fd9e1eb1bcf8726bb98359aa5204bd33485b471455; directory_access_token='"${directory_access_token}"'; directory_refresh_token='"${directory_refresh_token}"'; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=-330454231%7CMCIDTS%7C18280%7CMCMID%7C45993473060174549671353300097144335983%7CMCAAMLH-1580434689%7C9%7CMCAAMB-1580434689%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1579837089s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C3.1.2; s_sq=%5B%5BB%5D%5D; mboxEdgeCluster=28; mbox=PC#ff77b07984e6447e8ca81967c1376f11.28_0#1643074702|session#c2983b608c5f46c4875b95c6dfd7f5e3#1579831430; ADRUM_BTa=R:47|g:d60c3734-8ec9-4ba6-a83f-8b76de91883c|n:customer1_acb14d98-cf8b-4f6d-8860-1c1af7831070; ADRUM_BT1=R:47|i:22765|e:1002|d:92; t_ppv=Ward%20Directory%20and%20Map%2C0%2C100%2C267%2C2447; utag_main=v_id:016aeb6d84c7000c9febf6d43f4003079007407101788$_sn:226$_ss:0$_st:1579831702234$vapi_domain:churchofjesuschrist.org$dc_visit:226$_se:3$ses_id:1579827934751%3Bexp-session$_pn:8%3Bexp-session$dc_event:20%3Bexp-session$dc_region:us-east-1%3Bexp-session' -H 'lds-account-id: 1562cace-a0ad-4df9-a868-54f2bfe5f9cc' --compressed > directory.json
sleep 2

cp directory.json directory-orig.json
}

# =======================
function fetchMinisteringAssignments {
dividerLine
echo "fetching ministering assignments"

curl 'https://lcr.churchofjesuschrist.org/ministering?lang=eng&type=EQ' \
  -H 'Connection: keep-alive' \
  -H 'Pragma: no-cache' \
  -H 'Cache-Control: no-cache' \
  -H 'sec-ch-ua: "Chromium";v="94", "Google Chrome";v="94", ";Not A Brand";v="99"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'Sec-Fetch-Mode: navigate' \
  -H 'Sec-Fetch-User: ?1' \
  -H 'Sec-Fetch-Dest: document' \
  -H 'Referer: https://ident-prod.churchofjesuschrist.org/' \
  -H 'Accept-Language: en-US' \
  -H 'Cookie: Church-auth-jwt-prod='"${ChurchAuthJwtProd}"'; ChurchSSO=ChurchSSO='"${ChurchSSO}"';' \
  --compressed | perl -p -e 's#<#\n<#g' | sed '/__NEXT_DATA__/!d; s/<[^>]*>//g' > ministering-eq.json

# | perl -p -e 's#<#\n<#g' | sed '/__NEXT_DATA__/!d; s/<[^>]*>//g' > ministering-eq.json
# | perl -p -e 's#<#\n<#g' | sed '/__NEXT_DATA__/!d; s/^[^=]*= //g' > ministering-eq.json
# sleep 2

sleep 2
}

# =======================
function fetchProposedMinisteringAssignments {
dividerLine
echo "fetching proposed ministering assignments"

curl 'https://lcr.churchofjesuschrist.org/ministering-proposed-assignments?lang=eng&type=EQ' \
  -H 'Connection: keep-alive' \
  -H 'Pragma: no-cache' \
  -H 'Cache-Control: no-cache' \
  -H 'sec-ch-ua: "Chromium";v="94", "Google Chrome";v="94", ";Not A Brand";v="99"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'Sec-Fetch-Mode: navigate' \
  -H 'Sec-Fetch-User: ?1' \
  -H 'Sec-Fetch-Dest: document' \
  -H 'Referer: https://ident-prod.churchofjesuschrist.org/' \
  -H 'Accept-Language: en-US' \
  -H 'Cookie: Church-auth-jwt-prod='"${ChurchAuthJwtProd}"'; ChurchSSO=ChurchSSO='"${ChurchSSO}"';' \
  --compressed | perl -p -e 's#<#\n<#g' | sed '/__NEXT_DATA__/!d; s/<[^>]*>//g' > ministering-eq.json

# | perl -p -e 's#<#\n<#g' | sed '/__NEXT_DATA__/!d; s/<[^>]*>//g' > ministering-eq.json
# | perl -p -e 's#<#\n<#g' | sed '/__NEXT_DATA__/!d; s/^[^=]*= //g' > ministering-eq.json
# sleep 2

sleep 2
}

# =======================
function fetchYW {
dividerLine
echo "fetching yw"

curl 'https://lcr.churchofjesuschrist.org/services/orgs/sub-orgs-with-callings?ip=true&lang=eng&subOrgId=209083&unitNumber=13730' \
  -H 'Connection: keep-alive' \
  -H 'Pragma: no-cache' \
  -H 'Cache-Control: no-cache' \
  -H 'sec-ch-ua: "Chromium";v="92", " Not A;Brand";v="99", "Google Chrome";v="92"' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Referer: https://lcr.churchofjesuschrist.org/orgs/209083?unitNumber=13730&lang=eng' \
  -H 'Accept-Language: en-US' \
  -H 'Cookie: cr-aths=shown; at_check=true; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; s_ips=1333; s_cc=true; PFpreferredHomepage=COJC; ORIG_URL=/sso?realm=/church&service=OktaOIDC&goto=https://www.churchofjesuschrist.org/services/platform/v3/set-wam-cookie&authIndexType=service&authIndexValue=OktaOIDC; OAUTH_LOGOUT_URL=null; s_fid=7B5F17761279C3B3-1D97835CD233A4D2; notice_behavior=implied|us; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=-1124106680%7CMCIDTS%7C18853%7CMCMID%7C40667282663157899593710534620564257125%7CMCAAMLH-1629552863%7C9%7CMCAAMB-1629552863%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1628955263s%7CNONE%7CvVersion%7C5.2.0%7CMCAID%7CNONE; amlbcookie-prod=01; NTID=RZRJcz8Zj3EVLtlgM75bLImY0zqKBDgv; JSESSIONID=0; __VCAP_ID__=04be1c00-4627-49ee-70c9-4b98; sat_track=true; notice_behavior=implied|us; RT="z=1&dm=churchofjesuschrist.org&si=ce0ed987-a46d-45ed-a00a-5ae6faa8da11&ss=ksao0uhg&sl=0&tt=0&bcn=%2F%2F173e2547.akstat.io%2F"; agent-authn-tx=eAENjEEKgzAQAP+y5yxkTbKagD/oD0oP0V3wkFbRSAvi35vbDAzzvOCouSokiCFPQspIlnucos0ozge0wj25MHeDZTBw7qXFj+84NnlrXVbBeZV2IAOLZtH9gHTdBjbZIH3OUgzoryFxN8TgvKf79Qf5JCI7; ChurchSSO='"${ChurchSSO}"'; Church-auth-jwt-prod='"${ChurchAuthJwtProd}"'; gpv_Page=organization; s_tp=1333; mbox=PC#eda1224126154de99f0be65c0381779e.35_0#1692197873|session#d0a66df0cf1d4baea00e023210f6eee4#1628954124; s_plt=1.82; s_pltp=organization; s_ppv=organization%2C100%2C100%2C1333%2C1%2C1; gpv_cURL=lcr.churchofjesuschrist.org%2Forgs%2F209083; s_sq=%5B%5BB%5D%5D' \
  --compressed > yw.json

sleep 2

# {"name":"Macy, Jenna","spokenName":"Jenna Macy","nameOrder":null,"birthDate":"20060919","birthDateSort":"20060919","birthDaySort":"09-19","birthDayFormatted":"19 Sep","birthDateFormatted":"19 Sep 2006","gender":"FEMALE","genderCode":2,"mrn":null,"id":19080036881,"email":"macyjenna20@gmail.com","householdEmail":"cmacy001@yahoo.com","phone":"+1 (385) 335-7300","householdPhone":"8015410092","unitNumber":13730,"unitName":"Vineyard  1st Ward","priesthood":null,"priesthoodCode":null,"priesthoodType":null,"age":14,"actualAge":14,"actualAgeInMonths":178,"genderLabelShort":"F","visible":null,"nonMember":false,"outOfUnitMember":false,"notAccountable":false,"address":"205 S. Dry Creek Lane<br />Vineyard, Utah 84058","endowed":null,"sealedToSpouse":null,"defaultClass":true,"defaultClassTypeId":3082,"adultAgeOrMarried":false,"htvtCompanions":null,"htvtAssignments":null,"eligibleForHomeTeachingAssignment":false,"sustainedDate":null,"accountable":true,"formattedMrn":null,"setApart":false}

#   {
#     "name": "Claybaugh, Carter",
#     "gender": "MALE",
#     "birthDate": "20040413",
#     "priesthood": "PRIEST",
#     "actualAge": 17,
#     "nonMember": false,
#     "endowed": null,
#     "eligibleForHomeTeachingAssignment": true
#   },

#   {
#     "name": "Macy, Jenna",
#     "gender": "FEMALE",
#     "birthDate": "20060919",
#     "class": "YOUNG_WOMEN_18",
#     "actualAge": 14,
#     "nonMember": false,
#     "endowed": null,
#     "eligibleForHomeTeachingAssignment": false
#   },

cat yw.json | jq '.[0].children | map(select(.classGroup != null)) | map(. as $head | $head.members | map({ name, gender, birthDate, priesthood: null, class: $head.firstOrgType, actualAge, nonMember, endowed, eligibleForHomeTeachingAssignment })) | reduce .[] as $class ([]; . + $class)' > yw-cleaned.json
}

