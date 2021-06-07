#! /usr/local/bin/bash

die () {
    echo >&2 "$@"
    exit 1
}

get_defines () {
    [[ -f data_idle.json ]] && rm data_idle.json
    raw=$(find /Users/jrichards/Library/Application\ Support/Steam/steamapps/common/IdleChampions/IdleDragonsMac.app/Contents/Resources/Data/ -type f -name 'webRequestLog.txt' -exec cat {} \;) || die "File not found."
    json=$(grep '{' <<<$raw | jq -c '.') || die "Error in JSON."
    #echo "$json" >> ~/temp/Idle/data_idle.json
    echo "$json" # | python parser_idlechamps.py
}

silverBuy() {
    echo "Beginning to buy Silver chests."
    header='Content-Type:application/x-www-form-urlencoded'
    baseUrl='http://ps7.idlechampions.com/~idledragons/post.php?call='
    callType='buysoftcurrencychest'
    params='&user_id='$idleID'&hash='$hash'&instance_id='$instanceID'&chest_type_id=1&game_instance_id=1&count=100'

    while [[ $remainingGems -ge 5000 ]]; do
        curl -sX POST -H "$header" "$baseUrl$callType$params" >> results-$time.json
        remainingGems=$(jq '.currency_remaining | select ( . != null )' <results-$time.json | sort -h | head -1)
        echo "remaining: $remainingGems"
        sleep 2
    done;
    echo "Done buying Silver chests."
}


silverOpen() {
    echo "Beginning to open Silver chests."
    header='Content-Type:application/x-www-form-urlencoded'
    baseUrl='http://ps7.idlechampions.com/~idledragons/post.php?call='
    callType='opengenericchest'
    params='&gold_per_second=0&checksum=4c5f019b6fc6eefa4d47d21cfaf1bc68&user_id='$idleID'&hash='$hash'&instance_id='$instanceID'&chest_type_id=1&game_instance_id=1&count=50'

    while [[ $remainingSilver -ge 50 ]]; do
        curl -sX POST -H "$header" "$baseUrl$callType$params" >> results-$time.json
        remainingSilver=$(jq '.chests_remaining | select ( . != null )' <results-$time.json | sort -h | head -1)
        echo "remaining: $remainingSilver"
        sleep 2
    done;
    echo "Done opening Silver chests."
}

#init
cd ~/temp/Idle
json=$(get_defines)

#start here
idleID=$(jq -r '.internal_user_id | select( . != null)' <<<$json | uniq)
steamID=$(jq -r '.steam_user_id | select ( . != null)' <<<$json | uniq)
hash=$(jq -r '.hash | select ( . != null )' <<<$json | uniq)

#get fresh userdata
json=$(curl -sX POST -H "Content-Type:application/x-www-form-urlencoded" 'http://ps7.idlechampions.com/~idledragons/post.php?call=getuserdetails&include_free_play_objectives=true&instance_key=1&user_id=1213134&hash=72c78abb3aead4e07abaa857b1821d36')

instanceID=$(jq -r '.details.instance_id' <<<$json)
remainingSilver=$(jq '.details.chests."1"' <<<$json)
remainingGems=$(jq '.details.red_rubies' <<<$json)

echo "Chests to burn: $remainingSilver"
time=$(date +%Y-%m-%d-%HH%MM%SS)

silverBuy
silverOpen
