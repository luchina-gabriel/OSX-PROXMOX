#!/usr/bin/env bash
#
# apply-wifi-reset-bus.sh
#
# Forca secondary bus reset (hot reset no link) em placas WiFi PCIe usadas em
# passthrough VFIO, e persiste a configuracao via regra udev.
#
# Contexto: em varios chips Intel (AX210 8086:2725 e afins) o FLR completa sem
# erro mas nao devolve o card a um estado carregavel de firmware. Sintoma: a
# placa funciona no primeiro "qm start" depois do boot do host e falha em todos
# os starts seguintes -- o driver do guest nao atacha. O secondary bus reset
# resolve porque faz hot reset no link PCIe.
#
# Uso:  sudo ./apply-wifi-reset-bus.sh [--all-vendors]
#
#   --all-vendors   lista placas de rede sem fio de qualquer fabricante
#                   (por padrao filtra apenas Intel, vendor 0x8086)

set -euo pipefail

PCI_DEVICES=/sys/bus/pci/devices
RULES_DIR=/etc/udev/rules.d
FILTER_VENDOR=0x8086
VENDOR_LABEL="Intel"

[[ "${1:-}" == "--all-vendors" ]] && { FILTER_VENDOR=""; VENDOR_LABEL="qualquer fabricante"; }

# ---------------------------------------------------------------- aparencia --
if [[ -t 1 ]]; then
    B=$'\e[1m'; R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; Z=$'\e[0m'
else
    B=""; R=""; G=""; Y=""; C=""; Z=""
fi

info()  { printf '%s\n' "$*"; }
ok()    { printf '%s\n' "${G}✓${Z} $*"; }
warn()  { printf '%s\n' "${Y}!${Z} $*"; }
err()   { printf '%s\n' "${R}✗${Z} $*" >&2; }
head1() { printf '\n%s\n' "${B}$*${Z}"; }
die()   { err "$*"; exit 1; }

# --------------------------------------------------------- estado / cleanup --
SYSPATH=""
ORIG_METHOD=""
RESTORE_NEEDED=0

cleanup() {
    if (( RESTORE_NEEDED )) && [[ -n "$SYSPATH" && -n "$ORIG_METHOD" ]]; then
        warn "Restaurando reset_method original (${ORIG_METHOD}) apos falha."
        printf '%s\n' "$ORIG_METHOD" > "$SYSPATH/reset_method" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# ------------------------------------------------------------ pre-requisitos --
(( EUID == 0 )) || die "Rode como root (sudo $0)."

for bin in lspci udevadm; do
    command -v "$bin" >/dev/null 2>&1 \
        || die "Comando '$bin' nao encontrado. Instale pciutils / systemd-udev."
done

[[ -d "$PCI_DEVICES" ]] || die "$PCI_DEVICES nao existe. Este script e para Linux."

# ------------------------------------------------------------- enumeracao ----
# Classe PCI 0x0280 = Network controller (wireless). Ethernet e 0x0200.
declare -a SLOTS=() NAMES=() DRIVERS=() METHODS=()

for dev in "$PCI_DEVICES"/*/; do
    slot=$(basename "$dev")
    [[ -r "$dev/vendor" && -r "$dev/class" ]] || continue

    vendor=$(<"$dev/vendor")
    [[ -z "$FILTER_VENDOR" || "$vendor" == "$FILTER_VENDOR" ]] || continue

    class=$(<"$dev/class")
    [[ "${class:0:6}" == "0x0280" ]] || continue

    name=$(lspci -Dnn -s "$slot" 2>/dev/null | cut -d' ' -f2- || true)
    [[ -n "$name" ]] || name="(descricao indisponivel)"

    if [[ -L "$dev/driver" ]]; then
        driver=$(basename "$(readlink -f "$dev/driver")")
    else
        driver="(nenhum)"
    fi

    if [[ -r "$dev/reset_method" ]]; then
        method=$(<"$dev/reset_method")
    else
        method="(indisponivel)"
    fi

    SLOTS+=("$slot"); NAMES+=("$name"); DRIVERS+=("$driver"); METHODS+=("$method")
done

(( ${#SLOTS[@]} )) || die "Nenhuma placa WiFi PCIe de ${VENDOR_LABEL} encontrada.
Se a placa e de outro fabricante, rode com --all-vendors."

# ------------------------------------------------------------------- menu ----
head1 "Placas WiFi PCIe detectadas (${VENDOR_LABEL})"
printf '\n'
printf '  %-3s %-15s %-11s %-14s %s\n' "#" "SLOT" "DRIVER" "RESET_METHOD" "DISPOSITIVO"
printf '  %-3s %-15s %-11s %-14s %s\n' "---" "---------------" "-----------" "--------------" "-----------"
for i in "${!SLOTS[@]}"; do
    marker=""
    [[ "${METHODS[$i]}" == "bus" ]] && marker=" ${G}(ja em bus)${Z}"
    printf '  %-3s %-15s %-11s %-14s %s%s\n' \
        "$((i+1))" "${SLOTS[$i]}" "${DRIVERS[$i]}" "${METHODS[$i]}" "${NAMES[$i]:0:60}" "$marker"
done
printf '\n'

if (( ${#SLOTS[@]} == 1 )); then
    prompt="Selecione a placa [1] (Enter aceita, q sai): "
    default_choice=1
else
    prompt="Selecione a placa [1-${#SLOTS[@]}] (q sai): "
    default_choice=""
fi

choice=""
while true; do
    read -r -p "$prompt" choice || die "Entrada interrompida."
    [[ "$choice" == "q" || "$choice" == "Q" ]] && { info "Cancelado."; exit 0; }
    [[ -z "$choice" && -n "$default_choice" ]] && choice="$default_choice"
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#SLOTS[@]} )); then
        break
    fi
    err "Opcao invalida."
done

IDX=$((choice-1))
SLOT="${SLOTS[$IDX]}"
SYSPATH="$PCI_DEVICES/$SLOT"
NAME="${NAMES[$IDX]}"
CURRENT="${METHODS[$IDX]}"
RULE_FILE="$RULES_DIR/99-pci-reset-bus-${SLOT//[:.]/-}.rules"

head1 "Placa selecionada"
info "  Slot          : $SLOT"
info "  Dispositivo   : $NAME"
info "  Driver atual  : ${DRIVERS[$IDX]}"
info "  reset_method  : $CURRENT"
info "  Regra udev    : $RULE_FILE"

# -------------------------------------------------------- validacoes previas --
[[ -w "$SYSPATH/reset_method" ]] \
    || die "$SYSPATH/reset_method nao existe ou nao e gravavel.
Este kernel nao expoe controle de reset para esse dispositivo."

head1 "Verificacoes"

# Estado atual x persistencia: 'bus' setado na mao nao sobrevive ao reboot.
RULE_EXISTS=0
[[ -f "$RULE_FILE" ]] && RULE_EXISTS=1

if [[ "$CURRENT" == "bus" ]]; then
    if (( RULE_EXISTS )); then
        ok "Ja esta em 'bus' E a regra udev ja existe."
        info "  Conteudo atual de $RULE_FILE:"
        sed 's/^/    /' "$RULE_FILE"
        printf '\n'
        read -r -p "Reescrever a regra e revalidar mesmo assim? [s/N] " again
        [[ "$again" =~ ^[sSyY]$ ]] || { info "Nada a fazer. Saindo."; exit 0; }
    else
        warn "Ja esta em 'bus', mas NAO ha regra udev para este dispositivo."
        warn "Isso indica que o valor foi setado a mao e sera perdido no proximo"
        warn "reboot do host. O script vai criar a regra para tornar permanente."
    fi
else
    info "  reset_method atual: '$CURRENT' -> sera forcado para 'bus'."
fi

# Aviso sobre VMs em execucao: mexer no reset de um device em uso por uma VM
# ligada pode derrubar o dispositivo dentro dela.
if command -v qm >/dev/null 2>&1; then
    running=$(qm list 2>/dev/null | awk 'NR>1 && $3=="running" {print $1}' | tr '\n' ' ' || true)
    if [[ -n "${running// }" ]]; then
        warn "VMs em execucao: ${running}"
        warn "Se alguma usa $SLOT em passthrough, desligue-a antes de continuar."
    fi
fi

printf '\n'
read -r -p "Aplicar o patch em ${SLOT}? [s/N] " confirm
[[ "$confirm" =~ ^[sSyY]$ ]] || { info "Cancelado."; exit 0; }

# A partir daqui mexemos no sistema.
ORIG_METHOD="$CURRENT"
RESTORE_NEEDED=1

# --------------------------------- passo 1: descobrir metodos disponiveis ----
head1 "1/5  Consultando metodos de reset suportados"

AVAILABLE=""
if printf 'default\n' > "$SYSPATH/reset_method" 2>/dev/null; then
    AVAILABLE=$(<"$SYSPATH/reset_method")
    info "  Metodos disponiveis: $AVAILABLE"
else
    warn "Kernel nao aceitou 'default'; pulando a checagem previa."
fi

if [[ -n "$AVAILABLE" ]] && ! grep -qw "bus" <<<"$AVAILABLE"; then
    die "O dispositivo $SLOT nao suporta secondary bus reset.
Metodos disponiveis: $AVAILABLE
Isso normalmente significa que ele nao esta sozinho no root port PCIe.
Um bus reset ali afetaria dispositivos vizinhos, entao o kernel nao oferece."
fi
ok "Secondary bus reset ('bus') e suportado."

# ---------------------------------------- passo 2: escrever a regra udev -----
head1 "2/5  Gravando a regra udev"

if (( RULE_EXISTS )); then
    BACKUP="${RULE_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    cp -a "$RULE_FILE" "$BACKUP"
    info "  Backup do arquivo anterior: $BACKUP"
fi

cat > "$RULE_FILE" <<RULE_EOF
# Gerado por apply-wifi-reset-bus.sh em $(date -Is)
#
# $NAME
#
# O FLR neste dispositivo completa sem erro mas nao o devolve a um estado
# carregavel de firmware entre execucoes da VM. Forca secondary bus reset,
# que faz hot reset no link PCIe.
SUBSYSTEM=="pci", KERNEL=="$SLOT", ATTR{reset_method}="bus"
RULE_EOF

ok "Regra gravada em $RULE_FILE"
sed 's/^/    /' "$RULE_FILE"

# ----------------------------------------------- passo 3: recarregar udev ----
head1 "3/5  Recarregando o udev"

udevadm control --reload
ok "Regras recarregadas."

# ------------------------------ passo 4: validar que a REGRA e quem aplica ---
head1 "4/5  Validando"

# Zera para o default antes do trigger. Se depois do trigger o valor virar
# 'bus', a prova e de que foi a regra que aplicou -- e nao um valor residual.
if printf 'default\n' > "$SYSPATH/reset_method" 2>/dev/null; then
    pre=$(<"$SYSPATH/reset_method")
    info "  Antes do trigger : $pre"
    if [[ "$pre" == "bus" ]]; then
        warn "Valor default ja e 'bus'; a validacao nao consegue isolar o efeito"
        warn "da regra, mas a regra esta gravada corretamente."
    fi
else
    warn "Nao foi possivel zerar para default; validacao sera menos conclusiva."
fi

udevadm trigger --action=add "$SYSPATH"
udevadm settle --timeout=10 || true

FINAL=$(<"$SYSPATH/reset_method")
info "  Depois do trigger: $FINAL"

if [[ "$FINAL" != "bus" ]]; then
    err "A regra nao surtiu efeito. reset_method continua '$FINAL'."
    printf '\n'
    info "Fallback: use um servico systemd, que roda mais tarde no boot e nao"
    info "depende da janela do evento 'add' do udev:"
    cat <<'FALLBACK_EOF'

    cat > /etc/systemd/system/pci-reset-bus.service <<'EOF'
    [Unit]
    Description=Forca secondary bus reset no dispositivo PCI
    After=sysinit.target
    Before=pve-guests.service

    [Service]
    Type=oneshot
    RemainAfterExit=yes
    ExecStart=/bin/sh -c 'echo bus > /sys/bus/pci/devices/SLOT_AQUI/reset_method'

    [Install]
    WantedBy=multi-user.target
    EOF
    systemctl enable pci-reset-bus.service

FALLBACK_EOF
    exit 1
fi

ok "reset_method = bus, aplicado pela regra udev."

# --------------------------------------------------------- passo 5: final ----
RESTORE_NEEDED=0

head1 "5/5  Concluido"
printf '\n'
ok "Patch aplicado em ${B}${SLOT}${Z} (${NAME})"
printf '\n'
info "${Y}Falta o teste definitivo: reinicie o host.${Z}"
info "O valor de reset_method nao persiste sozinho -- ele volta ao default a"
info "cada boot. O que persiste e a regra udev, e so um reboot prova que ela"
info "esta sendo aplicada cedo o bastante."
printf '\n'
info "Depois do reboot, confirme com:"
printf '\n'
info "    ${C}cat /sys/bus/pci/devices/${SLOT}/reset_method${Z}      # esperado: bus"
printf '\n'
info "Se voltar '${AVAILABLE:-flr bus}', o evento 'add' do udev disparou cedo"
info "demais no boot; nesse caso troque pelo servico systemd (o script mostra"
info "o modelo quando a validacao falha)."
printf '\n'
info "Para reverter: ${C}rm ${RULE_FILE} && udevadm control --reload${Z}"
printf '\n'
