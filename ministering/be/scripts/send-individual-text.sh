# send individual and personalize text messages
# /Users/dcvezzani/personal-projects/ward/ministering/be/scripts/send-individual-text.sh QnJvdGhlciAke25hbWV9LAoKVGhpcyBpcyBhIHRlc3QuCgotLS0gUHJlcy4gVmV6emFuaQ== Vezzani 2097569688

sendText () {
  message=$(echo "$1" | base64 --decode)
  name="$2"
  phone="$3"
  # echo "message: '${message}', \nname: '${name}', phone: '${phone}'"
  USAGE="Usage: send-individual-text.sh {message (base64 encoded)} {name} {phone}\nE.g., send-individual-text.sh QnJvdGhlciAke25hbWV9LAoKVGhpcyBpcyBhIHRlc3QuCgotLS0gUHJlcy4gVmV6emFuaQ== Vezzani 2097569688"

  if [ "$message" == "" ]; then
    echo "Message is required"
    echo "$USAGE"
    return 1
  fi 

  if [ "$name" == "" ]; then
    echo "Name is required"
    echo "$USAGE"
    return 1
  fi 
  
  if [ "$phone" == "" ]; then
    echo "Phone is required"
    echo "$USAGE"
    return 1
  fi

  # echo ">>> message: \"$message\""

  # see http://tldp.org/LDP/abs/html/parameter-substitution.html
  # additional placeholders go here
  # string with variable // pattern / value to replace pattern
  # '//' means global; '/' means just the first
  MSG=$(echo "${message//'${name}'/$name}")

  # echo ">>> MSG: \"$phone\" > \"$MSG\""

  osascript ./scripts/sendMessage.scpt "$phone" "$MSG"
  # echo "xosascript ./scripts/sendMessage.scpt \"$phone\" \"$MSG\""
  # echo "Sending ${phone} > ${name}: MSG: ${MSG}" | xargs

  code="$?"
  # echo "code: ${code}"

  if [ "$code" != 0 ]; then
    echo "code: $code, message: '${MSG}', name: '${name}'"
    exit "$code"
  fi
  sleep 2
}

sendText "$1" "$2" "$3"

#   set targetService to 1st service whose service type = iMessage
#   set targetService to 1st service whose service type = SMS


