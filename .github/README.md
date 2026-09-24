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

### Main branch

- `main` is the working branch with personal changes.
- The unmodified upstream base can be fetched with `git fetch upstream` + rebase.

### Links

- Upstream: [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)

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

### Rama principal

- `main` es la rama de trabajo con los cambios personales.
- La base de upstream sin modificaciones se puede traer con `git fetch upstream` + rebase.

### Enlaces

- Upstream: [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)

### Licencia

GPL-3.0 (igual que el proyecto original).