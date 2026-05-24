fx_version 'cerulean'
game 'gta5'

author 'GameMaster'
description 'Advanced FiveM Admin System - Multi-Framework'
version '1.0.0'

shared_scripts {
    'shared/config.lua',
    'shared/utils.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- opzionale, solo se usi oxmysql
    'server/main.lua',
    'server/commands.lua',
    'server/bans.lua',
    'server/permissions.lua',
    'server/economy.lua',
    'server/whitelist.lua',
    'server/logs.lua',
    'server/rank_event.lua',
}

client_scripts {
    'client/main.lua',
    'client/menu.lua',
    'client/nui.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
}

lua54 'yes'
