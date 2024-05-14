D2D = {}

D2D.Debug = true

D2D.DiscordWebhook = "https://discord.com/api/webhooks/1207104549471649792/MlmlkmUOctKlE1bKcDfwkSUY82xJi0-WielhMXPGGStVhyMDsKRw_yVc4VvZxp4SAOBT" -- Generate your webhook here.

D2D.WebhookName = "Server Name" -- Put your servers name here.

D2D.WebhookID = "discord" -- What ID the discord logs should use, by default I use Discord accounts. If the logs wont show discord accounts change to either "steam" or "license" depending on your server.

D2D.FuelTick = "3" -- In this example it takes 3 seconds to take away 1 fuel, so 300 seconds to completley run out of 100 fuel.

D2D.ABVTick = "10" -- In this example it takes 10 seconds to gain 1% of ABV.

D2D.Animations = {
    ["pickup"] = {
        duration = '1.5',
        dict = "anim@move_m@trash",
        anim = "pickup",
        flag = nil,
        model = nil,
        bone = nil,
        pos = nil,
        rot = nil,
    },
    ["fuel"] = {
        duration = '5',
        dict = "timetable@gardener@filling_can",
        anim = "gar_ig_5_filling_can",
        flag = "49",
        model = GetHashKey("w_am_jerrycan"),
        bone = 60309,
        pos = { x = 0.0, y = -0.085, z = 0.185 },
        rot = { x = 45.0, y = 165.0, z = -180.0 },
    },
    ["ingredient"] = {
        duration = '1',
        dict = "anim@narcotics@trash",
        anim = "drop_front",
        flag = nil,
        model = nil,
        bone = nil,
        pos = nil,
        rot = nil,
    }
}

D2D.MoonShine = {
    ["distillery"] = {
        prop = GetHashKey("prop_moonshine"),
        fuel = 'WEAPON_PETROLCAN',
        ingredients = {'barley', 'fruit'}
    },
    ["distillery2"] = {
        prop = GetHashKey("prop_moonshine"),
        fuel = 'WEAPON_PETROLCAN',
        ingredients = {'barley', 'fruit'}
    },
    ["distillery3"] = {
        prop = GetHashKey("prop_moonshine"),
        fuel = 'WEAPON_PETROLCAN',
        ingredients = {'barley', 'fruit'}
    }
}

D2D.Ingredients = {
    ['barley'] = {
        maxABV = 85,
    },
    ['fruit'] = {
        maxABV = 20,
    }
}

RegisterNetEvent('D2D-Moonshine:Notifications')
AddEventHandler('D2D-Moonshine:Notifications', function(msg)
    TriggerEvent("esx:showNotification", msg)
end)

D2D.Translation = {
    ["havesetup"] = "You already have a brewery set up somewhere!",
    ["cantcarry"] = "You cannot carry this.",
    ["cheater"] = "You have been reported to admins for trying to exploit.",
    ["alreadyplacing"] = "You are already trying to place a prop.",
    ["empty"] = "Your fuel is empty, refill it to fuel your still.",
    ["added"] = "Added %s to the still.",
}

function Debug(...)
    if D2D.Debug then
        print(...)
    end
end
