**Findings (ordered by severity)**

1. High: Tide item has a hard runtime dependency on a helper defined in the weather item, so tide can fail when weather is not loaded.  
    [functions/_tide_item_tide.fish (line 25)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#) calls __tide_report_gnu_date_cmd, but it is defined in [functions/_tide_item_weather.fish (line 169)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#). I reproduced: Unknown command: __tide_report_gnu_date_cmd.
    
2. High: wttr provider has hidden coupling to weather helper functions, breaking moon-only/wttr paths.  
    [functions/_tide_report_provider_weather_wttr.fish (line 26)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#) and [functions/_tide_report_provider_weather_wttr.fish (line 29)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#) call __tide_report_time_string_to_unix from [functions/_tide_item_weather.fish (line 153)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#). I reproduced: Unknown command: __tide_report_time_string_to_unix.
    
3. Medium: Prompt-path sync cost is non-trivial, especially GitHub item.  
    GitHub runs multiple git commands every redraw at [functions/_tide_item_github.fish (line 8)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#), [functions/_tide_item_github.fish (line 13)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#), [functions/_tide_item_github.fish (line 37)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#), plus cache checks/jq. My warm-cache local benchmark was ~10.9ms per _tide_item_github call and ~39ms for all 4 items combined per redraw.
    
4. Medium: Locking strategy uses universal-variable writes on the prompt path.  
    set -U lock writes occur in [functions/_tide_report_handle_async_weather.fish (line 38)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#), [functions/_tide_report_handle_async_moon.fish (line 38)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#), [functions/_tide_item_tide.fish (line 62)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#), [functions/_tide_item_github.fish (line 87)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#), [functions/_tide_item_github.fish (line 102)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#). This is synchronous state I/O at render time and adds contention across shells.
    
5. Medium: Maintainability drift risk from duplicated defaults and monolithic install logic.  
    Defaults are duplicated in [functions/_tide_report_do_install.fish (line 39)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#), [test/helpers/setup.fish (line 27)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#), and partly in [conf.d/tide_report.fish (line 4)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#). Install/wizard/prompt mutation/preview all live in one 573-line file: [functions/_tide_report_do_install.fish](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#).
    
6. Medium: Test suite has blind spots that currently hide real regressions.  
    Always-pass test in [test/integration/render_vs_full_flow.fish (line 21)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#) and [test/integration/render_vs_full_flow.fish (line 22)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#). Coupling bugs are masked by sourcing weather before tide/provider tests in [test/unit/tide.fish (line 8)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#), [test/unit/tide/parse_tide_branches.fish (line 2)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#), [test/unit/weather/provider_wttr.fish (line 2)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#).
    
7. Low: Weather render does repeated expensive setup per redraw.  
    Large symbol regex is rebuilt each call at [functions/_tide_item_weather.fish (line 54)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#)-[functions/_tide_item_weather.fish (line 75)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#), and date-command detection is repeated at [functions/_tide_item_weather.fish (line 158)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#), [functions/_tide_item_weather.fish (line 183)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#), [functions/_tide_item_weather.fish (line 204)](https://file+.vscode-resource.vscode-cdn.net/home/mrbasa/.cursor/extensions/openai.chatgpt-26.304.20706-linux-x64/webview/#).
    

**Overall evaluation**

- Maintainability: Fair. Architecture intent is good (async + stale-first), but hidden inter-file coupling, duplicated defaults, and a large install/wizard file make refactors risky.
- Performance (prompt delivery): Acceptable-to-risky depending on enabled modules. Warm-cache redraw cost is likely noticeable for full module set, with GitHub path being the main synchronous contributor.

**Recommended remediation steps**

1. Extract shared time helpers (__tide_report_gnu_date_cmd, __tide_report_time_string_to_unix, unix formatting) into a dedicated helper file and source it from tide/weather/providers.
2. Remove provider dependency on item files; providers should depend only on provider/helper modules.
3. Replace set -U lock variables with cache-directory lock files (mkdir lockdir + mtime TTL) to avoid universal-variable I/O in prompt path.
4. Add lightweight session cache for GitHub repo metadata (repo slug, branch, cache paths) keyed by $PWD to avoid repeated git calls every render.
5. Precompute weather symbol regex and date flavor once per session.
6. Split install logic into defaults, wizard, prompt mutation, and preview files; keep _tide_report_do_install as orchestration only.
7. Create one canonical defaults map and reuse it for conf/install/test setup to eliminate drift.
8. Fix weak tests (especially always-pass integration test) and add explicit “module independence” tests: tide without weather, moon+wttr without weather item.
9. Add non-network microbench tests with warm caches and target budgets (for example full prompt path under a chosen ms threshold on CI baseline).
10. Keep network tests optional, but gate correctness on deterministic fixtures and isolation tests.

**Validation gap**

- I could not run the full fishtape suite in this sandbox because fishtape is not installed and fish universal-variable writes are restricted here. I did run syntax checks and direct function reproductions for the two high-severity coupling failures.