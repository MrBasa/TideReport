source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_handle_async_weather.fish"

function __tide_report_provider_wttr
    echo wttr
end
function __tide_report_provider_openmeteo
    echo openmeteo
end

@test "provider dispatch uses wttr" (
    set -g tide_report_weather_provider wttr
    __tide_report_fetch_weather /tmp/x 5 _lock
) = "wttr"

@test "provider dispatch uses openmeteo" (
    set -g tide_report_weather_provider openmeteo
    __tide_report_fetch_weather /tmp/x 5 _lock
) = "openmeteo"

@test "provider dispatch falls back to wttr" (
    set -g tide_report_weather_provider invalid
    __tide_report_fetch_weather /tmp/x 5 _lock
) = "wttr"
