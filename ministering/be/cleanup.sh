prevImgData=$(cat yearbook-photo-attributes.dat.bak)
directory=$(cat  ../../directory-cleaned.json)
eq=$(cat  ../../eq-cleaned.json)

echo "{" > yearbook-photo-attributes.dat.new
echo "" > missing-uuid.dat
for uuid in $(echo "$prevImgData" | jq -r '. | keys | join("\n")' | xargs); do
  personName=$(cat ../../directory.json | jq -r 'map(.members) | flatten | map(select(.uuid == "'"$uuid"'"))[0].name')
  # echo "$personName"

  if [ ! "$personName" == "null" ]; then
    personId=$(echo "$eq" | jq 'map(select(.name == "'"$personName"'"))[0].id')
    # echo "$personId"

    
    personImageBlock=$(echo $(echo "$prevImgData" | jq '.["'"$uuid"'"]' | jq '{"name":"'"$personName"'"} * .' )",")
    # echo "$personImageBlock"
    personImageBlock="\"$personId\":${personImageBlock}"
    echo "$personImageBlock"
    echo "$personImageBlock" >> yearbook-photo-attributes.dat.new
  else
    echo "$uuid" >> missing-uuid.dat
  fi
  
done
echo "{}}" >> yearbook-photo-attributes.dat.new
