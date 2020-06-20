#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#define PLUGIN "[MG] Get player's position"
#define VERSION "1.0"
#define AUTH "Vieni"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTH)

    register_clcmd("get_origin", "send_origin_message")
}

public send_origin_message(id)
{
    if(!is_user_alive(id))
        return PLUGIN_HANDLED

    new Float:lVector[3]
    pev(id, pev_origin, lVector)
    client_print(id, print_console, "Origin: %.2f | %.2f | %.2f", lVector[0], lVector[1], lVector[2])

    pev(id, pev_angles, lVector)
    client_print(id, print_console, "Angle: %.2f | %.2f | %.2f", lVector[0], lVector[1], lVector[2])

    return PLUGIN_HANDLED
}