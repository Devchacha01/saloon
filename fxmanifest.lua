fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name 'rsg-saloon-premium'
author 'devchacha'
description 'Premium Saloon Management System for RSGCore'
version '2.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/crafting.lua',
    'client/shop.lua',
    'client/jukebox.lua',
    'client/propplacer.lua',
    'client/consumption.lua',
    'client/drunk.lua',
    'client/billing.lua',
    'client/animations.lua',
    'client/piano.lua',
    'client/phonograph.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/logs.lua',
    'server/main.lua',
    'server/crafting.lua',
    'server/shop.lua',
    'server/storage.lua',
    'server/cashbox.lua',
    'server/placedprops.lua',
    'server/billing.lua',
    'server/employees.lua',
    'server/piano.lua',
    'server/phonograph.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/sounds/*.mp3',
    'html/images/*.png',
    'locales/*.lua'
}

dependencies {
    'rsg-core',
    'ox_lib',
    'oxmysql',
    'ox_target'
}
