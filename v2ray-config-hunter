#!/usr/bin/env bash

# ============================================
# Fatahi V2Ray Config Hunter v1.0
# Developer: Abolfazl
# Instagram: @dotAbolfazl
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

DB=""
OUTDIR=""
TOKEN=""
MAX_PER=50
CHANNELS=()

banner() {
    clear
    echo ""
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}|${NC}                                                              ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}  ${GREEN}  ███████╗ █████╗ ████████╗ █████╗ ██╗  ██╗██╗${NC}            ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}  ${GREEN}  ██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██║  ██║██║${NC}            ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}  ${GREEN}  █████╗  ███████║   ██║   ███████║███████║██║${NC}            ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}  ${GREEN}  ██╔══╝  ██╔══██║   ██║   ██╔══██║██╔══██║██║${NC}            ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}  ${GREEN}  ██║     ██║  ██║   ██║   ██║  ██║██║  ██║██║${NC}            ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}  ${GREEN}  ╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝${NC}            ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}                                                              ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}       ${WHITE}${BOLD}V2Ray Config Hunter v1.0${NC}                              ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}                                                              ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}                                          }                              ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}                                                                         ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}                                                              ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}   ${DIM}Extract V2Ray configs from Telegram channels,${NC}             ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}   ${DIM}test ping, show fastest with full config address.${NC}         ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}                                                              ${CYAN}|${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
}

line() { echo -e "${DIM}------------------------------------------------------------${NC}"; }
wait_enter() { echo ""; echo -ne "${DIM}  Press Enter to continue...${NC}"; read -r; }

install_deps() {
    echo -e "${CYAN}[*] Checking tools...${NC}"
    for tool in curl jq sqlite3 python3 ping; do
        if command -v "$tool" &>/dev/null; then
            echo -e "  ${GREEN}OK${NC} $tool"
        else
            echo -e "  ${YELLOW}Installing${NC} $tool"
            sudo apt-get install -y "$tool" -qq 2>/dev/null || true
        fi
    done
    python3 -c "import requests" 2>/dev/null || {
        echo -e "  ${YELLOW}Installing${NC} python3 requests"
        pip3 install requests -q 2>/dev/null || pip install requests -q 2>/dev/null || true
    }
    echo -e "${GREEN}[OK] All good${NC}"
    line
}

step_output_dir() {
    echo ""
    echo -e "${WHITE}${BOLD}  Step 1: Where to save output?${NC}"
    echo -e "  ${DIM}(default: current folder)${NC}"
    echo -ne "  ${YELLOW}Path: ${NC}"
    read -r p
    if [ -z "$p" ]; then OUTDIR="$(pwd)"; else OUTDIR="$p"; fi
    mkdir -p "$OUTDIR" 2>/dev/null || OUTDIR="$(pwd)"
    DB="$OUTDIR/v2ray.db"
    echo -e "  ${GREEN}OK:${NC} $OUTDIR"
    line
}

init_db() {
    sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS channels (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE, config_count INTEGER DEFAULT 0, last_scanned TEXT, status TEXT DEFAULT 'active');"
    sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS configs (id INTEGER PRIMARY KEY AUTOINCREMENT, protocol TEXT, server TEXT DEFAULT '', port INTEGER DEFAULT 0, ping_ms INTEGER DEFAULT 0, status TEXT DEFAULT 'unknown', channel_source TEXT DEFAULT '', raw_config TEXT UNIQUE NOT NULL, found_at TEXT DEFAULT CURRENT_TIMESTAMP, tested_at TEXT);"
}

step_token() {
    echo ""
    echo -e "${WHITE}${BOLD}  Step 2: Telegram Bot Token${NC}"
    echo -e "  ${DIM}Get it from @BotFather on Telegram${NC}"
    echo -ne "  ${YELLOW}Token: ${NC}"
    read -r TOKEN
    if [ -z "$TOKEN" ]; then
        echo -e "  ${RED}Empty! Try again.${NC}"
        step_token
        return
    fi
    echo -ne "  ${DIM}Checking...${NC}"
    local resp
    resp=$(curl -s --connect-timeout 10 "https://api.telegram.org/bot${TOKEN}/getMe" 2>/dev/null)
    if echo "$resp" | jq -e ".ok" 2>/dev/null | grep -q "true"; then
        local name
        name=$(echo "$resp" | jq -r ".result.username")
        echo -e "\r  ${GREEN}OK! Bot: @${name}                ${NC}"
    else
        echo -e "\r  ${RED}Bad token! Try again.           ${NC}"
        step_token
    fi
    line
}

step_channels() {
    echo ""
    echo -e "${WHITE}${BOLD}  Step 3: Telegram Channels${NC}"
    echo -e "  ${DIM}Enter channel usernames one by one.${NC}"
    echo -e "  ${DIM}Example: v2ray_configs  or  @VPN_free${NC}"
    echo -e "  ${DIM}Empty line = done.${NC}"
    echo ""
    local n=0
    while true; do
        echo -ne "  ${YELLOW}Channel #$((n+1)): ${NC}"
        read -r ch
        [ -z "$ch" ] && break
        ch=$(echo "$ch" | sed 's/^@//' | tr -d ' ')
        [ -z "$ch" ] && continue
        CHANNELS+=("$ch")
        sqlite3 "$DB" "INSERT OR IGNORE INTO channels (username) VALUES ('@$ch');"
        echo -e "    ${GREEN}+ @$ch${NC}"
        ((n++)) || true
    done
    if [ $n -eq 0 ]; then
        echo -e "  ${RED}Need at least one channel!${NC}"
        step_channels
        return
    fi
    echo -e "  ${GREEN}OK: $n channel(s)${NC}"
    line
}

step_max() {
    echo ""
    echo -e "${WHITE}${BOLD}  Step 4: How many configs per channel?${NC}"
    echo -e "  ${DIM}Newest messages first. Default: 50${NC}"
    echo -ne "  ${YELLOW}Max [50]: ${NC}"
    read -r m
    if [ -z "$m" ]; then
        MAX_PER=50
    elif [[ "$m" =~ ^[0-9]+$ ]] && [ "$m" -gt 0 ]; then
        MAX_PER=$m
    else
        MAX_PER=50
    fi
    echo -e "  ${GREEN}OK: $MAX_PER per channel${NC}"
    line
}

vpn_on() {
    echo ""
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}|${NC}  ${WHITE}${BOLD}Turn ON your VPN now!${NC}                ${PURPLE}|${NC}"
    echo -e "${PURPLE}|${NC}  ${DIM}Telegram is blocked in Iran.${NC}         ${PURPLE}|${NC}"
    echo -e "${PURPLE}|${NC}  ${DIM}VPN needed to reach channels.${NC}        ${PURPLE}|${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo -ne "  ${GREEN}Press Enter when VPN is ON...${NC}"
    read -r
    echo -ne "  ${DIM}Testing connection...${NC}"
    if curl -s --connect-timeout 15 "https://t.me/s/durov" | grep -qi "durov"; then
        echo -e "\r  ${GREEN}OK! Telegram is reachable.         ${NC}"
    else
        echo -e "\r  ${RED}Cannot reach Telegram! Check VPN.  ${NC}"
        echo -ne "  ${YELLOW}Press Enter to retry...${NC}"
        read -r
        vpn_on
    fi
}

vpn_off() {
    echo ""
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}|${NC}  ${WHITE}${BOLD}Turn OFF your VPN now!${NC}               ${PURPLE}|${NC}"
    echo -e "${PURPLE}|${NC}  ${DIM}Need real ping from your location.${NC}  ${PURPLE}|${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo -ne "  ${GREEN}Press Enter when VPN is OFF...${NC}"
    read -r
}

scrape() {
    echo ""
    echo -e "${WHITE}${BOLD}  Step 5: Extracting configs (newest first)${NC}"
    echo ""
    local pyf="/tmp/_v2scraper_$$.py"
    cat > "$pyf" << 'ENDOFPYTHON'
#!/usr/bin/env python3
import sys, sqlite3, time, os, re

try:
    import requests
except ImportError:
    os.system("pip3 install requests 2>/dev/null")
    import requests

DB = sys.argv[1]
MAXC = int(sys.argv[2])

PROTOCOLS = [
    "vmess://"  ,
    "vless://"  ,
    "trojan://" ,
    "ss://"     ,
    "ssr://"    ,
]

# characters that end a config string
STOP = set()
STOP.add(chr(32))
STOP.add(chr(9))
STOP.add(chr(10))
STOP.add(chr(13))
STOP.add(chr(60))
STOP.add(chr(62))
STOP.add(chr(34))
STOP.add(chr(39))
STOP.add(chr(92))

def grab_configs(html):
    html = html.replace("<br/>", chr(10))
    html = html.replace("<br>", chr(10))
    html = html.replace("</div>", chr(10))
    html = html.replace("</p>", chr(10))
    html = html.replace("&amp;", "&")
    out = []
    seen = set()
    for proto in PROTOCOLS:
        i = 0
        while True:
            i = html.find(proto, i)
            if i < 0:
                break
            j = i + len(proto)
            while j < len(html) and html[j] not in STOP and ord(html[j]) > 31:
                j = j + 1
            c = html[i:j].strip()
            # trim trailing junk
            while c and c[-1] in ",.;:)]}":",
                c = c[:-1]
            # cut at any leftover html tag
            lt = c.find("<")
            if lt > 0:
                c = c[:lt]
            c = c.strip()
            if len(c) > 20 and c not in seen:
                seen.add(c)
                name = proto.replace("://", "")
                out.append((c, name))
            i = j
    return out

def do_channel(ch):
    ch = ch.replace("@", "").strip()
    if not ch:
        return []
    bag = []
    seen = set()
    ua = "Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0"
    hdr = {"User-Agent": ua}
    try:
        url = "https://t.me/s/" + ch
        r = requests.get(url, headers=hdr, timeout=20)
        if r.status_code != 200:
            print("    [!] HTTP " + str(r.status_code) + " - maybe private")
            return []
        page = r.text
        for raw, proto in grab_configs(page):
            if raw not in seen and len(bag) < MAXC:
                seen.add(raw)
                bag.append((raw, proto))
        print("    Page 1: " + str(len(bag)) + " config(s)")
        if len(bag) >= MAXC:
            return bag[:MAXC]
        # find message IDs for pagination
        pat = re.compile(r"data-post=[^/]+/(\d+)")
        nums = [int(x) for x in pat.findall(page)]
        if not nums:
            return bag
        before = min(nums)
        for pg in range(2, 40):
            if len(bag) >= MAXC:
                break
            try:
                u2 = "https://t.me/s/" + ch + "?before=" + str(before)
                r2 = requests.get(u2, headers=hdr, timeout=15)
                if r2.status_code != 200 or len(r2.text) < 500:
                    break
                got = 0
                for raw, proto in grab_configs(r2.text):
                    if raw not in seen and len(bag) < MAXC:
                        seen.add(raw)
                        bag.append((raw, proto))
                        got = got + 1
                print("    Page " + str(pg) + ": +" + str(got) + ", total: " + str(len(bag)))
                nums2 = [int(x) for x in pat.findall(r2.text)]
                if nums2:
                    nb = min(nums2)
                    if nb >= before:
                        break
                    before = nb
                else:
                    break
                time.sleep(1.5)
            except Exception as e:
                print("    [!] Page " + str(pg) + " error: " + str(e))
                break
    except Exception as e:
        print("    [!] Error: " + str(e))
    return bag[:MAXC]

def main():
    conn = sqlite3.connect(DB)
    rows = conn.execute("SELECT username FROM channels WHERE status='active'").fetchall()
    chs = [r[0] for r in rows]
    print("[*] Channels: " + str(len(chs)) + ", max " + str(MAXC) + " per channel")
    print()
    total_new = 0
    for i, ch in enumerate(chs):
        ch = ch.strip()
        if not ch:
            continue
        print("  [" + str(i+1) + "/" + str(len(chs)) + "] " + ch)
        cfgs = do_channel(ch)
        saved = 0
        for raw, proto in cfgs:
            try:
                conn.execute("INSERT OR IGNORE INTO configs (raw_config, protocol, channel_source, status) VALUES (?,?,?,?)", (raw, proto, ch, "unknown"))
                saved = saved + 1
            except:
                pass
        conn.commit()
        try:
            conn.execute("UPDATE channels SET config_count=?, last_scanned=datetime('now') WHERE username=?", (saved, ch))
        except:
            pass
        conn.commit()
        total_new = total_new + saved
        print("    -> " + str(saved) + " saved")
        if i < len(chs) - 1:
            time.sleep(2)
    dbt = conn.execute("SELECT COUNT(*) FROM configs").fetchone()[0]
    conn.close()
    print()
    print("[OK] Done! New: " + str(total_new) + ", Total: " + str(dbt))

if __name__ == "__main__":
    main()
ENDOFPYTHON
    python3 "$pyf" "$DB" "$MAX_PER" 2>&1 | while IFS= read -r x; do
        echo -e "    $x"
    done
    rm -f "$pyf" 2>/dev/null
    local total
    total=$(sqlite3 "$DB" "SELECT COUNT(*) FROM configs;" 2>/dev/null)
    echo ""
    echo -e "  ${GREEN}Total configs in database: ${WHITE}$total${NC}"
    line
}

get_server() {
    local raw="$1" proto="$2" srv=""
    case "$proto" in
        vmess)
            local d=$(echo "$raw" | sed 's|vmess://||' | base64 -d 2>/dev/null)
            [ -n "$d" ] && srv=$(echo "$d" | jq -r '.add // empty' 2>/dev/null)
            ;;
        vless|trojan)
            srv=$(echo "$raw" | sed -E 's|^[a-z]+://[^@]*@||' | sed -E 's|[:/?#].*||')
            ;;
        ss)
            local sp=$(echo "$raw" | sed 's|ss://||' | sed 's|#.*||')
            if echo "$sp" | grep -q '@'; then
                srv=$(echo "$sp" | sed 's|.*@||' | sed 's|:.*||')
            else
                local sd=$(echo "$sp" | base64 -d 2>/dev/null)
                [ -n "$sd" ] && srv=$(echo "$sd" | sed 's|.*@||' | sed 's|:.*||')
            fi ;;
        ssr)
            local sd=$(echo "$raw" | sed 's|ssr://||' | base64 -d 2>/dev/null)
            [ -n "$sd" ] && srv=$(echo "$sd" | cut -d: -f1)
            ;;
    esac
    echo "$srv"
}

ping_test() {
    echo ""
    echo -e "${WHITE}${BOLD}  Step 6: Testing all configs${NC}"
    local total
    total=$(sqlite3 "$DB" "SELECT COUNT(*) FROM configs;" 2>/dev/null)
    echo -e "  ${WHITE}Total: $total configs${NC}"
    [ "$total" -eq 0 ] 2>/dev/null && echo -e "  ${RED}Nothing to test!${NC}" && return
    echo ""
    local done_count=0 alive=0 dead=0
    while IFS='|' read -r id raw proto; do
        ((done_count++)) || true
        local srv=$(get_server "$raw" "$proto")
        if [ -z "$srv" ] || [ "$srv" = "null" ]; then
            sqlite3 "$DB" "UPDATE configs SET status='dead', tested_at=datetime('now') WHERE id=$id;"
            ((dead++)) || true
            continue
        fi
        local pct=$((done_count * 100 / total))
        printf "\r  ${BLUE}[%d/%d] (%d%%)${NC} %-40s" "$done_count" "$total" "$pct" "$srv"
        sqlite3 "$DB" "UPDATE configs SET server='$(echo $srv | sed "s/'/''/g")' WHERE id=$id;"
        # try ICMP ping first
        local ms=$(ping -c 2 -W 3 -q "$srv" 2>/dev/null | grep avg | awk -F/ '{print int($5)}')
        ms=${ms:-0}
        if [ "$ms" -gt 0 ] 2>/dev/null && [ "$ms" -lt 9999 ] 2>/dev/null; then
            sqlite3 "$DB" "UPDATE configs SET ping_ms=$ms, status='alive', tested_at=datetime('now') WHERE id=$id;"
            ((alive++)) || true
        else
            # try TCP connect
            local port=$(echo "$raw" | grep -oE ':[0-9]+' | head -1 | tr -d ':')
            port=${port:-443}
            local t1=$(date +%s%N)
            if timeout 4 bash -c "echo >/dev/tcp/$srv/$port" 2>/dev/null; then
                local t2=$(date +%s%N)
                local tcp_ms=$(( (t2 - t1) / 1000000 ))
                if [ "$tcp_ms" -gt 0 ] 2>/dev/null && [ "$tcp_ms" -lt 9999 ] 2>/dev/null; then
                    sqlite3 "$DB" "UPDATE configs SET ping_ms=$tcp_ms, status='alive', port=$port, tested_at=datetime('now') WHERE id=$id;"
                    ((alive++)) || true
                else
                    sqlite3 "$DB" "UPDATE configs SET status='dead', tested_at=datetime('now') WHERE id=$id;"
                    ((dead++)) || true
                fi
            else
                sqlite3 "$DB" "UPDATE configs SET status='dead', tested_at=datetime('now') WHERE id=$id;"
                ((dead++)) || true
            fi
        fi
    done < <(sqlite3 "$DB" "SELECT id, raw_config, protocol FROM configs;")
    echo ""
    echo ""
    echo -e "  ${GREEN}Done!${NC} Tested: $done_count | ${GREEN}Alive: $alive${NC} | ${RED}Dead: $dead${NC}"
    line
}

top10_table() {
    echo ""
    echo -e "${WHITE}${BOLD}  Top 10 Fastest Configs${NC}"
    echo -e "${CYAN}  Rank  Protocol   Server                          Port   Ping${NC}"
    echo -e "${CYAN}  ----  --------   ------------------------------  -----  ------${NC}"
    local rank=0
    while IFS='|' read -r proto srv port ms; do
        ((rank++)) || true
        local color="${GREEN}"
        [ "$ms" -gt 200 ] 2>/dev/null && color="${YELLOW}"
        [ "$ms" -gt 400 ] 2>/dev/null && color="${RED}"
        printf "  %-4s  %-8s   %-30s  %-5s  ${color}%sms${NC}\n" "#$rank" "$proto" "${srv:0:30}" "$port" "$ms"
    done < <(sqlite3 "$DB" "SELECT protocol, COALESCE(server,'?'), COALESCE(port,0), ping_ms FROM configs WHERE status='alive' AND ping_ms>0 ORDER BY ping_ms ASC LIMIT 10;")
    [ $rank -eq 0 ] && echo -e "  ${RED}No alive configs found.${NC}"
    echo ""
}

top10_full() {
    echo ""
    echo -e "${WHITE}${BOLD}  Top 10 - FULL CONFIG (ready to copy):${NC}"
    echo ""
    local rank=0
    while IFS='|' read -r proto srv ms raw; do
        ((rank++)) || true
        local c="${WHITE}"
        case $rank in 1) c="${GREEN}";; 2) c="${CYAN}";; 3) c="${YELLOW}";; esac
        local pc="${GREEN}"
        [ "$ms" -gt 200 ] 2>/dev/null && pc="${YELLOW}"
        [ "$ms" -gt 400 ] 2>/dev/null && pc="${RED}"
        echo -e "  ${c}#${rank}  ${WHITE}$proto${NC} | $srv | ${pc}${ms}ms${NC}"
        echo ""
        echo "$raw"
        echo ""
        echo -e "${DIM}  ────────────────────────────────────────${NC}"
        echo ""
    done < <(sqlite3 "$DB" "SELECT protocol, COALESCE(server,'?'), ping_ms, raw_config FROM configs WHERE status='alive' AND ping_ms>0 ORDER BY ping_ms ASC LIMIT 10;")
    [ $rank -eq 0 ] && echo -e "  ${RED}No alive configs.${NC}"
}

all_alive() {
    echo ""
    echo -e "${WHITE}${BOLD}  All Alive Configs (sorted by ping):${NC}"
    echo ""
    local n=0
    while IFS='|' read -r proto srv ms raw; do
        ((n++)) || true
        local pc="${GREEN}"
        [ "$ms" -gt 200 ] 2>/dev/null && pc="${YELLOW}"
        [ "$ms" -gt 400 ] 2>/dev/null && pc="${RED}"
        echo -e "  ${CYAN}#${n}${NC} $proto | $srv | ${pc}${ms}ms${NC}"
        echo "$raw"
        echo ""
    done < <(sqlite3 "$DB" "SELECT protocol, COALESCE(server,'?'), ping_ms, raw_config FROM configs WHERE status='alive' AND ping_ms>0 ORDER BY ping_ms ASC;")
    [ $n -eq 0 ] && echo -e "  ${RED}No alive configs.${NC}" || echo -e "  ${GREEN}Total: $n alive configs${NC}"
}

save_files() {
    echo ""
    echo -e "${WHITE}${BOLD}  Saving output files${NC}"
    sqlite3 "$DB" "SELECT raw_config FROM configs WHERE status='alive' AND ping_ms>0 ORDER BY ping_ms ASC LIMIT 10;" > "$OUTDIR/top10_configs.txt"
    sqlite3 "$DB" "SELECT raw_config FROM configs WHERE status='alive' ORDER BY ping_ms ASC;" > "$OUTDIR/all_configs.txt"
    echo -e "  ${GREEN}Saved:${NC} $OUTDIR/top10_configs.txt"
    echo -e "  ${GREEN}Saved:${NC} $OUTDIR/all_configs.txt"
    echo -e "  ${GREEN}  DB:${NC}  $DB"
    echo -e "  ${DIM}Import into v2rayNG / v2rayN / Nekoray / Clash${NC}"
    line
}

stats() {
    echo ""
    echo -e "${WHITE}${BOLD}  Stats${NC}"
    local tc=$(sqlite3 "$DB" "SELECT COUNT(*) FROM channels;")
    local tco=$(sqlite3 "$DB" "SELECT COUNT(*) FROM configs;")
    local ac=$(sqlite3 "$DB" "SELECT COUNT(*) FROM configs WHERE status='alive';")
    local dc=$(sqlite3 "$DB" "SELECT COUNT(*) FROM configs WHERE status='dead';")
    local avg=$(sqlite3 "$DB" "SELECT COALESCE(CAST(AVG(ping_ms) AS INT),0) FROM configs WHERE status='alive' AND ping_ms>0;")
    local best=$(sqlite3 "$DB" "SELECT COALESCE(MIN(ping_ms),0) FROM configs WHERE status='alive' AND ping_ms>0;")
    echo -e "  Channels: ${WHITE}$tc${NC}  |  Configs: ${WHITE}$tco${NC}"
    echo -e "  ${GREEN}Alive: $ac${NC}  |  ${RED}Dead: $dc${NC}"
    echo -e "  Avg ping: ${YELLOW}${avg}ms${NC}  |  Best: ${GREEN}${best}ms${NC}"
    line
}

run_auto() {
    vpn_on
    scrape
    vpn_off
    ping_test
    top10_table
    top10_full
    save_files
    stats
    echo ""
    echo -e "${GREEN}Done! | Abolfazl Fatahi | @_AbolfazlFatahi_${NC}"
}

menu() {
    while true; do
        echo ""
        echo -e "${CYAN}=== Menu ===${NC}"
        echo -e "  ${GREEN}1)${NC} Add more channels"
        echo -e "  ${GREEN}2)${NC} Scan channels ${YELLOW}(VPN ON)${NC}"
        echo -e "  ${GREEN}3)${NC} Ping test ${RED}(VPN OFF)${NC}"
        echo -e "  ${GREEN}4)${NC} Top 10 table"
        echo -e "  ${GREEN}5)${NC} Top 10 full configs"
        echo -e "  ${GREEN}6)${NC} All alive configs"
        echo -e "  ${GREEN}7)${NC} Save output files"
        echo -e "  ${GREEN}8)${NC} Stats"
        echo -e "  ${GREEN}9)${NC} Run all (auto)"
        echo -e "  ${RED}0)${NC} Exit"
        echo -ne "${YELLOW}  > ${NC}"
        read -r c
        case "$c" in
            1) step_channels; wait_enter;;
            2) vpn_on; scrape; wait_enter;;
            3) vpn_off; ping_test; top10_table; wait_enter;;
            4) top10_table; wait_enter;;
            5) top10_full; wait_enter;;
            6) all_alive; wait_enter;;
            7) save_files; wait_enter;;
            8) stats; wait_enter;;
            9) run_auto; wait_enter;;
            0) echo -e "${GREEN}Bye! @_AbolfazlFatahi_${NC}"; exit 0;;
            *) echo -e "${RED}Invalid${NC}";;
        esac
    done
}

# === START ===
banner
install_deps
step_output_dir
init_db
step_token
step_channels
step_max
echo ""
echo -ne "${YELLOW}  Run everything now? [Y/n]: ${NC}"
read -r yn
if [ -z "$yn" ] || echo "$yn" | grep -qi "^y"; then
    run_auto
fi
menu
