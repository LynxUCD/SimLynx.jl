using SimLynx, JSON, Gtk, Gtk.ShortNames, Plots, Statistics

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
    ("monster.mp4", Int(max_width/4), Int(max_height/4), :rgba, 1, 0),
    ("teapot.mp4", Int(max_width/4), Int(max_height/4), :gray, 1, 0),
    ("teapot.mp4", Int(max_width/4), Int(max_height/4), :rgba, 1/2, 1/4),
    ("teapot.mp4", Int(max_width/4), Int(max_height/4), :gray, 1/4, 0),
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
    histogram = GtkBox(:v)

    #set_gtk_property!(stats, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
    #set_gtk_property!(stats, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)

    #set_gtk_property!(_histogram, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
    #set_gtk_property!(_histogram, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)

    layout[num,3] = stats
    layout[num,4] = histogram

    pad = GtkLabel("")
    pad2 = GtkLabel("")

    title = GtkLabel("")
    push!(stats, pad)
    push!(histogram, pad2)

    G_.markup(title,"""<u><b> Processor $(num) Statistics </b></u>""")
    push!(stats, title)


    count_text = GtkLabel("Pixel Count: nan")
    min_text = GtkLabel("min: nan")
    max_text = GtkLabel("max: nan")
    range_text = GtkLabel("range: nan")
    histogram = GtkCanvas(350,256)
    # _bar = GtkCanvas(5,5)

    push!(stats, count_text)
    push!(stats, min_text)
    push!(stats, max_text)
    push!(stats, range_text)
    # layout[num, 6] = _bar
    #push!(_histogram, _pixelGraph)

    while(true)
        local data::Vector{UInt8}
        local frequency_arr::Array{UInt8,1}
        local type::Symbol
        local width::Int64
        local height::Int64

        @accept caller CameraFrame(_data::Vector{UInt8}, _type::Symbol, _width::Int64, _height::Int64) begin
            if verbose
                println("$(current_time()): Processing $(num) ($(length(data)) bytes)")
            end

            data   = _data
            type   = _type
            width  = _width
            height = _height
        end

        min = minimum(data)
        max = maximum(data)
        G_.text(count_text, "n: $(length(data))")
        G_.text(min_text, "min: $(min)")
        G_.text(max_text, "max: $(max)")
        G_.text(range_text, "range: $(max - min)")

        if type === :rgba
            rgba_data = reshape(data, (4, width * height))
            gray_rgb_data = zeros(UInt8, (3, width * height))
            gray_data = zeros(UInt8, width * height)
            gray_data .= rgb_to_gray.(rgba_data[1, :], rgba_data[2, :], rgba_data[3, :])
            # Convert RGB to grayscale
            gray_rgb_data[1, :] .= gray_data
            gray_rgb_data[2, :] .= gray_data
            gray_rgb_data[3, :] .= gray_data
            data = reshape(gray_rgb_data, (3, width, height))
        end

        for i = 0:255
            _c = count(==(i), data)
            push!(frequency_arr, _c)
        end

        @guarded draw(histogram) do widget
            ctx = getgc(histogram)
            h1 = height(histogram)
            w1 = width(histogram)

            local _max::Float64 = maximum(frequency_arr)
            local _len::Int64 = length(frequency_arr)

            # Workaround because we can't clear what's drawn on a canvas. As far as we know, yet
            rectangle(ctx, 0, 0, w1, h1)
            set_source_rgb(ctx, 255, 255, 255)
            fill(ctx)

            set_source_rgb(ctx, 0, 0, 0)
            for i = 1:_len
                local _w::Float64 = frequency_arr[i] / _max
                local _h::Float64 = h1/_len
                move_to(ctx, 0, i)
                line_to(ctx, w1 * _w, i)
                Graphics.stroke(ctx)    # Need to specify Graphics. or else @guarded does not have stroke defined
            end
        end

        # @guarded draw(_bar) do widget
        #     ctx = getgc(_bar)
        #     h = height(_bar)
        #     w = width(_bar)
        #     # Paint red or green rectangle
        #     rectangle(ctx, 0, 0, w, h)
        #     _red = (maxi - mini) < 64 ? 1 : 0
        #     _green = (maxi - mini) < 64 ? 0 : 1
        #     set_source_rgb(ctx, _red, _green, 0)
        #     fill(ctx)
        # end

        showall(window)
    end
end

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
            processors[i] = @schedule at 0 processing_model(i, def[2], def[3])  #def[2] and def[3] and weidth and height in that order
        end
        # decider = @schedule at 0 decision_model
        start_simulation()
    end
end

main()
