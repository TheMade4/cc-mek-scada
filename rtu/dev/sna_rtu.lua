local rtu = require("rtu.rtu")

local sna_rtu = {}

-- create new solar neutron activator (sna) device
---@param sna table
function sna_rtu.new(sna)
    local unit = rtu.init_unit()

    -- discrete inputs --
    -- none

    -- coils --
    -- none

    -- input registers --
    -- build properties
    unit.connect_input_reg(sna.getInputCapacity)
    unit.connect_input_reg(sna.getOutputCapacity)
    -- current state
    unit.connect_input_reg(sna.getProductionRate)
    unit.connect_input_reg(sna.getPeakProductionRate)
    -- tanks
    unit.connect_input_reg(sna.getInput)
    unit.connect_input_reg(sna.getInputNeeded)
    unit.connect_input_reg(sna.getInputFilledPercentage)
    unit.connect_input_reg(sna.getOutput)
    unit.connect_input_reg(sna.getOutputNeeded)
    unit.connect_input_reg(sna.getOutputFilledPercentage)

    -- holding registers --
    -- none

    return unit.interface()
end

return sna_rtu
