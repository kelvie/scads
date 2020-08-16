// I use the same parameters enough to make a lib for this

include <BOSL2/std.scad>
defaultThickness = 0.4;
defaultHeight = 2;
defaultFont="Noto Sans";


module addText(text, t=defaultThickness, h=defaultHeight, font=defaultFont) {
    down(t - 0.01)
        linear_extrude(t) text(font=font, text=text, size=h, halign="center", valign="center");
}

module cutText(text, t=defaultThickness, h=defaultHeight) {
    difference() {
        children(0);
        addText(text, t, h);
    }
}
