pragma Singleton

import Quickshell
import qs.modules.common

// Weather lookups for the bar. The ii `Weather` service fetches wttr.in, so
// `Weather.data.wCode` is a World Weather Online code (the same 48-code set
// `Icons.weatherIconMap` is keyed by) - not AccuWeather. The table below
// therefore describes the WWO codes directly and pairs each one with the
// pill tint used by the weather cell/island.
Singleton {
    id: root

    readonly property var codeInfo: ({
        "113": { description: "Clear", background: "#2A6F97" },
        "116": { description: "Partly cloudy", background: "#3C6E91" },
        "119": { description: "Cloudy", background: "#55697A" },
        "122": { description: "Overcast", background: "#5A6472" },
        "143": { description: "Mist", background: "#6B7280" },
        "176": { description: "Patchy rain possible", background: "#3F6C8C" },
        "179": { description: "Patchy snow possible", background: "#6E7F8C" },
        "182": { description: "Patchy sleet possible", background: "#64798C" },
        "185": { description: "Patchy freezing drizzle", background: "#5A7A8C" },
        "200": { description: "Thundery outbreaks possible", background: "#5B4A7A" },
        "227": { description: "Blowing snow", background: "#7C8B99" },
        "230": { description: "Blizzard", background: "#8A99A6" },
        "248": { description: "Fog", background: "#6E7784" },
        "260": { description: "Freezing fog", background: "#6A7A86" },
        "263": { description: "Patchy light drizzle", background: "#46688A" },
        "266": { description: "Light drizzle", background: "#44658A" },
        "281": { description: "Freezing drizzle", background: "#4E6E88" },
        "284": { description: "Heavy freezing drizzle", background: "#45607F" },
        "293": { description: "Patchy light rain", background: "#40658C" },
        "296": { description: "Light rain", background: "#3E6289" },
        "299": { description: "Moderate rain at times", background: "#3A5C86" },
        "302": { description: "Moderate rain", background: "#355682" },
        "305": { description: "Heavy rain at times", background: "#2F4C77" },
        "308": { description: "Heavy rain", background: "#2A4470" },
        "311": { description: "Light freezing rain", background: "#4A6A85" },
        "314": { description: "Heavy freezing rain", background: "#3F5C7A" },
        "317": { description: "Light sleet", background: "#5F7387" },
        "320": { description: "Moderate or heavy sleet", background: "#55697E" },
        "323": { description: "Patchy light snow", background: "#75848F" },
        "326": { description: "Light snow", background: "#7C8B97" },
        "329": { description: "Patchy moderate snow", background: "#84939F" },
        "332": { description: "Moderate snow", background: "#8C9BA6" },
        "335": { description: "Patchy heavy snow", background: "#94A3AE" },
        "338": { description: "Heavy snow", background: "#9CAAB4" },
        "350": { description: "Ice pellets", background: "#6F8090" },
        "353": { description: "Light rain shower", background: "#40668B" },
        "356": { description: "Moderate or heavy rain shower", background: "#3A5D85" },
        "359": { description: "Torrential rain shower", background: "#2F4E78" },
        "362": { description: "Light sleet showers", background: "#5E7386" },
        "365": { description: "Moderate or heavy sleet showers", background: "#54687C" },
        "368": { description: "Light snow showers", background: "#76858F" },
        "371": { description: "Moderate or heavy snow showers", background: "#7E8D98" },
        "374": { description: "Light ice pellet showers", background: "#6D7E8D" },
        "377": { description: "Heavy ice pellet showers", background: "#63748A" },
        "386": { description: "Patchy light rain with thunder", background: "#55477A" },
        "389": { description: "Heavy rain with thunder", background: "#4A3D6E" },
        "392": { description: "Patchy light snow with thunder", background: "#6A6480" },
        "395": { description: "Heavy snow with thunder", background: "#5E5878" },
    })

    function info(code) {
        const key = String(code);
        return root.codeInfo[key] ?? root.codeInfo["113"] ?? null;
    }

    function description(code) {
        return root.info(code)?.description ?? "";
    }

    function background(code) {
        return root.info(code)?.background ?? "transparent";
    }

    function icon(code) {
        return Icons.getWeatherIcon(code) ?? "cloud";
    }
}
