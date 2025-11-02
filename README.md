# Tide Report Plugin

A collection of simple, asynchronous, and configurable prompt sections for the [Tide][] Fish prompt.

This plugin provides prompt items that display useful information (weather, moon phase, ocean tides, and GitHub repo stats) without slowing down your shell.

## ✨ Key Features

* **Asynchronous**: Fetches data in the background to keep your prompt fast.
* **Efficient**: Makes a single API call for both weather and moon data.
* **Modular**: Provides independent prompt items. Use only the ones you want.
* **Configurable**: Easily customize formats, units, location, and refresh rates.
* **Helpful**: Provides succinct weather data, moon phase data, GitHub stats, or if you really want to lean into the maritime theme, tide data.

## Examples
![Screenshot](https://github.com/user-attachments/assets/185f983b-7db9-4934-bf0b-202d19315613)
![Screenshot](https://github.com/user-attachments/assets/afa0b8a8-9ff4-47c8-ae64-e20f6093c16c)
![Screenshot](https://github.com/user-attachments/assets/2441a581-2925-44e9-8d13-e98e11b4c17a)

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

Or add `MrBasa/TideReportv1` to `~/.config/fish/fish_plugins` and run `fisher update`. This is the recommended workflow when using a dotconfig manager.
See the [Fisher][] and [Tide][] documentation for more details on installing plugins.

## 🚀 Available Prompt Sections

* `github`: Displays stars, forks, watchers, issues, and PRs for the current `gh` repo.
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

## ⚡ Caching Behavior

To keep your prompt fast, this plugin fetches data in the background and relies on cached data. This is done to prevent slow network requests from blocking your shell.

All file-based caches are stored in `~/.cache/tide-report/`.

### Weather, Moon, and Tide Modules

These modules use an asynchronous, file-based caching system with two timers:
1.  **Refresh (`..._refresh_seconds`)**: This is the "stale" timer. If you load your prompt and the cached data is older than this value, the prompt will **show the stale data** and trigger a fetch in the background. Your prompt is not blocked.
2.  **Expire (`..._expire_seconds`)**: This is the "invalid" timer. If the cached data is older than this value (or doesn't exist), the prompt will **show the unavailable text** (e.g., `🌊`) and trigger a background fetch.

This means it is **expected behavior** to see the "unavailable" text for a few seconds when the cache is empty or has expired.

The `weather` and `moon` modules are highly efficient, sharing a single API call and a single cache file (`~/.cache/tide-report/wttr.json`).

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
| `tide_report_service_timeout_millis` | Timeout for all web requests, in milliseconds.             | `3000`             |
| `tide_report_wttr_url`               | URL for [wttr.in][], for self-hosted options.              | `https://wttr.in`  |
| `tide_report_units`                  | Units for weather and tide: `m` (Metric), `u` (USCS)       | `m`                |
| `tide_time_format`                   | Time format string for Tide Prompt times (e.g. `"%H:%M"`). | From Tide         |

### 🤖 GitHub Module (`github`)

**Requires `gh` CLI to be installed and authenticated.**

The module displays stats for the current repository, with icons you can customize.

| Symbol                                  | Meaning              |
| --------------------------------------- | -------------------- |
| `★` (Stars)                             | Total stargazer count|
| `⑂` (Forks)                             | Total fork count     |
| `👁` (Watchers)                          | Total watcher count  |
| `!` (Issues)                            | Open issue count     |
| `PR` (Pull Requests)                    | Open PR count        |
| `!auth` (Error)                         | `gh` CLI is not authenticated |

| Variable                             | Description                                                     | Default           |
| ------------------------------------ | --------------------------------------------------------------- | ----------------- |
| `tide_github_color`                  | Prompt item color                                               | `(theme default)` |
| `tide_github_bg_color`               | Prompt item background color                                    | `(theme default)` |
| `tide_report_weather_symbol_color`   | Color for symbols in weather ouput                              | `white`           |
| `tide_report_github_icon_stars`      | Icon for stars.                                                 | `★`               |
| `tide_report_github_icon_forks`      | Icon for forks.                                                 | `⑂`               |
| `tide_report_github_icon_watchers`   | Icon for watchers.                                              | `👁`               |
| `tide_report_github_icon_issues`     | Icon for open issues.                                           | `!`               |
| `tide_report_github_icon_prs`        | Icon for open pull requests.                                    | `PR`              |
| `tide_report_github_color_stars`     | Color for stargazers.                                           | `yellow`          |
| `tide_report_github_color_forks`     | Color for forks (defaults to `..._color_stars`).                | `yellow`          |
| `tide_report_github_color_watchers`  | Color for watchers (defaults to `..._color_stars`).             | `yellow`          |
| `tide_report_github_color_issues`    | Color for issues (defaults to `..._color_stars`).               | `yellow`          |
| `tide_report_github_color_prs`       | Color for PRs (defaults to `..._color_stars`).                  | `yellow`          |
| `tide_report_github_refresh_seconds` | GitHub data cache time for a given repository.                  | `30`              |

### ☔ Weather Module (`weather`)

**This module requires `jq` for parsing JSON.**

The weather format is a string with custom specifiers.

| Specifier | Description                                   | Example     |
| :---      | :---                                          | :---        |
| `%t`      | Temperature (with `+` or `-` sign)            | `+10°`      |
| `%C`      | Condition text                                | `Clear`     |
| `%c`      | Condition emoji                               | `☀️`        |
| `%w`      | Wind speed and unit                           | `15km/h`    |
| `%d`      | Wind direction arrow                          | `⬆`         |
| `%h`      | Humidity                                      | `80%`       |
| `%f`      | 'Feels like' temperature                      | `Overcast`  |
| `%u`      | UV Index                                      | `42`        |
| `%S`      | Sunrise time                                  | `06:37`     |
| `%s`      | Sunset time                                   | `19:46`     |

| Variable                                | Description                                                             | Default           |
| --------------------------------------- | ----------------------------------------------------------------------- | ----------------- |
| `tide_weather_color`                    | Prompt item color                                                       | `(theme default)` |
| `tide_weather_bg_color`                 | Prompt item background color                                            | `(theme default)` |
| `tide_report_weather_format`            | Format string (see table above).                                        | `"%t %c"`         |
| `tide_report_weather_location`          | Any location `wttr.in` accepts (e.g., `Paris`, `90210`).                | `""` (IP-based)   |
| `tide_report_weather_refresh_seconds`   | How old data can be before a background refresh is triggered.           | `300`             |
| `tide_report_weather_expire_seconds`    | How old data can be before it's considered invalid.                     | `600`             |
| `tide_report_weather_language`          | Two-letter language code (e.g., `de`, `fr`, `zh-cn`).                   | `en`              |
| `tide_report_weather_unavailable_text`  | Text to display when weather data is not available.                     | ``               |
| `tide_report_weather_unavailable_color` | Color for the unavailable text.                                         | `red`             |

### 🌕 Moon Module (`moon`)

**This module requires `jq` and shares a cache with the `weather` module.** It simply displays the moon phase emoji provided by `wttr.in`.

| Variable                              | Description                                                     | Default           |
| ------------------------------------- | --------------------------------------------------------------- | ----------------- |
| `tide_moon_color`                     | Prompt item color                                               | `(theme default)` |
| `tide_moon_bg_color`                  | Prompt item background color                                    | `(theme default)` |
| `tide_report_moon_refresh_seconds`    | How old data can be before a background refresh is triggered.   | `14400`           |
| `tide_report_moon_expire_seconds`     | How old data can be before it's considered invalid.             | `28800`           |
| `tide_report_moon_unavailable_text`   | Text to display when moon data is not available.                | ``               |
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
| `tide_report_tide_unavailable_text`  | Text to display when tide data is not available.                | `🌊`                |
| `tide_report_tide_unavailable_color` | Color for the unavailable text.                                 | `red`              |
| `tide_report_tide_show_level`        | Set to `"true"` to show the height of the next tide.            | `"true"`           |



## Acknowledgements
* [Jorge Bucaran](https://github.com/jorgebucaran) and [Ilan Cosman](https://github.com/IlanCosman) for making [Fisher][] and [Tide][].
* [Moby Dick](https://www.gutenberg.org/ebooks/2701), the sweet air of the ocean breeze, and the gentle lullaby the sea sings before she breaks you on the rocks.
* [NOAA](https://www.noaa.gov) - we'll miss them when they're gone... 🇺🇸😢
* [Igor Chubin](https://github.com/chubin) and all the contributors/sponsors of [wttr.in][].

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
