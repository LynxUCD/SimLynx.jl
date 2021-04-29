using SimLynx, JSON, Gtk, Gtk.ShortNames, Plots, Statistics, StatsBase

include("assets.jl")
include("utilities.jl")

const N = 4
const verbose = false
const stochastic = false

cameras = Vector{Any}(undef,N)
processors = Vector{Any}(undef,N)

camera_canvasen = [box1, box2, box3, box4]
processor_canvasen = Vector{Any}(undef,N)



camera_defs = [
    ("DashcamFootage1.mp4", Int(max_width/4), Int(max_height/4), :rgba, 1, 0),
    ("DashcamFootage2.mp4", Int(max_width/4), Int(max_height/4), :gray, 1, 0),
    ("DashcamFootage3.mp4", Int(max_width/4), Int(max_height/4), :rgba, 1/2, 1/4),
    ("DashcamFootage4.mp4", Int(max_width/4), Int(max_height/4), :gray, 1/4, 0),
]

function ffmpeg_subprocess(num, filename, type, width, height, contrast, brightness)
    out = Pipe()
    ps = run(pipeline(`ffmpeg -i $(filename) -f image2pipe -vcodec rawvideo -s $(width)x$(height) -vf eq=contrast=$(contrast):brightness=$(brightness) -pix_fmt $(type) -`,
                      stdout=out, stderr="ffmpeg_stderr[$(num)].txt"),
             wait=false)
    close(out.in)
    return ps, out
end

function count_frames(filename)
    out = Pipe()
    ps = run(pipeline(`ffprobe -i $(filename) -print_format json -loglevel fatal -show_streams -count_frames -select_streams v`,
                      stdout=out, stderr="ffprobe_stderr.txt"),
             wait=true)
    json = JSON.parse(out)
    close(out)
    return parse(Int64, first(json["streams"])["nb_read_frames"])
end

@process camera_model(num, filename, width, height, type, contrast, brightness) begin
    local process = processors[num]
    local canvas = camera_canvasen[num]

    if stochastic
        contrast = random_contrast()
        brightness = random_brightness()
    end

    dim = :rgba === type ? 4 : 3
    alph = :rgba === type ? true : false

    n_frames = count_frames(filename)

    local data::Array{UInt8,1} = zeros(UInt8, width * height * dim)
    local gray_data::Array{UInt8,1} = zeros(UInt8, width * height)
    pixbuf = Pixbuf(data=reshape(data, (width * dim, height)), has_alpha=alph)

    status = GtkStatusbar(); push!(status, 1, "File: $filename")
    push!(canvas, status)

    bitmap = GtkImage(pixbuf)
    push!(canvas, bitmap)

    progress = GtkProgressBar()
    push!(canvas, progress)

    showall(window)

    ps, out = ffmpeg_subprocess(num, filename, type, width, height, contrast, brightness)

    n = 1
    while !eof(out)
        if type === :rgba
            read!(out, data)
        else
            read!(out, gray_data)
            for i = 1:length(gray_data)  # This could be faster
                data[(i-1)*3+1] = gray_data[i]
                data[(i-1)*3+2] = gray_data[i]
                data[(i-1)*3+3] = gray_data[i]
            end
        end
        G_.from_pixbuf(bitmap, pixbuf)
        set_gtk_property!(progress, :fraction, n/n_frames)
        pop!(status, 1)
        push!(status, 1, "File: $filename, frame $n")

        if verbose
            println("$(current_time()): Camera $(num) grabbing frame $(n) ($(length(data)) bytes)")
        end
        # yieldto(control_task())
        wait(1/10)
        @send process CameraFrame(data, type, width, height)
        n += 1
    end

    if verbose
        println("$(current_time()): Camera $(num) end of file after $(n-1) frame")
    end
end

@process processing_model(num) begin
    stats = GtkBox(:v)
    histogram = GtkCanvas(350,256)

    layout[num,3] = stats
    layout[num,4] = histogram


    pad = GtkLabel(""); push!(stats, pad)
    pad = GtkLabel(""); push!(stats, pad)



    title = GtkLabel(""); G_.markup(title,"""<u><b> Processor $(num) Statistics </b></u>""")
    push!(stats, title)


    count_text = GtkLabel("Pixel Count: nan"); push!(stats, count_text)
    min_text = GtkLabel("min: nan"); push!(stats, min_text)
    max_text = GtkLabel("max: nan"); push!(stats, max_text)
    range_text = GtkLabel("range: nan"); push!(stats, range_text)

    local frequency_arr::Array{Int64} = Array{Int64}(undef,256)
    local data::Array{UInt8}
    local type::Symbol
    local _width::Int64
    local _height::Int64
    local _mean::Float64
    local _variance::Float64
    local _kurtosis::Float64
    local _min::Int64
    local _max::Int64

    while(true)
        @accept caller CameraFrame(_data::Array{UInt8}, _type::Symbol, width::Int64, height::Int64) begin
            if verbose
                println("$(current_time()): Processing $(num) ($(length(data)) bytes)")
            end
            data   = _data
            type   = _type
            _width  = width
            _height = height
        end

        _min = minimum(data)
        _max = maximum(data)
        # _mean, _variance = StatsBase.mean_and_var(data)
        # _kurtosis = StatsBase.kurtosis(data, _mean)

        G_.text(count_text, "n: $(length(data))")
        G_.text(min_text, "min: $(_min)")
        G_.text(max_text, "max: $(_max)")
        G_.text(range_text, "range: $(_max - _min)")

        if type === :rgba
            rgba_data = reshape(data, (4, _width * _height))
            gray_rgb_data = zeros(UInt8, (3, _width * _height))
            gray_data = zeros(UInt8, _width * _height)
            gray_data .= rgb_to_gray.(rgba_data[1, :], rgba_data[2, :], rgba_data[3, :])
            # Convert RGB to grayscale
            gray_rgb_data[1, :] .= gray_data
            gray_rgb_data[2, :] .= gray_data
            gray_rgb_data[3, :] .= gray_data
            data = reshape(gray_rgb_data, (3, _width, _height))
        end
        frequency_arr = []
        for i = 0:255
            _c = count(==(i), data)
            push!(frequency_arr, _c)
        end

        # @send process Threat_Level(num, min, max, _kurtosis)

        @guarded draw(histogram) do widget
            ctx = getgc(histogram)
            h1 = height(histogram)
            w1 = width(histogram)

            local _max::Int64 = maximum(frequency_arr)

            # Workaround because we can't clear what's drawn on a canvas. As far as we know, yet
            rectangle(ctx, 0, 0, w1, h1)
            set_source_rgb(ctx, 255, 255, 255)
            fill(ctx)

            set_source_rgb(ctx, 0, 0, 0)
            for i = 1:255
                local _w::Float64 = frequency_arr[i] / _max
                local _h::Float64 = h1/255
                move_to(ctx, 0, i)
                line_to(ctx, w1 * _w, i)
                Graphics.stroke(ctx)
            end
        end
        showall(window)
        sleep(0.0001)
    end
end

# @process decision_model(num) begin
#     local num::Int64
#     local min::Int64
#     local max::Int64
#     local kurtosis::Float64

#     while(true)
#         @accept caller Threat_Level(_num, _min, _max, _kurtosis) begin
#             if verbose
#                 println("$(current_time()): Processing $(num) ($(length(data)) bytes)")
#             end
#             _num, _min, _max, _kurtosis
#         end

#         @guarded draw(_bar) do widget
#             ctx = getgc(_bar)
#             h = height(_bar)
#             w = width(_bar)
#             # Paint red or green rectangle
#             rectangle(ctx, 0, 0, w, h)
#             _red = (maxi - mini) < 64 ? 1 : 0
#             _green = (maxi - mini) < 64 ? 0 : 1
#             set_source_rgb(ctx, _red, _green, 0)
#             fill(ctx)
#         end
#     end
# end

function main()
    println("FISA Prototype Mock-Up")

    f_version = run(`ffmpeg -version`)
    if occursin("not found", string(f_version))
        throw(ErrorException("ffmpeg executable not found"))
    end
    println(f_version)

    @simulation begin
        for (i, def) in enumerate(camera_defs)
            cameras[i] = @schedule at i*10 camera_model(i, def...)
            processors[i] = @schedule at 0 processing_model(i)
        end
        # decider = @schedule at 0 decision_model
        start_simulation()
    end
end

main()
