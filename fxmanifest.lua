fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'DareToDoyle'
description 'A moonshine creation script for use in ESX FiveM'
version '1.0'

shared_scripts {
    'config.lua',
	'@ox_lib/init.lua',
}

server_scripts {
	'server.lua',
}

client_scripts {
	'client.lua',
	
}
escrow_ignore {
  'config.lua', 
  'client.lua', 
  'server.lua', 
}

data_file 'DLC_ITYP_REQUEST' 'stream/d2d_moonshine.ytyp'
