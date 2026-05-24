--[[ ============================================================
     ADVANCED ADMIN SYSTEM - CONFIG
     Compatibile con: ESX | QBCore | Standalone
============================================================ ]]

Config = {}

-- ============================================================
-- FRAMEWORK DETECTION (auto o manuale)
-- 'auto' | 'esx' | 'qbcore' | 'standalone'
-- ============================================================
Config.Framework = 'auto'

-- ============================================================
-- PERMESSI ADMIN
-- Livelli: 1 = Mod, 2 = Admin, 3 = Senior Admin, 4 = Owner
-- ============================================================
Config.Ranks = {
    [1] = { name = 'Moderatore',    color = '#3B82F6', canBan = false, canKick = true,  canFreeze = true,  canSpectate = true  },
    [2] = { name = 'Admin',         color = '#10B981', canBan = true,  canKick = true,  canFreeze = true,  canSpectate = true  },
    [3] = { name = 'Senior Admin',  color = '#F59E0B', canBan = true,  canKick = true,  canFreeze = true,  canSpectate = true  },
    [4] = { name = 'Owner',         color = '#EF4444', canBan = true,  canKick = true,  canFreeze = true,  canSpectate = true  },
}

-- Identifiers degli owner (steam, license, discord)
Config.Owners = {
    'steam:110000112345678',
    'license:abcdef1234567890abcdef1234567890abcdef12',
}

-- ============================================================
-- BAN SYSTEM
-- ============================================================
Config.BanSettings = {
    useDatabase    = false,        -- true = salva su DB (richiede oxmysql), false = file JSON
    banFile        = 'bans.json',  -- percorso relativo alla risorsa
    checkOnJoin    = true,
    checkHWID      = true,
    kickMessage    = '[ADMIN SYSTEM] Sei stato bannato dal server.\nMotivo: %s\nScadenza: %s\nAppella su: discord.gg/tuoserver',
}

-- ============================================================
-- WHITELIST
-- ============================================================
Config.Whitelist = {
    enabled     = false,
    kickMessage = '[ADMIN SYSTEM] Non sei in whitelist. Fai richiesta su discord.gg/tuoserver',
}

-- ============================================================
-- LOGS (Discord Webhook)
-- ============================================================
Config.Logs = {
    enabled        = true,
    webhookBan     = '',   -- inserisci webhook Discord
    webhookKick    = '',
    webhookAdmin   = '',
    webhookJoin    = '',
    webhookEcon    = '',
    serverName     = 'Il Mio Server FiveM',
    serverIcon     = '',   -- URL icona server
}

-- ============================================================
-- ECONOMY (standalone, usato solo se framework = standalone)
-- ============================================================
Config.Economy = {
    startingMoney  = 500,
    startingBank   = 2500,
    currencySymbol = '$',
}

-- ============================================================
-- MENU NUI
-- ============================================================
Config.Menu = {
    openKey     = 'F10',   -- tasto per aprire il menu admin
    adminChat   = true,    -- chat separata per admin
    adminChatPrefix = '[ADMIN]',
}

-- ============================================================
-- COMANDI RAPIDI (in-game)
-- ============================================================
Config.Commands = {
    ban        = 'aban',
    kick       = 'akick',
    warn       = 'awarn',
    freeze     = 'afreeze',
    spectate   = 'aspectate',
    bring      = 'abring',
    goto_      = 'agoto',
    noclip     = 'anoclip',
    revive     = 'arevive',
    setrank    = 'asetrank',
    givemoney  = 'agivemoney',
    setmoney   = 'asetmoney',
    addwhite   = 'awhiteadd',
    remwhite   = 'awhiterem',
    stafflist  = 'stafflist',
}
