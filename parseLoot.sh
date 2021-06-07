
get_defines() {
	user=$(whoami)
	raw=$(find /Users/$user/Library/Application\ Support/Steam/steamapps/common/IdleChampions/IdleDragonsMac.app/Contents/Resources/Data/ -type f -name 'webRequestLog.txt' -exec cat {} \;) || die "File not found."
	json=$(grep '{' <<<$raw | jq -c '.') || die "Error in JSON."
	echo "$json"
}

defines=$(get_defines)
#get hero names/ids
files=$(find . -type f -name "results*.json")
if [[ -n $files ]]; then
	heroJSON=$(jq '.hero_defines[]' <<<$defines 2>/dev/null | jq '{"hero_id":.id,"hero_name":.name}')
	results=$(jq -c '.loot_details[] | select ( . != null )' results* 2>/dev/null | grep -v "add_gold_amount" | grep -v ',"okay":true,' | grep -v "add_inventory_buff" | jq 'select(.gilded == true)')
	filter=$(jq '{"hero_id": .hero_id, "slot_id": .slot_id}'<<<$results)
	merged=$(echo "$heroJSON" "$filter" | jq --slurp 'group_by(.hero_id)[] | add')
	newShiny=$(jq 'if .slot_id? then . else empty end'<<<"$merged")
	echo "New Shinys found:"
	jq '.' <<<"$newShiny"
	echo "Clean up results?"
	select yn in "Yes" "No"; do
		case $yn in
			Yes ) find . -type f -name "results*.json" -exec mv {} ./oldresults/ \; 2>/dev/null; break;;
			No ) exit;;
			* ) echo "Please select yes or no.";;
		esac
	done
else
	echo "No results found. Have you purchased chests?"
fi
