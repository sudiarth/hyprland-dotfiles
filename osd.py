#!/usr/bin/env python3
"""Donut-style OSD indicator for volume/brightness (Wayland via GTK Layer Shell)."""

import sys
import math
import gi

gi.require_version("Gtk", "3.0")
try:
    gi.require_version("GtkLayerShell", "0.1")
    USE_LAYER_SHELL = True
except ValueError:
    USE_LAYER_SHELL = False

from gi.repository import Gtk, Gdk, GLib

if USE_LAYER_SHELL:
    from gi.repository import GtkLayerShell
import cairo

ICON = sys.argv[1] if len(sys.argv) > 1 else ""
VALUE = int(sys.argv[2]) if len(sys.argv) > 2 else 0
LABEL = sys.argv[3] if len(sys.argv) > 3 else ""

SIZE = 180
RING = 14
TIMEOUT = 1200


class DonutOSD(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_app_paintable(True)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_default_size(SIZE, SIZE)

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)

        if USE_LAYER_SHELL:
            GtkLayerShell.init_for_window(self)
            GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
            GtkLayerShell.set_exclusive_zone(self, -1)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, False)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, False)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, False)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, False)
        else:
            self.set_type_hint(Gdk.WindowTypeHint.NOTIFICATION)
            display = Gdk.Display.get_default()
            monitor = display.get_primary_monitor() or display.get_monitor(0)
            geo = monitor.get_geometry()
            self.move(
                geo.x + (geo.width - SIZE) // 2,
                geo.y + (geo.height - SIZE) // 2,
            )

        self.connect("draw", self.on_draw)
        GLib.timeout_add(TIMEOUT, Gtk.main_quit)

    def on_draw(self, widget, cr):
        cr.set_operator(cairo.OPERATOR_SOURCE)
        cr.set_source_rgba(0, 0, 0, 0)
        cr.paint()

        cx, cy = SIZE / 2, SIZE / 2
        radius = (SIZE - RING - 20) / 2

        # Background ring
        cr.set_line_width(RING)
        cr.set_source_rgba(0.95, 0.95, 0.95, 0.12)
        cr.arc(cx, cy, radius, 0, 2 * math.pi)
        cr.stroke()

        # Progress arc
        fraction = VALUE / 100.0
        start = -math.pi / 2
        end = start + 2 * math.pi * fraction
        cr.set_line_width(RING)
        cr.set_line_cap(cairo.LINE_CAP_ROUND)
        cr.set_source_rgba(0.95, 0.95, 0.95, 0.85)
        if fraction > 0:
            cr.arc(cx, cy, radius, start, end)
            cr.stroke()

        # Icon + text stacked vertically, centered as a unit
        cr.set_source_rgba(0.95, 0.95, 0.95, 0.9)

        cr.select_font_face(
            "FontAwesome", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL
        )
        cr.set_font_size(28)
        icon_ext = cr.text_extents(ICON)

        cr.select_font_face(
            "Poppins", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL
        )
        cr.set_font_size(14)
        text = LABEL if LABEL else f"{VALUE}%"
        text_ext = cr.text_extents(text)

        gap = 8
        total_h = icon_ext.height + gap + text_ext.height
        top_y = cy - total_h / 2

        # Draw icon
        cr.select_font_face(
            "FontAwesome", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL
        )
        cr.set_font_size(28)
        cr.move_to(
            cx - icon_ext.width / 2 - icon_ext.x_bearing,
            top_y - icon_ext.y_bearing,
        )
        cr.show_text(ICON)

        # Draw value text
        cr.select_font_face(
            "Poppins", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL
        )
        cr.set_font_size(14)
        cr.move_to(
            cx - text_ext.width / 2 - text_ext.x_bearing,
            top_y + icon_ext.height + gap - text_ext.y_bearing,
        )
        cr.show_text(text)

        return False


win = DonutOSD()
win.show_all()
Gtk.main()
