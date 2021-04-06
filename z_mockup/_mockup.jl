using SimLynx, Distributions, JSON, Gtk, Gtk.ShortNames

const N = 4
const verbose = true
const stochastic = false

cameras = Vector{Any}(undef,N)
processors = Vector{Any}(undef,N)

random_contrast() = rand(Uniform(-2,2))
random_brightness() = rand(Uniform(-1,1))

function CameraFrame(::Array{UInt8}) end

max_width, max_height = Base.displaysize()

win = Window("FISA Prototype Mock-Up", -1, -1)
hbox = GtkBox(:h)

camera_defs = [
    ("SampleVideo_1280x720_5mb.mp4", 320, 180, :rgba, 1, 0),
    ("teapot.mp4", 320, 180, :gray, 1, 0),
    ("teapot.mp4", 320, 180, :rgba, 1/2, 1/4),
    ("teapot.mp4", 320, 180, :gray, 1/4, 0),
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

    data = zeros(UInt8, width * height * 4)
    v = :rgba === type ? 4 : 3
    pixbuf = Pixbuf(data=reshape(data, (width * z, height)), has_alpha=true)

    m_box = GtkBox(:v)
    p_box = GtkBox(:v)

    push!(window, canvas)

    bitmap = Image(pixbuf)
    push!(m_box, bitmap)

    progress = ProgressBar()
    push!(canvas, progress)

    status = Statusbar(); push!(status, 1, "File: $filename")
    push!(canvas, status)


    ps, out = ffmpeg_subprocess(num, filename, type, width, height, contrast, brightness)

    n = 1
    while !eof(out)
        read!(out, data)
        G_.from_pixbuf(bitmap, pixbuf)
        set_gtk_property!(progress, :fraction, n/n_frames)
        pop!(status, 1)
        push!(status, 1, "File: $filename, frame $n")

        if verbose
            println("$(current_time()): Camera $(num) grabbing frame $(n) ($(length(data)) bytes)")
        end
        # yieldto(control_task())
        wait(1/10)

        # @send process CameraFrame(data, type)
        @send process CameraFrame(data, type)
        n += 1
    end

    if verbose
        println("$(current_time()): Camera $(num) end of file after $(n-1) frame")
    end
end

@process processing_model(num) begin
    while(true)
        @accept caller CameraFrame(data, type) begin
            if verbose
                println("$(current_time()): Processing $(num) received a $(type) frame ($(length(data)) bytes)")
            end
            # n = (type == :rgba) ? length(data)/4 : length(data)
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

showall(window)

main()

# win = GtkWindow("My First Gtk.jl Program", 400, 200)

# b = GtkButton("Click Me")
# push!(win,b)

# showall(win)

# (define frame
#   (instantiate frame%
#     ("FISA Prototype Mock-Up")
#     (style '(no-resize-border))
#     (stretchable-width #f)
#     (stretchable-height #f)))

# (define menu-bar
#   (instantiate menu-bar%
#     (frame)))

# (define file-menu
#   (instantiate menu%
#     ("&File" menu-bar)))

# (define exit-menu-item
#   (instantiate menu-item%
#     ("E&xit" file-menu)
#     (callback
#      (lambda (menu-item event)
#        (send frame show #f)))))

# (define chain-panel
#   (instantiate horizontal-panel%
#     (frame)))

# (define chain0
#   (instantiate group-box-panel%
#     ("Camera 0" chain-panel)
#     (min-width 322)))

# (define chain1
#   (instantiate group-box-panel%
#     ("Camera 1" chain-panel)
#     (min-width 322)))

# (define chain2
#   (instantiate group-box-panel%
#     ("Camera 2" chain-panel)
#     (min-width 322)))

# (define chain3
#   (instantiate group-box-panel%
#     ("Camera 3" chain-panel)
#     (min-width 322)))

# (define camera0
#   (instantiate canvas%
#     (chain0)
#     (style '(border))
#     (min-height 182)))

# (define camera1
#   (instantiate canvas%
#     (chain1)
#     (style '(border))
#     (min-height 182)))

# (define camera2
#   (instantiate canvas%
#     (chain2)
#     (style '(border))
#     (min-height 182)))

# (define camera3
#   (instantiate canvas%
#     (chain3)
#     (style '(border))
#     (min-height 182)))

# (define camera-canvases
#   (vector camera0 camera1 camera2 camera3))

# (define histogram0
#   (instantiate canvas%
#     (chain0)
#     (style '(border))
#     (min-height 258)))

# (define histogram1
#   (instantiate canvas%
#     (chain1)
#     (style '(border))
#     (min-height 258)))

# (define histogram2
#   (instantiate canvas%
#     (chain2)
#     (style '(border))
#     (min-height 258)))

# (define histogram3
#   (instantiate canvas%
#     (chain3)
#     (style '(border))
#     (min-height 258)))

# (define histogram-canvases
#   (vector histogram0 histogram1 histogram2 histogram3))

# (define statistics0
#   (instantiate editor-canvas%
#     (chain0)
#     (min-height 220)))
# (define statistics-text0 (instantiate text% ()))
# (send statistics0 set-editor statistics-text0)

# (define statistics1
#   (instantiate editor-canvas%
#     (chain1)
#     (min-height 220)))
# (define statistics-text1 (instantiate text% ()))
# (send statistics1 set-editor statistics-text1)

# (define statistics2
#   (instantiate editor-canvas%
#     (chain2)
#     (min-height 220)))
# (define statistics-text2 (instantiate text% ()))
# (send statistics2 set-editor statistics-text2)

# (define statistics3
#   (instantiate editor-canvas%
#     (chain3)
#     (min-height 220)))
# (define statistics-text3 (instantiate text% ()))
# (send statistics3 set-editor statistics-text3)

# (define statistics-canvases
#   (vector statistics0 statistics1 statistics2 statistics3))
# (define statistics-texts
#   (vector statistics-text0 statistics-text1 statistics-text2 statistics-text3))

# (define decision0
#   (instantiate canvas%
#     (chain0)
#     (style '(border))
#     (min-height 20)))

# (define decision1
#   (instantiate canvas%
#     (chain1)
#     (style '(border))
#     (min-height 20)))

# (define decision2
#   (instantiate canvas%
#     (chain2)
#     (style '(border))
#     (min-height 20)))

# (define decision3
#   (instantiate canvas%
#     (chain3)
#     (style '(border))
#     (min-height 20)))

# (define decisions-canvases
#   (vector decision0 decision1 decision2 decision3))

# (define run-button
#   (instantiate button%
#     ("Run" frame)
#     (callback (lambda (b ce) (main)))))

# (send frame show #t)
