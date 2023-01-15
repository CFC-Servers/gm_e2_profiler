local grey = Color( 175, 192, 198 )

local white = Color( 220, 220, 220 )
local blue = Color( 120, 162, 204 )

local callsHeader =      "Calls "
local timeAvgHeader =    "Time Avg "
local timeMaxHeader =    "Time Max "
local timeTotalHeader  = "Time Total "
local memMaxHeader =     "Mem Max "

local signatureHeader

local function printHeaders( longestSignature )
    signatureHeader = string.format( "%-" .. longestSignature .. "s", "Function" )

    MsgC(
        blue, signatureHeader,   grey, " | ",
        blue, callsHeader,       grey, " | ",
        blue, timeAvgHeader,     grey, " | ",
        blue, timeMaxHeader,     grey, " | ",
        blue, timeTotalHeader,   grey, " | ",
        blue, memMaxHeader,     grey, " |",
        "\n"
    )
end

local function nicetime( seconds )
    if seconds < 0.0001 then
        return string.format( "%.2f", seconds * 1000000 ) .. "us"
    elseif seconds < 0.1 then
        return string.format( "%.2f", seconds * 1000 ) .. "ms"
    else
        return string.format( "%.2f", seconds ) .. "s"
    end
end

local function nicesize( kilobytes )
    local isnegative = kilobytes < 0
    local prefix = isnegative and "-" or ""
    kilobytes = math.abs( kilobytes )

    if kilobytes < 0.1 then
        return string.format( "%s%.2f", prefix, kilobytes * 1024 ) .. "B"
    elseif kilobytes < 1024 then
        return string.format( "%s%.2f", prefix, kilobytes ) .. "KB"
    else
        return string.format( "%s%.2f", prefix, kilobytes / 1024 ) .. "MB"
    end
end

local function printRow( row )
    local function fmt( value, header )
        return string.format( "%-" .. #header .. "s", value )
    end

    MsgC(
        white,
        fmt( row.signature,              signatureHeader ), "   ",
        fmt( row.calls,                  callsHeader     ), "   ",
        fmt( nicetime( row.timeAvg ),    timeAvgHeader   ), "   ",
        fmt( nicetime( row.timeMax ),    timeMaxHeader   ), "   ",
        fmt( nicetime( row.timeTotal ),  timeMaxHeader   ), "   ",
        fmt( nicesize( row.memMax  ),    memMaxHeader    ), "   ",
        "\n"
    )
end

local function prepareData( data )
    local newData = {}

    for signature, v in pairs( data ) do
        if not v.calls then
            print( "Empty v.calls:", signature, v )
            print( "" )
        else
            if v.calls > 0 then
                v.signature = signature
                table.insert( newData, v )
            end
        end
    end

    return newData
end

local function sortData( data, sortMem )
    table.sort(
        data,
        function( a, b )
            if sortMem then
                return a.memMax > b.memMax
            else
                return a.timeAvg > b.timeAvg
            end
        end
    )
end

local function reportHighestAveragePerCount( max, sortMem )
    local copy = table.Copy( E2ProfData )
    local data = prepareData( copy )
    sortData( data, sortMem )

    local longestSignature = 0

    for _, v in ipairs( data ) do
        longestSignature = math.max( longestSignature, #v.signature )
    end

    printHeaders( longestSignature )
    for i = 1, max or 25 do
        local row = data[i]
        if not row then break end

        printRow( row )
    end
end

concommand.Add(
    "e2_profiler_report",
    function( ply, _, args )
        if IsValid( ply ) and not ply:IsSuperAdmin() then return end

        local max = tonumber( args[1] )
        local sortMem = tobool( args[2] )

        reportHighestAveragePerCount( max, sortMem )
    end
)
