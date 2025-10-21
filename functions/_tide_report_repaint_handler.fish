# TideReport :: Event Handler
# Listens for update events from the fetchers and triggers a prompt repaint.

function _tide_report_repaint_handler --on-event tide_report_weather_updated --on-event tide_report_moon_updated --on-event tide_report_tide_updated
    commandline -f repaint
end
