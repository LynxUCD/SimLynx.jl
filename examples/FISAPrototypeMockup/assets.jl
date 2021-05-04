#------------ BEGIN UI variables ------------------
max_width = 1500
max_height = 1080
#------------ END UI variables ---------------------


#------------ BEGIN Main Window Assets -------------
window = GtkWindow("FISA Prototype Mock-Up", max_width, max_height)
set_gtk_property!(window, :accept_focus, true)
set_gtk_property!(window, :expand, true)

layout = GtkGrid()
set_gtk_property!(layout, :expand, true)
set_gtk_property!(layout, :column_homogeneous, true)

showall(window)

push!(window, layout)
#------------ END Main Window Assets ---------------

#------------ BEGIN Camera Model Assets -------------
box1 = GtkBox(:v)
set_gtk_property!(box1, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
set_gtk_property!(box1, :valign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
layout[1,1:2] = box1

box2 = GtkBox(:v)
set_gtk_property!(box2, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
set_gtk_property!(box2, :valign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
layout[2,1:2] = box2

box3 = GtkBox(:v)
set_gtk_property!(box3, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
set_gtk_property!(box3, :valign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
layout[3,1:2] = box3

box4 = GtkBox(:v)
set_gtk_property!(box4, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
set_gtk_property!(box4, :valign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
layout[4,1:2] = box4
camera_canvasen = [box1, box2, box3, box4]
#------------ END Camera Model Assets --------------

#------------ BEGIN Processor Model Assets ---------
# -------------------------STATS--------------------
stats1 = GtkBox(:v)
# set_gtk_property!(stats1, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
# set_gtk_property!(stats1, :valign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
pad = GtkLabel(""); push!(stats1, pad)
pad = GtkLabel(""); push!(stats1, pad)
layout[1,3] = stats1

stats2 = GtkBox(:v)
# set_gtk_property!(stats2, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
# set_gtk_property!(stats2, :valign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
pad = GtkLabel(""); push!(stats2, pad)
pad = GtkLabel(""); push!(stats2, pad)
layout[2,3] = stats2

stats3 = GtkBox(:v)
# set_gtk_property!(stats3, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
# set_gtk_property!(stats3, :valign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
pad = GtkLabel(""); push!(stats3, pad)
pad = GtkLabel(""); push!(stats3, pad)
layout[3,3] = stats3

stats4 = GtkBox(:v)
# set_gtk_property!(stats4, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
# set_gtk_property!(stats4, :valign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
pad = GtkLabel(""); push!(stats4, pad)
pad = GtkLabel(""); push!(stats4, pad)
layout[4,3] = stats4

camera_statsen = [stats1, stats2, stats3, stats4]
# -----------------------HISTOGRAM------------------
histogram1 = GtkCanvas(350,256)
set_gtk_property!(histogram1, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
set_gtk_property!(histogram1, :valign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
layout[1,4] = histogram1

histogram2 = GtkCanvas(350,256)
set_gtk_property!(histogram2, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
set_gtk_property!(histogram2, :valign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
layout[2,4] = histogram2

histogram3 = GtkCanvas(350,256)
set_gtk_property!(histogram3, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
set_gtk_property!(histogram3, :valign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
layout[3,4] = histogram3

histogram4 = GtkCanvas(350,256)
set_gtk_property!(histogram4, :halign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
set_gtk_property!(histogram4, :valign, Gtk.GConstants.GtkAlign.GTK_ALIGN_START)
layout[4,4] = histogram4

camera_histogramen = [histogram1, histogram2, histogram3, histogram4]
#------------ END Processor Model Assets -----------

#------------ BEGIN Decision Model Assets ----------
bar1 = GtkCanvas(5,5)
layout[1,7] = bar1

bar2 = GtkCanvas(5,5)
layout[2,7] = bar2

bar3 = GtkCanvas(5,5)
layout[3,7] = bar3

bar4 = GtkCanvas(5,5)
layout[4,7] = bar4
decision_canvasen = [bar1, bar2, bar3, bar4]
#------------ END Decision Model Assets ------------
