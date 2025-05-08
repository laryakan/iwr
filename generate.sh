#!/bin/bash

# Colors
Color_Off='\033[0m'       # Text Reset
Black='\033[0;30m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m' 

DEBUG_MODE=0
if [[ $1 == '-v' ]]; then
	DEBUG_MODE=1
	echo -e "$Red DEBUG MODE ON $Color_Off"
fi

if [[ $1 == '-vv' ]]; then
	DEBUG_MODE=1
	DEBUG_VERBOSE_MODE=1
	echo -e "$Red VERBOSE DEBUG MODE ON $Color_Off"
fi

if [[ $1 == '-vvv' ]]; then
	DEBUG_MODE=1
	DEBUG_VERBOSE_MODE=1
	DEBUG_VERY_VERBOSE_MODE=1
	echo -e "$Red VERY VERBOSE DEBUG MODE ON $Color_Off"
fi

echo -e "$Green=== INCREASED WEAPON RANGES GENERATOR ===$Color_Off"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "We're currently in: $SCRIPT_DIR"

read -p "Reset to default before applying factor? [Y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
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

echo -e "$Yellow DISCLAIMER : This generator do not touch weapon damage, because it would underbalance the game balance regarding shield and hull"
echo -e "BUT: We can mitigate your factor to balance your weapons range base on an indice calculated on Vanilla weapon ranges (excl. missiles)"
echo -e "and avoid beam (which have a longer range) to be too overpowered in \"kite mode\" against ballistic weapons (laser, galtling, shotgun, etc...)"
echo -e "NB: We will take weapon tier into account (MK1 or MK2), but we won't balance missile engine (missile have their own lifetime, not depending on their engine)"
echo -e "$Color_Off"

# Default mitigation
ADJUST_FACTOR=0
MK1MITIGATOR=1
MK2MITIGATOR=1
MK1MEDIUM=16000
MK2MEDIUM=8900

read -p "Would you like us to adjust your factor depending on our modification to be balanced ? [Y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	ADJUST_FACTOR=1
	# Mitigating factor, calculated on vanilla projectile on May 8th 2025
	MK1MITIGATOR="0.066"
	MK2MITIGATOR="0.112"
fi

echo "Listing Vanilla files..."
while IFS=  read -r -d $'\0'; do
    FINDFILES+=("$REPLY")
done < <(find "$SCRIPT_DIR/assets" "$SCRIPT_DIR/extensions" -type f -name "*.xml"  -print0)

TOTALFILES=${#FINDFILES[@]}
echo -e "Number of files to modify : $TOTALFILES"

read -p "Proceed?  [Y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
	exit 0
fi

# Metrics recorder
COUNT=0
LONGESTMK1_RANGE_FOUND=0
SHORTESTMK1_RANGE_FOUND=9999999999
LONGESTMK2_RANGE_FOUND=0
SHORTESTMK2_RANGE_FOUND=9999999999
MK1LONGEST_FILE=''
MK1SHORTEST_FILE=''
MK2LONGEST_FILE=''
MK2SHORTEST_FILE=''

echo -e "Applying factor $factor...\n\n"
# loop over files
for FILE in "${FINDFILES[@]}"
do
	#BEGIN LOGICAL CALCULATION ON A SINGLE FILE
	if [[ $DEBUG_VERBOSE_MODE -eq 1 ]]; then
		echo -e "\n$Yellow => Starting Operating file:\n\t$FILE $Color_Off"
	fi

	MACRO=$(grep -oP '<macro name="\K[^"]+' "$FILE")
	BULLET_LINE=$(grep '<bullet ' "$FILE")
	TRUST_LINE=$(grep '<thrust ' "$FILE")

	if [[ (-z "$MACRO" || -z "$BULLET_LINE") && (-z "$MACRO" || -z "$TRUST_LINE") ]]; then
		echo ""
		echo -e "$Red ❌\tNo valid macro in file: $FILE$Color_Off"
		continue
	fi

	# Qualifying weapon projectile or engine type based on macro name
	TYPE=""
	[[ $MACRO =~ (gatling|plasma|laser|charge|cannon|shotgun|ion|flak|sticky|arc|swarm|disruptor) ]] && TYPE="ballistic"
	[[ $MACRO =~ railgun ]] && TYPE="railgun"
	[[ $MACRO =~ (beam|mining|burst|nova|bio) ]] && TYPE="range_based"
	[[ $MACRO =~ engine ]] && TYPE="engine"
	
	# Qualifying tier
	[[ $MACRO =~ mk1 ]] && MK=1
	[[ $MACRO =~ mk2 ]] && MK=2

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
		METRICS_LIFE=$(get_attr "lifetime")
	elif [[ $TYPE == "railgun" ]]; then
		SPEED=$(get_attr "speed")
		METRICS_LIFE=$(get_attr "lifetime")
	elif [[ $TYPE == "range_based" ]]; then
		# WARNING : Do not use speed on beam, they are moving at light speed ! Only use range
		RANGE=$(get_attr "range")
		LIFE=$(get_attr "lifetime")
	elif [[ $TYPE == "engine" ]]; then
		THRUST=$(get_attr_engine "forward")
	fi
	
	# Recording METRICS
	if [[ $TYPE == "ballistic" ||  $TYPE == "railgun" ]]; then
		#$(echo "$SPEED * $METRICS_LIFE" | bc -l | tr -d '\r')
		METRICS_RANGE=$(echo "$SPEED * $METRICS_LIFE" | bc -l | tr -d '\r')
		if [[ $DEBUG_VERBOSE_MODE -eq 1 ]]; then
			echo "	Vanilla RANGE : $METRICS_RANGE"
		fi
		if [[ $MK -eq 1 ]]; then
			IS_SHORTER=$(echo "$METRICS_RANGE < $SHORTESTMK1_RANGE_FOUND" | bc -l)
			IS_LONGER=$(echo "$METRICS_RANGE > $LONGESTMK1_RANGE_FOUND" | bc -l)
			[[ $IS_SHORTER -eq 1 ]] && SHORTESTMK1_RANGE_FOUND="$METRICS_RANGE"
			[[ $IS_LONGER -eq 1 ]] && LONGESTMK1_RANGE_FOUND="$METRICS_RANGE"
			[[ $IS_SHORTER -eq 1 ]] && MK1SHORTEST_FILE="$FILE"
			[[ $IS_LONGER -eq 1 ]] && MK1LONGEST_FILE="$FILE"
			
		fi
		if [[ $MK -eq 2 ]]; then
			IS_SHORTER=$(echo "$METRICS_RANGE < $SHORTESTMK2_RANGE_FOUND" | bc -l)
			IS_LONGER=$(echo "$METRICS_RANGE > $LONGESTMK2_RANGE_FOUND" | bc -l)
			[[ $IS_SHORTER -eq 1 ]] && SHORTESTMK2_RANGE_FOUND="$METRICS_RANGE"
			[[ $IS_LONGER -eq 1 ]] && LONGESTMK2_RANGE_FOUND="$METRICS_RANGE"
			[[ $IS_SHORTER -eq 1 ]] && MK2SHORTEST_FILE="$FILE"
			[[ $IS_LONGER -eq 1 ]] && MK2LONGEST_FILE="$FILE"
		fi
	fi
	
	if [[ $TYPE == "range_based" ]]; then
		if [[ $DEBUG_VERBOSE_MODE -eq 1 ]]; then
			echo "	Vanilla RANGE : $RANGE"
		fi
		if [[ $MK -eq 1 ]]; then
			IS_SHORTER=$(echo "$RANGE < $SHORTESTMK1_RANGE_FOUND" | bc -l)
			IS_LONGER=$(echo "$RANGE > $LONGESTMK1_RANGE_FOUND" | bc -l)
			[[ $IS_SHORTER -eq 1 ]] && SHORTESTMK1_RANGE_FOUND="$RANGE"
			[[ $IS_LONGER -eq 1 ]] && LONGESTMK1_RANGE_FOUND="$RANGE"
		fi
		if [[ $MK -eq 2 ]]; then
			IS_SHORTER=$(echo "$RANGE < $SHORTESTMK2_RANGE_FOUND" | bc -l)
			IS_LONGER=$(echo "$RANGE > $LONGESTMK2_RANGE_FOUND" | bc -l)
			[[ $IS_SHORTER -eq 1 ]] && SHORTESTMK2_RANGE_FOUND="$RANGE"
			[[ $IS_LONGER -eq 1 ]] && LONGESTMK2_RANGE_FOUND="$RANGE"
		fi
	fi

	if [[ $ADJUST_FACTOR -eq 0 ]]; then
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
	else
		if [[ ($TYPE != "engine") ]]; then
		
			# Default adjusted factor for lesser range weapons
			[[ $MK -eq 1 ]] && ADJUSTED_FACTOR=$(echo "$FACTOR + $MK1MITIGATOR " | bc -l | tr -d '\r')
			[[ $MK -eq 2 ]] && ADJUSTED_FACTOR=$(echo "$FACTOR + $MK2MITIGATOR " | bc -l | tr -d '\r')
			# Comparing medium to know if we let the mitigation increase the range or if we have to decrease it
			if [[ $TYPE == "ballistic" ||  $TYPE == "railgun" ]]; then
				METRICS_RANGE=$(echo "$SPEED * $METRICS_LIFE" | bc -l | tr -d '\r')
				[[ $MK -eq 1 ]] && IS_LONGER=$(echo "$METRICS_RANGE > $MK1MEDIUM" | bc -l)
				[[ $MK -eq 2 ]] && IS_LONGER=$(echo "$METRICS_RANGE > $MK2MEDIUM" | bc -l)
				[[ $MK -eq 1 && $IS_LONGER -eq 1 ]] && ADJUSTED_FACTOR=$(echo "$FACTOR - $MK1MITIGATOR" | bc -l | tr -d '\r')
				[[ $MK -eq 2 && $IS_LONGER -eq 1 ]] && ADJUSTED_FACTOR=$(echo "$FACTOR - $MK2MITIGATOR" | bc -l | tr -d '\r')
			elif [[ $TYPE == "range_based" ]]; then
				[[ $MK -eq 1 ]] && IS_LONGER=$(echo "$RANGE > $MK1MEDIUM" | bc -l)
				[[ $MK -eq 2 ]] && IS_LONGER=$(echo "$RANGE > $MK2MEDIUM" | bc -l)
				[[ $MK -eq 1 && $IS_LONGER -eq 1 ]] && ADJUSTED_FACTOR=$(echo "$FACTOR - $MK1MITIGATOR" | bc -l | tr -d '\r')
				[[ $MK -eq 2 && $IS_LONGER -eq 1 ]] && ADJUSTED_FACTOR=$(echo "$FACTOR - $MK2MITIGATOR" | bc -l | tr -d '\r')
			fi
			
			[[ $DEBUG_VERY_VERBOSE_MODE -eq 1 ]] && echo -e "$Yellow ADJUSTED_FACTOR: "; echo "$ADJUSTED_FACTOR" | bc -l | tr -d '\r'; echo -e "$Color_Off"
		
			MODIFIED_LINE="$BULLET_LINE"
			[[ $SPEED ]] && \
			MODIFIED_LINE=$(echo "$MODIFIED_LINE" | sed -E "s/(speed=\")$SPEED\"/\1$(set_attr "$SPEED * $ADJUSTED_FACTOR")\"/")
			[[ $ANGLE ]] && \
			MODIFIED_LINE=$(echo "$MODIFIED_LINE" | sed -E "s/(angle=\")$ANGLE\"/\1$(set_attr "$ANGLE / $ADJUSTED_FACTOR")\"/")
			WARNING_ANGLE=$(echo "($ANGLE / $ADJUSTED_FACTOR) >= 1" | bc -l)
			[[ $DEBUG_MODE -eq 1 && $WARNING_ANGLE -eq 1 ]] && echo -e "$Red WARNING ! High Angle (Original: $ANGLE), file: $FILE $Color_Off"
			[[ $RANGE ]] && \
			MODIFIED_LINE=$(echo "$MODIFIED_LINE" | sed -E "s/(range=\")$RANGE\"/\1$(set_attr "$RANGE * $ADJUSTED_FACTOR")\"/")
			[[ $LIFETIME ]] && \
			MODIFIED_LINE=$(echo "$MODIFIED_LINE" | sed -E "s/(lifetime=\")$LIFETIME\"/\1$(set_attr "$LIFETIME * $ADJUSTED_FACTOR")\"/")
		else
			MODIFIED_LINE="$TRUST_LINE"
			[[ $THRUST ]] && \
			MODIFIED_LINE=$(echo "$MODIFIED_LINE" | sed -E "s/(forward=\")$THRUST\"/\1$(set_attr "$THRUST * $FACTOR")\"/")
		fi
	fi
	
	# Diff generation if need (else, we put a warning which can means that the file content isnt match what we searched)
	# Special case for engine
	if [[ ($TYPE != "engine") && ("$BULLET_LINE" != "$MODIFIED_LINE") ]]; then
		[[ $DEBUG_VERY_VERBOSE_MODE -eq 1 ]] && echo -e "$Red Old Line: \n$BULLET_LINE"; echo -e "$Color_Off"
		[[ $DEBUG_VERY_VERBOSE_MODE -eq 1 ]] && echo -e "$Green New modified:\n$MODIFIED_LINE"; echo -e "$Color_Off"
		echo '<?xml version="1.0" encoding="utf-8"?>' > "$FILE"
		echo '<!-- Increased Weapon Ranges Generated  -->' >> "$FILE"
		echo '<diff>' >> "$FILE"
		echo "  <replace sel=\"/macros/macro[@name='$MACRO']/properties/bullet\">" >> "$FILE"
		echo "    $MODIFIED_LINE" >> "$FILE"
		echo "  </replace>" >> "$FILE"
		echo '</diff>' >> "$FILE"
		#echo -e "$Green ✔\tDiff generated in $FILE$Color_Off"
		COUNT=$((COUNT+1))
		echo -ne "\rDone : $COUNT/$TOTALFILES"
	elif [[ ($TYPE == "engine") && ("$TRUST_LINE" != "$MODIFIED_LINE") ]]; then
		[[ $DEBUG_VERY_VERBOSE_MODE -eq 1 ]] && echo -e "$Red Old Line: \n$TRUST_LINE"; echo -e "$Color_Off"
		[[ $DEBUG_VERY_VERBOSE_MODE -eq 1 ]] && echo -e "$Green New modified:\n$MODIFIED_LINE"; echo -e "$Color_Off"
		echo '<?xml version="1.0" encoding="utf-8"?>' > "$FILE"
		echo '<!-- Increased Weapon Ranges Generated  -->' >> "$FILE"
		echo '<diff>' >> "$FILE"
		echo "  <replace sel=\"/macros/macro[@name='$MACRO']/properties/thrust\">" >> "$FILE"
		echo "    $MODIFIED_LINE" >> "$FILE"
		echo "  </replace>" >> "$FILE"
		echo '</diff>' >> "$FILE"
		#echo -e "$Green ✔\tDiff generated in $FILE$Color_Off"
		COUNT=$((COUNT+1))
		echo -ne "\rDone : $COUNT/$TOTALFILES"
	else
		echo ""
		echo -e "$Yellow⚠ \tCan't change anything in $FILE$Color_Off"
		if [[ $DEBUG_VERBOSE_MODE -eq 1 ]]; then
			echo "Modified attributes : $MODIFIED_LINE"
		fi
	fi
	
	#DEBUG
	#exit 0
	#END DEBUG

	# END LOGICAL CALCULATION
done

if [[ $DEBUG_MODE -eq 1 ]]; then
	echo -e "\n\nFor METRICS purpose and adjusting FACTOR mitigation, here are Vanilla RANGE metrics"
	
	echo -e "$Green === MKI === $Color_Off"
	echo "LONGESTMK1_RANGE_FOUND : $MK1LONGEST_FILE"; echo "$LONGESTMK1_RANGE_FOUND" | bc -l | tr -d '\r'
	echo "SHORTESTMK1_RANGE_FOUND : $MK1SHORTEST_FILE"; echo "$SHORTESTMK1_RANGE_FOUND" | bc -l | tr -d '\r'
	echo "Suggested mitigating factor by :"; echo "$SHORTESTMK1_RANGE_FOUND / $LONGESTMK1_RANGE_FOUND" | bc -l | tr -d '\r'
	echo "Medium recorded :"; echo "($SHORTESTMK1_RANGE_FOUND + $LONGESTMK1_RANGE_FOUND) / 2" | bc -l | tr -d '\r'
	
	echo -e "$Green === MKII === $Color_Off"
	echo "LONGESTMK2_RANGE_FOUND : $MK2LONGEST_FILE"; echo "$LONGESTMK2_RANGE_FOUND" | bc -l | tr -d '\r'
	echo "SHORTESTMK2_RANGE_FOUND : $MK2SHORTEST_FILE"; echo "$SHORTESTMK2_RANGE_FOUND" | bc -l | tr -d '\r'
	echo "Suggested mitigating factor by :"; echo "$SHORTESTMK2_RANGE_FOUND / $LONGESTMK2_RANGE_FOUND" | bc -l | tr -d '\r'
	echo "Medium recorded :"; echo "($SHORTESTMK2_RANGE_FOUND + $LONGESTMK2_RANGE_FOUND) / 2" | bc -l | tr -d '\r'
fi

echo -e "\n"



