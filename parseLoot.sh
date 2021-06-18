#!/usr/local/bin/bash

die () {
    echo >&2 "$@"
    exit 1
}

get_defines() {
	user=$(whoami)
	filepath='/Users/'$user'/Library/Application Support/Steam/steamapps/common/IdleChampions/IdleDragonsMac.app/Contents/Resources/Data/StreamingAssets/downloaded_files/cached_definitions.json'
	
	if [[ -r $filepath ]]; then
		json=$(jq '.' <"$filepath")
	else
		raw=$(find /Users/$user/Library/Application\ Support/Steam/steamapps/common/IdleChampions/IdleDragonsMac.app/Contents/Resources/Data/ -type f -name 'webRequestLog.txt' -exec cat {} \;) || die "File not found."
		json=$(grep '{' <<<$raw | jq -c '.') || die "Error in JSON."
	fi
	echo "$json"
}

defines=$(get_defines)
#get hero names/ids
files=$(find ./results -type f -name "results*.json")
heroJSON=$(jq -c '.hero_defines[]' <<<$defines 2>/dev/null | jq '{"hero_id":.id,"hero_name":.name}')
if [[ -n $files ]]; then
	results=$(jq -c '.loot_details[] | select ( . != null )' ./results/results-* 2>/dev/null | grep -v "add_gold_amount" | grep -v ',"okay":true,' | grep -v "add_inventory_buff" | jq 'select(.gilded == true)')
	filter=$(jq -c '{"hero_id": .hero_id, "slot_id": .slot_id}'<<<$results)
	merged=$(echo "$heroJSON" "$filter" | jq --slurp 'group_by(.hero_id)[] | add')
	newShiny=$(jq 'if .slot_id? then . else empty end'<<<"$merged")
	echo "New Shinys found:"
	jq '.' <<<"$newShiny"
	echo "Clean up results?"
	select yn in "Yes" "No"; do
		case $yn in
			Yes ) find ./results -type f -name "results-*.json" -exec mv {} ./oldresults/ \; 2>/dev/null; break;;
			No ) exit;;
			* ) echo "Please select yes or no.";;
		esac
	done
else
	echo "No results found. Have you purchased chests?"
fi
