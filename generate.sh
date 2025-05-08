#!/bin/bash

# Colors
Color_Off='\033[0m'       # Text Reset
Black='\033[0;30m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m' 

echo -e "$Green=== INCREASED WEAPON RANGES GENERATOR ===$Color_Off"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "We're currently in: $SCRIPT_DIR"

read -p "Reset to default before applying factor? [Y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	echo "Removing previously generated files..."
	rm -rf "$SCRIPT_DIR/assets" "$SCRIPT_DIR/extensions"

	echo "Reseting to default values..."
	rsync -a "$SCRIPT_DIR/_default/"* "$SCRIPT_DIR/"
fi

echo "Asking range factor..."
while :; do
	read -ep 'Enter range factor 1 to 9 (will be modulated by weapon type and current values): ' FACTOR 
    	[[ $FACTOR =~ ^[[:digit:]]+$ ]] || continue
		[[ $FACTOR -lt 10 && $FACTOR -gt 0 ]] || continue
    	break
done

echo "Listing Vanilla files..."
while IFS=  read -r -d $'\0'; do
    FINDFILES+=("$REPLY")
done < <(find "$SCRIPT_DIR/assets" "$SCRIPT_DIR/extensions" -type f -name "*.xml"  -print0)

TOTALFILES=${#FINDFILES[@]}
echo -e "Number of files to modify : $TOTALFILES"

read -p "Proceed?  [Y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]
then
	exit 0
fi

echo -e "Applying factor $factor...\n\n"
COUNT=0
# loop over files
for FILE in "${FINDFILES[@]}"
do
	#BEGIN LOGICAL CALCULATION ON A SINGLE FILE

	MACRO=$(grep -oP '<macro name="\K[^"]+' "$FILE")
	BULLET_LINE=$(grep '<bullet ' "$FILE")
	TRUST_LINE=$(grep '<thrust ' "$FILE")

	if [[ (-z "$MACRO" || -z "$BULLET_LINE") && (-z "$MACRO" || -z "$TRUST_LINE") ]]; then
		echo ""
		echo -e "$Red❌\tNo valid macro in file: $FILE$Color_Off"
		continue
	fi

	# Qualifying weapon projectile or engine type based on macro name
	TYPE=""
	[[ $MACRO =~ (gatling|plasma|laser|charge|cannon|shotgun|ion|flak|sticky|arc|swarm|disruptor) ]] && TYPE="ballistic"
	[[ $MACRO =~ railgun ]] && TYPE="railgun"
	[[ $MACRO =~ (beam|mining|burst|nova|bio) ]] && TYPE="range_based"
	[[ $MACRO =~ engine ]] && TYPE="engine"

	#DEBUG
	# echo "Captured macro : $MACRO"
	# echo "Identified type : $TYPE"
	# echo "Bullet line : $BULLET_LINE"
	#END DEBUG

	# Getting value
	get_attr() {
		echo "$BULLET_LINE" | grep -oP "$1=\"\K[^\"]+"
	}
	
	# Getting value for engine
	get_attr_engine() {
		echo "$TRUST_LINE" | grep -oP "$1=\"\K[^\"]+"
	}

	# Setting value
	set_attr() {
		awk "BEGIN { printf \"%.6f\", $1 }"
	}
	
	#Reset value from last time we passed here
	unset SPEED
	unset ANGL
	unset RANGE
	unset LIFE
	unset THRUST
	unset MODIFIED_LINE
	
	# Modifying stats depending on bullet type (or engine)
	if [[ $TYPE == "ballistic" ]]; then
		SPEED=$(get_attr "speed")
		ANGLE=$(get_attr "angle")
	elif [[ $TYPE == "railgun" ]]; then
		SPEED=$(get_attr "speed")
	elif [[ $TYPE == "range_based" ]]; then
		RANGE=$(get_attr "range")
		LIFE=$(get_attr "lifetime")
	elif [[ $TYPE == "engine" ]]; then
		THRUST=$(get_attr_engine "forward")
	fi

	if [[ ($TYPE != "engine") ]]; then
		MODIFIED_LINE="$BULLET_LINE"
		[[ $SPEED ]] && \
		MODIFIED_LINE=$(echo "$MODIFIED_LINE" | sed -E "s/(speed=\")$SPEED\"/\1$(set_attr "$SPEED * $FACTOR")\"/")
		[[ $ANGLE ]] && \
		MODIFIED_LINE=$(echo "$MODIFIED_LINE" | sed -E "s/(angle=\")$ANGLE\"/\1$(set_attr "$ANGLE / $FACTOR")\"/")
		[[ $RANGE ]] && \
		MODIFIED_LINE=$(echo "$MODIFIED_LINE" | sed -E "s/(range=\")$RANGE\"/\1$(set_attr "$RANGE * $FACTOR")\"/")
		[[ $LIFETIME ]] && \
		MODIFIED_LINE=$(echo "$MODIFIED_LINE" | sed -E "s/(lifetime=\")$LIFETIME\"/\1$(set_attr "$LIFETIME * $FACTOR")\"/")
	else
		MODIFIED_LINE="$TRUST_LINE"
		[[ $THRUST ]] && \
		MODIFIED_LINE=$(echo "$MODIFIED_LINE" | sed -E "s/(forward=\")$THRUST\"/\1$(set_attr "$THRUST * $FACTOR")\"/")
	fi
	
	# Diff generation if need (else, we put a warning which can means that the file content isnt match what we searched)
	# Special case for engine
	if [[ ($TYPE != "engine") && ("$BULLET_LINE" != "$MODIFIED_LINE") ]]; then
		echo '<?xml version="1.0" encoding="utf-8"?>' > "$FILE"
		echo '<diff>' >> "$FILE"
		echo "  <replace sel=\"/macros/macro[@name='$MACRO']/properties/bullet\">" >> "$FILE"
		echo "    $MODIFIED_LINE" >> "$FILE"
		echo "  </replace>" >> "$FILE"
		echo '</diff>' >> "$FILE"
		#echo -e "$Green✔\tDiff generated in $FILE$Color_Off"
		COUNT=$((COUNT+1))
		echo -ne "\rDone : $COUNT/$TOTALFILES"
	elif [[ ($TYPE == "engine") && ("$TRUST_LINE" != "$MODIFIED_LINE") ]]; then
		echo '<?xml version="1.0" encoding="utf-8"?>' > "$FILE"
		echo '<diff>' >> "$FILE"
		echo "  <replace sel=\"/macros/macro[@name='$MACRO']/properties/thrust\">" >> "$FILE"
		echo "    $MODIFIED_LINE" >> "$FILE"
		echo "  </replace>" >> "$FILE"
		echo '</diff>' >> "$FILE"
		#echo -e "$Green✔\tDiff generated in $FILE$Color_Off"
		COUNT=$((COUNT+1))
		echo -ne "\rDone : $COUNT/$TOTALFILES"
	else
		echo ""
		echo -e "$Yellow⚠\tCan't change anything in $FILE$Color_Off"
		#DEBUG
		echo "Modified attributes : $MODIFIED_LINE"
		#END DEBUG
	fi
	
	#DEBUG
	#exit 0
	#END DEBUG

	# END LOGICAL CALCULATION
done

echo -e "\n"



