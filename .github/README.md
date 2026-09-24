# dots-hyprland (fork para Artix)

Fork personal de [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) adaptado y configurado para **Artix Linux** (runit). Mantiene la rama de trabajo propia sobre la base de upstream.

> Este proyecto está en **progreso continuo**; se usa como respaldo y para llevar el registro de los ajustes.

## Diferencias respecto a upstream

- **Panel de pantallas (Display)**: nuevo panel de configuración de monitores con vista previa arrastrable y selección por clic, más scripts de utilidad (`monitor_caps.py`, `monitor_configurator.py`) gestionados desde la barra lateral.
- **Logo en fastfetch**: botón "Put in fastfetch" que instala el logo del panel de anime a mayor resolución (512×512, render nítido) y limpia el caché de imágenes de fastfetch para que el cambio se refleje al instante.
- **Touchpad**: `tap_button_map = "lrm"` y desactivado el gesto de clic hacia atrás (Clickfinger) para que el panel táctil responda a tres botones.
- **PATH local**: `~/.local/bin` tiene prioridad en el entorno (env.lua) para envoltorios locales y binarios de flake.
- **Dotfiles de fastfetch**: configuración con altura de 23 líneas y divisor temático.

## Rama principal

- `main` es la rama de trabajo con los cambios personales.
- La base de upstream sin modificaciones se puede traer con `git fetch upstream` + rebase.

## Enlaces

- Upstream: [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)

## Licencia

GPL-3.0 (igual que el proyecto original).