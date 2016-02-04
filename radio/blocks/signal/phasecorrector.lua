local ffi = require('ffi')
local table = require('table')
local math = require('math')

local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type
local Float32Type = require('radio.types.float32').Float32Type

local PhaseCorrectorBlock = block.factory("PhaseCorrectorBlock")

function PhaseCorrectorBlock:instantiate(num_samples)
    self.num_samples = num_samples
    self.phi_moving_average = 0.0
    self.phi_state = Float32Type.vector(self.num_samples)

    self:add_type_signature({block.Input("in", ComplexFloat32Type)}, {block.Output("out", ComplexFloat32Type)})
end

ffi.cdef[[
void *memmove(void *dest, const void *src, size_t n);
]]

function PhaseCorrectorBlock:process(x)
    local out = ComplexFloat32Type.vector(x.length)

    for i = 0, x.length-1 do
        if x.data[i].real ~= 0 then
            -- Calculate angle of this sample
            local phi = x.data[i]:arg()
            -- Clamp the angle to the right quadrants
            phi = (phi < -math.pi/2) and (phi + math.pi) or phi
            phi = (phi > math.pi/2) and (phi - math.pi) or phi

            -- Pop last element of our table
            local last_phi = self.phi_state.data[self.phi_state.length-1].value
            -- Shift the state samples down
            ffi.C.memmove(self.phi_state.data[1], self.phi_state.data[0], (self.phi_state.length-1)*ffi.sizeof(self.phi_state.data[0]))
            -- Insert phi sample into state
            self.phi_state.data[0].value = phi

            -- Update the moving average
            self.phi_moving_average = self.phi_moving_average + phi/self.num_samples - last_phi/self.num_samples
        end

        -- Adjust the phase of this sample with the moving average
        out.data[i] = x.data[i] * ComplexFloat32Type(math.cos(-self.phi_moving_average), math.sin(-self.phi_moving_average))
    end

    return out
end

return {PhaseCorrectorBlock = PhaseCorrectorBlock}