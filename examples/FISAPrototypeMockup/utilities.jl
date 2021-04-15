import Distributions.Uniform

function rgb_to_gray(r::UInt8, g::UInt8, b::UInt8)::UInt8
    round(UInt8, 0.2126f0r + 0.7152f0g + 0.0722f0b)
end

random_contrast() = rand(Uniform(-2,2))
random_brightness() = rand(Uniform(-1,1))
