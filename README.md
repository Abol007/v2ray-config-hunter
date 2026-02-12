#  V2Ray Config Hunter v5.0 🦅

A powerful Bash script to hunt, extract, and test V2Ray configs (VMess, VLESS, Trojan, SS, SSR) directly from Telegram channels.

## ✨ Features
- 📥 Extract configs from multiple Telegram channels automatically.
- 📂 Saves configs in a local SQLite database (`v2ray.db`).
- ⚡️ **Ping Test:** Real-time ping test (ICMP & TCP Connection) to find active servers.
- 📊 **Sorting:** Shows top 10 fastest configs.
- 🧹 **Clean Output:** Generates text files ready to import into v2rayNG/v2rayN.
- 🛡️ **No Hardcoded Tokens:** Asks for your Bot Token securely.

## 🚀 Installation & Usage

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Abol007/v2ray-config-hunter.git
   cd v2ray-config-hunter
Make the script executable:

Bash

chmod +x hunter.sh
Run it:

Bash

./hunter.sh


⚙️ Requirements
The script automatically checks and installs dependencies, but you need:

curl, jq, sqlite3, python3, pip, ping

⚠️ Important Note
VPN Requirement: You need a VPN ON to fetch configs from Telegram, and VPN OFF to test their real ping. The script will guide you.

Made with ❤️ by **Ig:** @_AbolfazlFatahi_
