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

# TODO: add these?
# aam_sc=aamsc%3D751537%7C708195; 
# ChurchSSO-int=wzBgxCgubHc4co1L7nMvZSsKKe0.*AAJTSQACMDIAAlNLABxZc3R0TTVkbndaNys0NGtrTjcrV1pMWE9HMmM9AAR0eXBlAANDVFMAAlMxAAIwMQ..*; 
# Church-auth-jwt-int=eyJ0eXAiOiJKV1QiLCJraWQiOiJrVlR5NDVhb0JoUnVBcWJ2MnQwbWU2NVpIMEk9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiJiZDg2ZDQ0MC1kOGQyLTRjYjMtOTc3ZS0wYTA4ZDZmMDk5MmItMTA0NDc1MTYiLCJpc3MiOiJodHRwczovL2lkZW50LWludC5jaHVyY2hvZmplc3VzY2hyaXN0Lm9yZy9zc28vb2F1dGgyIiwidG9rZW5OYW1lIjoiaWRfdG9rZW4iLCJub25jZSI6IkJFOTc3NTVENTQ2MUZGQ0JDNEY1ODEyQkU4QjkyN0U2IiwiYXVkIjoibDE4MDI3IiwiYWNyIjoiMCIsInNfaGFzaCI6Ilp5MzEtcGlpWGNSOUZ1VS0zaG9sT3ciLCJhenAiOiJsMTgwMjciLCJhdXRoX3RpbWUiOjE1Nzk2NDQxMTAsImZvcmdlcm9jayI6eyJzc290b2tlbiI6Ind6Qmd4Q2d1YkhjNGNvMUw3bk12WlNzS0tlMC4qQUFKVFNRQUNNRElBQWxOTEFCeFpjM1IwVFRWa2JuZGFOeXMwTkd0clRqY3JWMXBNV0U5SE1tTTlBQVIwZVhCbEFBTkRWRk1BQWxNeEFBSXdNUS4uKiIsInN1aWQiOiJmMzY1OGM3Mi1lMjgyLTRiY2YtOGUxMy0yZTcxZmU2MzhhYzktMTAzMzMyNjcifSwicmVhbG0iOiIvY2h1cmNoIiwiZXhwIjoxNTc5Njg3MzEwLCJ0b2tlblR5cGUiOiJKV1RUb2tlbiIsImlhdCI6MTU3OTY0NDExMCwiYWdlbnRfcmVhbG0iOiIvY2h1cmNoIn0.BiWwTjRX6BMZ4Nyeq3fX49DU36cxiYqkP9h0EKWqLY4x73TRatdZ4_rDhETFWxog75rWXtyCn21l84sw8ueP6GutKCgwHysJlFoBnpn2_BHPGsitdpDPo8AfrZSEEfnOvRVO6vPFUkD7WuxwTErfbZ-CNs_5Lm_JLonAY4CAP43St6gq-aeqK_cFZcsG4_ARbk2uX4BGZgYDXIHUxGZZZ6LWX7YuPBiSIWqYq9LsgNoTwgu2foHIf1Q_VQI7g0nY8HhJdt2UjHm312VaEk6aMZ3t3-Zyi_lOxVqsuOVyGHyqCSxTgL2lOeuNkMXvKi11_AHQhWr5IL-hIOwN4e7YCg; 
# TS01a096ec=01999b7023f962af0b95544d7ea951d0dac619e2fcf70032c859dbad548e18bc6f59a1efa460369ab9d55d0b22c33e35ef2535e546; 

echo "authorization_token=\"${authorization_token}\""
echo "refresh_token=\"${refresh_token}\""
echo "ChurchSSO=\"${ChurchSSO}\""
echo "ChurchAuthJwtProd=\"${ChurchAuthJwtProd}\""
echo "directory_access_token=\"${directory_access_token}\""
echo "directory_refresh_token=\"${directory_refresh_token}\""

read cont

echo "fetching ministering assignments"

curl 'https://lcr.churchofjesuschrist.org/ministering-proposed-assignments?lang=eng&type=EQ' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36' -H 'Sec-Fetch-User: ?1' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-Mode: navigate' -H 'Referer: https://lcr.churchofjesuschrist.org/ministering?lang=eng&type=EQ' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US' -H $'Cookie: audience_split=21; _fbp=fb.1.1558727984750.576138409; WRUIDCD=1979799963828235; lds-preferred-lang-v2=eng; s_fid=10C2A7BB8E217B78-195A92D72803F241; _ga=GA1.2.1976242211.1564161692; _cs_c=1; _cs_ex=1; cr-aths=shown; aam_sc=aamsc%3D751537%7C708195; aam_uuid=58837750016941287141775247194571768784; amlbcookie-int=01; ORIG_URL=/sso?realm=/church&service=OktaOIDC&goto=https%3A%2F%2Frecovery-test.churchofjesuschrist.org%3A443%2Fagent%2Fcustom-login-response%3Fstate%3D816bf7c0-bd29-83ba-527c-9961f7b430d5%26realm%3D%252Fchurch%26service%3DOktaOIDC&original_request_url=https%3A%2F%2Frecovery-test.churchofjesuschrist.org%3A443%2F&authIndexType=service&authIndexValue=OktaOIDC; NTID=mCZIerHXQoW74H0AxNi5IkA8FHLSCk8w; OAUTH_LOGOUT_URL=; ChurchSSO-int=gSBvaYM8bzrBTSe3a4s52vUDSi0.*AAJTSQACMDIAAlNLABxzcXhVUDRFcjFXaVlOQ1FvZVNSZGhUcS9sNFE9AAR0eXBlAANDVFMAAlMxAAIwMQ..*; Church-auth-jwt-int=eyJ0eXAiOiJKV1QiLCJraWQiOiJrVlR5NDVhb0JoUnVBcWJ2MnQwbWU2NVpIMEk9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJkY3ZlenphbmkiLCJhdWRpdFRyYWNraW5nSWQiOiJlNGM0N2IyMy00NjYyLTQ3ODUtOGIwNi01NDE3ODU4MmY2YWItMTA4MjM2NyIsImlzcyI6Imh0dHBzOi8vaWRlbnQtaW50LmNodXJjaG9mamVzdXNjaHJpc3Qub3JnL3Nzby9vYXV0aDIiLCJ0b2tlbk5hbWUiOiJpZF90b2tlbiIsIm5vbmNlIjoiRjM1NzJCQjBEMEM3QTM3QjkxODM1QUNBMzQwREI2MkEiLCJhdWQiOiJsMTgwMjYiLCJhY3IiOiIwIiwic19oYXNoIjoid2Zwa1N0ZXBkWG9SSHJUSTFJMjFodyIsImF6cCI6ImwxODAyNiIsImF1dGhfdGltZSI6MTU4MTExMzc2NCwiZm9yZ2Vyb2NrIjp7InNzb3Rva2VuIjoiZ1NCdmFZTThienJCVFNlM2E0czUydlVEU2kwLipBQUpUU1FBQ01ESUFBbE5MQUJ4emNYaFZVRFJGY2pGWGFWbE9RMUZ2WlZOU1pHaFVjUzlzTkZFOUFBUjBlWEJsQUFORFZGTUFBbE14QUFJd01RLi4qIiwic3VpZCI6ImUzODljZWEwLTJlNDgtNGRlNi1hMTk2LWY4MTVlMzIwOTg2ZC0xMTQ5NzQyIn0sInJlYWxtIjoiL2NodXJjaCIsImV4cCI6MTU4MTE1Njk2NCwidG9rZW5UeXBlIjoiSldUVG9rZW4iLCJpYXQiOjE1ODExMTM3NjQsImFnZW50X3JlYWxtIjoiL2NodXJjaCJ9.Noaz_JG8xz2xavp5Q8pRuPktedVQgFf21fRyDVLWyQvqd8MGiohsrr8AXVPKQZrcbQieH0OzHqDzpRqv_9PJ7lLOeqc6SYaOrmzU3cj-JBUP1hAeEB3Vwsb-0d6YFv0-Z4cvuJIbPQXSuj2ku6NRQRF5V95xtQMVloKYzGRe_HNRG4NG7D9ud5fryq7YlQsqQe5NKoo6sJ1A2hjiUjt4own4tBqvuA_HCPWExvnHJ1uGcro-0Gxm6AsFQoHuVj_zjvMHILHddgAZb2xq_i8K8HDqlHNycf7eKSMpnoP5M3yYrIEZq9X4vPf2_bNmpzigv_KKCarg0QTs_Ass9RT1rQ; check=true; audience_s_split=64; s_cc=true; mboxEdgeCluster=28; _CT_RS_=Recording; __CT_Data=gpv=80&ckp=tld&dm=churchofjesuschrist.org&apv_59_www11=81&cpv_59_www11=80&rpv_59_www11=80; ADRUM=s=1581303202963&r=https%3A%2F%2Fwww.churchofjesuschrist.org%2F%3F479231918; ctm={\'pgv\':1350636977909173|\'vst\':7385663247553829|\'vstr\':5589777858429154|\'intr\':1581303204375|\'v\':1|\'lvst\':40257}; RT="z=1&dm=churchofjesuschrist.org&si=4b6bde0e-30a3-4c02-a935-10ee036a655a&ss=k6fv39vp&sl=1&tt=3xk&bcn=%2F%2F17c8edca.akstat.io%2F&ld=3xv&nu=265aa681196d3099ae5db03a5201bc77&cl=aem&ul=af3&hd=chh"; TS01b07831=01999b702368a61c83c814648324cf1d39b577e9f29e339971a112868a38dfb670410b394611b9f686b1f98ef296160de0bfc66d0e; JSESSIONID=0; __VCAP_ID__=da0a8fd4-87fa-4a73-7603-5f46; AMCVS_66C5485451E56AAE0A490D45%40AdobeOrg=1; ChurchSSO='"${ChurchSSO}"'; Church-auth-jwt-prod='"${ChurchAuthJwtProd}"'; AMCV_66C5485451E56AAE0A490D45%40AdobeOrg=1099438348%7CMCIDTS%7C18303%7CMCMID%7C45993473060174549671353300097144335983%7CMCAAMLH-1581908208%7C9%7CMCAAMB-1581908208%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1581310608s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C2.1.0; mbox=PC#ff77b07984e6447e8ca81967c1376f11.28_0#1644548038|session#2d8bd0374b7147cb86c3b15127f8eca8#1581305625; utag_main=v_id:016aeb6d84c7000c9febf6d43f4003079007407101788$_sn:243$_ss:0$_st:1581305763077$vapi_domain:churchofjesuschrist.org$dc_visit:243$_se:3$ses_id:1581303192943%3Bexp-session$_pn:7%3Bexp-session$dc_event:20%3Bexp-session$dc_region:us-east-1%3Bexp-session; t_ppv=churchofjesuschrist.org%20%3A%20lcr%20%3A%20orgs%20%3A%20members-with-callings%2C66%2C54%2C676%2C256921; s_sq=ldsall%3D%2526pid%253Dchurchofjesuschrist.org%252520%25253A%252520lcr%252520%25253A%252520orgs%252520%25253A%252520members-with-callings%2526pidt%253D1%2526oid%253Dhttps%25253A%25252F%25252Flcr.churchofjesuschrist.org%25252Fministering%25253Flang%25253Deng%252526type%25253DEQ%2526ot%253DA' -H 'lds-account-id: 1562cace-a0ad-4df9-a868-54f2bfe5f9cc' --compressed | perl -p -e 's#<#\n<#g' | sed '/__NEXT_DATA__/!d; s/<[^>]*>//g' > ministering-eq.json

yarn start

echo "generating report"

cat report.json | jq '.' > report-final.json
sleep 2

echo "generating summary"

# cat report-final.json| jq '.by_district | to_entries | map({key, value: (.value | map({ name, age: .actualAge }))}) | from_entries' > report-summary.json
cat report-final.json| jq --sort-keys '{ministering_brothers: .ministering_brothers.by_district | to_entries | map({key, value: (.value | map(.name + " (" + (.actualAge | tostring) + ")") | sort)}) | from_entries, ministering_families: .ministering_families.by_district | to_entries | map({key, value: (.value | map(.name) | sort)}) | from_entries}' > report-summary.json
cat report-summary.json | jq '.'

echo "DONE!"

