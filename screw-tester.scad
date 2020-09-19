include <lib/BOSL2/std.scad>
include <lib/BOSL2/threading.scad>
include <lib/BOSL2/metric_screws.scad>
include <lib/text.scad>

/* [Hidden] */
$fs = 0.025;
$fa = $preview ? 10 : 5;
$eps = $fs/4;

module part(d=3, anchor=CENTER, spin=0, orient=TOP) {
    size = [40, 20, 10];
    pitch=get_metric_iso_coarse_thread_pitch(d);

    module _part() {
        diff("cutme")
            cuboid(size, rounding=3) {
            attach(TOP) label(str("M", d));
            left(10) {
                attach(TOP) label("SL 0.1");
                mirror_copy(BACK)
                    fwd(4) left(d-1)
                    threaded_rod($tags="cutme",
                                 d=d, pitch=pitch,
                                 l=size.z + $eps, $slop=0.1);

                right(d-1) threaded_rod($tags="cutme",
                             d=d, pitch=pitch,
                             l = size.y + $eps, $slop=0.1, orient=FRONT);

            }
            right(10) {
                attach(TOP) label("SL 0.2");
                mirror_copy(BACK)
                    fwd(4) right(d-1)
                    threaded_rod($tags="cutme",
                                 d=d, pitch=pitch,
                                 l=size.z + $eps, $slop=0.2);
                left(d-1) threaded_rod($tags="cutme",
                                        d=d, pitch=pitch,
                                        l = size.y + $eps, $slop=0.1, orient=FRONT);
            }
        }
    }

    attachable(size=size, anchor=anchor, spin=spin, orient=orient) {
        _part();
        children();
    }
}

part(d=3);

fwd(30)
part(d=2.5);
