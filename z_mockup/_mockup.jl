#using SimLynx, Distributions, JSON, Gtk, Gtk.ShortNames
using SimLynx, Distributions, JSON, Gtk, Gtk.ShortNames, Plots, Statistics

include("components.jl")

function CameraFrame(::Array{UInt8}) end

const N = 4
const verbose = true
const stochastic = false

cameras = Vector{Any}(undef,N)
processors = Vector{Any}(undef,N)

random_contrast() = rand(Uniform(-2,2))
random_brightness() = rand(Uniform(-1,1))

camera_defs = [
    ("SampleVideo_1280x720_5mb.mp4", Int(max_width/4), Int(max_height/4), :rgba, 1, 0),
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

    data = zeros(UInt8, width * height * dim)
    gray_data = zeros(UInt8, width * height)
    pixbuf = Pixbuf(data=reshape(data, (width * dim, height)), has_alpha=alph)

    canvas = GtkBox(:v)
    set_gtk_property!(canvas, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
    set_gtk_property!(canvas, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)

    status = Statusbar(); push!(status, 1, "File: $filename")
    set_gtk_property!(canvas, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
    push!(canvas, status)

    bitmap = Image(pixbuf)
    push!(canvas, bitmap)

    progress = ProgressBar()
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
            for i = 1:length(gray_data)
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
        @send process CameraFrame(data)
        n += 1
    end

    if verbose
        println("$(current_time()): Camera $(num) end of file after $(n-1) frame")
    end
end

@process processing_model(num) begin
    stats = GtkBox(:v)
    histogram = GtkBox(:v)

    set_gtk_property!(stats, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
    set_gtk_property!(stats, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)

    set_gtk_property!(histogram, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
    set_gtk_property!(histogram, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)

    grid[num,3] = stats
    grid[num,4] = histogram

    pad = GtkLabel("")

    title = GtkLabel("")
    push!(stats, pad)

    G_.markup(title,"""<u><b> Processor $(num) Statistics </b></u>""")
    push!(stats, title)


    n = GtkLabel("n: nan")
    _min = GtkLabel("min: nan")
    _max = GtkLabel("max: nan")
    _range = GtkLabel("range: nan")

    G_.justify(n, Gtk.GConstants.GtkJustification.LEFT)
    G_.justify(_min, Gtk.GConstants.GtkJustification.LEFT)
    G_.justify(_max, Gtk.GConstants.GtkJustification.LEFT)
    G_.justify(_range, Gtk.GConstants.GtkJustification.LEFT)

    push!(stats, n)
    push!(stats, _min)
    push!(stats, _max)
    push!(stats, _range)



    while(true)
        @accept caller CameraFrame(data) begin
            # dim = 3
            # frame = Array{UInt8, dim}()

            # for i = 1:Int(length(data)/dim)
            #     append!(frame, (data[i], data[i+1], data[i+2]))
            # end

            if verbose
                println("$(current_time()): Processing $(num) ($(length(data)) bytes)")
            end

            local _length::Int64 = length(data)
            local _minimum::Int64 = minimum(data)
            local _maximum::Int64 = maximum(data)

            G_.text(n, "n: $(_length)")
            G_.text(_min, "min: $(_minimum)")
            G_.text(_max, "max: $(_maximum)")
            G_.text(_range, "range: $(_maximum - _minimum)")

            showall(frame)
        end
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
            processors[i] = @schedule at 0 processing_model(i)
        end
        # decider = @schedule at 0 decision_model
        start_simulation()
    end
end

main()
