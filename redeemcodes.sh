#!/usr/local/bin/bash

die () {
    echo >&2 "$@"
    exit 1
}

get_defines () {
    [[ -f data_idle.json ]] && rm data_idle.json
    raw=$(find "/Users/$user/Library/Application Support/Steam/steamapps/common/IdleChampions/IdleDragonsMac.app/Contents/Resources/Data/" -type f -name 'webRequestLog.txt' -exec cat {} \;) || die "File not found."
    json=$(grep '{' <<<$raw | jq -c '.') || die "Error in JSON."
    #echo "$json" >> ~/temp/Idle/data_idle.json
    echo "$json" # | python parser_idlechamps.py
}

#init
user=$(whoami)
json=$(get_defines)


#start here
idleID=$(jq -r '.internal_user_id | select( . != null)' <<<$json | uniq)
steamID=$(jq -r '.steam_user_id | select ( . != null)' <<<$json | uniq)
hash=$(jq -r '.hash | select ( . != null )' <<<$json | uniq)

#get fresh userdata
json=$(curl -sX POST -H "Content-Type:application/x-www-form-urlencoded" 'http://ps7.idlechampions.com/~idledragons/post.php?call=getuserdetails&include_free_play_objectives=true&instance_key=1&user_id=1213134&hash=72c78abb3aead4e07abaa857b1821d36')

instanceID=$(jq -r '.details.instance_id' <<<$json)

time=$(date +%Y-%m-%d-%HH%MM%SS)

header='Content-Type:application/x-www-form-urlencoded'
baseUrl='http://ps7.idlechampions.com/~idledragons/post.php?call='
callType='redeemcoupon'
params='&language_id=1&timestamp=0&request_id=0&network_id=11&mobile_client_version=999&user_id='$idleID'&hash='$hash'&instance_id='$instanceID'&code='

#get old codes
path="/Users/$user/temp/Idle/idleChamps"
usedCodes=$(find "$path/oldcodes" -type f -exec cat {} \;)

while read -r line; do
    grep "$line" <<<$usedCodes
    if [[ $? -gt 0 ]]; then
        echo "Code $line not found. Redeeming."
        curl -sX POST -H "$header" "$baseUrl$callType$params$line" >> code-$time.json
        sleep 2
    else
        echo "Code $line found in redeemed codes. Skipping."
    fi
done<codes
echo "Done redeeming codes."
mv codes oldcodes/"$time-codes.redeemed"
