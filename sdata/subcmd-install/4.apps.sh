# This script is meant to be sourced.
# It's not for directly running.
printf "${STY_CYAN}[$0]: 4. Apps opcionales\n${STY_RST}"

# shellcheck shell=bash

# Optional application installer.
#
# Lets the user pick which extra applications to install (games, browsers,
# music players, code editors and programming tools) from a whiptail checklist,
# grouped by category, defined in sdata/dist-arch/apps.conf .
#
# Only implemented for Arch-based distros (which includes Artix). On any other
# distro the step prints a notice and returns without doing anything.
#
# Flags:
#   --skip-apps   Skip this whole step.
#   -f/--force    Do not ask; use the saved selection if present, else install
#                 nothing (same as accepting the "no apps" default).
#
# The chosen selection is remembered in $APPS_STATE_FILE so the next run can
# offer it as the default.

APPS_STATE_FILE="${DOTS_CORE_CONFDIR}/optional-apps.conf"

# Filled by apps_load_catalogue()
declare -a APPS_CATEGORY_KEYS=()
declare -A APPS_CATEGORY_TITLE=()
declare -A APPS_CATEGORY_DESC=()
declare -a APPS_ENTRY_CATEGORY=()
declare -a APPS_ENTRY_PACKAGE=()
declare -a APPS_ENTRY_NAME=()
declare -a APPS_ENTRY_DESC=()
declare -a APPS_PRESET_KEY=()
declare -A APPS_PRESET_TITLE=()
declare -A APPS_PRESET_CATEGORIES=()
declare -a APPS_SELECTED=()
APPS_SELECTION_DIRTY=false

function apps_die(){
  printf "${STY_RED}[$0]: $1${STY_RST}\n"
  return 1
}

function apps_load_catalogue(){
  local catalogue="${SUBCMD_DIR}/../dist-arch/apps.conf"
  if [[ ! -f "${catalogue}" ]]; then
    apps_die "Application catalogue not found: ${catalogue}" || return 1
  fi

  local line kind rest field1 field2 field3 field4
  while IFS= read -r line || [[ -n "${line}" ]]; do
    # Strip comments and blank lines
    line="${line%%#*}"
    line="$(printf '%s' "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [[ -z "${line}" ]] && continue

    kind="${line%%[[:space:]]*}"
    rest="${line#"${kind}"}"
    rest="${rest#"${rest%%[![:space:]]*}"}"

    # Split on "|" and trim each field
    IFS='|' read -r field1 field2 field3 field4 <<< "${rest}"
    field1="$(printf '%s' "${field1}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    field2="$(printf '%s' "${field2}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    field3="$(printf '%s' "${field3}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    field4="$(printf '%s' "${field4}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    case "${kind}" in
      CATEGORY)
        [[ -z "${field1}" || -z "${field2}" ]] && { apps_die "Malformed CATEGORY line." || return 1; }
        APPS_CATEGORY_KEYS+=("${field1}")
        APPS_CATEGORY_TITLE["${field1}"]="${field2}"
        APPS_CATEGORY_DESC["${field1}"]="${field3}"
        ;;
      APP)
        if [[ -z "${field1}" || -z "${field3}" ]]; then
          apps_die "Malformed APP line (needs at least category, name): ${line}" || return 1
        fi
        if [[ -z "${APPS_CATEGORY_TITLE[${field1}]:-}" ]]; then
          apps_die "APP refers to unknown category \"${field1}\": ${line}" || return 1
        fi
        APPS_ENTRY_CATEGORY+=("${field1}")
        APPS_ENTRY_PACKAGE+=("${field2}")
        APPS_ENTRY_NAME+=("${field3}")
        APPS_ENTRY_DESC+=("${field4}")
        ;;
      PRESET)
        [[ -z "${field1}" || -z "${field2}" || -z "${field3}" ]] && { apps_die "Malformed PRESET line." || return 1; }
        APPS_PRESET_KEY+=("${field1}")
        APPS_PRESET_TITLE["${field1}"]="${field2}"
        APPS_PRESET_CATEGORIES["${field1}"]="${field3}"
        ;;
      *)
        apps_die "Unknown directive \"${kind}\" in ${catalogue}" || return 1
        ;;
    esac
  done < "${catalogue}"

  return 0
}

# Echo the whiptail "tag" of an entry, which is "<category>::<package>".
# The name/description are separate so the tag stays stable across runs.
function apps_entry_tags_of_category(){
  local wanted="$1"
  local i
  for i in "${!APPS_ENTRY_CATEGORY[@]}"; do
    if [[ "${APPS_ENTRY_CATEGORY[$i]}" == "${wanted}" ]]; then
      printf '%s::%s\n' "${APPS_ENTRY_CATEGORY[$i]}" "${APPS_ENTRY_PACKAGE[$i]}"
    fi
  done
}

function apps_is_selected(){
  local tag="$1"
  local i
  for i in "${APPS_SELECTED[@]:-}"; do
    [[ "${i}" == "${tag}" ]] && return 0
  done
  return 1
}

function apps_load_saved_selection(){
  APPS_SELECTED=()
  [[ -f "${APPS_STATE_FILE}" ]] || return 0
  local line
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%%#*}"
    line="$(printf '%s' "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [[ -z "${line}" ]] && continue
    APPS_SELECTED+=("${line}")
  done < "${APPS_STATE_FILE}"
}

function apps_save_selection(){
  local tmpfile
  mkdir -p "$(dirname "${APPS_STATE_FILE}")"
  tmpfile="$(mktemp)"
  {
    printf '# Packages selected by ./setup install (step "4. Apps opcionales").\n'
    printf '# Edit by hand to change the default selection next time.\n'
    local tag
    for tag in "${APPS_SELECTED[@]}"; do
      [[ -n "${tag}" ]] && printf '%s\n' "${tag}"
    done
  } > "${tmpfile}"
  mv -f "${tmpfile}" "${APPS_STATE_FILE}"
}

# Present the checklist for one category. Result goes into APPS_SELECTED.
function apps_menu_category(){
  local category="$1"
  local title="${APPS_CATEGORY_TITLE[$category]}"
  local desc="${APPS_CATEGORY_DESC[$category]}"

  local -a args=()
  local i tag name description default_state
  for i in "${!APPS_ENTRY_CATEGORY[@]}"; do
    [[ "${APPS_ENTRY_CATEGORY[$i]}" == "${category}" ]] || continue
    tag="${APPS_ENTRY_CATEGORY[$i]}::${APPS_ENTRY_PACKAGE[$i]}"
    name="${APPS_ENTRY_NAME[$i]}"
    description="${APPS_ENTRY_DESC[$i]}"
    if apps_is_selected "${tag}"; then default_state="ON"; else default_state="OFF"; fi
    args+=("${tag}" "${name} — ${description}" "${default_state}")
  done
  # Nothing in this category
  (( ${#args[@]} == 0 )) && return 0

  local selected
  selected=$(whiptail --title "Apps — ${title}" \
    --checklist "\n${desc}\n\nEspacio = marcar/desmarcar · Tab = botones · Enter = confirmar\n" \
    0 0 0 "${args[@]}" 3>&1 1>&2 2>&3) || return 1

  # whiptail returns quoted tags; strip quotes and split by whitespace
  selected="${selected//\"/}"
  local -a newly_selected=()
  local t
  for t in ${selected}; do
    newly_selected+=("${t}")
  done

  # Rebuild APPS_SELECTED: drop everything from this category, then add picks
  local -a kept=()
  for t in "${APPS_SELECTED[@]}"; do
    [[ "${t}" == "${category}::"* ]] && continue
    kept+=("${t}")
  done
  APPS_SELECTED=("${kept[@]}" "${newly_selected[@]}")

  printf "${STY_GREEN}[$0]: %s — %d app(s) marcada(s).${STY_RST}\n" "${title}" "${#newly_selected[@]}"
  return 0
}

function apps_menu_presets(){
  # Returns 0 if a preset was applied, 1 otherwise.
  (( ${#APPS_PRESET_KEY[@]} == 0 )) && return 1

  local -a args=()
  local tag title categories
  local i
  for i in "${!APPS_PRESET_KEY[@]}"; do
    tag="${APPS_PRESET_KEY[$i]}"
    title="${APPS_PRESET_TITLE[$tag]}"
    categories="${APPS_PRESET_CATEGORIES[$tag]}"
    args+=("${tag}" "${title}")
  done

  local chosen
  chosen=$(whiptail --title "Apps — Presets" \
    --menu "\nSelecciona un atajo para marcar varias categorías de golpe,\n o \"Continuar\" si prefieres elegir categoría por categoría.\n" \
    0 0 0 "continue" "Continuar sin atajo" "${args[@]}" 3>&1 1>&2 2>&3) || return 1

  [[ "${chosen}" == "continue" || -z "${chosen}" ]] && return 1

  local preset="${APPS_PRESET_TITLE[$chosen]:-}"
  printf "${STY_BLUE}[$0]: Aplicando preset \"%s\"...${STY_RST}\n" "${preset}"
  local cat tag2
  local -a cats=()
  local -a preset_tags=()
  local added=0
  IFS=',' read -ra cats <<< "${APPS_PRESET_CATEGORIES[$chosen]}"
  for cat in "${cats[@]}"; do
    cat="$(printf '%s' "${cat}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [[ -z "${cat}" ]] && continue
    # Read into an array (no subshell) so APPS_SELECTED keeps its changes.
    preset_tags=()
    while IFS= read -r tag2; do
      preset_tags+=("${tag2}")
    done < <(apps_entry_tags_of_category "${cat}")
    for tag2 in "${preset_tags[@]}"; do
      [[ -z "${tag2}" ]] && continue
      # Skip entries that have no package of their own
      [[ "${tag2}" == *"::" ]] && continue
      # Accumulate across presets instead of replacing the selection.
      if ! apps_is_selected "${tag2}"; then
        APPS_SELECTED+=("${tag2}")
        added=$((added + 1))
      fi
    done
  done
  printf "${STY_GREEN}[$0]: Se marcaron %d app(s) nuevas con el atajo \"%s\" (total: %d).${STY_RST}\n" \
    "${added}" "${preset}" "${#APPS_SELECTED[@]}"
  return 0
}

function apps_print_summary(){
  if (( ${#APPS_SELECTED[@]} == 0 )); then
    printf "${STY_YELLOW}[$0]: No se instalará ninguna app opcional.${STY_RST}\n"
    return 0
  fi

  printf "\n${STY_BOLD}${STY_CYAN}Se instalarán estas apps:${STY_RST}\n"
  local cat tag i j
  for cat in "${APPS_CATEGORY_KEYS[@]}"; do
    local -a names=()
    for tag in "${APPS_SELECTED[@]}"; do
      [[ "${tag}" == "${cat}::"* ]] || continue
      local pkg="${tag#"${cat}::"}"
      for j in "${!APPS_ENTRY_PACKAGE[@]}"; do
        if [[ "${APPS_ENTRY_CATEGORY[$j]}" == "${cat}" && "${APPS_ENTRY_PACKAGE[$j]}" == "${pkg}" ]]; then
          names+=("${APPS_ENTRY_NAME[$j]} (${pkg})")
          break
        fi
      done
    done
    (( ${#names[@]} == 0 )) && continue
    printf "  ${STY_GREEN}%s${STY_RST}\n" "${APPS_CATEGORY_TITLE[$cat]}"
    printf "    - %s\n" "${names[@]}"
  done
  printf "\n"
}

function apps_install(){
  # Build the unique package list and install it in one go.
  local -a packages=()
  local tag pkg
  for tag in "${APPS_SELECTED[@]}"; do
    # Skip tags with an empty package ("category::")
    [[ "${tag}" == *"::" ]] && continue
    pkg="${tag##*::}"
    [[ -n "${pkg}" ]] && packages+=("${pkg}")
  done
  # de-duplicate, keep order
  local -a unique=()
  local p seen
  for p in "${packages[@]}"; do
    seen=false
    for u in "${unique[@]}"; do
      [[ "${u}" == "${p}" ]] && { seen=true; break; }
    done
    $seen || unique+=("${p}")
  done

  if (( ${#unique[@]} == 0 )); then
    printf "${STY_YELLOW}[$0]: No hay nada que instalar.${STY_RST}\n"
    return 0
  fi

  printf "${STY_CYAN}[$0]: Instalando %d paquete(s) con yay...${STY_RST}\n" "${#unique[@]}"
  if ! command -v yay >/dev/null 2>&1; then
    printf "${STY_RED}[$0]: \"yay\" no encontrado; no se pueden instalar paquetes de la AUR.${STY_RST}\n"
    printf "${STY_YELLOW}Se intentará con pacman (fallará para paquetes solo de AUR).${STY_RST}\n"
    v sudo pacman -S --needed --noconfirm "${unique[@]}"
  else
    v yay -S --needed --noconfirm --sudoloop "${unique[@]}"
  fi
}

# Decide the selection: saved file / interactive whiptail / non-interactive.
# Sets APPS_SELECTION_DIRTY=true when the user went through the menus, so the
# caller knows whether the saved selection should be overwritten.
function apps_prompt(){
  apps_load_saved_selection || true
  APPS_SELECTION_DIRTY=false

  if $ask; then
    if ! command -v whiptail >/dev/null 2>&1; then
      printf "${STY_RED}[$0]: \"whiptail\" no está instalado.${STY_RST}\n"
      printf "${STY_YELLOW}Instálalo (p. ej. \"sudo pacman -S libnewt\") o usa --skip-apps.${STY_RST}\n"
      return 1
    fi

    printf "\n${STY_BOLD}${STY_CYAN}Apps opcionales${STY_RST}\n"
    printf "${STY_CYAN}Este paso te permite instalar aplicaciones extra (juegos, navegadores,\n"
    printf "música, editores de código y herramientas de programación) que no son\n"
    printf "necesarias para que illogical-impulse funcione.${STY_RST}\n"
    pause

    # Optional shortcut menu; loops until the user continues or finishes.
    while apps_menu_presets; do
      if ! whiptail --title "Apps — Presets" --yesno \
        "Se marcaron las apps del atajo.\n\n¿Quieres aplicar otro atajo?" 0 0; then
        break
      fi
    done

    local cat
    for cat in "${APPS_CATEGORY_KEYS[@]}"; do
      apps_menu_category "${cat}" || true
    done
    APPS_SELECTION_DIRTY=true

    apps_print_summary

    if ! whiptail --title "Apps — Confirmar" --yesno \
      "¿Instalar las apps listadas arriba?" 0 0; then
      printf "${STY_YELLOW}[$0]: Instalación de apps cancelada por el usuario.${STY_RST}\n"
      return 0
    fi
  else
    # Non-interactive: use whatever was saved previously.
    if (( ${#APPS_SELECTED[@]} == 0 )); then
      printf "${STY_YELLOW}[$0]: Modo sin confirmación y sin selección guardada; no se instala ninguna app.${STY_RST}\n"
      return 0
    fi
    printf "${STY_BLUE}[$0]: Modo sin confirmación; usando la selección guardada (%d app/s).${STY_RST}\n" "${#APPS_SELECTED[@]}"
  fi

  return 0
}

#####################################################################################
# Entry point
#####################################################################################
if [[ "${SKIP_APPS}" == true ]]; then
  printf "${STY_YELLOW}[$0]: --skip-apps especificado; saltando apps opcionales.${STY_RST}\n"
elif [[ "${OS_GROUP_ID}" != "arch" ]]; then
  printf "${STY_YELLOW}[$0]: El catálogo de apps solo está definido para Arch/Artix; saltando.${STY_RST}\n"
else
  if apps_load_catalogue; then
    if apps_prompt; then
      # Persist the selection only when the user went through the menus;
      # in non-interactive mode we must not wipe what was saved before.
      if [[ "${APPS_SELECTION_DIRTY}" == true ]]; then
        apps_save_selection
      fi
      if (( ${#APPS_SELECTED[@]} > 0 )); then
        apps_install
      else
        printf "${STY_BLUE}[$0]: No se seleccionó ninguna app; nada que instalar.${STY_RST}\n"
      fi
    fi
  fi
fi
