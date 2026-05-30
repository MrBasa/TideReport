source (dirname (dirname (status filename)))/../helpers/setup.fish
source "$REPO_ROOT/functions/_tide_report_provider_moon_local.fish"

@test "moon_phase_name_from_fraction maps bucket 0 to New Moon" (
    __tide_report_moon_phase_name_from_fraction 0
) = "New Moon"

@test "moon_phase_name_from_fraction maps bucket 1 to Waxing Crescent" (
    __tide_report_moon_phase_name_from_fraction 0.125
) = "Waxing Crescent"

@test "moon_phase_name_from_fraction maps bucket 4 to Full Moon" (
    __tide_report_moon_phase_name_from_fraction 0.5
) = "Full Moon"

@test "moon_phase_name_from_fraction maps bucket 7 to Waning Crescent" (
    __tide_report_moon_phase_name_from_fraction 0.875
) = "Waning Crescent"
