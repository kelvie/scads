// uses commit 63164b35ad7f8b1b79efffca33a2e0e1c77fd45d
include <BOSL2/std.scad>

pegboardThickness = 5;
pegHoleThickness = 5;

// Creates a hook peg centered at origin, going out the y-axis (and the hookgoes
// down the z-access)
module hookPeg(pegTolerance=0.1, pegAngle=80, backLength=10, rounding=1.6) {

    // TODO: add chamfer to connect


    t = pegHoleThickness - pegTolerance;

    angle = 90 - pegAngle;
    // Calculate offset to make sure we get pegboardThickness where the two
    // pieces meet. See trig-math-off-set-corner-rectangle.svg for calculation
    yOff = angle == 0 ? 0 :
        (t - rounding) * (1 - cos(angle) + sin(angle) - tan(angle) * (sin(angle) + cos(angle) - 1));

    depth = pegboardThickness + t - yOff;
    back(depth) down(t/2)
        union() {
            // Horizontal part
            cuboid([t, depth, t],
                   anchor=BACK+BOTTOM,
                   rounding=rounding, edges=edges("ALL", except=FRONT));
            // Back peg part
            up(t-rounding)
                fwd(rounding)
                xrot(-pegAngle) // rotate around top front sphere
                fwd(rounding)
                up(rounding)
                cuboid([t, backLength, t],
                       rounding=rounding, anchor=TOP+FRONT);
        }
}

module straightPeg(pegTolerance=0.1, rounding=1.6) {
    pegHoleThickness = 5;
    t = pegHoleThickness - pegTolerance;
    depth = pegboardThickness;
    cuboid([t, depth, t],
           anchor=FRONT,
           rounding=rounding, edges=edges("ALL", except=FRONT));
}
