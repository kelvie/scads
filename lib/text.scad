// I use the same parameters enough to make a lib for this

include <BOSL2/std.scad>
default_thickness = 0.4;
default_height = 2;
default_font="Noto Sans:style=Bold";

$fs=0.025;

module label(text, t=default_thickness, h=default_height, font=default_font,
             orient=TOP, anchor=BOTTOM, spin=0) {
    size = [100, h, t];
    attachable(size=size, orient=orient, anchor=anchor, spin=spin) {
        down(t/2) linear_extrude(t)
            text(font=font, text=text, size=h, halign="center", valign="center");
        children();
    }
}

module cut_text(text, t=default_thickness, h=default_height) {
    difference() {
        children(0);
        addText(text, t, h);
    }
}

// TODO: remove these
module addText(text, t=default_thickness, h=default_height, font=default_font) {
    label(text, t, h, font);
}

module cutText(text, t=default_thickness, h=default_height) {
    cut_text(text, t, h)
        children(0);
}
