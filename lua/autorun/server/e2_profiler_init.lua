local unpack = unpack
local rawset = rawset
local SysTime = SysTime
local collectgarbage = collectgarbage

local enabled = CreateConVar( "e2_profiler_enabled", "0", FCVAR_ARCHIVE + FCVAR_PROTECTED, "Enable E2 profiler" )

E2ProfOriginals = E2ProfOriginals or {}
local originals = E2ProfOriginals

E2ProfData = {}
local data = E2ProfData

local start, rets, elapsed, memStart, mem
local function makeProfiler( signature, func )
    rawset( data, signature, {
        calls = 0,
        timeTotal = 0,
        timeAvg = 0,
        timeMax = 0,
        memMax = 0
    } )

    local signatureData = rawget( data, signature )

    local calls = 0
    local timeTotal = 0
    local timeMax = 0
    local memMax = 0

    return function( self, ... )
        memStart = collectgarbage( "count" )
        start = SysTime()

        rets = { func( self, ... ) }

        elapsed = SysTime() - start
        mem = math.max( collectgarbage( "count" ) - memStart, 0 )

        calls = calls + 1
        timeTotal = timeTotal + elapsed

        rawset( signatureData, "calls", calls )
        rawset( signatureData, "timeTotal", timeTotal )
        rawset( signatureData, "timeAvg", timeTotal / calls )

        if elapsed > timeMax then
            timeMax = elapsed
            rawset( signatureData, "timeMax", timeMax )
        end

        if mem > memMax then
            memMax = mem
            rawset( signatureData, "memMax", memMax )
        end

        return unpack( rets )
    end
end

local function enable()
    for signature, funcData in pairs( wire_expression2_funcs ) do
        local oldFunc = funcData[3]
        originals[signature] = originals[signature] or oldFunc
        wire_expression2_funcs[signature][3] = makeProfiler( signature, oldFunc )
    end

    print( "E2 profiler enabled!" )
end

local function disable()
    for signature in pairs( wire_expression2_funcs ) do
        wire_expression2_funcs[signature][3] = originals[signature]
    end

    print( "E2 profiler disabled!" )
end

hook.Add( "Initialize", "E2Profiler", function()
    cvars.AddChangeCallback( "e2_profiler_enabled", function( _, _, new )
        if new == "1" then
            enable()
        else
            disable()
        end
    end, "enable_callback" )

    if enabled:GetBool() then
        enable()
    end
end )

include( "e2_profiler/server/commands.lua" )
