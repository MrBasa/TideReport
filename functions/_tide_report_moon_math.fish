#! TideReport :: Moon phase math helpers (SunCalc-style)
#
#! Ported in spirit from SunCalc (https://github.com/mourner/suncalc)
#! by Vladimir Agafonkin, used under the BSD 2-Clause license.
#! We only implement the minimal subset needed to compute a numeric
#! lunar phase fraction in [0,1).

set -q __tide_report_moon_math_initialized; and test $__tide_report_moon_math_initialized = 1; and return
set -g __tide_report_moon_math_initialized 1

set -g __tide_report_moon_PI (math "acos(-1)")
set -g __tide_report_moon_rad (math "$__tide_report_moon_PI / 180")
set -g __tide_report_moon_day_seconds 86400
set -g __tide_report_moon_J1970 2440588
set -g __tide_report_moon_J2000 2451545
set -g __tide_report_moon_obliquity (math "$__tide_report_moon_rad * 23.4397")

function __tide_report_moon_to_days --argument-names unix_time
    set -l jd (math "$unix_time / $__tide_report_moon_day_seconds - 0.5 + $__tide_report_moon_J1970")
    math "$jd - $__tide_report_moon_J2000"
end

function __tide_report_moon_right_ascension --argument-names l b
    set -l e $__tide_report_moon_obliquity
    math "atan2(sin($l) * cos($e) - tan($b) * sin($e), cos($l))"
end

function __tide_report_moon_declination --argument-names l b
    set -l e $__tide_report_moon_obliquity
    math "asin(sin($b) * cos($e) + cos($b) * sin($e) * sin($l))"
end

function __tide_report_moon_sun_coords --argument-names d
    set -l rad $__tide_report_moon_rad
    set -l M (math "$rad * (357.5291 + 0.98560028 * $d)")
    set -l C (math "$rad * (1.9148 * sin($M) + 0.02 * sin(2 * $M) + 0.0003 * sin(3 * $M))")
    set -l P (math "$rad * 102.9372")
    set -l L (math "$M + $C + $P + $__tide_report_moon_PI")
    set -l ra (__tide_report_moon_right_ascension $L 0)
    set -l dec (__tide_report_moon_declination $L 0)
    printf "%s\n%s\n" $ra $dec
end

function __tide_report_moon_moon_coords --argument-names d
    set -l rad $__tide_report_moon_rad
    set -l L (math "$rad * (218.316 + 13.176396 * $d)")
    set -l M (math "$rad * (134.963 + 13.064993 * $d)")
    set -l F (math "$rad * (93.272 + 13.22935 * $d)")
    set -l l (math "$L + $rad * 6.289 * sin($M)")
    set -l b (math "$rad * 5.128 * sin($F)")
    set -l dt (math "385001 - 20905 * cos($M)")
    set -l ra (__tide_report_moon_right_ascension $l $b)
    set -l dec (__tide_report_moon_declination $l $b)
    printf "%s\n%s\n%s\n" $ra $dec $dt
end

function __tide_report_moon_phase_fraction_from_unix --argument-names unix_time
    set -l d (__tide_report_moon_to_days $unix_time)
    set -l sun_coords (__tide_report_moon_sun_coords $d)
    set -l s_ra $sun_coords[1]
    set -l s_dec $sun_coords[2]
    set -l moon_coords (__tide_report_moon_moon_coords $d)
    set -l m_ra $moon_coords[1]
    set -l m_dec $moon_coords[2]
    set -l m_dist $moon_coords[3]

    set -l sdist 149598000
    set -l phi (math "acos(sin($s_dec) * sin($m_dec) + cos($s_dec) * cos($m_dec) * cos($s_ra - $m_ra))")
    set -l inc (math "atan2($sdist * sin($phi), $m_dist - $sdist * cos($phi))")
    set -l angle (math "atan2(cos($s_dec) * sin($s_ra - $m_ra), sin($s_dec) * cos($m_dec) - cos($s_dec) * sin($m_dec) * cos($s_ra - $m_ra))")

    set -l sign 1
    if test (math "$angle") -lt 0
        set sign -1
    end

    set -l phase (math "0.5 + 0.5 * $inc * $sign / $__tide_report_moon_PI")
    math "($phase + 1) % 1"
end

