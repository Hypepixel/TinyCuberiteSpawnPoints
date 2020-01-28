gPlugin = nil

gSQLDatabse = sqlite3.open("Plugins/TinySpawnPoints/ReturningPlayers.sqlite");

gShouldRandomlyTeleportOnDeath = true;
gShouldRandomlyTeleportOnJoin = true;
gShouldRandomlyTeleportOnFirstJoin = true;

gMinXCoordinate = -8192;
gMaxXCoordinate = 8192;
gMinYCoordinate = 61;
gMaxYCoordinate = 72;
gMinZCoordinate = -8192;
gMaxZCoordinate = 8192;

function Initialize(aPlugin)
	aPlugin:SetName("TinySpawnPoints")
    aPlugin:SetVersion(1)

    gPlugin = aPlugin

    deathflag = {};

    cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_SPAWNED, OnSpawn)

    cPluginManager.AddHook(cPluginManager.HOOK_KILLED, OnDeath)

    if (gShouldRandomlyTeleportOnFirstJoin) then
        if (gSQLDatabse == nil) then
            LOGWARNING(aPlugin.GetName() .. ": Cannot open ReturningPlayers.sqlite");
            return false;
        end
        if not(gSQLDatabse:execute([[CREATE TABLE players ('id' string NOT NULL UNIQUE, PRIMARY KEY("id"))]])) then
            LOGWARNING(aPlugin.GetName() .. ": Cannot create database tables!")
            return false
        end
    end

	LOG("Initialised " .. aPlugin:GetName() .. " v." .. aPlugin:GetVersion())
	return true
end

function OnDisable()
	LOG(gPlugin:GetName() .. " is now disabled")
end

function RandomTeleport(aPlayer)
    if (aPlayer:IsPlayer()) then
        local playerName = aPlayer:GetName()
        local playerUUID = aPlayer:GetUUID()
        local xCoordinate = math.random(gMinXCoordinate, gMaxXCoordinate);
        local yCoordinate = math.random(gMinYCoordinate, gMaxYCoordinate);
        local zCoordinate = math.random(gMinZCoordinate, gMaxZCoordinate);

        aPlayer:SendAboveActionBarMessage("Spawning " .. playerName .. " (" .. playerUUID .. ") (x = " .. xCoordinate .. ", y = " .. yCoordinate ..", z = " .. zCoordinate .. ")");
        aPlayer:TeleportToCoords(xCoordinate, yCoordinate, zCoordinate);

        LOG("Spawned: " .. playerName .. " (" .. playerUUID .. ") (x = " .. xCoordinate .. ", y = " .. yCoordinate ..", z = " .. zCoordinate .. "))");
    end
end

function OnDeath(aVictim, aTDI, aDeathMessage)
    if (gShouldRandomlyTeleportOnDeath) then
        if (aVictim:IsPlayer()) then
            local UUID = aVictim:GetUUID()
            table.insert(deathflag, UUID);
            LOG(gPlugin:GetName() .. "Player register to death list: ( name = " .. aVictim:GetName() .. ", UUID = " .. UUID);
        end
    end
end

function OnSpawn(aPlayer)
    local onDeath = false;
    local UUID = aPlayer:GetUUID();

    for _,v in pairs(deathflag) do
        if (v == UUID) then
            onDeath = true;
            table.remove(deathflag, _)
          break
        end
      end

    if(gShouldRandomlyTeleportOnFirstJoin) then
        local playerQueryResult = gSQLDatabse:execute([[SELECT count(*) FROM players where id = "]] .. UUID .. [["]]);
        if (playerQueryResult ~= sqlite3.OK) then
            LOG("Inserting and spawning player with ID = " .. UUID);
            RandomTeleport(aPlayer);
            gSQLDatabse:execute([[insert into players (id) values ("]] .. UUID .. [[")]])
        end
    end

    if (onDeath) then
        RandomTeleport(aPlayer)
    else
        if (gShouldRandomlyTeleportOnJoin) then
            RandomTeleport(aPlayer)
        end
    end
end