# Tide Report Fish Shell Plugin

A collection of simple, asynchronous, and configurable prompt sections for the [Tide][] Fish prompt.
This plugin provides prompt items that display **Weather**, **Moon Phase**, **Ocean Tides**, and **GitHub** data without slowing down your shell.

## ✨ Key Features

* **Asynchronous**: Fetches data in the background to keep your prompt fast.
* **Efficient**: With the default weather provider (Open-Meteo), weather is fetched in the background; moon uses a separate request when needed.
* **Modular**: Provides independent prompt items. Use only the ones you want.
* **Configurable**: Easily customize formats, units, location, and refresh rates.
* **Helpful**: Provides succinct weather data, moon phase data, GitHub stats, or if you really want to lean into the maritime theme, tide data.

## Examples
![Screenshot](https://github.com/user-attachments/assets/185f983b-7db9-4934-bf0b-202d19315613)
![Screenshot](https://github.com/user-attachments/assets/afa0b8a8-9ff4-47c8-ae64-e20f6093c16c)
![Screenshot](https://github.com/user-attachments/assets/2441a581-2925-44e9-8d13-e98e11b4c17a)

## Quick start

1. Install the plugin: `fisher install MrBasa/TideReport@v1`
2. On a **first install** (when no Tide Report items are in your prompt), an **interactive wizard** runs: you see a preview of each prompt item and choose which to add (GitHub, weather, moon, tide). You can press Enter at each step to accept the defaults (GitHub, weather, moon on; tide off). If you add weather, you can pick one of three format presets (concise, medium, or detailed).
3. Run `tide reload` or open a new terminal to see the prompt.
4. If weather shows as unavailable at first, the plugin may still be detecting your location in the background; wait a moment or set [weather location](#weather-location) manually.

## 🔗 Dependencies

* **`curl`**: Required by the `weather`, `moon`, and `tide` modules to fetch data.
* **`gh`**: The [GitHub CLI](https://cli.github.com). Required by the `github` module. You must be authenticated (`gh auth login`).
* **`jq`**: **Required by all modules** (`github`, `tide`, `weather`, `moon`) for parsing JSON data.
* The latest version of [Fish][].
* [Fisher][] plugin manager.
* A [Nerd Font](https://github.com/ryanoasis/nerd-fonts) (optional, for icons).

## 📦 Installation

Install with [Fisher][]:

```fish
fisher install MrBasa/TideReport@v1
```

On a **first install**, an interactive wizard lets you choose which items to add and shows a sample of each. Defaults: GitHub, weather, and moon are added (tide is not); weather format is medium. Non-interactive installs (e.g. in CI) get the same defaults without prompts.

If you install from a **local path** (e.g. during development) and the prompt items do not appear, run:
```fish
tide_report_install
```

Or add `MrBasa/TideReport@v1` to `~/.config/fish/fish_plugins` and run `fisher update`. This is the recommended workflow when using a dotconfig manager.
See the [Fisher][] and [Tide][] documentation for more details on installing plugins.

### Clean reinstall

If the installer did not run (e.g. prompt items never appeared after install) or you see odd behavior after repeated installs/uninstalls, do a clean reinstall:

1. Remove the plugin: `fisher remove MrBasa/TideReport` (or the path you used, e.g. `fisher remove /path/to/TideReport`).
2. Optionally start a new Fish session so universals are reloaded.
3. Install again: `fisher install MrBasa/TideReport@v1` (or your path).

If items still do not appear, run `tide_report_install` once to apply configuration and add prompt items, then `tide reload`.

## 🚀 Available Prompt Sections

* `github`: Displays stars, forks, watchers, issues, and PRs for the current `gh` repo.
* `weather`: Displays the current weather (from Open-Meteo or wttr.in).
* `moon`: Displays the current moon phase (from a local offline model by default, or wttr.in when moon provider is wttr).
* `tide`: Displays the next high/low tide from NOAA (US-based).

## 🔧 Usage

After the install wizard (or on a non-interactive install), **weather**, **moon**, and **github** are added by default; **tide** is not. To add **tide** or change the order of items, edit the Tide prompt lists and reload:

```fish
set -Ua tide_right_prompt_items tide
tide reload
```

## ⚙️ Configuration
Set any of the following variables universally or add them to your `config.fish` to override defaults.

## ⚡ Caching Behavior

To keep your prompt fast, this plugin fetches data in the background and relies on cached data. This is done to prevent slow network requests from blocking your shell. Background fetch jobs are disowned so the shell does not wait for them when drawing the prompt (avoiding a 3–6 second delay on new shells when cache is empty or expired).

All file-based caches are stored in `~/.cache/tide-report/`.

### Weather, Moon, and Tide Modules

These modules use an asynchronous, file-based caching system with two timers:
1.  **Refresh (`..._refresh_seconds`)**: This is the "stale" timer. If you load your prompt and the cached data is older than this value, the prompt will **show the stale data** and trigger a fetch in the background. Your prompt is not blocked.
2.  **Expire (`..._expire_seconds`)**: This is the "invalid" timer. If the cached data is older than this value (or doesn't exist), the prompt will **show the unavailable text** (e.g., `🌊`) and trigger a background fetch.

This means it is **expected behavior** to see the "unavailable" text for a few seconds when the cache is empty or has expired.

With the **wttr** weather provider, one API call fills both weather and moon. With **Open-Meteo** (the default), weather and moon are independent. The moon item uses a **local, offline lunar phase model** by default, or **wttr.in** when `tide_report_moon_provider` is set to `wttr`.

### GitHub Module

The `github` module's caching is simpler and based on Fish's universal variables (not files).
* It caches data per-repository.
* Data is fetched *synchronously* if:
    1.  You change to a new directory that is a git repository.
    2.  You are in the same repository, but the cache is older than `tide_report_github_refresh_seconds`.

### Global Settings

These settings apply to all modules in this plugin.

| Variable                             | Description                                                | Default            |
| ------------------------------------ | ---------------------------------------------------------- | ------------------ |
| `tide_report_service_timeout_millis` | Timeout for all web requests, in milliseconds.             | `6000`             |
| `tide_report_wttr_url`               | URL for [wttr.in][], used for weather (wttr) and moon.     | `https://wttr.in`  |
| `tide_report_weather_provider`       | Weather backend: `wttr` or `openmeteo`.                    | `openmeteo`        |
| `tide_report_units`                  | Units for weather and tide: `m` (Metric), `u` (USCS)       | `m`                |
| `tide_time_format`                   | Time format string for Tide Prompt times (e.g. `"%H:%M"`). | From Tide         |

### 🤖 GitHub Module (`github`)

**Requires `gh` CLI to be installed and authenticated.**

The module displays stats for the current repository, with icons you can customize.

| Symbol                                  | Meaning              |
| --------------------------------------- | -------------------- |
| `★` (Stars)                             | Total stargazer count|
| `⑂` (Forks)                             | Total fork count     |
| `` (Watchers)                          | Total watcher count  |
| `!` (Issues)                            | Open issue count     |
| `PR` (Pull Requests)                    | Open PR count        |
| `!auth` (Error)                         | `gh` CLI is not authenticated |

| Variable                             | Description                                                     | Default           |
| ------------------------------------ | --------------------------------------------------------------- | ----------------- |
| `tide_github_color`                  | Prompt item color                                               | `white`           |
| `tide_github_bg_color`               | Prompt item background color                                    | `(theme default)` |
| `tide_report_github_icon_stars`      | Icon for stars.                                                 | `★`               |
| `tide_report_github_icon_forks`      | Icon for forks.                                                 | `⑂`               |
| `tide_report_github_icon_watchers`   | Icon for watchers.                                              | ``               |
| `tide_report_github_icon_issues`     | Icon for open issues.                                           | `!`               |
| `tide_report_github_icon_prs`        | Icon for open pull requests.                                    | `PR`              |
| `tide_report_github_color_stars`     | Color for stargazers.                                           | `yellow`          |
| `tide_report_github_color_forks`     | Color for forks (defaults to `..._color_stars`).                | `yellow`          |
| `tide_report_github_color_watchers`  | Color for watchers (defaults to `..._color_stars`).             | `yellow`          |
| `tide_report_github_color_issues`    | Color for issues (defaults to `..._color_stars`).               | `yellow`          |
| `tide_report_github_color_prs`       | Color for PRs (defaults to `..._color_stars`).                  | `yellow`          |
| `tide_report_github_refresh_seconds` | GitHub data cache time for a given repository.                  | `30`              |
| `tide_report_github_unavailable_text`  | Text to display when GitHub data is not available.            | `...`            |
| `tide_report_github_unavailable_color` | Color for the unavailable text.                               | `red`             |

### ☔ Weather Module (`weather`)

**This module requires `jq` for parsing JSON.**

The weather format is a string with custom specifiers. When you add the weather item in the install wizard, you can choose one of three presets: **concise** (emoji + temp), **medium** (emoji + temp + wind), or **detailed** (thermometer + temp, feels-like in parentheses, humidity + wind).

| Specifier | Description                                   | Example     |
| :---      | :---                                          | :---        |
| `%t`      | Temperature (with `+` or `-` sign)            | `+10°`      |
| `%C`      | Condition text                                | `Clear`     |
| `%c`      | Condition emoji                               | `☀️`        |
| `%w`      | Wind speed and unit                           | `15km/h`    |
| `%d`      | Wind direction arrow (direction wind is blowing *to*; matches wttr.in) | `⬇` etc.   |
| `%h`      | Humidity                                      | `80%`       |
| `%f`      | 'Feels like' temperature                      | `+8°`       |
| `%u`      | UV Index                                      | `42`        |
| `%S`      | Sunrise time                                  | `06:37`     |
| `%s`      | Sunset time                                   | `19:46`     |

| Variable                                | Description                                                             | Default           |
| --------------------------------------- | ----------------------------------------------------------------------- | ----------------- |
| `tide_weather_color`                    | Prompt item color                                                       | `(theme default)` |
| `tide_weather_bg_color`                 | Prompt item background color                                            | `(theme default)` |
| `tide_report_weather_format`            | Format string (see table above).                                        | `"%c %t %d%w"`    |
| `tide_report_weather_symbol_color`      | Color for symbols in weather output.                                    | `white`           |
| `tide_report_weather_location`          | Location for weather. See [Weather location](#weather-location) below.  | `""`              |
| `tide_report_weather_refresh_seconds`   | How old data can be before a background refresh is triggered.           | `300`             |
| `tide_report_weather_expire_seconds`    | How old data can be before it's considered invalid.                     | `900`             |
| `tide_report_weather_language`          | Two-letter language code (e.g., `de`, `fr`, `zh-cn`).                   | `en`              |
| `tide_report_weather_unavailable_text`  | Text to display when weather data is not available.                     | `...`            |
| `tide_report_weather_unavailable_color` | Color for the unavailable text.                                         | `red`             |

#### Weather location

`tide_report_weather_location` controls where weather is fetched for. Valid values depend on the weather provider (`tide_report_weather_provider`). **Both providers accept GPS coordinates** as `latitude,longitude` (e.g. `-78.46,106.79`). No spaces.

**When provider is `openmeteo` (default):**

- **Empty string `""`** (default): Your location is detected from your IP in the background and cached per shell session (file under `~/.cache/tide-report/`). A new terminal in a new place will detect again. No need to set anything for IP-based weather.
- **Place name or postal code:** The value is sent to the [Open-Meteo Geocoding API](https://open-meteo.com/en/docs/geocoding-api). Use a city name, region, or postal code (e.g. `Berlin`, `London`, `90210`). At least three characters are recommended for fuzzy matching.
- **GPS coordinates:** Use `latitude,longitude` to skip geocoding.

**When provider is `wttr`:**

- **Empty string `""`**: wttr.in uses your IP address to guess your location.
- **City or place name:** Use a single word or hyphenated name (e.g. `Paris`, `Saint-Petersburg`, `New-York`). Unicode is supported. For spaces use hyphens or `+` (e.g. `Eiffel+tower`).
- **3-letter airport code:** e.g. `muc`, `lhr`, `jfk`.
- **Postal or area code:** e.g. `90210`, `94107`.
- **GPS coordinates:** `latitude,longitude` (e.g. `-78.46,106.79`).
- **Domain name:** Prefix with `@` (e.g. `@stackoverflow.com`) for location derived from the domain.

### 🌕 Moon Module (`moon`)

**This module requires `jq`.** It uses its own cache file (`~/.cache/tide-report/moon.json`). Moon phase is computed by a **local, offline astronomical model** by default (inspired by the Sun and Moon formulas from [SunCalc](https://github.com/mourner/suncalc)), or fetched from **wttr.in** when `tide_report_moon_provider` is `wttr`. When both moon and weather use wttr, one request fills both caches. It displays the moon phase emoji.

| Variable                              | Description                                                     | Default           |
| ------------------------------------- | --------------------------------------------------------------- | ----------------- |
| `tide_moon_color`                     | Prompt item color                                               | `(theme default)` |
| `tide_moon_bg_color`                  | Prompt item background color                                    | `(theme default)` |
| `tide_report_moon_provider`          | Moon backend: `local` (offline model) or `wttr`.                | `local`           |
| `tide_report_moon_refresh_seconds`   | How old data can be before a background refresh is triggered.   | `14400`           |
| `tide_report_moon_expire_seconds`    | How old data can be before it's considered invalid.             | `28800`           |
| `tide_report_moon_unavailable_text`  | Text to display when moon data is not available.                | `...`            |
| `tide_report_moon_unavailable_color`  | Color for the unavailable text.                                 | `red`             |

### 🌊 Tide Module (`tide`)

**This module requires `jq` and you must set a Station ID (default Boston).**

To find your nearest station, use the [**NOAA Tides and Currents Map**](https://tidesandcurrents.noaa.gov/map/index.html). Search for your location (e.g., by city or ZIP code), click on a nearby station icon on the map, and copy the `Station ID` number. Ensure that the station has high and low tide predictions available.

| Variable                             | Description                                                     | Default            |
| ------------------------------------ | --------------------------------------------------------------- | ------------------ |
| `tide_tide_color`                    | Prompt item color                                               | `0087AF`           |
| `tide_tide_bg_color`                 | Prompt item background color                                    | `(theme default)`  |
| `tide_report_tide_station_id`        | **Required.** The NOAA station ID (e.g., `8443970` for Boston). | `"8443970"`        |
| `tide_report_tide_refresh_seconds`   | How old data can be before a background refresh is triggered.   | `14400`            |
| `tide_report_tide_expire_seconds`    | How old data can be before it's considered invalid.             | `28800`            |
| `tide_report_tide_symbol_high`       | Symbol to show for an upcoming high tide.                       | `⇞`                |
| `tide_report_tide_symbol_low`        | Symbol to show for an upcoming low tide.                        | `⇟`                |
| `tide_report_tide_symbol_color`      | Color for the high/low tide symbol.                             | `white`            |
| `tide_report_tide_unavailable_text`  | Text to display when tide data is not available.                | `🌊...`            |
| `tide_report_tide_unavailable_color` | Color for the unavailable text.                                 | `red`              |
| `tide_report_tide_show_level`        | Set to `"true"` to show the height of the next tide.            | `"true"`           |

## Testing

The project uses [Fishtape](https://github.com/jorgebucaran/fishtape) for unit and integration tests. Install it with Fisher:

**CI:** GitHub Actions runs the test suite on **Ubuntu** (GNU `date`) and **macOS** (BSD `date`) on every push and PR so that date-formatting and cache logic stay compatible with both.

```fish
fisher install jorgebucaran/fishtape
```

From the repo root, run all tests:

```fish
fishtape test/unit/*.fish test/integration/*.fish
```

Run only unit tests or only integration tests:

```fish
fishtape test/unit/*.fish
fishtape test/integration/*.fish
```

**Pre-push hook (gated check-in):** To run the test suite automatically before every push to `main` or `master` (and block the push if tests fail), install the pre-push hook from the repo root:

```sh
cp scripts/pre-push .git/hooks/pre-push && chmod +x .git/hooks/pre-push
```

You need Fish and Fishtape available (same as running the tests manually). The hook only runs when the push updates `main` or `master`; pushes to other branches are not gated.

Tests use fixture data under `test/fixtures/` and do not require network access or Tide to be installed.

## Troubleshooting

- **Weather shows as unavailable:** With the default provider (Open-Meteo) and empty location, the plugin detects your location from your IP in the background. Wait a few seconds for the first fetch to complete, or open a new terminal to trigger a fresh lookup. You can also set [weather location](#weather-location) explicitly.

## Acknowledgements
* [Jorge Bucaran](https://github.com/jorgebucaran) and [Ilan Cosman](https://github.com/IlanCosman) for making [Fisher][] and [Tide][].
* [Moby Dick](https://www.gutenberg.org/ebooks/2701), the sweet air of the ocean breeze, and the gentle lullaby the sea sings before she breaks you on the rocks.
* [NOAA](https://www.noaa.gov) - we'll miss them when they're gone... 🇺🇸😢
* [Igor Chubin](https://github.com/chubin) and all the contributors/sponsors of [wttr.in][].
* [Vladimir Agafonkin](https://github.com/mourner) for the [SunCalc](https://github.com/mourner/suncalc) library, whose public moon phase formulas inspired the local lunar model used here.

### Other Handy Fish Plugins I Use:
* [jorgebucaran/fisher](https://github.com/jorgebucaran/fisher)
* [ilancosman/tide](https://github.com/ilancosman/tide)
* [gazorby/fish-abbreviation-tips](https://github.com/gazorby/fish-abbreviation-tips)
* [laughedelic/pisces](https://github.com/laughedelic/pisces)
* [meaningful-ooo/sponge](https://github.com/meaningful-ooo/sponge)
* [nickeb96/puffer-fish](https://github.com/nickeb96/puffer-fish)
* [jorgebucaran/spark.fish](https://github.com/jorgebucaran/spark.fish)
* [jorgebucaran/humantime.fish](https://github.com/jorgebucaran/humantime.fish)
* [jhillyerd/plugin-git](https://github.com/jhillyerd/plugin-git)
* [PatrickF1/fzf.fish](https://github.com/PatrickF1/fzf.fish)


[fish]: https://fishshell.com/
[fisher]: https://github.com/jorgebucaran/fisher
[tide]: https://github.com/IlanCosman/tide
[wttr.in]: https://github.com/chubin/wttr.in
