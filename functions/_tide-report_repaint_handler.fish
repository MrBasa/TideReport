# tide-report :: Event Handler
# Listens for update events from the fetchers and triggers a prompt repaint.

function _tide-report_repaint_handler --on-event tide-report_weather_updated --on-event tide-report_moon_updated --on-event tide-report_tide_updated
    commandline -f repaint
end
