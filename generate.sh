#!/bin/bash

# Colors
Color_Off='\033[0m'       # Text Reset
Black='\033[0;30m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m' 

# Out of loop functions
# Setting value
set_attr() {
	awk "BEGIN { printf \"%.4f\", $1 }"
}

# Calculate value
calc() {
	printf %.4f $(echo "$1" | bc -l)
}

compare() {
	echo "$1" | bc -l
}

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

if [[ $1 == '-vvvv' ]]; then
	POKE_MODE=1
	echo -e "$Red POKE MODE ON $Color_Off"
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
echo -e "$Yellow"
echo -e "The script should work with factor higher than 3, but high factor can also mean unbalance, because in order to increase the weapons range, while keeping weapons efficiency,"
echo -e "we also have to increase their precision. Too high factor may result either: on high damage weapons, too much precision (like shootgun) or (if we dont change precision)"
echo -e "weapons that will never hit their target on futher distance than vanilla ones, so their efficiency will remain the same even on higher range. We can apply a specific factor"
echo -e "on angle, it will be asked if you're factor is too high. A factor of 1 means Vanilla value remains unchanged, you don't need this script then."
echo -e "$Color_Off"
while :; do
	read -ep 'Enter range factor 2 to 9: ' FACTOR 
    	[[ $FACTOR =~ ^[[:digit:]]+$ ]] || continue
		[[ $FACTOR -lt 10 && $FACTOR -gt 0 ]] || continue
    	break
done

ANGLE_FACTOR=$FACTOR
if [[ $(compare " $ANGLE_FACTOR > 2 " ) -eq  1 ]]; then
	read -p "We have detected that you whant to apply a factor higher than 2, would you like to apply a specific angle factor (between 1 and 3)? [Y/N] " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Nn]$ ]]; then
		while :; do
		read -ep "Enter angle factor 1 to 3 (1 = Vanilla angle, current factor is $ANGLE_FACTOR): " ANGLE_FACTOR
			[[ $ANGLE_FACTOR =~ ^[[:digit:]]+$ ]] || continue
			[[ $ANGLE_FACTOR -lt 4 && $ANGLE_FACTOR -gt 0 ]] || continue
			break
		done
	fi
fi

echo -e "\n$Yellow ! DISCLAIMER : This generator do not touch weapon damage, because it would underbalance the game regarding shield and hull"
echo -e "BUT: We can mitigate your factor to balance your weapons range based on an indice calculated on Vanilla weapon ranges (excl. missiles)"
echo -e "and avoid beam (which have a longer range) to be too much overpowered in \"kite mode\" against ballistic weapons (laser, galtling, shotgun, etc...)"
echo -e "NB: We will take weapon tier into account (MK1 or MK2), but we won't balance missile engine (missile have their own lifetime, not depending on their engine)"
echo -e "In any case, the debug mode (\"./generate.sh -v\") can warn you if value are too high depending on the factor you asked"
echo -e "$Color_Off"

# Default mitigation
ADJUST_FACTOR=0
MK1MITIGATOR=1
MK2MITIGATOR=1
MK1MEDIUM=16000
MK2MEDIUM=8900

read -p "Would you like us to adjust your factor depending on our modification to be \"more\" balanced (strongly recommended) ? [Y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	ADJUST_FACTOR=1
	# Mitigating factor, calculated on vanilla projectile on May 8th 2025
	MK1MITIGATOR="0.066"
	MK2MITIGATOR="0.112"
else
	echo -e "$Yellow ! DISCLAIMER : The factor you entered will remain unchanged, will be applied as is to weapon ranges"
	echo -e " ! DISCLAIMER : no further warnings will occur if the generated values are too high or too low, if you change your mind, restart the script"
	echo -e "$Color_Off"
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
	
	#Reset value from last time we passed here
	unset SPEED
	unset ANGLE
	unset RANGE
	unset LIFE
	unset THRUST
	unset MODIFIED_LINE
	
	# Modifying stats depending on bullet type (or engine)
	if [[ $TYPE == "ballistic" ]]; then #(gatling|plasma|laser|charge|cannon|shotgun|ion|flak|sticky|arc|swarm|disruptor)
		SPEED=$(get_attr "speed")
		ANGLE=$(get_attr "angle")
		METRICS_LIFE=$(get_attr "lifetime")
	elif [[ $TYPE == "railgun" ]]; then
		SPEED=$(get_attr "speed")
		METRICS_LIFE=$(get_attr "lifetime")
	elif [[ $TYPE == "range_based" ]]; then #(beam|mining|burst|nova|bio)
		# WARNING : Do not use speed on beam, they are moving at light speed ! Only use range
		RANGE=$(get_attr "range")
		LIFE=$(get_attr "lifetime")
	elif [[ $TYPE == "engine" ]]; then
		THRUST=$(get_attr_engine "forward")
	fi
	
	# Recording METRICS
	#(gatling|plasma|laser|charge|cannon|shotgun|ion|flak|sticky|arc|swarm|disruptor|railgun)
	if [[ $TYPE == "ballistic" ||  $TYPE == "railgun" ]]; then
		METRICS_RANGE=$(calc "$SPEED * $METRICS_LIFE")
		if [[ $DEBUG_VERBOSE_MODE -eq 1 ]]; then
			echo "	Vanilla RANGE : $METRICS_RANGE"
		fi
		if [[ $MK -eq 1 ]]; then
			[[ $(compare "$METRICS_RANGE < $SHORTESTMK1_RANGE_FOUND") -eq 1 ]] && SHORTESTMK1_RANGE_FOUND="$METRICS_RANGE" && MK1SHORTEST_FILE="$FILE"
			[[ $(compare "$METRICS_RANGE > $LONGESTMK1_RANGE_FOUND") -eq 1 ]] && LONGESTMK1_RANGE_FOUND="$METRICS_RANGE" && MK1LONGEST_FILE="$FILE"
		fi
		if [[ $MK -eq 2 ]]; then
			[[ $(compare "$METRICS_RANGE < $SHORTESTMK2_RANGE_FOUND") -eq 1 ]] && SHORTESTMK2_RANGE_FOUND="$METRICS_RANGE" && MK2SHORTEST_FILE="$FILE"
			[[ $(compare "$METRICS_RANGE > $LONGESTMK2_RANGE_FOUND") -eq 1 ]] && LONGESTMK2_RANGE_FOUND="$METRICS_RANGE" && MK2LONGEST_FILE="$FILE"
		fi
	fi
	
	#(beam|mining|burst|nova|bio)
	if [[ $TYPE == "range_based" ]]; then
		if [[ $DEBUG_VERBOSE_MODE -eq 1 ]]; then
			echo "	Vanilla RANGE : $RANGE"
		fi
		if [[ $MK -eq 1 ]]; then
			[[ $(compare "$RANGE < $SHORTESTMK1_RANGE_FOUND") -eq 1 ]] && SHORTESTMK1_RANGE_FOUND="$RANGE" && MK1SHORTEST_FILE="$FILE"
			[[ $(compare "$RANGE > $LONGESTMK1_RANGE_FOUND") -eq 1 ]] && LONGESTMK1_RANGE_FOUND="$RANGE" && MK1LONGEST_FILE="$FILE"
		fi
		if [[ $MK -eq 2 ]]; then
			[[ $(compare "$RANGE < $SHORTESTMK2_RANGE_FOUND") -eq 1 ]] && SHORTESTMK2_RANGE_FOUND="$RANGE" && MK2SHORTEST_FILE="$FILE"
			[[ $(compare "$RANGE > $LONGESTMK2_RANGE_FOUND") -eq 1 ]] && LONGESTMK2_RANGE_FOUND="$RANGE" && MK2LONGEST_FILE="$FILE"
		fi
	fi
	if [[ $ADJUST_FACTOR -eq 0 ]]; then
		if [[ ($TYPE != "engine") ]]; then
			MODIFIED_LINE="$BULLET_LINE"
			[[ $SPEED ]] && \
			MODIFIED_LINE=$(echo "$MODIFIED_LINE" | sed -E "s/(speed=\")$SPEED\"/\1$(set_attr "$SPEED * $FACTOR")\"/")
			[[ $ANGLE ]] && \
			MODIFIED_LINE=$(echo "$MODIFIED_LINE" | sed -E "s/(angle=\")$ANGLE\"/\1$(set_attr "$ANGLE / $ANGLE_FACTOR")\"/")
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
			# Comparing medium to know if we let the mitigation increase the range or if we have to decrease it
			[[ $MK -eq 1 ]] && ADJUSTED_FACTOR=$(calc "$FACTOR + $MK1MITIGATOR ")
			[[ $MK -eq 2 ]] && ADJUSTED_FACTOR=$(calc "$FACTOR + $MK2MITIGATOR ")
			if [[ $TYPE == "ballistic" ||  $TYPE == "railgun" ]]; then
				METRICS_RANGE=$(calc "$SPEED * $METRICS_LIFE")
				[[ $MK -eq 1 ]] && [[ $(compare "$METRICS_RANGE > $MK1MEDIUM" ) -eq 1 ]] && ADJUSTED_FACTOR=$(calc "$FACTOR - $MK1MITIGATOR ")
				[[ $MK -eq 2 ]] && [[ $(compare "$METRICS_RANGE > $MK2MEDIUM" ) -eq 1 ]] && ADJUSTED_FACTOR=$(calc "$FACTOR - $MK2MITIGATOR ")
				# Fail safe to avoid reducing range instead of increasing it
				[[ $(compare "$ADJUSTED_FACTOR < 1") -eq 1 ]] && ADJUSTED_FACTOR=1
				NEW_RANGE=$(calc "$METRICS_RANGE * $ADJUSTED_FACTOR")
				WARNING_RANGE=$(calc "$MK1MEDIUM * $ADJUSTED_FACTOR")
				[[ $MK -eq 2 ]] && WARNING_RANGE=$(calc "$MK2MEDIUM * $ADJUSTED_FACTOR")
				if [[ $DEBUG_VERBOSE_MODE -eq 1 ]]; then
					echo "	IWR RANGE : $NEW_RANGE"
				fi
				[[ $DEBUG_MODE -eq 1 ]] && [[ $(compare "$NEW_RANGE > $WARNING_RANGE") -eq 1 ]] && \
				echo -e "\n$Red ! WARNING ! High range (Original: \"$METRICS_RANGE\", New: \"$NEW_RANGE\"), file: $FILE $Color_Off" && \
				echo -e "$Yellow We suggest you to adjust this value manualy into the file, it probably happened because vanilla value are much higher than other weapons $Color_Off \n"
			elif [[ $TYPE == "range_based" ]]; then
				[[ $MK -eq 1 ]] && [[ $(compare "$RANGE > $MK1MEDIUM" ) -eq 1 ]] && ADJUSTED_FACTOR=$(calc "$FACTOR - $MK1MITIGATOR ")
				[[ $MK -eq 2 ]] && [[ $(compare "$RANGE > $MK2MEDIUM" ) -eq 1 ]] && ADJUSTED_FACTOR=$(calc "$FACTOR - $MK2MITIGATOR ")
				# Fail safe to avoid reducing range instead of increasing it
				[[ $(compare "$ADJUSTED_FACTOR < 1") -eq 1 ]] && ADJUSTED_FACTOR=1
				NEW_RANGE=$(calc "$RANGE * $ADJUSTED_FACTOR" )
				WARNING_RANGE=$(calc "$MK1MEDIUM * $ADJUSTED_FACTOR")
				[[ $MK -eq 2 ]] && WARNING_RANGE=$(calc "$MK2MEDIUM * $ADJUSTED_FACTOR")
				if [[ $DEBUG_VERBOSE_MODE -eq 1 ]]; then
					echo "	IWR RANGE : $NEW_RANGE"
				fi
				[[ $DEBUG_MODE -eq 1 ]] && [[ $(compare "$NEW_RANGE > $WARNING_RANGE") -eq 1 ]] && \
				echo -e "\n$Red ! WARNING ! High range (Original: \"$RANGE\", New: \"$NEW_RANGE\"), file: $FILE $Color_Off" && \
				echo -e "$Yellow We suggest you to adjust this value manualy into the file, it probably happened because vanilla value are much higher than other weapons $Color_Off \n"
			fi
			[[ $DEBUG_VERY_VERBOSE_MODE -eq 1 ]] && echo -e "$Yellow ADJUSTED_FACTOR: "
			[[ $DEBUG_VERY_VERBOSE_MODE -eq 1 ]] && echo "$ADJUSTED_FACTOR"
			[[ $DEBUG_VERY_VERBOSE_MODE -eq 1 ]] && echo -e "$Color_Off"
			
			# In case that the angle factor is still the same as the original factor, we to a favor to the user and apply the mitigation to it... even if the angle will probably remain too low
			[[ $(compare "$FACTOR == $ANGLE_FACTOR") -eq 1 ]] && ANGLE_FACTOR=$ADJUSTED_FACTOR
			
			MODIFIED_LINE="$BULLET_LINE"
			[[ $SPEED ]] && \
			MODIFIED_LINE=$(echo "$MODIFIED_LINE" | sed -E "s/(speed=\")$SPEED\"/\1$(set_attr "$SPEED * $ADJUSTED_FACTOR")\"/")
			[[ $ANGLE ]] && \
			MODIFIED_LINE=$(echo "$MODIFIED_LINE" | sed -E "s/(angle=\")$ANGLE\"/\1$(set_attr "$ANGLE / $ANGLE_FACTOR")\"/")
			## START POKE ERROR (standard_in) 1: syntax error
			[[ ! -z "$ANGLE" ]] && WARNING_ANGLE=$(calc "$ANGLE / $ANGLE_FACTOR")
			#[[ $POKE_MODE -eq 1 ]] && echo -e "$Red 267 : $ANGLE / $ADJUSTED_FACTOR $Color_Off"
			[[ $DEBUG_MODE -eq 1 ]] && [[ $(compare "$WARNING_ANGLE > 1") -eq 1 ]] && \
			echo -e "\n$Red ! WARNING ! High Angle (Original: \"$ANGLE\", New: \"$WARNING_ANGLE\"), file: $FILE $Color_Off"
			[[ ! -z "$ANGLE" ]] && [[ $DEBUG_MODE -eq 1 ]] && [[ $(compare "$WARNING_ANGLE < ( $ANGLE / 3 )") -eq 1 ]] && \
			echo -e "\n$Red ! WARNING ! Low angle (Original: \"$ANGLE\", New: \"$WARNING_ANGLE\"), file: $FILE $Color_Off" && \
			echo -e "$Yellow We suggest you to adjust this value manualy into the file, the weapon maybe be too powerful if too much precise depending on its damage $Color_Off \n"
			## END POKE ERROR (standard_in) 1: syntax error
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
		[[ $DEBUG_VERY_VERBOSE_MODE -eq 1 ]] && echo -e "$Red Old Line: \n$BULLET_LINE" && echo -e "$Color_Off"
		[[ $DEBUG_VERY_VERBOSE_MODE -eq 1 ]] && echo -e "$Green New modified:\n$MODIFIED_LINE" && echo -e "$Color_Off"
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
		[[ $DEBUG_VERY_VERBOSE_MODE -eq 1 ]] && echo -e "$Red Old Line: \n$TRUST_LINE" && echo -e "$Color_Off"
		[[ $DEBUG_VERY_VERBOSE_MODE -eq 1 ]] && echo -e "$Green New modified:\n$MODIFIED_LINE" && echo -e "$Color_Off"
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
		echo -e "\n$Yellow⚠ \tCan't change anything in $FILE$Color_Off"
		if [[ $DEBUG_VERBOSE_MODE -eq 1 ]]; then
			echo "Modified attributes : $MODIFIED_LINE"
		fi
	fi
	
	#DEBUG
	#exit 0
	#END DEBUG

	# END LOGICAL CALCULATION
done

if [[ $DEBUG_VERY_VERBOSE_MODE -eq 1 ]]; then
	echo -e "\n\nFor METRICS purpose and adjusting FACTOR mitigation, here are Vanilla RANGE metrics"
	echo -e "$Green === MKI === $Color_Off"
	echo -e "LONGESTMK1_RANGE_FOUND : $MK1LONGEST_FILE"; calc "$LONGESTMK1_RANGE_FOUND"; echo ""
	echo "SHORTESTMK1_RANGE_FOUND : $MK1SHORTEST_FILE"; calc "$SHORTESTMK1_RANGE_FOUND"; echo ""
	echo "Suggested mitigating factor by :"; calc "$SHORTESTMK1_RANGE_FOUND / $LONGESTMK1_RANGE_FOUND"; echo ""
	echo "Medium recorded :"; calc "($SHORTESTMK1_RANGE_FOUND + $LONGESTMK1_RANGE_FOUND) / 2"; echo ""
	
	echo -e "$Green === MKII === $Color_Off"
	echo "LONGESTMK2_RANGE_FOUND : $MK2LONGEST_FILE"; calc "$LONGESTMK2_RANGE_FOUND"; echo ""
	echo "SHORTESTMK2_RANGE_FOUND : $MK2SHORTEST_FILE"; calc "$SHORTESTMK2_RANGE_FOUND"; echo ""
	echo "Suggested mitigating factor by :"; calc "$SHORTESTMK2_RANGE_FOUND / $LONGESTMK2_RANGE_FOUND"; echo ""
	echo "Medium recorded :"; calc "($SHORTESTMK2_RANGE_FOUND + $LONGESTMK2_RANGE_FOUND) / 2"; echo ""
fi

echo -e "\n"



