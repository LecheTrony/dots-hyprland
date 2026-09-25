<div align="center">
  <h1>dots-hyprland</h1>
  <p><b>Fork for Artix</b> · <b>Fork para Artix</b></p>
  <p>
    <a href="#english">English</a> ·
    <a href="#español">Español</a>
  </p>
  <hr>
</div>

<a name="english"></a>
## English 🌐

**dots-hyprland** is a personal fork of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) adapted and configured for **Artix Linux** (with dinit). It keeps its own working branch on top of the upstream base.

> This project is in **continuous progress**; it is used as a backup and to keep track of the customizations.

### Differences from upstream

- **Display panel**: new monitor configuration panel with draggable preview and click-to-select, plus utility scripts (`monitor_caps.py`, `monitor_configurator.py`) managed from the left sidebar.
- **Fastfetch logo**: "Put in fastfetch" button that installs the anime panel logo at higher resolution (512×512, crisp rendering) and clears the fastfetch image cache so the change shows immediately.
- **Touchpad**: `tap_button_map = "lrm"` with Clickfinger gestures disabled so the touchpad responds to three buttons.
- **Local PATH**: `~/.local/bin` takes priority in the environment (`env.lua`) for local wrappers and flake binaries.
- **Fastfetch dotfiles**: configuration with a 23-line height and a themed separator.
- **Wallpaper selectors (adapted from iNiR)**: three styles — **Grid**, **Coverflow** and **Launcher** — switchable from Settings (Interface → Wallpaper selector) or via IPC/global shortcuts.
- **Coverflow / Launcher**: smooth coverflow carousel (slot layout without 3D rotation, batch-generated thumbnails, keyboard/scroll navigation) and a fullscreen skewed launcher list with folder history and search.
- **Wallpaper transitions (adapted from iNiR)**: animated transition when changing the wallpaper — Crossfade, Fade through, Zoom, Slide, Push, Wipe or **Random** (cycles through all); configurable in Settings → Background → "Wallpaper transition".
- **YT Music player (adapted from iNiR)**: a YouTube Music client in a new "Music" tab of the left sidebar — search, playlists, queue, liked songs, lyrics, account sync and a rich now-playing card. Backed by `yt-dlp` + `mpv` + `socat` + `deno` and the InnerTube engine (python-ytmusicapi) for real YT Music tracks (audio-only); toggle it with `sidebar.ytmusic.enable` in the config.
- **Lutris games**: a "Games" tab in the left sidebar that reads your local Lutris library (pga.db) and lists installed games with cover art, platform/runner and playtime; clicking a game launches it with `lutris lutris:rungame/<slug>` and shows a progress spinner on the row until the game window shows up (there is also a search box, a refresh button and a shortcut to open the Lutris client). Toggle it with `sidebar.lutris.enable`.

### Main branch

- `main` is the working branch with personal changes.
- The unmodified upstream base can be fetched with `git fetch upstream` + rebase.

### Links

- Upstream: [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)

### Credits

- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) — base project / upstream.
- [snowarch/iNiR](https://github.com/snowarch/iNiR) — wallpaper selector adaptation source (coverflow carousel and skewed launcher list), animated wallpaper transitions (crossfade / fade-through / zoom / slide / push / wipe + random), and the YT Music / Innertune player port (sidebar "Music" tab with search, playlists, queue and player widgets).

### License

GPL-3.0 (same as the original project).

---

<a name="español"></a>
## Español 🌐

**dots-hyprland** es un fork personal de [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) adaptado y configurado para **Artix Linux** (con dinit). Mantiene su propia rama de trabajo sobre la base de upstream.

> Este proyecto está en **progreso continuo**; se usa como respaldo y para llevar el registro de los ajustes.

### Diferencias respecto a upstream

- **Panel de pantallas (Display)**: nuevo panel de configuración de monitores con vista previa arrastrable y selección por clic, más scripts de utilidad (`monitor_caps.py`, `monitor_configurator.py`) gestionados desde la barra lateral.
- **Logo en fastfetch**: botón "Put in fastfetch" que instala el logo del panel de anime a mayor resolución (512×512, render nítido) y limpia el caché de imágenes de fastfetch para que el cambio se refleje al instante.
- **Touchpad**: `tap_button_map = "lrm"` y desactivado el gesto de clic hacia atrás (Clickfinger) para que el panel táctil responda a tres botones.
- **PATH local**: `~/.local/bin` tiene prioridad en el entorno (`env.lua`) para envoltorios locales y binarios de flake.
- **Dotfiles de fastfetch**: configuración con altura de 23 líneas y divisor temático.
- **Selectores de fondo (adaptados de iNiR)**: tres estilos — **Grid** (cuadrícula), **Coverflow** (carrusel) y **Launcher** (lista sesgada a pantalla completa) — conmutables desde Ajustes (Interface → Wallpaper selector) o mediante IPC/atajos globales.
- **Coverflow / Launcher**: carrusel fluido (layout de slots sin rotación 3D, miniaturas generadas en lote, navegación con teclado/scroll) y lista launcher a pantalla completa con historial de carpetas y búsqueda.
- **Transiciones de fondo (adaptadas de iNiR)**: al cambiar el wallpaper hay transición animada — Crossfade, Fade through, Zoom, Slide, Push, Wipe o **Random** (alterna todas); configurables en Ajustes → Background → "Wallpaper transition".
- **Reproductor de YT Music (adaptado de iNiR)**: un cliente de YouTube Music en una nueva pestaña "Music" de la barra lateral — búsqueda, playlists, cola, canciones con "Me gusta", letras, sincronización de cuenta y una tarjeta de reproducción enriquecida. Respaldado por `yt-dlp` + `mpv` + `socat` + `deno` y el motor InnerTube (python-ytmusicapi) para reproducir pistas reales de YT Music (solo audio); se activa con `sidebar.ytmusic.enable` en la configuración.
- **Juegos de Lutris**: una pestaña "Games" en la barra lateral izquierda que lee tu biblioteca local de Lutris (pga.db) y lista los juegos instalados con su carátula, plataforma/runner y tiempo de juego; al hacer clic en un juego se lanza con `lutris lutris:rungame/<slug>` y aparece un spinner de progreso en la fila hasta que aparece la ventana del juego (también hay buscador, botón de refrescar y acceso directo al cliente de Lutris). Se activa con `sidebar.lutris.enable`.

### Rama principal

- `main` es la rama de trabajo con los cambios personales.
- La base de upstream sin modificaciones se puede traer con `git fetch upstream` + rebase.

### Enlaces

- Upstream: [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)

### Créditos

- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) — proyecto base / upstream.
- [snowarch/iNiR](https://github.com/snowarch/iNiR) — fuente de la adaptación de los selectores de fondo (carrusel coverflow y lista launcher sesgada), de las transiciones animadas de fondo (crossfade / fade-through / zoom / slide / push / wipe + random) y del port del reproductor de YT Music / Innertune (pestaña "Music" de la barra lateral con búsqueda, playlists, cola y widgets de reproducción).

### Licencia

GPL-3.0 (igual que el proyecto original).