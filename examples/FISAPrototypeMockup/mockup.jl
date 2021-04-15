using SimLynx, JSON, Gtk, Gtk.ShortNames, Plots, Statistics

include("assets.jl")
include("utilities.jl")

const N = 4
const verbose = false
const stochastic = false

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
    if stochastic
        contrast = random_contrast()
        brightness = random_brightness()
    end

    process = processors[num]

    n_frames = count_frames(filename)

    dim = :rgba === type ? 4 : 3
    alph = :rgba === type ? true : false

    local data::Array{UInt8,1} = zeros(UInt8, width * height * dim)
    local gray_data::Array{UInt8,1} = zeros(UInt8, width * height)
    pixbuf = GtkPixbuf(data=reshape(data, (width * dim, height)), has_alpha=alph)

    canvas = columns[num]
    status = GtkStatusbar(); push!(status, 1, "File: $filename")
    set_gtk_property!(canvas, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
    push!(canvas, status)

    bitmap = GtkImage(pixbuf)
    push!(canvas, bitmap)

    progress = GtkProgressBar()
    push!(canvas, progress)

    grid[num,1:2] = canvas

    showall(frame)

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
        @send process CameraFrame(data, type)
        n += 1
    end

    if verbose
        println("$(current_time()): Camera $(num) end of file after $(n-1) frame")
    end
end

@process processing_model(num, _width, _height) begin
    stats = GtkBox(:v)
    _histogram = GtkBox(:v)

    #set_gtk_property!(stats, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
    #set_gtk_property!(stats, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)

    #set_gtk_property!(_histogram, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
    #set_gtk_property!(_histogram, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)

    grid[num,3] = stats
    grid[num,4] = _histogram

    pad = GtkLabel("")
    pad2 = GtkLabel("")

    title = GtkLabel("")
    push!(stats, pad)
    push!(_histogram, pad2)

    G_.markup(title,"""<u><b> Processor $(num) Statistics </b></u>""")
    push!(stats, title)


    n = GtkLabel("n: nan")
    _min = GtkLabel("min: nan")
    _max = GtkLabel("max: nan")
    _range = GtkLabel("range: nan")
    _pixelGraph = GtkCanvas(350,256)
    _bar = GtkCanvas(5,5)


    #G_.justify(n, Gtk.GConstants.GtkJustification.LEFT)
    #G_.justify(_min, Gtk.GConstants.GtkJustification.LEFT)
    #G_.justify(_max, Gtk.GConstants.GtkJustification.LEFT)
    #G_.justify(_range, Gtk.GConstants.GtkJustification.LEFT)

    push!(stats, n)
    push!(stats, _min)
    push!(stats, _max)
    push!(stats, _range)
    grid[num, 5] = _pixelGraph
    grid[num, 6] = _bar
    #push!(_histogram, _pixelGraph)



    while(true)
        local data = nothing
        local type = nothing
        @accept caller CameraFrame(_data, _type) begin
            data = _data
            type = _type
        end

            if verbose
                println("$(current_time()): Processing $(num) ($(length(data)) bytes)")
            end

            mini = minimum(data)
            maxi = maximum(data)
            G_.text(n, "n: $(length(data))")
            G_.text(_min, "min: $(mini)")
            G_.text(_max, "max: $(maxi)")
            G_.text(_range, "range: $(maxi - mini)")
            frequency_arr = []

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

            for i = 0:255
                _c = count(==(i), data)
                push!(frequency_arr, _c)
            end

            @guarded draw(_pixelGraph) do widget
                ctx = getgc(_pixelGraph)
                h1 = height(_pixelGraph)
                w1 = width(_pixelGraph)

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

            @guarded draw(_bar) do widget
                ctx = getgc(_bar)
                h = height(_bar)
                w = width(_bar)
                # Paint red or green rectangle
                rectangle(ctx, 0, 0, w, h)
                _red = (maxi - mini) < 64 ? 1 : 0
                _green = (maxi - mini) < 64 ? 0 : 1
                set_source_rgb(ctx, _red, _green, 0)
                fill(ctx)
            end

            showall(frame)
        work(rand(0:4))
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
            # (vector-set! cameras i (schedule #:at (* 10 i) (camera-model i file-name width height type alpha beta)))
            println(def...)
            cameras[i] = @schedule at i*10 camera_model(i, def...)
            processors[i] = @schedule at 0 processing_model(i, def[2], def[3])  #def[2] and def[3] and weidth and height in that order
        end
        # decider = @schedule at 0 decision_model
        start_simulation()
    end
end

main()
