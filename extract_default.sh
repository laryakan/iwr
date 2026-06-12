#!/bin/bash

# Extraction of IWR "_default" assets files from X4: Foundations Vanilla
# Place this script at the root of a CAT extraction from "X4: Foundations"
# For extraction of assets from Vanilla version and official DLC extensions
# use the following commands with XRCatTool (Windows cmd) :
# for %f in ("F:\Games\X4 Foundations\*.cat") do XRCatTool.exe -in "%f" -out "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0" 
# md "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions
# md "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions\ego_dlc_timelines"
# for %f in ("F:\Games\X4 Foundations\extensions\ego_dlc_timelines\*.cat") do XRCatTool.exe -in "%f" -out "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions\ego_dlc_timelines" 
# md "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions\ego_dlc_boron"
# for %f in ("F:\Games\X4 Foundations\extensions\ego_dlc_boron\*.cat") do XRCatTool.exe -in "%f" -out "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions\ego_dlc_boron" 
# md "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions\ego_dlc_pirate"
# for %f in ("F:\Games\X4 Foundations\extensions\ego_dlc_pirate\*.cat") do XRCatTool.exe -in "%f" -out "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions\ego_dlc_pirate" 
# md "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions\ego_dlc_split"
# for %f in ("F:\Games\X4 Foundations\extensions\ego_dlc_split\*.cat") do XRCatTool.exe -in "%f" -out "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions\ego_dlc_split" 
# md "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions\ego_dlc_terran"
# for %f in ("F:\Games\X4 Foundations\extensions\ego_dlc_terran\*.cat") do XRCatTool.exe -in "%f" -out "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions\ego_dlc_terran" 
# md "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions\ego_dlc_mini_01"
# for %f in ("F:\Games\X4 Foundations\extensions\ego_dlc_mini_01\*.cat") do XRCatTool.exe -in "%f" -out "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions\ego_dlc_mini_01"
# md "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions\ego_dlc_mini_02"
# for %f in ("F:\Games\X4 Foundations\extensions\ego_dlc_mini_02\*.cat") do XRCatTool.exe -in "%f" -out "S:\users\paulw\downloads\x4\XTools_1.11\extracts\x4_9.0\extensions\ego_dlc_mini_02"

OUTPUT_DIR="_default"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

mkdir -p "$SCRIPT_DIR/$OUTPUT_DIR"

copy_files() {
    local src_dir="$1"
    local pattern="$2"
    local dest_subdir="$3"
    local message="$4"
    
    if [[ -d "$src_dir" ]]; then
        echo "  → $message..."
        for file in "$src_dir"/$pattern; do
            if [[ -f "$file" ]]; then
                mkdir -p "$SCRIPT_DIR/$OUTPUT_DIR/$dest_subdir"
                cp "$file" "$SCRIPT_DIR/$OUTPUT_DIR/$dest_subdir/"
            fi
        done
    fi
}

echo "Copying Vanilla assets..."

copy_files "$SCRIPT_DIR/assets/fx/weaponFx/macros" "bullet*.xml" "assets/fx/weaponFx/macros" "Copying bullet macros"
copy_files "$SCRIPT_DIR/assets/props/Engines/macros" "*engine_missile*.xml" "assets/props/Engines/macros" "Copying engine missile macros"
copy_files "$SCRIPT_DIR/assets/props/WeaponSystems/missile/macros" "*.xml" "assets/props/WeaponSystems/missile/macros" "Copying missile macros"

# Official DLC extensions
for dlc_dir in "$SCRIPT_DIR/extensions"/ego_dlc_*; do
    if [[ -d "$dlc_dir" ]]; then
        dlc_name=$(basename "$dlc_dir")
        echo "Copying assets from $dlc_name..."
        copy_files "$SCRIPT_DIR/extensions/$dlc_name/assets/fx/weaponFx/macros" "bullet*.xml" "extensions/$dlc_name/assets/fx/weaponFx/macros" "Copying bullet macros"
        copy_files "$SCRIPT_DIR/extensions/$dlc_name/assets/props/Engines/macros" "*engine_missile*.xml" "extensions/$dlc_name/assets/props/Engines/macros" "Copying engine missile macros"
        copy_files "$SCRIPT_DIR/extensions/$dlc_name/assets/props/WeaponSystems/missile/macros" "*.xml" "extensions/$dlc_name/assets/props/WeaponSystems/missile/macros" "Copying missile macros"
    fi
done

echo "Converting line endings to LF..."
find "$SCRIPT_DIR/$OUTPUT_DIR" -type f -name "*.xml" -exec dos2unix {} \; > /dev/null 2>&1

echo "✓ Extraction completed in: $OUTPUT_DIR/"
