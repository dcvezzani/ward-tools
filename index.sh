source functions.sh

echo "Get copy of Directory curl; paste in ./cookies.txt"
read cont
loadCookies

fetchDirectory

echo "Get copy of LCR curl; paste in ./cookies.txt"
read cont
loadCookies
# sleep 2

transformDirectory

fetchElders

fetchMembersWithCallings

fetchSisters

fetchYM

fetchYW

fetchMinisteringAssignments

transformMinisteringAssignments

transformDirectoryVersions

generateReport

echo "DONE!"

