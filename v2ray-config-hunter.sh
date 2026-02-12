#!/bin/bash
# V2Ray Config Hunter v5.0


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

DB_FILE="" CONFIG_FILE="" TOP10_FILE="" LOG_FILE="" OUTPUT_DIR="" BOT_TOKEN=""
MAX_CONFIGS_PER_CHANNEL=50
CHANNELS=()

show_banner() {
    clear
    echo ""
    echo -e "${CYAN}+======================================================================+${NC}"
    echo -e "${CYAN}|${NC}                                                                    ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}  ${GREEN}  ███████╗ █████╗ ████████╗ █████╗ ██╗  ██╗██╗${NC}                  ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}  ${GREEN}  ██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██║  ██║██║${NC}                  ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}  ${GREEN}  █████╗  ███████║   ██║   ███████║███████║██║${NC}                  ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}  ${GREEN}  ██╔══╝  ██╔══██║   ██║   ██╔══██║██╔══██║██║${NC}                  ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}  ${GREEN}  ██║     ██║  ██║   ██║   ██║  ██║██║  ██║██║${NC}                  ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}  ${GREEN}  ╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝${NC}                  ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}                                                                    ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}          ${WHITE}${BOLD}V2Ray Config Hunter v5.0${NC}                                  ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}                                                                    ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}    ${PURPLE}Developer:${NC}  ${CYAN}Abolfazl ${NC}                                  ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}    ${PURPLE}Instagram:${NC} ${YELLOW}@DotAbolfazl${NC}                                ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}                                                                    ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}  ${DIM}Extracts V2Ray configs from Telegram channels,${NC}                   ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}  ${DIM}tests ping, shows fastest with full address.${NC}                     ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}                                                                    ${CYAN}|${NC}"
    echo -e "${CYAN}+======================================================================+${NC}"
    echo ""
}

separator() { echo -e "${DIM}--------------------------------------------------------------${NC}"; }
log_msg() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }
press_enter() { echo ""; echo -ne "${DIM}  Press Enter...${NC}"; read -r; }

check_dependencies() {
    echo -e "${CYAN}[*] Checking dependencies...${NC}"
    local deps=("curl" "jq" "sqlite3" "python3") missing=()
    for dep in "${deps[@]}"; do
        if command -v "$dep" &>/dev/null; then
            echo -e "  ${GREEN}OK${NC} $dep"
        else
            echo -e "  ${RED}MISSING${NC} $dep"
            missing+=("$dep")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        sudo apt-get update -qq 2>/dev/null || true
        for pkg in "${missing[@]}"; do sudo apt-get install -y "$pkg" -qq 2>/dev/null || true; done
    fi
    python3 -c "import requests" 2>/dev/null || pip3 install requests 2>/dev/null || pip install requests 2>/dev/null || true
    echo -e "${GREEN}[OK] Dependencies ready${NC}"
    separator
}

ask_output_dir() {
    echo ""
    echo -e "${WHITE}${BOLD}  Step 1: Where to save output files?${NC}"
    echo -e "  ${DIM}Default: current directory ($(pwd))${NC}"
    echo -ne "  ${YELLOW}Output directory [Enter=current]: ${NC}"
    read -r user_dir
    if [ -z "$user_dir" ]; then OUTPUT_DIR="$(pwd)"; else OUTPUT_DIR="$user_dir"; fi
    [ ! -d "$OUTPUT_DIR" ] && mkdir -p "$OUTPUT_DIR" 2>/dev/null
    [ ! -d "$OUTPUT_DIR" ] && OUTPUT_DIR="$(pwd)"
    DB_FILE="${OUTPUT_DIR}/v2ray_hunter.db"
    CONFIG_FILE="${OUTPUT_DIR}/all_configs.txt"
    TOP10_FILE="${OUTPUT_DIR}/top10_configs.txt"
    LOG_FILE="${OUTPUT_DIR}/hunter.log"
    echo -e "  ${GREEN}[OK] Output: ${WHITE}${OUTPUT_DIR}${NC}"
    separator
}

init_database() {
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS channels (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE NOT NULL, config_count INTEGER DEFAULT 0, last_scanned DATETIME, status TEXT DEFAULT 'active');"
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS configs (id INTEGER PRIMARY KEY AUTOINCREMENT, protocol TEXT NOT NULL, server TEXT DEFAULT '', port INTEGER DEFAULT 0, ping_ms INTEGER DEFAULT 0, status TEXT DEFAULT 'unknown', channel_source TEXT DEFAULT '', raw_config TEXT UNIQUE NOT NULL, found_at DATETIME DEFAULT CURRENT_TIMESTAMP, tested_at DATETIME);"
    echo -e "${GREEN}[OK] Database ready${NC}"
}

get_bot_token() {
    echo ""
    echo -e "${WHITE}${BOLD}  Step 2: Telegram Bot Token${NC}"
    echo -e "  ${DIM}Get from @BotFather on Telegram${NC}"
    echo -ne "  ${YELLOW}Bot token: ${NC}"
    read -r BOT_TOKEN
    [ -z "$BOT_TOKEN" ] && echo -e "  ${RED}Empty token!${NC}" && exit 1
    echo -ne "  ${YELLOW}Validating...${NC}"
    local info=$(curl -s --connect-timeout 10 "https://api.telegram.org/bot${BOT_TOKEN}/getMe" 2>/dev/null)
    if echo "$info" | jq -e ".ok" 2>/dev/null | grep -q "true"; then
        local bn=$(echo "$info" | jq -r ".result.username")
        echo -e "\r  ${GREEN}[OK] Bot @${bn} connected!              ${NC}"
    else
        echo -e "\r  ${RED}[X] Invalid token!                     ${NC}"
        get_bot_token
    fi
}

get_channels_from_user() {
    echo ""
    echo -e "${WHITE}${BOLD}  Step 3: Telegram Channels${NC}"
    echo -e "  ${DIM}Enter channel usernames (e.g. @v2ray_configs or v2ray_free)${NC}"
    echo -e "  ${DIM}Press Enter on empty line when done.${NC}"
    echo ""
    local count=0
    while true; do
        echo -ne "  ${YELLOW}Channel #$((count+1)): ${NC}"
        read -r ch
        [ -z "$ch" ] || [ "$ch" = "done" ] && break
        ch=$(echo "$ch" | sed 's/^@//' | tr -d ' ')
        [ -z "$ch" ] && continue
        CHANNELS+=("$ch")
        sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO channels (username) VALUES ('@$ch');" 2>/dev/null
        echo -e "    ${GREEN}+ @$ch${NC}"
        ((count++)) || true
    done
    if [ $count -eq 0 ]; then
        echo -e "  ${RED}No channels! Need at least one.${NC}"
        get_channels_from_user
    else
        echo -e "  ${GREEN}[OK] $count channel(s) added${NC}"
    fi
    separator
}

ask_max_configs() {
    echo ""
    echo -e "${WHITE}${BOLD}  Step 4: How many configs per channel?${NC}"
    echo -e "  ${DIM}Extracts NEWEST first. Recommended: 20-100. Default: 50${NC}"
    echo -ne "  ${YELLOW}Max per channel [50]: ${NC}"
    read -r mi
    if [ -z "$mi" ]; then MAX_CONFIGS_PER_CHANNEL=50
    elif [[ "$mi" =~ ^[0-9]+$ ]] && [ "$mi" -gt 0 ]; then MAX_CONFIGS_PER_CHANNEL=$mi
    else echo -e "  ${RED}Invalid. Using 50${NC}"; MAX_CONFIGS_PER_CHANNEL=50; fi
    echo -e "  ${GREEN}[OK] Max ${WHITE}${MAX_CONFIGS_PER_CHANNEL}${GREEN} per channel (newest first)${NC}"
    separator
}

ask_vpn_on() {
    echo ""
    echo -e "${PURPLE}+----------------------------------------------------------+${NC}"
    echo -e "${PURPLE}|${NC}  ${WHITE}${BOLD}Please turn ON your VPN!${NC}                                ${PURPLE}|${NC}"
    echo -e "${PURPLE}|${NC}  ${DIM}Telegram is blocked. VPN needed to access channels.${NC}    ${PURPLE}|${NC}"
    echo -e "${PURPLE}|${NC}  ${CYAN}Press Enter after VPN is on...${NC}                          ${PURPLE}|${NC}"
    echo -e "${PURPLE}+----------------------------------------------------------+${NC}"
    echo -ne "${GREEN}  VPN ON? (Enter) ${NC}"
    read -r
    echo -ne "${YELLOW}  Testing Telegram...${NC}"
    if curl -s --connect-timeout 15 "https://t.me/s/durov" | grep -q "durov"; then
        echo -e "\r${GREEN}  [OK] Telegram connected!                    ${NC}"
    else
        echo -e "\r${RED}  [X] Failed! Check VPN.                      ${NC}"
        echo -ne "${YELLOW}  Enter to retry...${NC}"; read -r
        ask_vpn_on
    fi
}

ask_vpn_off() {
    echo ""
    echo -e "${PURPLE}+----------------------------------------------------------+${NC}"
    echo -e "${PURPLE}|${NC}  ${WHITE}${BOLD}Now turn OFF your VPN!${NC}                                  ${PURPLE}|${NC}"
    echo -e "${PURPLE}|${NC}  ${DIM}Need real ping from your location.${NC}                      ${PURPLE}|${NC}"
    echo -e "${PURPLE}|${NC}  ${CYAN}Press Enter after VPN is off...${NC}                         ${PURPLE}|${NC}"
    echo -e "${PURPLE}+----------------------------------------------------------+${NC}"
    echo -ne "${GREEN}  VPN OFF? (Enter) ${NC}"
    read -r
}

scrape_channels() {
    echo ""
    echo -e "${WHITE}${BOLD}  Step 5: Extracting configs (newest first)${NC}"
    echo ""
    local PYFILE="/tmp/v2ray_scraper_$$.py"
    cat > "$PYFILE" << 'PYEOF'
#!/usr/bin/env python3
import sys, sqlite3, time, os, re

try:
    import requests
except ImportError:
    os.system("pip3 install requests")
    import requests

DB_FILE = sys.argv[1]
MAX_PER_CH = int(sys.argv[2])

PROTOS = ["vmess://", "vless://", "trojan://", "ss://", "ssr://"]

def is_stop(c):
    if c in " \t\n\r":
        return True
    if c in "<>\\":
        return True
    if ord(c) < 33:
        return True
    return False

def extract(text):
    text = text.replace("<br/>", " ").replace("<br>", " ")
    text = text.replace("</div>", " ").replace("</p>", " ")
    text = text.replace("&amp;", "&").replace("&#33;", "!")
    found = []
    seen = set()
    for proto in PROTOS:
        start = 0
        while True:
            idx = text.find(proto, start)
            if idx == -1:
                break
            end = idx + len(proto)
            while end < len(text) and not is_stop(text[end]):
                end += 1
            cfg = text[idx:end].strip()
            while cfg and cfg[-1] in ",.;)]":
                cfg = cfg[:-1]
            tp = cfg.find("<")
            if tp > 0:
                cfg = cfg[:tp]
            cfg = cfg.strip()
            if len(cfg) > 20 and cfg not in seen:
                seen.add(cfg)
                pn = proto.replace("://", "")
                found.append((cfg, pn))
            start = end
    return found

def save(conn, raw, proto, ch):
    try:
        conn.execute("INSERT OR IGNORE INTO configs (raw_config, protocol, channel_source, status) VALUES (?,?,?,?)", (raw, proto, ch, "unknown"))
        return True
    except:
        return False

def scrape(username, maxc):
    username = username.replace("@", "").strip()
    results = []
    seen = set()
    hdrs = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0"}
    try:
        url = "https://t.me/s/" + username
        r = requests.get(url, headers=hdrs, timeout=20)
        if r.status_code != 200:
            print("    [!] HTTP {} - channel may be private".format(r.status_code))
            return []
        html = r.text
        cfgs = extract(html)
        for raw, proto in cfgs:
            if raw not in seen and len(results) < maxc:
                seen.add(raw)
                results.append((raw, proto))
        print("    [*] Page 1: {} config(s)".format(len(results)))
        if len(results) >= maxc:
            return results[:maxc]
        ids = re.findall(r'data-post="[^/]+(\d+)"', html)
        if not ids:
            ids = re.findall(r'data-post="[^"]+/(\d+)"', html)
        if ids:
            min_id = min(int(x) for x in ids)
            for pg in range(2, 32):
                if len(results) >= maxc:
                    break
                try:
                    u2 = "https://t.me/s/{}?before={}".format(username, min_id)
                    r2 = requests.get(u2, headers=hdrs, timeout=15)
                    if r2.status_code != 200 or len(r2.text) < 500:
                        break
                    cfgs2 = extract(r2.text)
                    nc = 0
                    for raw, proto in cfgs2:
                        if raw not in seen and len(results) < maxc:
                            seen.add(raw)
                            results.append((raw, proto))
                            nc += 1
                    print("    [*] Page {}: +{}, total: {}".format(pg, nc, len(results)))
                    nids = re.findall(r'data-post="[^"]+/(\d+)"', r2.text)
                    if nids:
                        nm = min(int(x) for x in nids)
                        if nm >= min_id:
                            break
                        min_id = nm
                    else:
                        break
                    time.sleep(1.5)
                except Exception as e:
                    print("    [!] Page {} error: {}".format(pg, e))
                    break
    except Exception as e:
        print("    [!] Error: {}".format(e))
    return results[:maxc]

def main():
    conn = sqlite3.connect(DB_FILE)
    chs = [r[0] for r in conn.execute("SELECT username FROM channels WHERE status='active'").fetchall()]
    print("[*] Scanning {} channel(s), max {} per channel (newest first)".format(len(chs), MAX_PER_CH))
    print()
    total = 0
    for i, ch in enumerate(chs):
        ch = ch.strip()
        if not ch:
            continue
        print("  [{}/{}] Scanning {}...".format(i+1, len(chs), ch))
        cfgs = scrape(ch, MAX_PER_CH)
        cnt = 0
        for raw, proto in cfgs:
            if save(conn, raw, proto, ch):
                cnt += 1
        conn.commit()
        try:
            conn.execute("UPDATE channels SET config_count=?, last_scanned=datetime('now') WHERE username=?", (cnt, ch))
            conn.commit()
        except:
            pass
        total += cnt
        print("    -> {} new config(s) saved".format(cnt))
        if i < len(chs) - 1:
            time.sleep(2)
    dbt = conn.execute("SELECT COUNT(*) FROM configs").fetchone()[0]
    conn.close()
    print()
    print("[OK] Scan complete! New: {}, Total in DB: {}".format(total, dbt))

if __name__ == "__main__":
    main()
PYEOF
    python3 "$PYFILE" "$DB_FILE" "$MAX_CONFIGS_PER_CHANNEL" 2>&1 | while IFS= read -r line; do
        echo -e "    $line"
    done
    rm -f "$PYFILE" 2>/dev/null
    local tc=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM configs;" 2>/dev/null)
    echo -e "  ${GREEN}[OK] Total in DB: ${WHITE}$tc${NC}"
    separator
}

extract_server() {
    local raw="$1" protocol="$2" server=""
    case "$protocol" in
        vmess)
            local d=$(echo "$raw" | sed 's|vmess://||' | base64 -d 2>/dev/null)
            [ -n "$d" ] && server=$(echo "$d" | jq -r '.add // empty' 2>/dev/null)
            ;;
        vless|trojan)
            server=$(echo "$raw" | sed -E 's|^[a-z]+://[^@]*@||' | sed -E 's|[:/?#].*||')
            ;;
        ss)
            local sp=$(echo "$raw" | sed 's|ss://||' | sed 's|#.*||')
            if echo "$sp" | grep -q '@'; then
                server=$(echo "$sp" | sed 's|.*@||' | sed 's|:.*||')
            else
                local sd=$(echo "$sp" | base64 -d 2>/dev/null)
                [ -n "$sd" ] && server=$(echo "$sd" | sed 's|.*@||' | sed 's|:.*||')
            fi ;;
        ssr)
            local sd=$(echo "$raw" | sed 's|ssr://||' | base64 -d 2>/dev/null)
            [ -n "$sd" ] && server=$(echo "$sd" | cut -d':' -f1)
            ;;
    esac
    echo "$server"
}

test_all_configs() {
    echo ""
    echo -e "${WHITE}${BOLD}  Step 6: Ping testing all configs${NC}"
    local total=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM configs;" 2>/dev/null)
    echo -e "  ${WHITE}Total: $total${NC}"
    [ "$total" -eq 0 ] && echo -e "  ${RED}No configs!${NC}" && return
    local tested=0 alive=0 dead=0
    while IFS='|' read -r id raw protocol; do
        ((tested++)) || true
        local server=$(extract_server "$raw" "$protocol")
        if [ -z "$server" ] || [ "$server" = "null" ]; then
            sqlite3 "$DB_FILE" "UPDATE configs SET status='dead', tested_at=datetime('now') WHERE id=$id;" 2>/dev/null
            ((dead++)) || true; continue
        fi
        local pct=$((tested * 100 / total))
        echo -ne "\r  ${BLUE}[$tested/$total] ($pct%)${NC} ${WHITE}$server${NC}                         "
        sqlite3 "$DB_FILE" "UPDATE configs SET server='$(echo $server | sed "s/'/''/g")' WHERE id=$id;" 2>/dev/null
        local pr=$(ping -c 2 -W 3 -q "$server" 2>/dev/null | grep 'avg' | awk -F'/' '{print int($5)}')
        pr=${pr:-0}
        if [ "$pr" -gt 0 ] 2>/dev/null && [ "$pr" -lt 9999 ] 2>/dev/null; then
            sqlite3 "$DB_FILE" "UPDATE configs SET ping_ms=$pr, status='alive', tested_at=datetime('now') WHERE id=$id;" 2>/dev/null
            ((alive++)) || true
        else
            local port=$(echo "$raw" | grep -oE ':[0-9]+' | head -1 | tr -d ':')
            port=${port:-443}
            if timeout 5 bash -c "echo >/dev/tcp/$server/$port" 2>/dev/null; then
                local t1=$(date +%s%N)
                timeout 5 bash -c "echo >/dev/tcp/$server/$port" 2>/dev/null
                local t2=$(date +%s%N)
                local tp=$(( (t2 - t1) / 1000000 ))
                if [ "$tp" -gt 0 ] 2>/dev/null; then
                    sqlite3 "$DB_FILE" "UPDATE configs SET ping_ms=$tp, status='alive', port=$port, tested_at=datetime('now') WHERE id=$id;" 2>/dev/null
                    ((alive++)) || true
                else
                    sqlite3 "$DB_FILE" "UPDATE configs SET status='dead', tested_at=datetime('now') WHERE id=$id;" 2>/dev/null
                    ((dead++)) || true
                fi
            else
                sqlite3 "$DB_FILE" "UPDATE configs SET status='dead', tested_at=datetime('now') WHERE id=$id;" 2>/dev/null
                ((dead++)) || true
            fi
        fi
    done < <(sqlite3 "$DB_FILE" "SELECT id, raw_config, protocol FROM configs;" 2>/dev/null)
    echo ""
    echo -e "  ${GREEN}Tested: $tested | Alive: $alive | Dead: $dead${NC}"
    separator
}

show_top10_table() {
    echo ""
    echo -e "${WHITE}${BOLD}  Top 10 - Lowest Ping${NC}"
    echo -e "${CYAN}  Rank  Protocol   Server                            Port    Ping${NC}"
    echo -e "${CYAN}  ----  --------   --------------------------------  ------  -------${NC}"
    local rank=0 has=0
    while IFS='|' read -r proto srv port pm; do
        has=1; ((rank++)) || true
        local m=""
        case $rank in 1) m="1st";; 2) m="2nd";; 3) m="3rd";; *) m="${rank}th";; esac
        local pc="${GREEN}"
        [ "$pm" -gt 200 ] 2>/dev/null && pc="${YELLOW}"
        [ "$pm" -gt 400 ] 2>/dev/null && pc="${RED}"
        printf "  %-4s  %-8s   %-32s  %-6s  ${pc}%sms${NC}\n" "$m" "$proto" "${srv:0:32}" "$port" "$pm"
    done < <(sqlite3 "$DB_FILE" "SELECT protocol, COALESCE(server,'?'), COALESCE(port,0), ping_ms FROM configs WHERE status='alive' AND ping_ms>0 ORDER BY ping_ms ASC LIMIT 10;" 2>/dev/null)
    [ $has -eq 0 ] && echo -e "  ${RED}No alive configs!${NC}"
}

show_top10_full() {
    echo ""
    echo -e "${WHITE}${BOLD}  Top 10 - FULL CONFIG (copy ready):${NC}"
    echo ""
    local rank=0 has=0
    while IFS='|' read -r proto srv pm raw; do
        has=1; ((rank++)) || true
        local c="${WHITE}"
        case $rank in 1) c="${GREEN}";; 2) c="${CYAN}";; 3) c="${YELLOW}";; esac
        local pc="${GREEN}"
        [ "$pm" -gt 200 ] 2>/dev/null && pc="${YELLOW}"
        [ "$pm" -gt 400 ] 2>/dev/null && pc="${RED}"
        echo -e "  ${c}--- #$rank  $proto | $srv | ${pc}${pm}ms${NC}"
        echo ""
        echo "$raw"
        echo ""
    done < <(sqlite3 "$DB_FILE" "SELECT protocol, COALESCE(server,'?'), ping_ms, raw_config FROM configs WHERE status='alive' AND ping_ms>0 ORDER BY ping_ms ASC LIMIT 10;" 2>/dev/null)
    [ $has -eq 0 ] && echo -e "  ${RED}No alive configs!${NC}"
    separator
}

show_all_alive() {
    echo ""
    echo -e "${WHITE}${BOLD}  All Alive Configs (sorted by ping):${NC}"
    echo ""
    local count=0
    while IFS='|' read -r proto srv pm raw; do
        ((count++)) || true
        local pc="${GREEN}"
        [ "$pm" -gt 200 ] 2>/dev/null && pc="${YELLOW}"
        [ "$pm" -gt 400 ] 2>/dev/null && pc="${RED}"
        echo -e "  ${CYAN}#${count}${NC} ${WHITE}$proto${NC} | ${DIM}$srv${NC} | ${pc}${pm}ms${NC}"
        echo "$raw"
        echo ""
    done < <(sqlite3 "$DB_FILE" "SELECT protocol, COALESCE(server,'?'), ping_ms, raw_config FROM configs WHERE status='alive' AND ping_ms>0 ORDER BY ping_ms ASC;" 2>/dev/null)
    [ $count -eq 0 ] && echo -e "  ${RED}No alive configs!${NC}" || echo -e "  ${GREEN}Total alive: $count${NC}"
    separator
}

export_configs() {
    echo ""
    echo -e "${WHITE}${BOLD}  Saving files${NC}"
    sqlite3 "$DB_FILE" "SELECT raw_config FROM configs WHERE status='alive' AND ping_ms>0 ORDER BY ping_ms ASC LIMIT 10;" > "$TOP10_FILE" 2>/dev/null
    sqlite3 "$DB_FILE" "SELECT raw_config FROM configs WHERE status='alive' ORDER BY ping_ms ASC;" > "$CONFIG_FILE" 2>/dev/null
    echo -e "  ${GREEN}[OK] Top 10: ${WHITE}$TOP10_FILE${NC}"
    echo -e "  ${GREEN}[OK] All:    ${WHITE}$CONFIG_FILE${NC}"
    echo -e "  ${DIM}Import into V2RayNG / V2RayN / Nekoray / Shadowrocket${NC}"
    separator
}

show_stats() {
    echo ""
    echo -e "${WHITE}${BOLD}  Statistics${NC}"
    local tc=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM channels;" 2>/dev/null)
    local tco=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM configs;" 2>/dev/null)
    local ac=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM configs WHERE status='alive';" 2>/dev/null)
    local dc=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM configs WHERE status='dead';" 2>/dev/null)
    local ap=$(sqlite3 "$DB_FILE" "SELECT COALESCE(CAST(AVG(ping_ms) AS INTEGER),0) FROM configs WHERE status='alive' AND ping_ms>0;" 2>/dev/null)
    local mp=$(sqlite3 "$DB_FILE" "SELECT COALESCE(MIN(ping_ms),0) FROM configs WHERE status='alive' AND ping_ms>0;" 2>/dev/null)
    echo -e "  Channels: ${WHITE}$tc${NC}  |  Total: ${WHITE}$tco${NC}  |  ${GREEN}Alive: $ac${NC}  |  ${RED}Dead: $dc${NC}"
    echo -e "  Avg ping: ${YELLOW}${ap}ms${NC}  |  Best: ${GREEN}${mp}ms${NC}"
}

run_automatic() {
    echo -e "${PURPLE}-- Phase 1: Extract (VPN ON) --${NC}"
    ask_vpn_on; scrape_channels
    echo -e "${PURPLE}-- Phase 2: Ping (VPN OFF) --${NC}"
    ask_vpn_off; test_all_configs
    echo -e "${PURPLE}-- Phase 3: Results --${NC}"
    show_top10_table; show_top10_full; export_configs; show_stats
    echo ""
    echo -e "${GREEN}All done! | Abolfazl Fatahi | @_AbolfazlFatahi_${NC}"
}

main_menu() {
    while true; do
        echo ""
        echo -e "${CYAN}+----------------------------------------------------------+${NC}"
        echo -e "${CYAN}|${NC}  ${WHITE}${BOLD}Main Menu${NC}                                              ${CYAN}|${NC}"
        echo -e "${CYAN}+----------------------------------------------------------+${NC}"
        echo -e "${CYAN}|${NC}  ${GREEN}1)${NC} Add more channels                                  ${CYAN}|${NC}"
        echo -e "${CYAN}|${NC}  ${GREEN}2)${NC} Scan channels (${YELLOW}VPN ON${NC})                             ${CYAN}|${NC}"
        echo -e "${CYAN}|${NC}  ${GREEN}3)${NC} Ping test (${RED}VPN OFF${NC})                                 ${CYAN}|${NC}"
        echo -e "${CYAN}|${NC}  ${GREEN}4)${NC} Top 10 table                                      ${CYAN}|${NC}"
        echo -e "${CYAN}|${NC}  ${GREEN}5)${NC} Top 10 full configs (copy)                         ${CYAN}|${NC}"
        echo -e "${CYAN}|${NC}  ${GREEN}6)${NC} ALL alive configs                                  ${CYAN}|${NC}"
        echo -e "${CYAN}|${NC}  ${GREEN}7)${NC} Export/save files                                  ${CYAN}|${NC}"
        echo -e "${CYAN}|${NC}  ${GREEN}8)${NC} Statistics                                         ${CYAN}|${NC}"
        echo -e "${CYAN}|${NC}  ${GREEN}9)${NC} Run all auto                                       ${CYAN}|${NC}"
        echo -e "${CYAN}|${NC}  ${RED}0)${NC} Exit                                                ${CYAN}|${NC}"
        echo -e "${CYAN}+----------------------------------------------------------+${NC}"
        echo -ne "${YELLOW}  [0-9]: ${NC}"
        read -r ch
        case "$ch" in
            1) get_channels_from_user; press_enter;;
            2) ask_vpn_on; scrape_channels; press_enter;;
            3) ask_vpn_off; test_all_configs; show_top10_table; press_enter;;
            4) show_top10_table; press_enter;;
            5) show_top10_full; press_enter;;
            6) show_all_alive; press_enter;;
            7) export_configs; press_enter;;
            8) show_stats; press_enter;;
            9) run_automatic; press_enter;;
            0) echo -e "${GREEN}Bye! | Abolfazl Fatahi | @_AbolfazlFatahi_${NC}"; exit 0;;
            *) echo -e "${RED}Invalid!${NC}";;
        esac
    done
}

main() {
    show_banner
    check_dependencies
    echo -e "${WHITE}${BOLD}  Fatahi V2Ray Config Hunter${NC}"
    echo -e "  ${DIM}Developer: Abolfazl Fatahi | Instagram: @_AbolfazlFatahi_${NC}"
    echo ""
    echo -e "  ${DIM}Steps: 1.Output dir 2.Bot token 3.Channels 4.Max configs${NC}"
    echo -e "  ${DIM}       5.VPN ON->extract 6.VPN OFF->ping 7.Results${NC}"
    separator
    ask_output_dir; init_database; get_bot_token
    get_channels_from_user; ask_max_configs
    echo -ne "${YELLOW}  Run all automatically? [Y/n]: ${NC}"
    read -r ay
    if [ -z "$ay" ] || echo "$ay" | grep -qi "^y"; then run_automatic; fi
    main_menu
}

main "$@"
