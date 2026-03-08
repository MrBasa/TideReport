## TideReport :: Moon phase math helpers (SunCalc-style)
##
## Ported in spirit from SunCalc (https://github.com/mourner/suncalc)
## by Vladimir Agafonkin, used under the BSD 2-Clause license.
## We only implement the minimal subset needed to compute a numeric
## lunar phase fraction in [0,1).

## Evaluate floating-point math expressions with maximum precision.
function __tide_report_moon_eval --description "Evaluate moon math expression at max precision" --argument-names expression
    math --scale=max "$expression"
end

## Ensure moon constants are initialized with high precision.
function __tide_report_moon_init_constants --description "Initialize moon math constants with high precision"
    set -g __tide_report_moon_PI (__tide_report_moon_eval "acos(-1)")
    set -g __tide_report_moon_rad (__tide_report_moon_eval "$__tide_report_moon_PI / 180")
    set -q __tide_report_moon_day_seconds; or set -g __tide_report_moon_day_seconds 86400
    set -q __tide_report_moon_J1970; or set -g __tide_report_moon_J1970 2440588
    set -q __tide_report_moon_J2000; or set -g __tide_report_moon_J2000 2451545
    set -g __tide_report_moon_obliquity (__tide_report_moon_eval "$__tide_report_moon_rad * 23.4397")
end

## Convert Unix time (seconds) to days since J2000 epoch.
function __tide_report_moon_to_days --description "Convert Unix time to days since J2000 epoch" --argument-names unix_time
    set -l jd (__tide_report_moon_eval "$unix_time / $__tide_report_moon_day_seconds - 0.5 + $__tide_report_moon_J1970")
    __tide_report_moon_eval "$jd - $__tide_report_moon_J2000"
end

## Compute right ascension in radians for ecliptic coordinates l, b.
function __tide_report_moon_right_ascension --description "Compute right ascension in radians for ecliptic lon/lat" --argument-names l b
    set -l e $__tide_report_moon_obliquity
    __tide_report_moon_eval "atan2(sin($l) * cos($e) - tan($b) * sin($e), cos($l))"
end

## Compute declination in radians for ecliptic coordinates l, b.
function __tide_report_moon_declination --description "Compute declination in radians for ecliptic lon/lat" --argument-names l b
    set -l e $__tide_report_moon_obliquity
    __tide_report_moon_eval "asin(sin($b) * cos($e) + cos($b) * sin($e) * sin($l))"
end

## Compute Sun right ascension and declination at days offset d since J2000.
function __tide_report_moon_sun_coords --description "Compute Sun right ascension and declination for day offset d" --argument-names d
    set -l rad $__tide_report_moon_rad
    set -l M (__tide_report_moon_eval "$rad * (357.5291 + 0.98560028 * $d)")
    set -l C (__tide_report_moon_eval "$rad * (1.9148 * sin($M) + 0.02 * sin(2 * $M) + 0.0003 * sin(3 * $M))")
    set -l P (__tide_report_moon_eval "$rad * 102.9372")
    set -l L (__tide_report_moon_eval "$M + $C + $P + $__tide_report_moon_PI")
    set -l ra (__tide_report_moon_right_ascension $L 0)
    set -l dec (__tide_report_moon_declination $L 0)
    printf "%s\n%s\n" $ra $dec
end

## Compute Moon coordinates and distance at days offset d since J2000.
function __tide_report_moon_moon_coords --description "Compute Moon lon/lat-based coords and distance for day offset d" --argument-names d
    set -l rad $__tide_report_moon_rad
    set -l L (__tide_report_moon_eval "$rad * (218.316 + 13.176396 * $d)")
    set -l M (__tide_report_moon_eval "$rad * (134.963 + 13.064993 * $d)")
    set -l F (__tide_report_moon_eval "$rad * (93.272 + 13.22935 * $d)")
    set -l l (__tide_report_moon_eval "$L + $rad * 6.289 * sin($M)")
    set -l b (__tide_report_moon_eval "$rad * 5.128 * sin($F)")
    set -l dt (__tide_report_moon_eval "385001 - 20905 * cos($M)")
    set -l ra (__tide_report_moon_right_ascension $l $b)
    set -l dec (__tide_report_moon_declination $l $b)
    printf "%s\n%s\n%s\n" $ra $dec $dt
end

## Compute normalized lunar phase fraction in [0,1) from Unix time.
function __tide_report_moon_phase_fraction_from_unix --description "Compute normalized lunar phase fraction from Unix time" --argument-names unix_time
    set -l d (__tide_report_moon_to_days $unix_time)
    set -l sun_coords (__tide_report_moon_sun_coords $d)
    set -l s_ra $sun_coords[1]
    set -l s_dec $sun_coords[2]
    set -l moon_coords (__tide_report_moon_moon_coords $d)
    set -l m_ra $moon_coords[1]
    set -l m_dec $moon_coords[2]
    set -l m_dist $moon_coords[3]

    set -l sdist 149598000
    set -l phi (__tide_report_moon_eval "acos(sin($s_dec) * sin($m_dec) + cos($s_dec) * cos($m_dec) * cos($s_ra - $m_ra))")
    set -l inc (__tide_report_moon_eval "atan2($sdist * sin($phi), $m_dist - $sdist * cos($phi))")
    set -l angle (__tide_report_moon_eval "atan2(cos($s_dec) * sin($s_ra - $m_ra), sin($s_dec) * cos($m_dec) - cos($s_dec) * sin($m_dec) * cos($s_ra - $m_ra))")

    set -l sign 1
    if test (__tide_report_moon_eval "$angle") -lt 0
        set sign -1
    end

    set -l phase (__tide_report_moon_eval "0.5 + 0.5 * $inc * $sign / $__tide_report_moon_PI")
    __tide_report_moon_eval "($phase + 1) % 1"
end

## Compute illumination percentage (0–100) from Unix time.
## Uses phase fraction; formula: (1 - cos(2π * phase_fraction)) / 2 * 100.
## Returns nothing and exits non-zero if phase_fraction cannot be computed.
function __tide_report_moon_illumination_from_unix --description "Compute moon illumination percentage (0–100) from Unix time" --argument-names unix_time
    set -l phase_fraction (__tide_report_moon_phase_fraction_from_unix $unix_time)
    if test -z "$phase_fraction"
        return 1
    end
    __tide_report_moon_eval "(1 - cos(2 * $__tide_report_moon_PI * $phase_fraction)) / 2 * 100"
end

__tide_report_moon_init_constants
