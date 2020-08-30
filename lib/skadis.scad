// uses commit 63164b35ad7f8b1b79efffca33a2e0e1c77fd45d
include <BOSL2/std.scad>

pegboardThickness = 5;
pegHoleThickness = 5;

defaultPegTolerance = 0.2;
defaultRounding = 1.5;
defaultPegAngle = 67.5;
shape = 1; // [0: cuboid, 1: cylinder]

module negativeChamfer(id, amount) {
    rounding = -amount;

    // Negative chamfers seem to need to be larger for round cuboids than
    // cylinders
    if (shape == 0) {
        size = (id - amount) * [1, 1, 1];
        back(size.y/2)
            // negative chamfers on a cuboid can only can be on the top or
            // bottom, so we gotta rotate it after
            xrot(90)
                cuboid(size, rounding=rounding, edges=TOP);
    } else if (shape == 1) {
        size = id * [1, 0.5, 1];
        back(size.y / 2)
            xrot(180)
                pegShape(size, rounding=rounding/2, roundFront=false);
    }
}

module pegShape(size, anchor=CENTER, rounding=0, roundFront=true) {
    if (shape == 0) {
        roundEdges = edges("ALL", except=roundFront ? [] : FRONT);
        cuboid(size, anchor=anchor, rounding=rounding, edges=roundEdges);
    } else if (shape == 1) {
        // This is just a ycyl with rounding
        rounding1 = roundFront ? rounding : undef;
        cyl(d=size.x, l=size.y, anchor=rot(from=BACK, to=UP, p=anchor), orient=BACK, rounding2=rounding, rounding1=rounding1);
    }
}

// Creates a hook peg centered at origin, going out the y-axis (and the hookgoes
// down the z-access)
module hookPeg(pegTolerance=defaultPegTolerance,
               pegAngle=defaultPegAngle,
               backLength=10,
               rounding=defaultRounding) {
    t = pegHoleThickness - pegTolerance;

    angle = 90 - pegAngle;

    // Calculate offset to make sure we get pegboardThickness where the two
    // pieces meet. See trig-math-off-set-corner-rectangle.svg for calculation
    yOff = angle == 0 ? 0 :
        (t - rounding) * (1 - cos(angle) + sin(angle) - tan(angle) * (sin(angle) + cos(angle) - 1));

    depth = pegboardThickness + pegTolerance + t - yOff;

    module cutPeg(anchor) {
        intersection() {
            fwd(t - yOff)
                xrot(-pegAngle / 2)
                cuboid((t+2) * [2, 2, 2], anchor=anchor);
            children(0);
        }
    }
    back(depth) down(t/2)
        union() {
        // Horizontal part
        cutPeg(anchor=BACK)
            pegShape([t, depth, t],
                     anchor=BACK+BOTTOM,
                     rounding=rounding, roundFront=false);

        // Back peg part
        cutPeg(anchor=FRONT)
            up(t-rounding)
            fwd(rounding)
            xrot(-pegAngle) // rotate around top front sphere
            fwd(rounding)
            up(rounding)
            pegShape([t, backLength, t],
                     rounding=rounding, anchor=TOP+FRONT);
    }
    negativeChamfer(t, rounding);
}

module straightPeg(pegTolerance=defaultPegTolerance, rounding=defaultRounding) {
    pegHoleThickness = 5;
    t = pegHoleThickness - pegTolerance;
    depth = pegboardThickness;
    union() {
        pegShape([t, depth, t],
               anchor=FRONT,
               rounding=rounding, roundFront=false);

        negativeChamfer(t, rounding);
    }
}
