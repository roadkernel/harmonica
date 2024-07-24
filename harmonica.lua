print(" _____________________________________ ")
print("|                                     |")
print("|             HARMONICA               |")
print("|              RECODE                 |")
print("|_____________________________________|")
gui.add_notification('harmonica', 'welcome suka!')

--[[
TODO:

    add drag to slowdown indicator

]]


local p = 'lua>elements a'
local btab = 'lua>elements b'





local hitlog_checkbox = gui.checkbox(btab .. 'muminlog', btab, 'muminlog')
local anim_breaker_combo = gui.combobox(p .. '>mumin breaker', p, 'mumin breakers', true, 'leg breaker', 'legs in air', 'zero pitch on land') 
local static_legs = gui.combobox(p .. '>leg breaker', p, 'on groud', false, 'static', 'stutter', 'muminwalk')
local static_legs_air = gui.combobox(p .. '>leg air', p, 'in air', false, 'static', 'muminwalk')
local globalenable = gui.checkbox(btab .. 'muminspec', btab, 'muminspec')


local function contains(table, val)
    if #table > 0 then
        for i=1, #table do
            if table[i] == val then
                return true
            end
        end
    end
    return false
end

local function visibility()
    local vals = anim_breaker_combo:get(true)

    static_legs:set_visible(contains(vals, 'leg breaker'))
    static_legs_air:set_visible(contains(vals, 'legs in air'))

end

visibility()

anim_breaker_combo:add_callback(function()
    visibility()
end)


-- FFI

ffi.cdef[[
    typedef void*(__thiscall* get_client_entity_t)(void*, int);

    typedef struct
    {
        char pad20[24];
        uint32_t m_nSequence;
        float m_flPrevCycle;
        float m_flWeight;
        char pad20[8];
        float m_flCycle;
        void *m_pOwner;
        char pad_0038[ 4 ];
    } animation_layer_t;
    
    typedef struct
    { 
        char pad[ 3 ];
        char m_bForceWeaponUpdate; //0x4
        char pad1[ 91 ];
        void* m_pBaseEntity; //0x60
        void* m_pActiveWeapon; //0x64
        void* m_pLastActiveWeapon; //0x68
        float m_flLastClientSideAnimationUpdateTime; //0x6C
        int m_iLastClientSideAnimationUpdateFramecount; //0x70
        float m_flAnimUpdateDelta; //0x74
        float m_flEyeYaw; //0x78
        float m_flPitch; //0x7C
        float m_flGoalFeetYaw; //0x80
        float m_flCurrentFeetYaw; //0x84
        float m_flCurrentTorsoYaw; //0x88
        float m_flUnknownVelocityLean; //0x8C
        float m_flLeanAmount; //0x90
        char pad2[ 4 ];
        float m_flFeetCycle; //0x98
        float m_flFeetYawRate; //0x9C
        char pad3[ 4 ];
        float m_fDuckAmount; //0xA4
        float m_fLandingDuckAdditiveSomething; //0xA8
        char pad4[ 4 ];
        float m_vOriginX; //0xB0
        float m_vOriginY; //0xB4
        float m_vOriginZ; //0xB8
        float m_vLastOriginX; //0xBC
        float m_vLastOriginY; //0xC0
        float m_vLastOriginZ; //0xC4
        float m_vVelocityX; //0xC8
        float m_vVelocityY; //0xCC
        char pad5[ 4 ];
        float m_flUnknownFloat1; //0xD4
        char pad6[ 8 ];
        float m_flUnknownFloat2; //0xE0
        float m_flUnknownFloat3; //0xE4
        float m_flUnknown; //0xE8
        float m_flSpeed2D; //0xEC
        float m_flUpVelocity; //0xF0
        float m_flSpeedNormalized; //0xF4
        float m_flFeetSpeedForwardsOrSideWays; //0xF8
        float m_flFeetSpeedUnknownForwardOrSideways; //0xFC
        float m_flTimeSinceStartedMoving; //0x100
        float m_flTimeSinceStoppedMoving; //0x104
        bool m_bOnGround; //0x108
        bool m_bInHitGroundAnimation; //0x109
        float m_flTimeSinceInAir; //0x10A
        float m_flLastOriginZ; //0x10E
        float m_flHeadHeightOrOffsetFromHittingGroundAnimation; //0x112
        float m_flStopToFullRunningFraction; //0x116
        char pad7[ 4 ]; //0x11A
        float m_flMagicFraction; //0x11E
        char pad8[ 60 ]; //0x122
        float m_flWorldForce; //0x15E
        char pad9[ 462 ]; //0x162
        float m_flMaxYaw; //0x334
    } anim_state_t;
]]

local class_ptr = ffi.typeof('void***')
local uintptr_t = ffi.typeof('uintptr_t**')

local function this_call(call_function, parameters)
    return function(...)
        return call_function(parameters, ...)
    end
end

local VClientEntityList = ffi.cast(uintptr_t, utils.find_interface('client.dll', 'VClientEntityList003'))
local get_client_entity = this_call(ffi.cast('get_client_entity_t', VClientEntityList[0][3]), VClientEntityList)

local is_moving = false
local was_in_air = true

local reference_legs = gui.get_combobox('rage>anti-aim>desync>leg slide')

local anim_breakers = {
    -- legs in air
    ['legs in air'] = function(pointer)
        if was_in_air then
            local v = static_legs_air:get_value()
            if v == 'static' then
                ffi.cast('float*', ffi.cast('uintptr_t', pointer) + 10104)[6] = 1
            else
                ffi.cast('float*', ffi.cast('uintptr_t', pointer) + 10104)[6] = 0
                ffi.cast('animation_layer_t**', ffi.cast('uintptr_t', pointer) + 0x2990)[0][6].m_flWeight = 1
    
            end
        end
    end,

    -- zero pitch on land
    ['zero pitch on land'] = function(pointer)
        if not was_in_air then
            local anim_state = ffi.cast('anim_state_t**', ffi.cast('uintptr_t', pointer) + 0x9960)[0]

            if anim_state.m_bInHitGroundAnimation then
                ffi.cast('float*', ffi.cast('uintptr_t', pointer) + 10104)[12] = 0.5
            end
        end
    end,

    -- moonwalk
    ['moonwalk'] = function(pointer)
        if is_moving then
            ffi.cast('float*', ffi.cast('uintptr_t', pointer) + 10104)[7] = 0
            ffi.cast('animation_layer_t**', ffi.cast('uintptr_t', pointer) + 0x2990)[0][7].m_flWeight = 0
        end
    end,

    ['leg breaker'] = function(pointer)
        if is_moving and contains(anim_breaker_combo:get(true), 'moonwalk') == false then
            local me = entities.get_entity(engine.get_local_player())
            local v = static_legs:get_value()
            if v == 'static' then
                local strafing = me:get_prop("m_bStrafing")
                reference_legs:set_value(strafing and 'Default' or 'Always slide')
                ffi.cast('float*', ffi.cast('uintptr_t', pointer) + 10104)[0] = 0
            elseif v == 'stutter' then
                local check = global_vars.tickcount % 2.5
                reference_legs:set_value(check == 0 and 'Always slide' or 'Never slide')
                ffi.cast('float*', ffi.cast('uintptr_t', pointer) + 10104)[0] = 0
            else
                ffi.cast('float*', ffi.cast('uintptr_t', pointer) + 10104)[7] = 0
                ffi.cast('animation_layer_t**', ffi.cast('uintptr_t', pointer) + 0x2990)[0][7].m_flWeight = 0
            end
        end
    end
}


--DEF AA PART

local enabled = gui.checkbox (p .. 'mumin defensive', p, 'mumin defensive')

local dt = gui.get_checkbox ( "rage>aimbot>general>double tap" )
local hs = gui.get_checkbox ( "rage>aimbot>general>hide shot" )

local fl_frozen = bit.lshift ( 1, 6 )

local in_attack = bit.lshift ( 1, 0 )
local in_attack2 = bit.lshift ( 1, 11 )


local checker = 0
local defensive = false

-- CREATEMOVE CMD

function on_create_move(cmd)
    local index = engine.get_local_player()
    local player = entities.get_entity(index)

    if not (player and player:is_alive()) then
        return
    end

    local pointer = get_client_entity(index)

    local fFlags = player:get_prop('m_fFlags')
    local in_air = fFlags == 256 or fFlags == 262

    if in_air then
        was_in_air = true
    end

    is_moving = math.abs(player:get_prop('m_vecVelocity[0]') + player:get_prop('m_vecVelocity[1]')) > 3
    
    local getCombo = anim_breaker_combo:get(true)

    for i, x in pairs(getCombo) do
        anim_breakers[x](pointer)
    end

    was_in_air = in_air

-- DEF AA PART

 local me = entities.get_entity ( engine.get_local_player ( ) )
    if not me or not me:is_valid ( ) then
        return
    end

    local tickbase = me:get_prop ( "m_nTickBase" )

    defensive = math.abs ( tickbase - checker ) >= 3
    checker = math.max ( tickbase, checker or 0 )


end
-- DEF AA PART

function on_player_spawn ( event )
    if engine.get_player_for_user_id ( event:get_int ( 'userid' ) ) == engine.get_local_player ( ) then
        checker = 0
    end
end
-- DEF AA PART

function on_run_command ( cmd )
    if not enabled:get() or not dt:get() and not hs:get() then
        return
    end

    local buttons = cmd:get_buttons ( )
    if bit.band ( buttons, in_attack ) == in_attack or bit.band ( buttons, in_attack2 ) == in_attack2 then
        return
    end

    local me = entities.get_entity ( engine.get_local_player ( ) )
    if not me or not me:is_valid ( ) then
        return
    end

    local flags = me:get_prop ( 'm_fFlags' )
    if bit.band ( flags, fl_frozen ) == fl_frozen then
        return
    end

    if info.fatality.lag_ticks > 1 then
        return
    end

    if defensive then
        cmd:set_view_angles ( utils.random_int ( -90, 45 ), utils.random_int(-359, 359), 0 ) --, utils.random_int(-359, 359),
        --        cmd:set_view_angles ( utils.random_int ( -359, 359 ), utils.random_int ( -88, 88 ), 0 )

    elseif info.fatality.can_fastfire == false then
        cmd:set_view_angles ( utils.random_int ( -90, 90 ), utils.random_int(-359, 359), 0 )
        --        cmd:set_view_angles ( utils.random_int ( -359, 359 ), utils.random_int ( -88, 88 ), 0 )

    end
end

local hit_counter = 0
local text_to_show = ""
local show_text = false
local start_time = 0
local duration = 5
local last_shot_type = 0
local textx = 0
local Font = render.create_font("pixel.ttf", 18, render.font_flag_outline)


function on_shot_registered(e)
    local target_name = entities.get_entity(e.target):get_player_info().name
    local hitgroup = e.server_hitgroup
    local hitgroup_names = ""
    case = {
        [1] = "Head",
        [2] = "Chest",
        [3] = "Stomach",
        [4] = "Unknown",
        [5] = "Arms",
        [6] = "Legs",
        [7] = "Feet",
        default = "Unknown"
    }
    if e.result == "hit" then
        show_text = true
        hit_counter = hit_counter +1
        start_time = global_vars.realtime
        last_shot_type = 1
        hitgroup_names = case[hitgroup] or case.default
        text_to_show = "Hit "..target_name.." in the ".. hitgroup_names .." for ".. e.client_damage .."(".. e.backtrack .."ms)"
    else
        show_text = true
        hit_counter = hit_counter +1
        start_time = global_vars.realtime
        last_shot_type = 0
        text_to_show = "Miss " .. target_name .. " with" .. " (" .. math.floor(e.hitchance) .. "%) (" .. e.result .. ")"
    end
    print(text_to_show)
end

function renderhitlog()
if hitlog_checkbox:get() then
local x, y = render.get_screen_size()

    if show_text and start_time + duration > global_vars.realtime then
        textx, texty = render.get_text_size(Font, "[" .. hit_counter .. "] " .. text_to_show)
        local def_color

        if last_shot_type == 1 then
            def_color = {214, 250, 132, 255}  --hit
        else
            def_color = {245, 102, 66, 255}  --miss
        end
        if global_vars.realtime > start_time + 2 then
            local fade_duration = 1
            local elapsed_time = global_vars.realtime - (start_time + 2)
            def_color[4] = math.max(0, def_color[4] - (elapsed_time / fade_duration) * 255)
        end

        render.text(Font, x / 1.9 - textx / 2 + 100, y / 1.5 + 195, "[" .. hit_counter .. "] " .. text_to_show, render.color(unpack(def_color)), render.align_center)
        end
    end
end
--indicators start



local korobka_s_indicatoramu = gui.combobox(btab .. '>mumin indicators', btab, 'mumin indicators', false, 'none', 'mumin', 'mephedrone', 'halifat')
local korobka_s_markami = gui.combobox(btab .. '>mumin watermark', btab, 'mumin watermark', false, 'none', 'Brushstrike', 'mono', 'pasted')--SELECT TYPE
local size={render.get_screen_size()}
local font = render.create_font("tahoma.ttf", 14)
local font2 = render.create_font("CascadiaCode.ttf", 17)
local font777 = render.create_font("tahoma.ttf", 15, render.font_flag_shadow, render.font_flag_outline)
local font3 = render.create_font("pixel.ttf", 16, render.font_flag_outline)
local fontp4 = render.create_font("pixel.ttf", 13, render.font_flag_outline)
local dt = gui.get_checkbox('rage>aimbot>general>double tap')
local forum_name  = info.fatality.username
local desyncdeltaind = info.fatality.desync
local lagttt = info.fatality.lag_ticks
local rl_time =  global_vars.realtime
local fps111         = 1 / global_vars.frametime;
local tickrate111    = 1 / global_vars.interval_per_tick
local frstnd = gui.get_checkbox('rage>anti-aim>angles>freestanding')
local mind = gui.get_checkbox('rage>weapon>general>weapon>override')
local font666 = render.create_font("Brushstrike.ttf", 23, render.font_flag_shadow, render.font_flag_outline)
local candoubletapbool = info.fatality.can_fastfire


function watermarkrender1()

-- indicator by rirzo

 local player=entities.get_entity(engine.get_local_player())
     local x, y = render.get_screen_size()
    add_y = 35
    if player==nil then return end
    if not player:is_alive() then  return end --or enabled:get()==false




render.text(font777, x / 2 + 6, y / 2 + 20,"HARMONICA",render.color(220, 135, 49, 255)) -- under cross
if not frstnd:get() then
    render.text(font777, x / 2 + 6, y / 2 + 33,"DYNAMIC",render.color(209, 159, 230, 255) )
    else
    render.text(font777, x / 2 + 6, y / 2 + 33,"FREESTAND",render.color(209, 159, 230, 255)) 
end
if mind:get() then
    add_y = add_y + 11
    render.text(font777, x / 2 + 6, y / 2 + add_y, "DAMAGE",render.color(252, 24, 18, 255) )
end

    add_y = add_y + 13
    if dt:get() then
    render.text(font777, x / 2 + 6, y / 2 + add_y,"DT",render.color(187, 255, 0, 255) )
    end

end
-- ÍÓ ×Å 
-- ÏÎÍÅÑËÀÑÜ 
-- ÕÀÕÀÕÀÕ

local muminantiaimkek = gui.checkbox(p .. 'mumin aa', p, 'mumin aa')

-- VELIKIY RANDOM 
local randomkekerman = utils.random_int(1, 2)
local randomkekerman1 = utils.random_int(1, 2)
local randomkekerman2 = utils.random_int(1, 2)
local randomkekerman3 = utils.random_int(1, 2)
local randomtrashtalk = utils.random_int(1, 15)
local randomkekerman111 = utils.random_int(-60, 60)
local randomkekerman222 = utils.random_int(35, 60)
local randomkekerman333 = utils.random_int(-180, -65)
local randomkekerman3334 = utils.random_int(-180, 180)

-- OY BLYA OTEEEEEC 
local fakeyawDRAIN_bigmac_dunuts = gui.get_combobox('rage>anti-aim>desync>fake yaw')
local fakeyawkek = gui.get_slider('rage>anti-aim>desync>fake yaw>settings>value')
local yawjitter = gui.get_slider('rage>anti-aim>angles>yaw jitter>settings>value')
local yawfakelimit = gui.get_slider('rage>anti-aim>desync>fake yaw>settings>limit')
local settocenter_ya_hochy_est_sad = gui.get_combobox('rage>anti-aim>angles>yaw jitter')
local yj = gui.get_combobox('rage>anti-aim>angles>yaw jitter')
local medlennya_hodba_maxim = gui.get_checkbox('misc>movement>slide')
--rage>anti-aim>angles>yaw jitter>settings>value

function allahy_random_txt_exe_js()
  if randomkekerman > -181 then
      if engine.is_in_game() == false then return end

      --ZAGATOVKI
        local crouch = input.is_key_down(0x11)
        local lplr = entities.get_entity(engine.get_local_player())
        local air = lplr:get_prop("m_hGroundEntity") == -1
        local velocity_x = math.floor(lplr:get_prop("m_vecVelocity[0]"))
        local velocity_y = math.floor(lplr:get_prop("m_vecVelocity[1]"))
        local speed_hiv_vich_death = math.sqrt(velocity_x ^ 2 + velocity_y ^ 2)
       


        -- da hrani menya otec...
        randomkekerman = utils.random_int(-87, 123)
        randomkekerman1 = utils.random_int(-180, 180)
        randomkekerman2 = utils.random_int(-60, 60)
        randomkekerman111 = utils.random_int(35, 60)
        randomkekerman222 = utils.random_int(35, 60)
        randomkekerman333 = utils.random_int(-180, -65)
        randomkekerman3334 = utils.random_int(-180, 180)
        
        --oh blyaaa
        fakeyawkek:set('125')
        yawfakelimit:set('60')
        fakeyawDRAIN_bigmac_dunuts:set('Opposite')
        settocenter_ya_hochy_est_sad:set('Center')
        yawjitter:set('-8')

         if crouch then
        yj:set('None')
        fakeyawkek:set(randomkekerman1)
        yawfakelimit:set(randomkekerman2)
        

        else if air then
        yawjitter:set(randomkekerman)
        fakeyawkek:set(randomkekerman1)
        yawfakelimit:set(randomkekerman2)
        settocenter_ya_hochy_est_sad:set('Offset')
        fakeyawDRAIN_bigmac_dunuts:set('Peek real')
        

        else if air and crouch then
                yj:set('None')
        fakeyawkek:set(randomkekerman1)
        yawfakelimit:set(randomkekerman2)
        

        
        else if medlennya_hodba_maxim:get() and not air and not crouch then
        local random_for_stance = utils.random_int(0, 50)
        yj:set('Offset')
        fakeyawkek:set('-180')
        fakeyawDRAIN_bigmac_dunuts:set('Peek fake')
        yawfakelimit:set(randomkekerman111)
       end  
       end
       end
       end
  end
end

local trollen_wagen_sueta_gang = gui.checkbox(btab .. 'mumin-troll', btab, 'mumin-troll')

function on_player_death(event)
if trollen_wagen_sueta_gang:get() then
    randomtrashtalk = utils.random_int(1, 15)
    if randomtrashtalk == 1 then
    gui.add_notification('harmonica', 'oops! (retard)')   
    else if randomtrashtalk == 2 then
    gui.add_notification('harmonica', '1')
    else if randomtrashtalk == 3 then
    gui.add_notification('harmonica', 'jihad has failed')
    else if randomtrashtalk == 4 then
    gui.add_notification('harmonica', '!rs')
    else if randomtrashtalk == 5 then
    gui.add_notification('harmonica', 'u r fucking retarded')
    else if randomtrashtalk == 6 then
    gui.add_notification('harmonica', 'nigger')
    else if randomtrashtalk == 7 then
    gui.add_notification('harmonica', 'posmotri na nebo')
    else if randomtrashtalk == 8 then
    gui.add_notification('harmonica', 'ebanblu` klop')
    else if randomtrashtalk == 9 then
    gui.add_notification('harmonica', 'gamesense.pub/forums/register.php')
    else if randomtrashtalk == 10 then
    gui.add_notification('harmonica', 'kys')
    else if randomtrashtalk == 11 then
    gui.add_notification('harmonica', 'u will get better')
    else if randomtrashtalk == 12 then
    gui.add_notification('harmonica', 'unlucky')
    else if randomtrashtalk == 13 then
    gui.add_notification('harmonica', 'YOHOHO')
    else if randomtrashtalk == 14 then
    gui.add_notification('harmonica', 'shodu za peso4kom')
    else if randomtrashtalk == 15 then
    gui.add_notification('harmonica', 'u almost did it')
    end
    end
    end
    end
    end
    end
    end
    end
    end
    end
    end
    end
    end
    end
    end
end
end


local defaa_list = gui.get_combobox('rage>aimbot>general>defensive fake')
local defaa_list2 = gui.get_combobox('rage>aimbot>general>defensive lag')
local defaa_fuckup_toggle = gui.checkbox(p .. 'mumindef fucker', p, 'mumindef fucker')
local random_def_aa_fucker = utils.random_int(1, 2)

function defaafuckup()
    random_def_aa_fucker = utils.random_int(1, 100)
     --   defaa_list:set('Quick yaw')
      --  defaa_list2:set('In air')
    
    if random_def_aa_fucker < 10 then
        defaa_list:set('Yaw flip')
       -- print(random_def_aa_fucker)
    else if 
        random_def_aa_fucker > 50 then
        defaa_list:set('Quick yaw')
       -- defaa_list2:set('In air')
        end
    end

    
end


function on_setup_move(cmd)
        if muminantiaimkek:get() then
        allahy_random_txt_exe_js()
        end

        if defaa_fuckup_toggle:get() then
        defaafuckup()
        end
end


local verdana = render.create_font("Brushstrike.ttf", 15, render.font_flag_shadow, render.font_flag_outline)
local verdana2 = render.create_font("Brushstrike.ttf", 10, render.font_flag_shadow, render.font_flag_outline)
local pixel2222 = render.create_font("pixel.ttf", 20, render.font_flag_shadow, render.font_flag_outline)
local screen_size = {render.get_screen_size()}

function animate(value, cond, max, speed, dynamic, clamp)

    -- animation speed
    speed = speed * global_vars.frametime * 20

    -- static animation
    if dynamic == false then
        if cond then
            value = value + speed
        else
            value = value - speed
        end
    
    -- dynamic animation
    else
        if cond then
            value = value + (max - value) * (speed / 100)
        else
            value = value - (0 + value) * (speed / 100)
        end
    end

    -- clamp value
    if clamp then
        if value > max then
            value = max
        elseif value < 0 then
            value = 0
        end
    end

    return value
end

function drag(var_x, var_y, size_x, size_y)
    local mouse_x, mouse_y = input.get_cursor_pos()

    local drag = false

    if input.is_key_down(0x01) then
        if mouse_x > var_x:get_int() and mouse_y > var_y:get_int() and mouse_x < var_x:get_int() + size_x and mouse_y < var_y:get_int() + size_y then
            drag = true
        end
    else
        drag = false
    end

    if (drag) then
        var_x:set_int(mouse_x - (size_x / 2))
        var_y:set_int(mouse_y - (size_y / 2))
    end

end
local fontind = render.create_font("tahoma.ttf", 12, render.font_flag_shadow, render.font_flag_outline)


local delta = info.fatality.desync

local ItemIndexToMenuIdx =
{
    [38] = 1,
    [11] = 1,
    [40] = 2,
    [9]  = 3,
    [64] = 4,
    [1]  = 4,
    [61] = 5,
    [2]  = 5,
    [3]  = 5,
    [4]  = 5,
    [30] = 5,
}

local DoubleTapRef = gui.get_checkbox("rage>aimbot>general>double tap")
local HSRef = gui.get_checkbox("rage>aimbot>general>hide shot")
local ScreensizeX, ScreensizeY = render.get_screen_size()
local Offset1 = math.vec3(-18, -17)
local Offset = math.vec3(15, 15)
local Offset3 = math.vec3(-6, -25)
local delta = info.fatality.desync	
local mind = gui.get_checkbox('rage>weapon>general>weapon>override')
local frstnd = gui.get_checkbox('rage>anti-aim>angles>freestanding')
local dt = gui.get_checkbox('rage>aimbot>general>double tap')

function kek123()
  
    render.text(verdana, ScreensizeX / 2 + 76, ScreensizeY / 2 - Offset1.y, "harmonica", render.color(255, 255, 255, 255), render.align_right) 
    add_y = 20

    
        if frstnd:get() then
        add_y = add_y + 15
        render.text(pixel2222, ScreensizeX / 2 - 45 , ScreensizeY / 2 + add_y, "freestand",render.color(255, 201, 120, 175) )
    end
        if dt:get() then
        add_y = add_y + 15
        render.text(pixel2222, ScreensizeX / 2 - 45 , ScreensizeY / 2 + add_y, "doubletap",render.color(228, 255, 120, 175) )
    end 
    if mind:get() then
        add_y = add_y + 15
        render.text(pixel2222, ScreensizeX / 2 - 45 , ScreensizeY / 2 + add_y, "damage",render.color(255, 120, 131, 175) )
    end 

end

local slowdownindicatorkek = gui.checkbox(btab .. 'slowdown indicator', btab, 'slowdown indicator')
local screen_size = {render.get_screen_size()}
local slow_x = gui.slider('lua>elements b>x', 'lua>elements b', 'x slider', -1500, 1500)
local slow_y = gui.slider('lua>elements b>y', 'lua>elements b', 'y slider', -1500, 1500)


local verdana = render.create_font("verdana.ttf", 42, render.font_flag_shadow, render.font_flag_outline)
local calibri = render.create_font("calibri.ttf", 13, render.font_flag_shadow, render.font_flag_outline)

function on_slow()

    if not slowdownindicatorkek:get() then return end

    local pos = {slow_x:get(), slow_y:get()}
    local size = {100 + 100, 22}
    local player=entities.get_entity(engine.get_local_player())
    if player==nil then return end
    if not player:is_alive() or slowdownindicatorkek:get()==false then  return end
    local mod=player:get_prop("m_flVelocityModifier")
    mod=mod*100
    if mod==100 and not gui.is_menu_open() then return end
    drag(slow_x, slow_y, size[1], size[2])
    alpha_anim = math.floor(math.abs(math.sin(global_vars.realtime) * 4) * 6)
    alpha_anim1 = math.floor(math.abs(math.sin(global_vars.realtime) * 7) * 255)
    render.rect_filled_rounded(pos[1] , pos[2] , pos[1] + size[1], pos[2] + 22,render.color(186, 209, 128,  255 ), 5)
    render.rect_filled_rounded(pos[1] + 2, pos[2] + 2, pos[1] + size[1]  - 2, pos[2] + 20, render.color(20, 20, 20, 255 ), 4)
    render.rect_filled_rounded(pos[1] + 4, pos[2] + 4, pos[1] + size[1] + mod - 104, pos[2] + 18, render.color(20, 20, 20,  255 ), 4)
    render.triangle_filled(pos[1] - 30, pos[2]- 15, pos[1] -6 , pos[2]+ 32, pos[1] -54, pos[2]+32, render.color(186, 209, 128, 255 )) 
    render.triangle_filled(pos[1] - 30, pos[2]- 10, pos[1] -10 , pos[2]+ 30, pos[1] -50, pos[2]+30, render.color(20, 20, 20,  255)) 
    render.text(verdana, pos[1] - 37 , pos[2] - 5, "!", render.color(255, 255, 255, 255 ))
    render.text(calibri, pos[1] + 45 , pos[2]+ 6, "Slow down: "..tostring(math.floor(mod)).."%" , render.color(255, 255, 255, 255 ))
end

--WATERMARKS

function truewatermark4real() --Brushstrike
        render.text(font666,1520, 10," harmonica   recode",render.color(255, 255, 255)) 
end

function pastedwatermark() --pasted thx random forum dude
    local x, y=render.get_screen_size()
    local player=entities.get_entity(engine.get_local_player())
    if player==nil then return end
    local text="fatality.win | "..engine.get_player_info(engine.get_local_player()).name.." | delay: "..math.floor(utils.get_rtt()*500).."ms | "..utils.get_time().hour..":"..utils.get_time().min..":"..utils.get_time().sec
    local textx, texty=render.get_text_size(font, text)
    render.rect_filled(x-15,16, x-textx-25, 35, render.color(0, 0, 0, 140))
    render.rect_filled(x-15,14, x-textx-25, 16, render.color(207, 252, 3, 140))
    render.text(font, x-textx-20,17, text, render.color(255,255, 255, 255))
end

local fatcalibrifonttt = render.create_font("calibri_bold.ttf", 15, render.font_flag_shadow, render.font_flag_outline)

function truewatermark4real2() --mono
        render.text(fatcalibrifonttt,1620, 10," harmonica   recode   |   user: ".. forum_name,render.color(255, 255, 255))         
end


function thehalifatindicators()

          if engine.is_in_game() == false then return end
          local keking = engine.is_in_game()
        local crouch = input.is_key_down(0x11)
        local lplr = entities.get_entity(engine.get_local_player())
        local air = lplr:get_prop("m_hGroundEntity") == -1
        local velocity_x = math.floor(lplr:get_prop("m_vecVelocity[0]"))
        local velocity_y = math.floor(lplr:get_prop("m_vecVelocity[1]"))
        local speed_hiv_vich_death = math.sqrt(velocity_x ^ 2 + velocity_y ^ 2)
        local player=entities.get_entity(engine.get_local_player())
        local x, y = render.get_screen_size()
        add_y = 35
        if player==nil then return end
        local alpha2 = math.floor(math.abs(math.sin(global_vars.realtime) * 1) * 255)

        render.text(fatcalibrifonttt, x / 2 - 34 , y / 2 + 20,"harm",render.color(255, 255, 255, 255))
        render.text(fatcalibrifonttt, x / 2 + 3 , y / 2 + 20,"onica",render.color(255, 255, 255, alpha2))


        add_y = 48
        if player:is_alive() and not air and not crouch then
        render.text(fatcalibrifonttt, x / 2 - 25  , y / 2 + 33,"ground",render.color(227, 255, 84, 255))
        

        else if air then
            render.text(fatcalibrifonttt, x / 2 - 10  , y / 2 + 33,"air",render.color(227, 255, 84, 255))
        
        else if crouch then
            render.text(fatcalibrifonttt, x / 2 - 12  , y / 2 + 33,"low",render.color(227, 255, 84, 255))

        end
        end
        end

        if not frstnd:get() then
    render.text(fatcalibrifonttt, x / 2 - 28, y / 2 + 48,"dynamic",render.color(255, 255, 255, 185) )
    else
    render.text(fatcalibrifonttt, x / 2 - 33 , y / 2 + 48,"freestand",render.color(227, 113, 204, 185)) 
end
if mind:get() then
    add_y = add_y + 15
    render.text(fatcalibrifonttt, x / 2 - 25, y / 2 + add_y, "damage",render.color(227, 113, 113, 185) )
end

    add_y = add_y + 15
    if dt:get() then
    render.text(fatcalibrifonttt, x / 2 - 8, y / 2 + add_y,"dt",render.color(84, 255, 150, 185) )
    end

end

local infobar = gui.checkbox(btab .. 'mumintab toggle', btab, 'mumintab toggle')
local infobar_color = gui.color_picker('lua>elements b>mumintab colorpicker', 'lua>elements b', 'mumintab colorpicker', render.color('#fff'))
local infobar_color2 = gui.color_picker('lua>elements b>mumintab colorpicker 2', 'lua>elements b', 'mumintab colorpicker 2', render.color('#fff'))
local mumintab_style = gui.combobox(btab .. '>mumintab style', btab, 'mumintab style', false, '1', '2', '3', '4', '5') 

    local pixel = render.create_font("pixel.ttf", 13, render.font_flag_outline)

function gui_controller_from_silkroad()
    local text =  "harmonica"
    local alpha2 = math.floor(math.abs(math.sin(global_vars.realtime) * 1) * 255)
    local player=entities.get_entity(engine.get_local_player())
    if player==nil then return end
    if not player:is_alive() then  return end
    local x, y = render.get_screen_size()    
    if infobar:get() then 
    render.rect_filled_multicolor(0, y / 2, 210, (y / 2) + 33,infobar_color:get(), render.color(0,0,0,0),render.color(0,0,0,0), infobar_color:get())   
        render.text(pixel, 40,(y / 2), "harmonica.lua", render.color(255,255,255,255))
        render.text(pixel, 37 ,(y / 2) + 10, " [recode]", render.color(infobar_color2:get().r, infobar_color2:get().g, infobar_color2:get().b, alpha2))
         render.text(pixel, 10,(y / 2) + 20, "t.me/medvedev_telegram", render.color(255,255,255,255))
         if mumintab_style:get() == '1' then
            render.rect_filled(7, (y / 2) + 2, 32, (y / 2) + 7,render.color(255,255,255,255))
            render.rect_filled(7, (y / 2) + 7, 32, (y / 2) + 12,render.color(0, 40, 210,255))
            render.rect_filled(7, (y / 2) + 12, 32, (y / 2) + 17,render.color(2228, 24, 28,255))
         else if mumintab_style:get() == '2' then
            render.rect_filled(7, (y / 2) + 2, 32, (y / 2) + 7,render.color(0, 0, 0, 255))
            render.rect_filled(7, (y / 2) + 7, 32, (y / 2) + 12,render.color(0, 40, 210,255))
            render.rect_filled(7, (y / 2) + 12, 32, (y / 2) + 17,render.color(2228, 24, 28))
         else if mumintab_style:get() == '3' then
            render.rect_filled(7, (y / 2) + 2, 32, (y / 2) + 7,render.color(19, 165, 216, 255))
            render.rect_filled(7, (y / 2) + 7, 32, (y / 2) + 12,render.color(0,40,210,255)) 
            render.rect_filled(7, (y / 2) + 12, 32, (y / 2) + 17,render.color(2228,24,28,255))
         else if mumintab_style:get() == '4' then
            render.rect_filled(7, (y / 2) + 2, 32, (y / 2) + 7,render.color(0, 0, 0, 255))
            render.rect_filled(7, (y / 2) + 7, 32, (y / 2) + 12,render.color(216, 200, 40,255))
            render.rect_filled(7, (y / 2) + 12, 32, (y / 2) + 17,render.color(255, 255, 255,255))
         else if mumintab_style:get() == '5' then
            render.rect_filled(7, (y / 2) + 2, 32, (y / 2) + 7,render.color(0, 0,0,255))
            render.rect_filled(7, (y / 2) + 7, 32, (y / 2) + 12,render.color(255,255,255,255))
            render.rect_filled(7, (y / 2) + 12, 32, (y / 2) + 17,render.color(255, 17, 0,255))
         end
        end
        end
        end
        end
    end
end


local screen_size = {render.get_screen_size()}

-- fonts
local verdana = render.create_font("verdana.ttf", 14, render.font_flag_shadow)

-- menu
local keybinds_cb = gui.checkbox(btab .. 'keybinds', btab, 'keybinds')
local keybinds_x = gui.slider('lua>elements b>x keybinds', 'lua>elements b', 'x keybinds', -1500, 1500)
local keybinds_y = gui.slider('lua>elements b>y keybinds', 'lua>elements b', 'y keybinds', -1500, 1500)


function animate(value, cond, max, speed, dynamic, clamp)

    -- animation speed
    speed = speed * global_vars.frametime * 20

    -- static animation
    if dynamic == false then
        if cond then
            value = value + speed
        else
            value = value - speed
        end
    
    -- dynamic animation
    else
        if cond then
            value = value + (max - value) * (speed / 100)
        else
            value = value - (0 + value) * (speed / 100)
        end
    end

    -- clamp value
    if clamp then
        if value > max then
            value = max
        elseif value < 0 then
            value = 0
        end
    end

    return value
end


function keybinds_paint_lol()

    if not keybinds_cb:get() then return end

    local pos = {keybinds_x:get(), keybinds_y:get()}

    local size_offset = 0

    local binds =
    {
        gui.get_checkbox ( "rage>aimbot>general>double tap" ):get(),
        gui.get_checkbox ( "rage>aimbot>general>hide shot" ):get(),
        gui.get_checkbox ( "rage>weapon>SSG-08>weapon>override" ):get(), -- override dmg is taken from the scout 
        gui.get_checkbox ( "rage>aimbot>general>force extra safety" ):get(), --force sp
        gui.get_checkbox('rage>anti-aim>angles>freestanding'):get(),
     --   gui.get_checkbox ( "rage>aimbot>general>headshot only" ):get(), --head only
        gui.get_checkbox ( "misc>movement>fake duck" ):get() --fd
       -- gui.get_checkbox('rage>anti-aim>angles>freestanding'):get() --freestnd
    }
    --rage>weapon>SSG-08>weapon>override

    local binds_name = 
    {
        "Doubletap",
        "Hideshots",
        "Min. Damage",
        "Force safepoint",
        "Free standing",
        "Fake duck",
       -- "Free standing",
    }

    if not binds[4] then
        if not binds[5] then
            if not binds[3] then
                if not binds[1] then
                    if not binds[6] then
                        if not binds[2] then
                            size_offset = 0
                        else
                            size_offset = 38
                        end
                    else
                        size_offset = 40
                    end
                else
                    size_offset = 41
                end
            else
                size_offset = 54
            end
        else
            size_offset = 63
        end
    else
        size_offset = 70
    end

    animated_size_offset = animate(animated_size_offset or 0, true, size_offset, 60, true, false)

    local size = {100 + animated_size_offset, 22}

    local enabled = ""
    local text_size = render.get_text_size(verdana, enabled) + 7

    local override_active = binds[3] or binds[4] or binds[5] or binds[6] or binds[7] or binds[8]
    local other_binds_active = binds[1] or binds[2] or binds[9] or binds[10] or binds[11]

    drag(keybinds_x, keybinds_y, size[1], size[2])

    alpha = animate(alpha or 0, gui.is_menu_open() or override_active or other_binds_active, 1, 0.5, false, true)

    -- glow
    for i = 1, 10 do
        render.rect_filled_rounded(pos[1] - i, pos[2] - i, pos[1] + size[1] + i, pos[2] + size[2] + i, render.color(207, 252, 3, (20 - (2 * i)) * alpha), 10)
    end

    -- top rect
    render.push_clip_rect(pos[1], pos[2], pos[1] + size[1], pos[2] + 5)
    render.rect_filled_rounded(pos[1], pos[2], pos[1] + size[1], pos[2] + size[2], render.color(186, 209, 128, 255 * alpha), 5)
    render.pop_clip_rect()

    -- bot rect
    render.push_clip_rect(pos[1], pos[2] + 17, pos[1] + size[1], pos[2] + 22)
    render.rect_filled_rounded(pos[1], pos[2], pos[1] + size[1], pos[2] + 22, render.color(186, 209, 128, 255 * alpha), 5)
    render.pop_clip_rect()

    -- other
    render.rect_filled_multicolor(pos[1], pos[2] + 5, pos[1] + size[1], pos[2] + 17, render.color(186, 209, 128, 255 * alpha), render.color(186, 209, 128, 255 * alpha), render.color(186, 209, 128, 255 * alpha), render.color(186, 209, 128, 255 * alpha))
    render.rect_filled_rounded(pos[1] + 2, pos[2] + 2, pos[1] + size[1] - 2, pos[2] + 20, render.color(24, 24, 26, 255 * alpha), 5)
    render.text(verdana, pos[1] + size[1] / 2 - render.get_text_size(verdana, "keybinds") / 2 - 1, pos[2] + 3, "keybinds", render.color(255, 255, 255, 255 * alpha))


    local bind_offset = 0
    dt_alpha = animate(dt_alpha or 0, binds[1], 1, 0.5, false, true)
    render.text(verdana, pos[1] + 6, pos[2] + size[2] + 2, binds_name[1], render.color(255, 255, 255, 255 * dt_alpha))
    render.text(verdana, pos[1] + size[1] - text_size, pos[2] + size[2] + 2, enabled, render.color(255, 255, 255, 255 * dt_alpha))
    if binds[1] then
        bind_offset = bind_offset + 15
    end

    hs_alpha = animate(hs_alpha or 0, binds[2], 1, 0.5, false, true)
    render.text(verdana, pos[1] + 6, pos[2] + size[2] + 2 + bind_offset, binds_name[2], render.color(255, 255, 255, 255 * hs_alpha))
    render.text(verdana, pos[1] + size[1] - text_size, pos[2] + size[2] + 2 + bind_offset, enabled, render.color(255, 255, 255, 255 * hs_alpha))
    if binds[2] then
        bind_offset = bind_offset + 15
    end

    dmg_alpha = animate(dmg_alpha or 0, binds[3], 1, 0.5, false, true)
    render.text(verdana, pos[1] + 6, pos[2] + size[2] + 2 + bind_offset, binds_name[3], render.color(255, 255, 255, 255 * dmg_alpha))
    render.text(verdana, pos[1] + size[1] - text_size, pos[2] + size[2] + 2 + bind_offset, enabled, render.color(255, 255, 255, 255 * dmg_alpha))
    if binds[3] then
        bind_offset = bind_offset + 15
    end

    fs_alpha = animate(fs_alpha or 0, binds[4], 1, 0.5, false, true)
    render.text(verdana, pos[1] + 6, pos[2] + size[2] + 2 + bind_offset, binds_name[4], render.color(255, 255, 255, 255 * fs_alpha))
    render.text(verdana, pos[1] + size[1] - text_size, pos[2] + size[2] + 2 + bind_offset, enabled, render.color(255, 255, 255, 255 * fs_alpha))
    if binds[4] then
        bind_offset = bind_offset + 15
    end

    ho_alpha = animate(ho_alpha or 0, binds[5], 1, 0.5, false, true)
    render.text(verdana, pos[1] + 6, pos[2] + size[2] + 2 + bind_offset, binds_name[5], render.color(255, 255, 255, 255 * ho_alpha))
    render.text(verdana, pos[1] + size[1] - text_size, pos[2] + size[2] + 2 + bind_offset, enabled, render.color(255, 255, 255, 255 * ho_alpha))
    if binds[5] then
        bind_offset = bind_offset + 15
    end

    fd_alpha = animate(fd_alpha or 0, binds[6], 1, 0.5, false, true)
    render.text(verdana, pos[1] + 6, pos[2] + size[2] + 2 + bind_offset, binds_name[6], render.color(255, 255, 255, 255 * fd_alpha))
    render.text(verdana, pos[1] + size[1] - text_size, pos[2] + size[2] + 2 + bind_offset, enabled, render.color(255, 255, 255, 255 * fd_alpha))

end




-- ON_PAINT

utils.set_clan_tag('harmonica')


function on_paint()

if slowdownindicatorkek:get() then
    on_slow()
end

if korobka_s_indicatoramu:get()=='mephedrone' then
    kek123()
end

if korobka_s_indicatoramu:get()=='mumin' then
     watermarkrender1()
end

if korobka_s_indicatoramu:get()=='halifat' then
    thehalifatindicators()
end

if korobka_s_indicatoramu:get()=='none' then
    
end

renderhitlog()

if korobka_s_markami:get()=='Brushstrike' then
    truewatermark4real()
end

if korobka_s_markami:get()=='mono' then
    truewatermark4real2()
end

if korobka_s_markami:get()=='pasted' then
    pastedwatermark()
end

if korobka_s_markami:get()=='none' then
    
end

keybinds_paint_lol()

gui_controller_from_silkroad()

end