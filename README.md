# Tide Report Plugin

A collection of simple, asynchronous, and configurable prompt sections for the [Tide][] Fish prompt.

This plugin provides prompt items that display useful information (like weather, moon phase, and ocean tides) without slowing down your shell.

** WORK IN PROGRESS **

## ✨ Key Features

* **Truly Asynchronous**: Uses Tide's native event system to fetch data in the background and **update the prompt live** when the data arrives.
* **Modular**: Provides independent prompt items. Use only the ones you want.
* **Configurable**: Easily customize the format, units, location, and refresh rates.
* **Helpful**: Provides succinct weather data, moon phase data, or if you really want to lean into the maritime theme, tide data.
* **Growing?**: May expand this to provide other prompt sections such as: sunrise/sundown, weather forecast, or ???

##  Dependencies

* **`jq`**: The `tide` module requires `jq` for parsing JSON data. You can install it with your system's package manager (e.g., `sudo apt install jq`).
* The latest version of [Fish][] (tested with `4.0.2`).
* [Fisher][] plugin manager.
* A [Nerd Font](https://github.com/ryanoasis/nerd-fonts) configured in your terminal.

## 📦 Installation

Install with [Fisher][]:

```fish
fisher install MrBasa/TideReport
```

Or add `MrBasa/TideReport` to `~/.config/fish/fish_plugins` and run `fisher update`. This is the recommended workflow when using a dotconfig manager.
See the [Fisher][] and [Tide][] documentation for more details on installation.

## 🚀 Available Prompt Sections

* `weather`: Displays the current weather from `wttr.in`.
* `moon`: Displays the current moon phase from `wttr.in`.
* `tide`: Displays the next high/low tide from NOAA (US-based).

## 🔧 Usage

Add any of the module items to your Tide prompt. For example:

```fish
set -Ua tide_right_prompt_items weather moon tide
tide reload
```

## ⚙️ Configuration

### Global Settings

This setting applies to all modules in this plugin.

| Variable                             | Description                                      | Default            |
| ------------------------------------ | ------------------------------------------------ | ------------------ |
| `tide_report_service_timeout_millis` | Timeout for all web requests, in milliseconds.   | `3000`             |
| `tide_report_wttr_url`               | URL for [wttr.in][], for self-hosted options.    | `https://wttr.in`  |

### 󰞍 Tide Module (`tide`)

**This module requires you to set a Station ID.**

To find your nearest station, use the [**NOAA Tides and Currents Map**](https://tidesandcurrents.noaa.gov/map/index.html). Search for your location (e.g., by city or ZIP code), click on a nearby station icon on the map, and copy the `Station ID` number.

| Variable                           | Description                                                     | Default      |
| ---------------------------------- | --------------------------------------------------------------- | ------------ |
| `tide_report_tide_station_id`      | **Required.** The NOAA station ID (e.g., `8443970` for Boston). | `"9087044"`  |
| `tide_report_tide_units`           | `english` (feet) or `metric` (meters).                          | `english`    |
| `tide_report_tide_refresh_seconds` | How old data can be before a background refresh is triggered.   | `900`        |
| `tide_report_tide_expire_seconds`  | How old data can be before it's considered invalid.             | `1800`       |
| `tide_report_tide_arrow_rising`    | Symbol to show for an upcoming high tide.                       | `⇞`          |
| `tide_report_tide_arrow_falling`   | Symbol to show for an upcoming low tide.                        | `⇟`          |
| `tide_report_tide_unavailable_text`| Text to display when tide data is not available.                | `🌊...`       |
| `tide_tide_color`                  | Prompt item color                                               | ``           |
| `tide_tide_bg_color`               | Prompt item background color                                    | ``           |
| `tide_tide_icon`                   | Prompt item color                                               | ``           |

### 󰙾 Weather Module (`weather`)

| Variable                              | Description                                                             | Default         |
| ------------------------------------- | ----------------------------------------------------------------------- | --------------- |
| `tide_report_weather_format`          | `wttr.in` format (`1`-`4`). See [wttr.in docs](https://wttr.in/:help).  | `2`             |
| `tide_report_weather_units`           | `u` (USCS), `m` (Metric/Celsius), `M` (Metric/Wind Speed m/s)           | `m`             |
| `tide_report_weather_location`        | Any location `wttr.in` accepts (e.g., `Paris`, `90210`).                | `""` (IP-based) |
| `tide_report_weather_refresh_seconds` | How old data can be before a background refresh is triggered.           | `300`           |
| `tide_report_weather_expire_seconds`  | How old data can be before it's considered invalid.                     | `600`           |
| `tide_report_weather_language`        | Two-letter language code (e.g., `de`, `fr`, `zh-cn`).                   | `en`            |
| `tide_report_weather_unavailable_text`| Text to display when weather data is not available.                     | `...`          |

###  Moon Module (`moon`)

| Variable                           | Description                                                     | Default     |
| ---------------------------------- | --------------------------------------------------------------- | ----------- |
| `tide_report_moon_format`          | `wttr.in` moon format (e.g., `%m` for emoji, `%M` for name).    | `"%m"`      |
| `tide_report_moon_refresh_seconds` | How old data can be before a background refresh is triggered.   | `3600`      |
| `tide_report_moon_expire_seconds`  | How old data can be before it's considered invalid.             | `7200`      |
| `tide_report_moon_unavailable_text`| Text to display when moon data is not available.                | `...`      |

## Acknowledgements
* [Jorge Bucaran](https://github.com/jorgebucaran) and [Ilan Cosman](https://github.com/IlanCosman) for making [Fisher][] and [Tide][].
* [Moby Dick](https://www.gutenberg.org/ebooks/2701), the sweet air of the ocean breeze, and the gentle lullaby the sea sings before she breaks you on the rocks.
* [NOAA](https://www.noaa.gov) - we'll miss them when they're gone...  󰱭
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
