#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>
#include <reapi>

#define PLUGIN "[MG] CTF Mod"
#define VERSION "1.0"
#define AUTH "Vieni"

#define FLAG_BODY_BASE 0
#define FLAG_BODY_RED 1
#define FLAG_BODY_BLUE 2

#define FLAG_SEQ_DROPPED 0
#define FLAG_SEQ_STAND 1
#define FLAG_SEQ_BASE 2

#define FLAG_STATUS_DROPPED 0
#define FLAG_STATUS_STAND 1
#define FLAG_STATUS_BASE 2

#define ENTNAME_FLAGBASE "flag_base"
#define ENTNAME_TRFLAG "tr_flag"
#define ENTNAME_CTFLAG "ct_flag"

#define EV_INT_flagstatus EV_INT_iuser1

#define EV_VEC_basicorigin EV_VEC_vuser1

#define FLAG_MODEL "models/mastergaming/misc/flag0.mdl"

new const Float:FLAG_MIN_STAND_BOX[3] = {-2.0, -2.0, 0.0}
new const Float:FLAG_MAX_STAND_BOX[3] = {2.0, 2.0, 16.0}
new const Float:FLAG_MIN_DROPPED_BOX[3] = {-20.0, -20.0, 0.0}
new const Float:FLAG_MAX_DROPPED_BOX[3] = {20.0, 20.0, 20.0}

new const Float:FLAG_SPAWN_VELOCITY[3] = {0.0, 0.0, -500.0}
new const Float:FLAG_DROP_VELOCITY[3] = {0.0, 0.0, 50.0}

new const gFlagSounds[][] = 
{
    "sound/mastergaming/effects/en_bfl_dropped0.mp3",
    "sound/mastergaming/effects/en_bfl_returned0.mp3",
    "sound/mastergaming/effects/en_bfl_taken0.mp3",
    "sound/mastergaming/effects/en_bt_scores0.mp3",
    "sound/mastergaming/effects/en_rfl_dropped0.mp3",
    "sound/mastergaming/effects/en_rfl_returned0.mp3",
    "sound/mastergaming/effects/en_rfl_taken0.mp3",
    "sound/mastergaming/effects/en_rt_scores0.mp3"
}

new gCtScore, gTrScore

new gUserFlag[33]

new gMaxPlayers

new gSyncHudStatus

public plugin_init()
{
    RegisterHamPlayer(Ham_Killed, "fwHamPlayerKilledPost", 1)

    register_touch(ENTNAME_TRFLAG, "player", "flag_touch_tr")
    register_touch(ENTNAME_CTFLAG, "player", "flag_touch_ct")

    gMaxPlayers = get_maxplayers()

    gSyncHudStatus = CreateHudSyncObj()

    loadLocations()
}

public plugin_precache()
{
    precache_model(FLAG_MODEL)

    for(new i; i < sizeof(gFlagSounds); i++)
        precache_generic(gFlagSounds[i])
}

public msgTeamScore(msg_id, msg_dest, id)
{
    new lTeamName[15]

    get_msg_arg_string(1, lTeamName, charsmax(lTeamName))

    client_print(0, print_console, "%d | %d", get_msg_arg_int(1), get_msg_arg_int(2))
    client_print(0, print_console, "%s | %d", lTeamName, get_msg_arg_int(2))

    if(equal(lTeamName, "TERRORIST"))
    {
        set_msg_arg_int(2, get_msg_argtype(2), gTrScore)
    }
    else
    {
        set_msg_arg_int(2, get_msg_argtype(2), gCtScore)
    }
}

public flag_touch_ct(flagId, toucherId)
{
    if(!is_user_alive(toucherId))
        return
    
    static lFlagStatus
    lFlagStatus = entity_get_int(flagId, EV_INT_flagstatus)
        
    if(CsTeams:get_user_team(toucherId) == CS_TEAM_CT)
    {
        if(lFlagStatus == FLAG_STATUS_STAND && is_valid_ent(gUserFlag[toucherId]) && entity_get_int(gUserFlag[toucherId], EV_INT_flagstatus) == FLAG_STATUS_BASE)
        {
            scoreFlag(gUserFlag[toucherId], toucherId, "CT")
            return
        }

        if(lFlagStatus != FLAG_STATUS_DROPPED)
            return
        
        returnFlag(flagId, toucherId)
        return
    }

    if(lFlagStatus == FLAG_STATUS_BASE)
        return

    takeFlag(flagId, toucherId)
}

public flag_touch_tr(flagId, toucherId)
{
    if(!is_user_alive(toucherId))
        return
    
    static lFlagStatus
    lFlagStatus = entity_get_int(flagId, EV_INT_flagstatus)
        
    if(CsTeams:get_user_team(toucherId) == CS_TEAM_T)
    {
        if(lFlagStatus == FLAG_STATUS_STAND && is_valid_ent(gUserFlag[toucherId]) && entity_get_int(gUserFlag[toucherId], EV_INT_flagstatus) == FLAG_STATUS_BASE)
        {
            scoreFlag(gUserFlag[toucherId], toucherId, "TERRORIST")
            return
        }

        if(lFlagStatus != FLAG_STATUS_DROPPED)
            return
        
        returnFlag(flagId, toucherId)
        return
    }

    if(lFlagStatus == FLAG_STATUS_BASE)
        return

    takeFlag(flagId, toucherId)
}

public fwHamPlayerKilledPost(victim, attacker, shouldgib)
{
    if(!is_valid_ent(gUserFlag[victim]))
        return
    
    if(entity_get_edict(gUserFlag[victim], EV_ENT_owner) != victim)
    {
        log_amx("[PLAYERKILLED] The flag's owner ain't the player while player has the flag by variable! (%d | %d)", victim, gUserFlag[victim])
        return
    }

    dropFlag(gUserFlag[victim], victim)
}

public client_disconnected(id)
{
    dropFlag(gUserFlag[id], id)
}

scoreFlag(flagId, id, const lMessage[])
{
    if(!is_valid_ent(flagId))
        return
    
    if(equal(lMessage, "CT"))
    {
        gCtScore++

        for(new i = 1; i <= gMaxPlayers; i++)
        {
            if(!is_user_connected(id))
                continue

            client_cmd(i, "mp3 ^"play^" ^"%s^"", gFlagSounds[3])
        }

        rg_update_teamscores(gCtScore, gTrScore, false)

        returnFlag(flagId, id, 1)

        return
    }

    if(equal(lMessage, "TERRORIST"))
    {
        gTrScore++

        for(new i = 1; i <= gMaxPlayers; i++)
        {
            if(!is_user_connected(id))
                continue

            client_cmd(i, "mp3 ^"play^" ^"%s^"", gFlagSounds[7])
        }

        rg_update_teamscores(gCtScore, gTrScore, false)

        returnFlag(flagId, id, 1)

        return
    }

    log_amx("[SCOREFLAG] !!WARNING!! INVALID MESSAGE STRING WAS GIVEN!! (%s)", lMessage)
}

returnFlag(flagId, id, type = 0)
{
    if(!is_valid_ent(flagId))
        return
    
    new Float:lVector[3]

    switch(entity_get_int(flagId, EV_INT_body))
    {
        case FLAG_BODY_BLUE:
        {
            if(type == 1)
            {
                gUserFlag[id] = 0
            }

            for(new i = 1;(i <= gMaxPlayers && type == 0); i++)
            {
                if(!is_user_connected(id))
                    continue

                client_cmd(i, "mp3 ^"play^" ^"%s^"", gFlagSounds[1])
            }
            
            entity_set_int(flagId, EV_INT_sequence, FLAG_SEQ_STAND)
            entity_set_size(flagId, FLAG_MIN_STAND_BOX, FLAG_MAX_STAND_BOX)
            entity_set_vector(flagId, EV_VEC_velocity, FLAG_SPAWN_VELOCITY)
            entity_set_vector(flagId, EV_VEC_angles, Float:{0.0, 0.0, 0.0})
            entity_set_edict(flagId, EV_ENT_aiment, 0)
            entity_set_edict(flagId, EV_ENT_owner, 0)
            entity_set_int(flagId, EV_INT_movetype, MOVETYPE_TOSS)
            entity_set_int(flagId, EV_INT_solid, SOLID_TRIGGER)
            entity_set_float(flagId, EV_FL_gravity, 2.0)

            entity_get_vector(flagId, EV_VEC_basicorigin, lVector)
            entity_set_origin(flagId, lVector)

            entity_set_int(flagId, EV_INT_flagstatus, FLAG_STATUS_STAND)
        }
        case FLAG_BODY_RED:
        {
            if(type == 1)
            {
                gUserFlag[id] = 0
            }

            for(new i = 1;(i <= gMaxPlayers && type == 0); i++)
            {
                if(!is_user_connected(id))
                    continue

                client_cmd(i, "mp3 ^"play^" ^"%s^"", gFlagSounds[5])
            }

            entity_set_int(flagId, EV_INT_sequence, FLAG_SEQ_STAND)
            entity_set_size(flagId, FLAG_MIN_DROPPED_BOX, FLAG_MAX_DROPPED_BOX)
            entity_set_vector(flagId, EV_VEC_velocity, FLAG_DROP_VELOCITY)
            entity_set_vector(flagId, EV_VEC_angles, Float:{0.0, 0.0, 0.0})
            entity_set_edict(flagId, EV_ENT_aiment, 0)
            entity_set_edict(flagId, EV_ENT_owner, 0)
            entity_set_int(flagId, EV_INT_movetype, MOVETYPE_TOSS)
            entity_set_int(flagId, EV_INT_solid, SOLID_TRIGGER)
            entity_set_float(flagId, EV_FL_gravity, 2.0)

            entity_get_vector(flagId, EV_VEC_basicorigin, lVector)
            entity_set_origin(flagId, lVector)

            entity_set_int(flagId, EV_INT_flagstatus, FLAG_STATUS_STAND)
        }
        default:
        {
            log_amx("[DROPFLAG] Invalid flag body! (%d | %d)", flagId, entity_get_int(flagId, EV_INT_body))
            return
        }
    }
}

dropFlag(flagId, id)
{
    if(!is_valid_ent(flagId))
        return

    switch(entity_get_int(flagId, EV_INT_body))
    {
        case FLAG_BODY_BLUE:
        {
            for(new i = 1; i <= gMaxPlayers; i++)
            {
                if(!is_user_connected(id))
                    continue

                client_cmd(i, "mp3 ^"play^" ^"%s^"", gFlagSounds[0])
            }

            gUserFlag[id] = 0
            
            entity_set_int(flagId, EV_INT_sequence, FLAG_SEQ_DROPPED)
            entity_set_size(flagId, FLAG_MIN_DROPPED_BOX, FLAG_MAX_DROPPED_BOX)
            entity_set_vector(flagId, EV_VEC_velocity, FLAG_DROP_VELOCITY)
            entity_set_vector(flagId, EV_VEC_angles, Float:{0.0, 0.0, 0.0})
            entity_set_edict(flagId, EV_ENT_aiment, 0)
            entity_set_edict(flagId, EV_ENT_owner, 0)
            entity_set_int(flagId, EV_INT_movetype, MOVETYPE_TOSS)
            entity_set_int(flagId, EV_INT_solid, SOLID_TRIGGER)
            entity_set_float(flagId, EV_FL_gravity, 2.0)

            entity_set_int(flagId, EV_INT_flagstatus, FLAG_STATUS_DROPPED)
        }
        case FLAG_BODY_RED:
        {
            for(new i = 1; i <= gMaxPlayers; i++)
            {
                if(!is_user_connected(id))
                    continue

                client_cmd(i, "mp3 ^"play^" ^"%s^"", gFlagSounds[4])
            }

            gUserFlag[id] = 0

            entity_set_int(flagId, EV_INT_sequence, FLAG_SEQ_DROPPED)
            entity_set_size(flagId, FLAG_MIN_DROPPED_BOX, FLAG_MAX_DROPPED_BOX)
            entity_set_vector(flagId, EV_VEC_velocity, FLAG_DROP_VELOCITY)
            entity_set_vector(flagId, EV_VEC_angles, Float:{0.0, 0.0, 0.0})
            entity_set_edict(flagId, EV_ENT_aiment, 0)
            entity_set_edict(flagId, EV_ENT_owner, 0)
            entity_set_int(flagId, EV_INT_movetype, MOVETYPE_TOSS)
            entity_set_int(flagId, EV_INT_solid, SOLID_TRIGGER)
            entity_set_float(flagId, EV_FL_gravity, 2.0)

            entity_set_int(flagId, EV_INT_flagstatus, FLAG_STATUS_DROPPED)
        }
        default:
        {
            log_amx("[DROPFLAG] Invalid flag body! (%d | %d)", flagId, entity_get_int(flagId, EV_INT_body))
            return
        }
    }
}

takeFlag(flagId, id)
{
    if(!is_valid_ent(flagId))
        return

    switch(entity_get_int(flagId, EV_INT_body))
    {
        case FLAG_BODY_BLUE:
        {
            for(new i = 1; i <= gMaxPlayers; i++)
            {
                if(!is_user_connected(id))
                    continue

                client_cmd(i, "mp3 ^"play^" ^"%s^"", gFlagSounds[2])
            }

            entity_set_int(flagId, EV_INT_sequence, FLAG_SEQ_BASE)
            entity_set_size(flagId, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0})
            entity_set_vector(flagId, EV_VEC_velocity, Float:{0.0, 0.0, 0.0})
            entity_set_edict(flagId, EV_ENT_aiment, id)
            entity_set_edict(flagId, EV_ENT_owner, id)
            entity_set_int(flagId, EV_INT_movetype, MOVETYPE_FOLLOW)
            entity_set_int(flagId, EV_INT_solid, SOLID_NOT)
            entity_set_float(flagId, EV_FL_gravity, 0.0)

            entity_set_int(flagId, EV_INT_flagstatus, FLAG_STATUS_BASE)

            gUserFlag[id] = flagId
        }
        case FLAG_BODY_RED:
        {
            for(new i = 1; i <= gMaxPlayers; i++)
            {
                if(!is_user_connected(id))
                    continue

                client_cmd(i, "mp3 ^"play^" ^"%s^"", gFlagSounds[6])
            }

            entity_set_int(flagId, EV_INT_sequence, FLAG_SEQ_BASE)
            entity_set_size(flagId, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0})
            entity_set_vector(flagId, EV_VEC_velocity, Float:{0.0, 0.0, 0.0})
            entity_set_edict(flagId, EV_ENT_aiment, id)
            entity_set_edict(flagId, EV_ENT_owner, id)
            entity_set_int(flagId, EV_INT_movetype, MOVETYPE_FOLLOW)
            entity_set_int(flagId, EV_INT_solid, SOLID_NOT)
            entity_set_float(flagId, EV_FL_gravity, 0.0)

            entity_set_int(flagId, EV_INT_flagstatus, FLAG_STATUS_BASE)

            gUserFlag[id] = flagId
        }
        default:
        {
            log_amx("[TAKEFLAG] !!WARNING!! INVALID FLAG BODY GIVEN! (%d | %d)", flagId, entity_get_int(flagId, EV_INT_body))
        }
    }
}

loadLocations()
{
    new lFile[90], lLineId, lText[55], lSubStrings[7][10], Float:lVector[3], lEnt, lEntBase
    new lCtSpawnsDeleted = false
    new lTSpawnsDeleted = false
    new lCtFlagsDeleted = false
    new lTrFlagsDeleted = false

    get_configsdir(lFile, charsmax(lFile))
    get_mapname(lText, charsmax(lText))
    format(lFile, charsmax(lFile), "%s/mg_ctf/%s.txt", lFile, lText)

    while((lLineId = read_file(lFile, lLineId, lText, charsmax(lText))))
    {
        explode_string(lText, " ", lSubStrings, 7, charsmax(lSubStrings[]), false)

        if(equal(lSubStrings[0], "CT_SPAWN"))
        {
            if(!lCtSpawnsDeleted)
            {
                remove_entity_name("info_player_start")
                lCtSpawnsDeleted = true
            }

            lEnt = create_entity("info_player_start")

            if(!is_valid_ent(lEnt))
                continue

            lVector[0] = str_to_float(lSubStrings[1])
            lVector[1] = str_to_float(lSubStrings[2])
            lVector[2] = str_to_float(lSubStrings[3])

            entity_set_origin(lEnt, lVector)

            lVector[0] = str_to_float(lSubStrings[4])
            lVector[1] = str_to_float(lSubStrings[5])
            lVector[2] = str_to_float(lSubStrings[6])

            entity_set_vector(lEnt, EV_VEC_angles, lVector)

            continue
        }

        if(equal(lSubStrings[0], "TR_SPAWN"))
        {
            if(!lTSpawnsDeleted)
            {
                remove_entity_name("info_player_deathmatch")
                lTSpawnsDeleted = true
            }

            lEnt = create_entity("info_player_deathmatch")

            if(!is_valid_ent(lEnt))
                continue

            lVector[0] = str_to_float(lSubStrings[1])
            lVector[1] = str_to_float(lSubStrings[2])
            lVector[2] = str_to_float(lSubStrings[3])

            entity_set_origin(lEnt, lVector)

            lVector[0] = str_to_float(lSubStrings[4])
            lVector[1] = str_to_float(lSubStrings[5])
            lVector[2] = str_to_float(lSubStrings[6])

            entity_set_vector(lEnt, EV_VEC_angles, lVector)

            continue
        }

        if(equal(lSubStrings[0], "CT_FLAG"))
        {
            if(!lCtFlagsDeleted)
            {
                remove_entity_name(ENTNAME_CTFLAG)
                lCtFlagsDeleted = true
            }

            lEnt = create_entity("info_target")
            lEntBase = create_entity("info_target")

            if(!is_valid_ent(lEnt))
                continue
            
            if(!is_valid_ent(lEntBase))
            {
                remove_entity(lEnt)
                continue
            }
                
            lVector[0] = str_to_float(lSubStrings[1])
            lVector[1] = str_to_float(lSubStrings[2])
            lVector[2] = str_to_float(lSubStrings[3])

            entity_set_model(lEnt, FLAG_MODEL)
            entity_set_string(lEnt, EV_SZ_classname, ENTNAME_CTFLAG)
            entity_set_int(lEnt, EV_INT_body, FLAG_BODY_BLUE)
            entity_set_int(lEnt, EV_INT_sequence, FLAG_SEQ_STAND)
            DispatchSpawn(lEnt)
            entity_set_origin(lEnt, lVector)
            entity_set_vector(lEnt, EV_VEC_basicorigin, lVector)
            entity_set_size(lEnt, FLAG_MIN_STAND_BOX, FLAG_MAX_STAND_BOX)
            entity_set_vector(lEnt, EV_VEC_velocity, FLAG_SPAWN_VELOCITY)
            entity_set_vector(lEnt, EV_VEC_angles, Float:{0.0, 0.0, 0.0})
            entity_set_edict(lEnt, EV_ENT_aiment, 0)
            entity_set_int(lEnt, EV_INT_movetype, MOVETYPE_TOSS)
            entity_set_int(lEnt, EV_INT_solid, SOLID_TRIGGER)
            entity_set_float(lEnt, EV_FL_gravity, 2.0)             

            entity_set_model(lEntBase, FLAG_MODEL)
            entity_set_string(lEntBase, EV_SZ_classname, ENTNAME_FLAGBASE)
            entity_set_int(lEntBase, EV_INT_body, 0)
            entity_set_int(lEntBase, EV_INT_sequence, FLAG_SEQ_BASE)
            DispatchSpawn(lEntBase)
            entity_set_origin(lEntBase, lVector)
            entity_set_vector(lEntBase, EV_VEC_velocity, Float:{0.0, 0.0, 0.0})
            entity_set_int(lEntBase, EV_INT_movetype, MOVETYPE_TOSS)

            entity_set_int(lEntBase, EV_INT_renderfx, kRenderFxGlowShell)
            entity_set_float(lEntBase, EV_FL_renderamt, 100.0)
            entity_set_vector(lEntBase, EV_VEC_rendercolor, Float:{0.0, 0.0, 150.0})

            
            entity_set_int(lEnt, EV_INT_flagstatus, FLAG_STATUS_STAND)

            continue
        }

        if(equal(lSubStrings[0], "TR_FLAG"))
        {
            if(!lTrFlagsDeleted)
            {
                remove_entity_name(ENTNAME_TRFLAG)
                lTrFlagsDeleted = true
            }

            lEnt = create_entity("info_target")
            lEntBase = create_entity("info_target")

            if(!is_valid_ent(lEnt))
                continue
                
            if(!is_valid_ent(lEntBase))
            {
                remove_entity(lEnt)
                continue
            }
                
            lVector[0] = str_to_float(lSubStrings[1])
            lVector[1] = str_to_float(lSubStrings[2])
            lVector[2] = str_to_float(lSubStrings[3])

            entity_set_model(lEnt, FLAG_MODEL)
            entity_set_string(lEnt, EV_SZ_classname, ENTNAME_TRFLAG)
            entity_set_int(lEnt, EV_INT_body, FLAG_BODY_RED)
            entity_set_int(lEnt, EV_INT_sequence, FLAG_SEQ_STAND)
            DispatchSpawn(lEnt)
            entity_set_origin(lEnt, lVector)
            entity_set_vector(lEnt, EV_VEC_basicorigin, lVector)
            entity_set_size(lEnt, FLAG_MIN_STAND_BOX, FLAG_MAX_STAND_BOX)
            entity_set_vector(lEnt, EV_VEC_velocity, FLAG_SPAWN_VELOCITY)
            entity_set_vector(lEnt, EV_VEC_angles, Float:{0.0, 0.0, 0.0})
            entity_set_edict(lEnt, EV_ENT_aiment, 0)
            entity_set_int(lEnt, EV_INT_movetype, MOVETYPE_TOSS)
            entity_set_int(lEnt, EV_INT_solid, SOLID_TRIGGER)
            entity_set_float(lEnt, EV_FL_gravity, 2.0)             

            entity_set_model(lEntBase, FLAG_MODEL)
            entity_set_string(lEntBase, EV_SZ_classname, ENTNAME_FLAGBASE)
            entity_set_int(lEntBase, EV_INT_body, 0)
            entity_set_int(lEntBase, EV_INT_sequence, FLAG_SEQ_BASE)
            DispatchSpawn(lEntBase)
            entity_set_origin(lEntBase, lVector)
            entity_set_vector(lEntBase, EV_VEC_velocity, Float:{0.0, 0.0, 0.0})
            entity_set_int(lEntBase, EV_INT_movetype, MOVETYPE_TOSS)

            entity_set_int(lEntBase, EV_INT_renderfx, kRenderFxGlowShell)
            entity_set_float(lEntBase, EV_FL_renderamt, 100.0)
            entity_set_vector(lEntBase, EV_VEC_rendercolor, Float:{150.0, 0.0, 0.0})

            entity_set_int(lEnt, EV_INT_flagstatus, FLAG_STATUS_STAND)

            continue
        }
    }
}