local radio = require('radio')

if #arg < 1 then
    io.stderr:write("Usage: " .. arg[0] .. " <FM radio frequency>\n")
    os.exit(1)
end

local frequency = tonumber(arg[1])
local offset = -600e3

local top = radio.CompositeBlock()
local b0 = radio.RtlSdrSource(frequency + offset, 2048000)
local b1 = radio.TunerBlock(offset, 190e3, 10)
local b2 = radio.FrequencyDiscriminatorBlock(6.0)
local b3 = radio.FMDeemphasisFilterBlock(75e-6)
local b4 = radio.DecimatorBlock(4)
local b5 = radio.PulseAudioSink()

local p1 = radio.GnuplotSpectrumSink(2048, 'Demodulated FM Spectrum')

top:connect(b0, b1, b2, b3, b4, b5)
top:connect(b2, p1)
top:run()