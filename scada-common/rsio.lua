--
-- Redstone I/O
--

local util = require("scada-common.util")

local rsio = {}

----------------------
-- RS I/O CONSTANTS --
----------------------

---@alias IO_LVL integer
local IO_LVL = {
    LOW = 0,
    HIGH = 1,
    DISCONNECT = -1 -- use for RTU session to indicate this RTU is not connected to this channel
}

---@alias IO_DIR integer
local IO_DIR = {
    IN = 0,
    OUT = 1
}

---@alias IO_MODE integer
local IO_MODE = {
    DIGITAL_IN = 0,
    DIGITAL_OUT = 1,
    ANALOG_IN = 2,
    ANALOG_OUT = 3
}

---@alias RS_IO integer
local RS_IO = {
    -- digital inputs --

    -- facility
    F_SCRAM       = 1,  -- active low, facility-wide scram

    -- reactor
    R_SCRAM       = 2,  -- active low, reactor scram
    R_ENABLE      = 3,  -- active high, reactor enable

    -- digital outputs --

    -- facility
    F_ALARM       = 4,  -- active high, facility safety alarm

    -- waste
    WASTE_PO      = 5,  -- active low, polonium routing
    WASTE_PU      = 6,  -- active low, plutonium routing
    WASTE_AM      = 7,  -- active low, antimatter routing

    -- reactor
    R_ALARM       = 8,  -- active high, reactor safety alarm
    R_SCRAMMED    = 9,  -- active high, if the reactor is scrammed
    R_AUTO_SCRAM  = 10, -- active high, if the reactor was automatically scrammed
    R_ACTIVE      = 11, -- active high, if the reactor is active
    R_AUTO_CTRL   = 12, -- active high, if the reactor burn rate is automatic
    R_DMG_CRIT    = 13, -- active high, if the reactor damage is critical
    R_HIGH_TEMP   = 14, -- active high, if the reactor is at a high temperature
    R_NO_COOLANT  = 15, -- active high, if the reactor has no coolant
    R_EXCESS_HC   = 16, -- active high, if the reactor has excess heated coolant
    R_EXCESS_WS   = 17, -- active high, if the reactor has excess waste
    R_INSUFF_FUEL = 18, -- active high, if the reactor has insufficent fuel
    R_PLC_FAULT   = 19, -- active high, if the reactor PLC reports a device access fault
    R_PLC_TIMEOUT = 20  -- active high, if the reactor PLC has not been heard from
}

rsio.IO_LVL = IO_LVL
rsio.IO_DIR = IO_DIR
rsio.IO_MODE = IO_MODE
rsio.IO = RS_IO

-----------------------
-- UTILITY FUNCTIONS --
-----------------------

-- channel to string
---@param channel RS_IO
function rsio.to_string(channel)
    local names = {
        "F_SCRAM",
        "R_SCRAM",
        "R_ENABLE",
        "F_ALARM",
        "WASTE_PO",
        "WASTE_PU",
        "WASTE_AM",
        "R_ALARM",
        "R_SCRAMMED",
        "R_AUTO_SCRAM",
        "R_ACTIVE",
        "R_AUTO_CTRL",
        "R_DMG_CRIT",
        "R_HIGH_TEMP",
        "R_NO_COOLANT",
        "R_EXCESS_HC",
        "R_EXCESS_WS",
        "R_INSUFF_FUEL",
        "R_PLC_FAULT",
        "R_PLC_TIMEOUT"
    }

    if util.is_int(channel) and channel > 0 and channel <= #names then
        return names[channel]
    else
        return ""
    end
end

local _B_AND = bit.band

local function _ACTIVE_HIGH(level) return level == IO_LVL.HIGH end
local function _ACTIVE_LOW(level) return level == IO_LVL.LOW end

-- I/O mappings to I/O function and I/O mode
local RS_DIO_MAP = {
    -- F_SCRAM
    { _f = _ACTIVE_LOW,  mode = IO_DIR.IN },
    -- R_SCRAM
    { _f = _ACTIVE_LOW,  mode = IO_DIR.IN },
    -- R_ENABLE
    { _f = _ACTIVE_HIGH, mode = IO_DIR.IN },
    -- F_ALARM
    { _f = _ACTIVE_HIGH, mode = IO_DIR.OUT },
    -- WASTE_PO
    { _f = _ACTIVE_LOW,  mode = IO_DIR.OUT },
    -- WASTE_PU
    { _f = _ACTIVE_LOW,  mode = IO_DIR.OUT },
    -- WASTE_AM
    { _f = _ACTIVE_LOW,  mode = IO_DIR.OUT },
    -- R_ALARM
    { _f = _ACTIVE_HIGH, mode = IO_DIR.OUT },
    -- R_SCRAMMED
    { _f = _ACTIVE_HIGH, mode = IO_DIR.OUT },
    -- R_AUTO_SCRAM
    { _f = _ACTIVE_HIGH, mode = IO_DIR.OUT },
    -- R_ACTIVE
    { _f = _ACTIVE_HIGH, mode = IO_DIR.OUT },
    -- R_AUTO_CTRL
    { _f = _ACTIVE_HIGH, mode = IO_DIR.OUT },
    -- R_DMG_CRIT
    { _f = _ACTIVE_HIGH, mode = IO_DIR.OUT },
    -- R_HIGH_TEMP
    { _f = _ACTIVE_HIGH, mode = IO_DIR.OUT },
    -- R_NO_COOLANT
    { _f = _ACTIVE_HIGH, mode = IO_DIR.OUT },
    -- R_EXCESS_HC
    { _f = _ACTIVE_HIGH, mode = IO_DIR.OUT },
    -- R_EXCESS_WS
    { _f = _ACTIVE_HIGH, mode = IO_DIR.OUT },
    -- R_INSUFF_FUEL
    { _f = _ACTIVE_HIGH, mode = IO_DIR.OUT },
    -- R_PLC_FAULT
    { _f = _ACTIVE_HIGH, mode = IO_DIR.OUT },
    -- R_PLC_TIMEOUT
    { _f = _ACTIVE_HIGH, mode = IO_DIR.OUT }
}

-- get the mode of a channel
---@param channel RS_IO
---@return IO_MODE
function rsio.get_io_mode(channel)
    local modes = {
        IO_MODE.DIGITAL_IN,     -- F_SCRAM
        IO_MODE.DIGITAL_IN,     -- R_SCRAM
        IO_MODE.DIGITAL_IN,     -- R_ENABLE
        IO_MODE.DIGITAL_OUT,    -- F_ALARM
        IO_MODE.DIGITAL_OUT,    -- WASTE_PO
        IO_MODE.DIGITAL_OUT,    -- WASTE_PU
        IO_MODE.DIGITAL_OUT,    -- WASTE_AM
        IO_MODE.DIGITAL_OUT,    -- R_ALARM
        IO_MODE.DIGITAL_OUT,    -- R_SCRAMMED
        IO_MODE.DIGITAL_OUT,    -- R_AUTO_SCRAM
        IO_MODE.DIGITAL_OUT,    -- R_ACTIVE
        IO_MODE.DIGITAL_OUT,    -- R_AUTO_CTRL
        IO_MODE.DIGITAL_OUT,    -- R_DMG_CRIT
        IO_MODE.DIGITAL_OUT,    -- R_HIGH_TEMP
        IO_MODE.DIGITAL_OUT,    -- R_NO_COOLANT
        IO_MODE.DIGITAL_OUT,    -- R_EXCESS_HC
        IO_MODE.DIGITAL_OUT,    -- R_EXCESS_WS
        IO_MODE.DIGITAL_OUT,    -- R_INSUFF_FUEL
        IO_MODE.DIGITAL_OUT,    -- R_PLC_FAULT
        IO_MODE.DIGITAL_OUT     -- R_PLC_TIMEOUT
    }

    if util.is_int(channel) and channel > 0 and channel <= #modes then
        return modes[channel]
    else
        return IO_MODE.ANALOG_IN
    end
end

--------------------
-- GENERIC CHECKS --
--------------------

local RS_SIDES = rs.getSides()

-- check if a channel is valid
---@param channel RS_IO
---@return boolean valid
function rsio.is_valid_channel(channel)
    return util.is_int(channel) and (channel > 0) and (channel <= RS_IO.R_PLC_TIMEOUT)
end

-- check if a side is valid
---@param side string
---@return boolean valid
function rsio.is_valid_side(side)
    if side ~= nil then
        for i = 0, #RS_SIDES do
            if RS_SIDES[i] == side then return true end
        end
    end
    return false
end

-- check if a color is a valid single color
---@param color integer
---@return boolean valid
function rsio.is_color(color)
    return util.is_int(color) and (color > 0) and (_B_AND(color, (color - 1)) == 0)
end

-----------------
-- DIGITAL I/O --
-----------------

-- get digital IO level reading
---@param rs_value boolean
---@return IO_LVL
function rsio.digital_read(rs_value)
    if rs_value then
        return IO_LVL.HIGH
    else
        return IO_LVL.LOW
    end
end

-- returns the level corresponding to active
---@param channel RS_IO
---@param level IO_LVL
---@return boolean
function rsio.digital_write(channel, level)
    if (not util.is_int(channel)) or (channel < RS_IO.F_ALARM) or (channel > RS_IO.R_PLC_TIMEOUT) then
        return false
    else
        return RS_DIO_MAP[channel]._f(level)
    end
end

-- returns true if the level corresponds to active
---@param channel RS_IO
---@param level IO_LVL
---@return boolean
function rsio.digital_is_active(channel, level)
    if (not util.is_int(channel)) or (channel > RS_IO.R_ENABLE) then
        return false
    else
        return RS_DIO_MAP[channel]._f(level)
    end
end

----------------
-- ANALOG I/O --
----------------

-- read an analog value scaled from min to max
---@param rs_value number redstone reading (0 to 15)
---@param min number minimum of range
---@param max number maximum of range
---@return number value scaled reading (min to max)
function rsio.analog_read(rs_value, min, max)
    local value = rs_value / 15
    return (value * (max - min)) + min
end

-- write an analog value from the provided scale range
---@param value number value to write (from min to max range)
---@param min number minimum of range
---@param max number maximum of range
---@return number rs_value scaled redstone reading (0 to 15)
function rsio.analog_write(value, min, max)
    local scaled_value = (value - min) / (max - min)
    return scaled_value * 15
end

return rsio
