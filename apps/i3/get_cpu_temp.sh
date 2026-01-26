#!/bin/bash

# CPU Temperature Script for Regolith/i3xrocks
# Outputs the CPU temperature (overall or highest core)

# Try using 'sensors' command if available (part of lm-sensors)
if command -v sensors >/dev/null 2>&1; then
    # Try to find "Package id 0" (common for Intel)
    TEMP=$(sensors | grep "Package id 0:" | awk '{print $4}' | tr -d '+')
    if [ -n "$TEMP" ]; then
        echo "$TEMP"
        exit 0
    fi
    
    # Try Tctl (common for AMD)
    TEMP=$(sensors | grep "Tctl:" | awk '{print $2}' | tr -d '+')
    if [ -n "$TEMP" ]; then
        echo "$TEMP"
        exit 0
    fi
    
    # Fallback to the first Core temperature if Package not found
    TEMP=$(sensors | grep "Core 0:" | awk '{print $3}' | tr -d '+')
    if [ -n "$TEMP" ]; then
        echo "$TEMP"
        exit 0
    fi
fi

# Fallback to /sys/class/thermal if sensors is missing or failed
if [ -d "/sys/class/thermal" ]; then
    MAX_TEMP=0
    FOUND=0
    
    # Look for x86_pkg_temp specifically
    for zone in /sys/class/thermal/thermal_zone*; do
        if [ -r "$zone/type" ] && [ -r "$zone/temp" ]; then
            TYPE=$(cat "$zone/type")
            if [ "$TYPE" = "x86_pkg_temp" ]; then
                TEMP=$(cat "$zone/temp")
                echo "$((TEMP / 1000))°C"
                exit 0
            fi
        fi
    done

    # If no specific package temp found, search for the highest valid temp
    for zone in /sys/class/thermal/thermal_zone*; do
        if [ -r "$zone/temp" ]; then
            TEMP=$(cat "$zone/temp")
            # Filter reasonable range (0-150 C)
            if [ "$TEMP" -gt 0 ] && [ "$TEMP" -lt 150000 ]; then
                if [ "$TEMP" -gt "$MAX_TEMP" ]; then
                    MAX_TEMP=$TEMP
                    FOUND=1
                fi
            fi
        fi
    done
    
    if [ "$FOUND" -eq 1 ]; then
        echo "$((MAX_TEMP / 1000)).0°C"
        exit 0
    fi
fi

echo "N/A"
