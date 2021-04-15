#------------ BEGIN UI variables --------------
max_width = 1500
max_height = 1080

cameras = Vector{Any}(undef,N)
processors = Vector{Any}(undef,N)
#------------ END UI variables --------------

#------------ BEGIN Main Window Assets --------------
frame = GtkWindow("FISA Prototype Mock-Up", max_width, max_height)
set_gtk_property!(frame, :accept_focus, true)
set_gtk_property!(frame, :expand, true)

grid = GtkGrid()
set_gtk_property!(grid, :expand, true)
set_gtk_property!(grid, :column_homogeneous, true)

showall(frame)

push!(frame, grid)
#------------ END Main Window Assets --------------

#------------ BEGIN Camera Model Assets --------------
box1 = GtkBox(:v)
set_gtk_property!(box1, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)

box2 = GtkBox(:v)
set_gtk_property!(box2, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)

box3 = GtkBox(:v)
set_gtk_property!(box3, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)

box4 = GtkBox(:v)
set_gtk_property!(box4, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)

push!(cameras, box1, box2, box3, box4)
#------------ END Camera Model Assets --------------

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
