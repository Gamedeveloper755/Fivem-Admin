# ⚔ Advanced FiveM Administration System

# Comprehensive, multi-framework administration system for FiveM GTA V servers.

# Compatibility

# ESX (es\_extended)

# QBCore (qb-core)

# Standalone (no framework)

# Auto-detection: The resource automatically detects the framework in use.

# \---

# Installation

# Copy the `fivem-admin` folder to `resources/\\\[custom]/`

# Add to `server.cfg`:

# ```

# Make sure fivem-admin

# ```

# Configure `shared/config.lua`:

# Add your identifier in `Config.Owners`

# Set up the Discord webhook in `Config.Logs`

# Enable/disable whitelist

# Start the server

# \---

# Structure files

# ```

# fivem admin/

# ├── fxmanifest.lua

# ├── shared/

# │ ├── config.lua ← Main Configuration

# │ └── utils.lua ← Shared Functions

# ├── server/

# │ ├── main.lua ← Kick, freeze, bring, goto, revive

# │ ├── commands.lua ← Chat commands (/aban, /akick, etc.)

# │ ├── permissions.lua ← Admin rank management

# │ ├── bans.lua ← Ban system (JSON file)

# │ ├── whitelist.lua ← Whitelist system

# │ ├── economy.lua ← Multi-fw economy management

# │ ├── logs.lua ← Discord logs webhook + join/leave

# │ └── rank\_event.lua ← Event getMyRank

# ├── client/

# │ ├── main.lua ← Client Actions (freeze, noclip, etc.)

# │ ├── menu.lua ← NUI Menu Manager

# │ └── nui.lua ← NUI Assistant

# └── html/ ← In-Game Admin Panel

# ├── index.html

# ├── css/style.css

# └── js/app.js

# ```

# \---

# Chat Commands

# Command Description Minimum Rank

# `/aban \\\[id] \\\[duration] \\\[reason]` Bans a player Admin (2)

# `/akick \\\[id] \\\[reason]` Kicks a player player Mod (1)

# `/warn \\\[id] \\\[reason]` Send a warn (3 = auto-kick) Mod (1)

# `/afreeze \\\[id]` Freeze a player Mod (1)

# `/abring \\\[id]` Bring the player to you Mod (1)

# `/agoto \\\[id]` Go to the player Mod (1)

# `/anoclip` Toggle noclip mode (1)

# `/arevive \\\[id?]` Revive (without id = yourself) Mod (1)

# `/asetrank \\\[id] \\\[1-4]` Set admin rank Owner (4)

# `/agivemoney \\\[id] \\\[amount] \\\[cash/bank]` Give money Admin (2)

# `/asetmoney \\\[id] \\\[amount] \\\[cash/bank]` Set money Admin (2)

# `/awhiteadd \\\[identifier] \\\[name]` Add whitelist Admin (2)

# `/awhiterem \\\[identifier]` Administrator whitelist Remove (2)

# `/stafflist` View online staff All

# Ban duration format

# `perm` or `0` → Permanent

# `7d` → 7 days

# `24h` → 24 hours

# `30m` → 30 minutes

# \---

# NUI Menu

# Press F10 (configurable) to open the graphical admin panel.

# Panel Features:

# 👥 Players — List of online players with ping and ranking, quick actions

# 🔨 Ban — List of active bans, remove bans

# 💰 Economy — Give/Set money (cash \& bank)

# 📋 Whitelist — Add/Remove players

# 🛡 Staff — Real-time online staff administration

# \---

# Administrator Rank

# Ranking Name Permissions

# 1 Moderator Kick, Block, Observe

# 2 Administration + Ban, Economy, Whitelist

# 3 Senior Admin + All Commands

# 4 Owner + Set Administrator Rank

# To manually set an administrator, edit `admins.json`:

# ```json

# {

# "license:abcdef123...": 2,

# "steam:110000112345678": 4

# }

# ```

# \---

# Register Discord

# Configure Webhook in `Config.Logs`:

# ```lua

# Config.Logs.webhookBan = 'https://discord.com/api/webhooks/...'

# Config.Logs.webhookKick = 'https://discord.com/api/webhooks/...'

# Config.Logs.webhookAdmin = 'https://discord.com/api/webhooks/...'

# Config.Logs.webhookJoin = 'https://discord.com/api/webhooks/...'

# Config.Logs.webhookEcon = 'https://discord.com/api/webhooks/...'

# ```

# \---

# Additional dependencies

# `ox\\\_lib` — modern notifications (fallback included)

# `oxmysql` — for database bans (default: JSON file)

