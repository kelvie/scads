// Everything is mm

// Edge of top and sides
edgeOffset = 6;

// Extra size for the bottom edge
edgeExtraBottom = 2;


module keyboard() {
    edgeOffsetBottom = edgeOffset + edgeExtraBottom;

    // Measured numbers

    // Single key height and width
    keyHeight = 20;
    keyWidth = 20;

    // The main part of the keyboard
    letterKeysWidth = 285;
    letterKeysHeight = 95.32;

    // vertical space between letter keys and f keys
    letterKeysFKeysSpacing = 8;

    // space between esc key and F1
    escKeySpaceRight = 18;
    escKeySpaceLeft = 6.2 - 6;

    // Width of the 4 f keys
    fourFKeysWidth = 76.5;

    fKeysSpacing = 8.5;

    fKeysPrtScSpacing = 4.61;

    prtScTripletWidth = 58;

    // Spacing between the letters and the InsDel group
    lettersInsDelSpacing = 4.26;

    insDelWidth = prtScTripletWidth;
    insDelHeight = 39;

    lettersArrowKeysSpacing = 4.34;
    lettersUpArrowSpacing = 23;
    upArrowWidth = 20;

    // includes up arrow
    arrowKeysHeight = 39;

    // Actually closer to 57.5, but lets be consistent? or are bottom rows different?
    bottomArrowsWidth = insDelWidth;

    // left to right
    totalWidth = edgeOffset + letterKeysWidth + lettersArrowKeysSpacing +
        bottomArrowsWidth + edgeOffset;
    // bottom up
    totalHeight = edgeOffsetBottom + letterKeysHeight + letterKeysFKeysSpacing
        + keyHeight + edgeOffset;

    difference() {
        xLeft = edgeOffset;
        yBottom = edgeOffsetBottom;

        square([totalWidth, totalHeight]);
        // letter keys

        translate([xLeft, yBottom])
            square([letterKeysWidth, letterKeysHeight]);

        xRightOfLetters = xLeft + letterKeysWidth;

        // bottom row arrow keys
        translate([xRightOfLetters + lettersArrowKeysSpacing, yBottom])
            square([bottomArrowsWidth, keyHeight]);

        // up and down arrows
        translate([xRightOfLetters + lettersUpArrowSpacing, yBottom])
            square([upArrowWidth, arrowKeysHeight]);


        // Insert/Delete/Home/End/etc
        // Align top of this box with the top of the letter keys
        translate([xRightOfLetters + lettersInsDelSpacing, yBottom + letterKeysHeight - insDelHeight])
            square([insDelWidth, insDelHeight]);

        yFKeysRow = yBottom + letterKeysHeight + letterKeysFKeysSpacing;

        // Esc Key
        translate([xLeft + escKeySpaceLeft, yFKeysRow])
            square([keyWidth, keyHeight]);

        xFKeyStart = xLeft + escKeySpaceLeft + keyWidth + escKeySpaceRight;

        // F1-F4
        for (i=[0:2])
            translate([xFKeyStart + i*(fKeysSpacing+fourFKeysWidth), yFKeysRow])
                square([fourFKeysWidth, keyHeight]);

        xPrtScr = xFKeyStart + 2*(fKeysSpacing+fourFKeysWidth) + fourFKeysWidth + fKeysPrtScSpacing;
        echo(xPrtScr);
        translate([xPrtScr, yFKeysRow])
            square([prtScTripletWidth, keyHeight]);
    }

}

keyboard();
