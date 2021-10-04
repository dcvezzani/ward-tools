# send individual and personalize text messages
message=$(echo "$1" | base64 --decode)
# echo "code: $code, message: '${message}', name: '${2}'"
# exit 1

# | perl -p -e 's###g'))
for line in $2; do
  name="${line##*,}"
  phone="${line%%,*}"

  if [ "$phone" == "" ]; then
    echo "Recipient (${name}) is missing a phone number.  Skipping to next recipient."
    continue
  fi 

  echo "Sending ${phone} > ${name}..."

  # MSG=$(echo "${message}" | perl -p -e 's#\${name}#'"$name"'#g')

  # see http://tldp.org/LDP/abs/html/parameter-substitution.html
  # additional placeholders go here
  # string with variable // pattern / value to replace pattern
  # '//' means global; '/' means just the first
  MSG=$(echo "${message//'${name}'/$name}")

# read -r -d '' MSG <<'EOF'   # everything is literal; don't resolve variables

# read -r -d '' MSG <<EOF
#   ${messageCopy}
# EOF
  # echo "messageCopy: ${messageCopy}"

  # xxx osascript ~/scripts/sendMessage.applescript "$phone" "$MSG"
  # osascript ./scripts/sendMessage.scpt "$phone" "$MSG"
  # echo "MSG: $MSG"
  # echo $(pwd)

  # echo "encoded string: ${1}"
  code="$?"
  # echo "code: ${code}"

  if [ "$code" != 0 ]; then
    echo "code: $code, message: '${MSG}', name: '${name}'"
    exit "$code"
  fi
  sleep 2

done


#   set targetService to 1st service whose service type = iMessage
#   set targetService to 1st service whose service type = SMS

