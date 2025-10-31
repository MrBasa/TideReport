# Tide Report Plugin

A collection of simple, asynchronous, and configurable prompt sections for the [Tide][] Fish prompt.

This plugin provides prompt items that display useful information (weather, moon phase, ocean tides, and GitHub repo stats) without slowing down your shell.

** THIS IS A WORK IN PROGRESS - weather, moon, and github modules should be in working order **

## ✨ Key Features

* **Asynchronous**: Uses Tide's native event system to fetch data in the background.
* **Modular**: Provides independent prompt items. Use only the ones you want.
* **Configurable**: Easily customize the format, units, location, and refresh rates.
* **Helpful**: Provides succinct weather data, moon phase data, GitHub stats, or if you really want to lean into the maritime theme, tide data.
* **Growing?**: May expand this to provide other prompt sections such as: sunrise/sundown, weather forecast, or ???

![Screenshot](https://github.com/user-attachments/assets/185f983b-7db9-4934-bf0b-202d19315613)

## 🔗 Dependencies

* **`curl`**: Required by the `weather`, `moon`, and `tide` modules to fetch data.
* **`gh`**: The [GitHub CLI](https://cli.github.com). Required by the `github` module. You must be authenticated (`gh auth login`).
* **`jq`**: Required by the `github` and `tide` modules for parsing JSON data.
* The latest version of [Fish][] (tested with `4.0.2`).
* [Fisher][] plugin manager.
* A [Nerd Font](https://github.com/ryanoasis/nerd-fonts) configured in your terminal.

## 📦 Installation

Install with [Fisher][]:

```fish
fisher install MrBasa/TideReport
```

Or add `MrBasa/TideReport` to `~/.config/fish/fish_plugins` and run `fisher update`. This is the recommended workflow when using a dotconfig manager.
See the [Fisher][] and [Tide][] documentation for more details on installing plugins.

## 🚀 Available Prompt Sections

* `github`: Displays stars, forks, open issues, and open PRs for the current `gh` repo.
* `weather`: Displays the current weather from `wttr.in`.
* `moon`: Displays the current moon phase from `wttr.in`.
* `tide`: Displays the next high/low tide from NOAA (US-based).

## 🔧 Usage

Add any of the module items to your Tide prompt. For example:

```fish
set -Ua tide_right_prompt_items weather moon tide github
tide reload
```

## ⚙️ Configuration
Set any of the following variables universally or add them to your `config.fish` to override defaults.

### Global Settings

This setting applies to all modules in this plugin.

| Variable                             | Description                                      | Default            |
| ------------------------------------ | ------------------------------------------------ | ------------------ |
| `tide_report_service_timeout_millis` | Timeout for all web requests, in milliseconds.   | `3000`             |
| `tide_report_wttr_url`               | URL for [wttr.in][], for self-hosted options.    | `https://wttr.in`  |

### 🤖 GitHub Module (`github`)

**Requires `gh` CLI to be installed and authenticated.**

| Variable                           | Description                                                     | Default           |
| ---------------------------------- | --------------------------------------------------------------- | ----------------- |
| `tide_github_color`                | Prompt item color                                               | `white`           |
| `tide_github_bg_color`             | Prompt item background color                                    | `(theme default)` |
| `tide_report_github_icon`          | Icon to display for the GitHub section.                         | ``               |
| `tide_report_github_color_stars`   | Color for the 'stars' count.                                    | `bryellow`        |
| `tide_report_github_color_forks`   | Color for the 'forks' count.                                    | `bryellow`        |
| `tide_report_github_color_issues`  | Color for the 'issues' count.                                   | `bryellow`        |
| `tide_report_github_color_prs`     | Color for the 'pull requests' count.                            | `bryellow`        |

### ☔ Weather Module (`weather`)

| Variable                                | Description                                                             | Default           |
| --------------------------------------- | ----------------------------------------------------------------------- | ----------------- |
| `tide_weather_color`                    | Prompt item color                                                       | `(theme default)` |
| `tide_weather_bg_color`                 | Prompt item background color                                            | `(theme default)` |
| `tide_report_weather_format`            | `wttr.in` format (`1`-`4`). See [wttr.in docs](https://wttr.in/:help).  | `2`               |
| `tide_report_weather_units`             | `u` (USCS), `m` (Metric/Celsius), `M` (Metric/Wind Speed m/s)           | `m`               |
| `tide_report_weather_location`          | Any location `wttr.in` accepts (e.g., `Paris`, `90210`).                | `""` (IP-based)   |
| `tide_report_weather_refresh_seconds`   | How old data can be before a background refresh is triggered.           | `300`             |
| `tide_report_weather_expire_seconds`    | How old data can be before it's considered invalid.                     | `600`             |
| `tide_report_weather_language`          | Two-letter language code (e.g., `de`, `fr`, `zh-cn`).                   | `en`              |
| `tide_report_weather_unavailable_text`  | Text to display when weather data is not available.                     | ``               |
| `tide_report_weather_unavailable_color` | Color for the unavailable text.                                         | `brred`           |

### 🌕 Moon Module (`moon`)

| Variable                              | Description                                                     | Default           |
| ------------------------------------- | --------------------------------------------------------------- | ----------------- |
| `tide_moon_color`                     | Prompt item color                                               | `(theme default)` |
| `tide_moon_bg_color`                  | Prompt item background color                                    | `(theme default)` |
| `tide_report_moon_format`             | `wttr.in` moon format (e.g., `%m` for emoji, `%M` for name).    | `"%m"`            |
| `tide_report_moon_refresh_seconds`    | How old data can be before a background refresh is triggered.   | `14400`           |
| `tide_report_moon_expire_seconds`     | How old data can be before it's considered invalid.             | `28800`           |
| `tide_report_moon_unavailable_text`   | Text to display when moon data is not available.                | ``               |
| `tide_report_moon_unavailable_color`  | Color for the unavailable text.                                 | `brred`           |

### 🌊 Tide Module (`tide`)

**This module requires `jq` and you must set a Station ID (default Boston).**

To find your nearest station, use the [**NOAA Tides and Currents Map**](https://tidesandcurrents.noaa.gov/map/index.html). Search for your location (e.g., by city or ZIP code), click on a nearby station icon on the map, and copy the `Station ID` number. Ensure that the station has high and low tide predictions available.

| Variable                             | Description                                                     | Default            |
| ------------------------------------ | --------------------------------------------------------------- | ------------------ |
| `tide_report_tide_station_id`        | **Required.** The NOAA station ID (e.g., `8443970` for Boston). | `"8443970"`        |
| `tide_report_tide_units`             | `english` (feet) or `metric` (meters).                          | `english`          |
| `tide_report_tide_refresh_seconds`   | How old data can be before a background refresh is triggered.   | `900`              |
| `tide_report_tide_expire_seconds`    | How old data can be before it's considered invalid.             | `1800`             |
| `tide_report_tide_arrow_rising`      | Symbol to show for an upcoming high tide.                       | `⇞`                |
| `tide_report_tide_arrow_falling`     | Symbol to show for an upcoming low tide.                        | `⇟`                |
| `tide_report_tide_unavailable_text`  | Text to display when tide data is not available.                | `🌊`                |
| `tide_report_tide_unavailable_color` | Color for the unavailable text.                                 | `red`              |
| `tide_tide_color`                    | Prompt item color                                               | `(theme default)`  |
| `tide_tide_bg_color`                 | Prompt item background color                                    | `(theme default)`  |

## Acknowledgements
* [Jorge Bucaran](https://github.com/jorgebucaran) and [Ilan Cosman](https://github.com/IlanCosman) for making [Fisher][] and [Tide][].
* [Moby Dick](https://www.gutenberg.org/ebooks/2701), the sweet air of the ocean breeze, and the gentle lullaby the sea sings before she breaks you on the rocks.
* [NOAA](https://www.noaa.gov) - we'll miss them when they're gone... 🇺🇸😢
* [Igor Chubin](https://github.com/chubin) and all the contributors/sponsors of [wttr.in][].

### Other Handy Fish Plugins I Use:
* jorgebucaran/fisher
* ilancosman/tide@v6
* gazorby/fish-abbreviation-tips
* laughedelic/pisces
* meaningful-ooo/sponge
* nickeb96/puffer-fish
* jorgebucaran/spark.fish
* jorgebucaran/humantime.fish
* jhillyerd/plugin-git
* PatrickF1/fzf.fish


[fish]: https://fishshell.com/
[fisher]: https://github.com/jorgebucaran/fisher
[tide]: https://github.com/IlanCosman/tide
[wttr.in]: https://github.com/chubin/wttr.in
