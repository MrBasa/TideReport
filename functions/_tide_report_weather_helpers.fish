## TideReport :: Shared weather helpers
##
## Open-Meteo location resolution and normalized weather.json builder.

function __tide_report_read_ip_location_cache --description "Read cached IP geolocation when fresh and owned by current shell" --argument-names now max_age_seconds
    set -l ip_file "$HOME/.cache/tide-report/ip-location"
    if not test -f "$ip_file"
        return 1
    end
    set -l line (string split '|' (cat "$ip_file" 2>/dev/null; or echo ""))
    if test (count $line) -lt 3; or test "$line[1]" != "$fish_pid"
        return 1
    end
    set -l mtime (__tide_report_file_mtime "$ip_file")
    test -n "$mtime"; or return 1
    set -l age (math $now - $mtime)
    if test $age -gt $max_age_seconds
        return 1
    end
    echo "$line[2],$line[3]"
end

function __tide_report_openmeteo_fetch_ip_geo --description "Fetch lat/lon (and optional display fields) from ip-api.com" --argument-names timeout_sec fields
    set -q fields; or set fields "lat,lon"
    set -l ip_data (curl -s -A "$tide_report_user_agent" --max-time $timeout_sec "http://ip-api.com/json/?fields=$fields")
    if test $status -ne 0; or test -z "$ip_data"
        return 1
    end
    echo "$ip_data"
end

function __tide_report_openmeteo_parse_lat_lon --description "Parse lat and lon from a coordinate string (forgiving whitespace)" --argument-names raw
    set -l trimmed (string trim -- "$raw")
    if not string match -qr '^-?[0-9]+\.?[0-9]*\s*,\s*-?[0-9]+\.?[0-9]*$' -- "$trimmed"
        return 1
    end
    set -l parts (string split ',' -- "$trimmed")
    set -l lat (string trim -- $parts[1])
    set -l lon (string trim -- $parts[2])
    if test -z "$lat"; or test -z "$lon"
        return 1
    end
    echo "$lat"
    echo "$lon"
end

function __tide_report_openmeteo_geocode --description "Geocode a place name via Open-Meteo; echo lat lon tz name admin1 country" --argument-names name timeout_sec
    set -l location_escaped (string escape --style url "$name")
    set -l geo_url "https://geocoding-api.open-meteo.com/v1/search?name=$location_escaped&count=1"
    set -l geo_data (curl -s -A "$tide_report_user_agent" --max-time $timeout_sec "$geo_url")
    if test $status -ne 0; or test -z "$geo_data"
        return 1
    end
    set -l lat (printf "%s" "$geo_data" | jq -r '.results[0].latitude // empty')
    set -l lon (printf "%s" "$geo_data" | jq -r '.results[0].longitude // empty')
    if test -z "$lat"; or test -z "$lon"
        return 1
    end
    set -l tz (printf "%s" "$geo_data" | jq -r '.results[0].timezone // "auto"')
    set -l geo_name (printf "%s" "$geo_data" | jq -r '.results[0].name // empty')
    set -l admin1 (printf "%s" "$geo_data" | jq -r '.results[0].admin1 // empty')
    set -l country (printf "%s" "$geo_data" | jq -r '.results[0].country // empty')
    echo "$lat"
    echo "$lon"
    echo "$tz"
    echo "$geo_name"
    echo "$admin1"
    echo "$country"
end

function __tide_report_openmeteo_resolve_location --description "Resolve lat, lon, and timezone for Open-Meteo requests" --argument-names location timeout_sec write_ip_cache
    set -l lat ""
    set -l lon ""
    set -l tz "auto"

    if set -q TIDE_REPORT_RESOLVED_LOCATION; and test -n "$TIDE_REPORT_RESOLVED_LOCATION"
        set -l parts (string split ',' -- $TIDE_REPORT_RESOLVED_LOCATION)
        if test (count $parts) -ge 2
            set lat (string trim -- $parts[1])
            set lon (string trim -- $parts[2])
        end
    else if test -z "$location"
        set -l ip_json (__tide_report_openmeteo_fetch_ip_geo "$timeout_sec" "lat,lon")
        if test $status -eq 0; and test -n "$ip_json"
            set lat (printf "%s" "$ip_json" | jq -r '.lat // empty')
            set lon (printf "%s" "$ip_json" | jq -r '.lon // empty')
            if test "$write_ip_cache" = true; and test -n "$lat"; and test -n "$lon"
                if set -q TIDE_REPORT_PARENT_PID; and test -n "$TIDE_REPORT_PARENT_PID"
                    set -l ip_file "$HOME/.cache/tide-report/ip-location"
                    mkdir -p (dirname "$ip_file")
                    printf "%s|%s|%s\n" "$TIDE_REPORT_PARENT_PID" "$lat" "$lon" > "$ip_file"
                end
            end
        end
    else if set parsed (__tide_report_openmeteo_parse_lat_lon "$location")
        set lat $parsed[1]
        set lon $parsed[2]
    else
        if not set geocoded (__tide_report_openmeteo_geocode "$location" "$timeout_sec")
            return 1
        end
        set lat $geocoded[1]
        set lon $geocoded[2]
        set tz $geocoded[3]
    end

    if test -z "$lat"; or test -z "$lon"
        return 1
    end

    echo "$lat"
    echo "$lon"
    echo "$tz"
end

function __tide_report_openmeteo_wizard_ip_line --description "Build wizard display line for detected IP location" --argument-names timeout_sec
    set -l ip_json (__tide_report_openmeteo_fetch_ip_geo "$timeout_sec" "lat,lon,city,regionName,country")
    if test $status -ne 0; or test -z "$ip_json"
        return 1
    end
    set -l lat (printf "%s" "$ip_json" | jq -r '.lat // empty')
    set -l lon (printf "%s" "$ip_json" | jq -r '.lon // empty')
    if test -z "$lat"; or test -z "$lon"
        return 1
    end
    set -l city (printf "%s" "$ip_json" | jq -r '.city // empty')
    set -l region (printf "%s" "$ip_json" | jq -r '.regionName // empty')
    set -l country (printf "%s" "$ip_json" | jq -r '.country // empty')
    set -l parts $city $region $country
    printf "%s (%s, %s)\n" (string join ", " $parts) "$lat" "$lon"
end

function __tide_report_build_weather_normalized_json --description "Build normalized weather.json object via jq" --argument-names tc tf fc ff cc ct wk wm wd hu uv su sv
    set -l ct_safe (string replace '\\' '\\\\' -- $ct)
    set ct_safe (string replace '"' '\\"' -- $ct_safe)
    set -l su_trim (string trim -- $su)
    set -l sv_trim (string trim -- $sv)
    jq -n \
        --argjson tc $tc --argjson tf $tf --argjson fc $fc --argjson ff $ff \
        --argjson cc $cc --arg ct "$ct_safe" --argjson wk $wk --argjson wm $wm \
        --arg wd "$wd" --argjson hu $hu --argjson uv $uv \
        --arg su "$su_trim" --arg sv "$sv_trim" \
        '{temp_c:$tc,temp_f:$tf,feels_like_c:$fc,feels_like_f:$ff,condition_code:$cc,condition_text:$ct,wind_speed_kmh:$wk,wind_speed_mph:$wm,wind_dir_16:$wd,humidity:$hu,uv_index:$uv,sunrise_utc:(if $su=="" then null else ($su|tonumber) end),sunset_utc:(if $sv=="" then null else ($sv|tonumber) end)}'
end
