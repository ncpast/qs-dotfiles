#version 440
// Coloured-logo icon (iOS dark mode style): every icon's tile becomes darkColor (with a subtle
// gradient), and the logo shows in colour on it.
//   - coloured tile (e.g. Steam, Telegram, Discord, Spotify): a white / light-tinted / grey / black
//     logo takes the original tile's colours, as they were at each spot (so a gradient tile gives
//     a gradient logo), brightened by `lift` so they show on the dark tile; coloured logo parts
//     keep theirs. A two-tone tile (different hues, e.g. CS2's orange + navy) gives a one-colour
//     logo in its most colourful tile colour instead.
//   - white tile (e.g. Brave, VSCodium): the logo keeps its colours; all white goes dark, unless
//     keepWhite is set: then only white that reaches the icon's edge counts as tile, so white
//     details enclosed by the logo (Brave's face) stay white.
//   - dark tile (e.g. a terminal): the logo is left as it is.
// The dark tile gets a thin light bevel along its edge (`rim`), like the icon theme's dark icons.
// Icons without a full tile (e.g. a folder shape) are left as they are.
//
// The tile's colours are sampled just inside the icon's edge (any colour seen at 3+ points, so
// gradient and two-tone tiles work; same as tinted_icon.frag).
//
// Compile after editing:
//   /usr/lib/qt6/bin/qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o colored_icon.frag.qsb colored_icon.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 darkColor;     // Theme.desktop_icon_dark_color
    float keepWhite;    // 1: keep white enclosed by the logo (see above)
    float lift;         // 0..1: how much the logo's colours are brightened (hue / saturation kept)
    float highlight;    // 0..1: strength of the glossy white band across the logo (0 = none)
    float rim;          // 0..1: strength of the light bevel along the tile's edge (0 = none)
};

layout(binding = 1) uniform sampler2D source;

const int N = 10;

vec4 unpremul(vec4 c) { return c.a > 0.0 ? vec4(c.rgb / c.a, c.a) : vec4(0.0); }
float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }
float chroma(vec3 c) { return max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b)); }

// hue in turns (0..1)
float hue(vec3 c) {
    float mx = max(c.r, max(c.g, c.b)), mn = min(c.r, min(c.g, c.b)), d = mx - mn;
    if (d < 1e-5) return 0.0;
    float h = mx == c.r ? mod((c.g - c.b) / d, 6.0) : mx == c.g ? (c.b - c.r) / d + 2.0 : (c.r - c.g) / d + 4.0;
    return h / 6.0;
}
float hueDist(float a, float b) { float d = abs(a - b); return min(d, 1.0 - d); }

// tile colours (seen at 3+ sample points); count = how many
void tileColours(out vec3 cols[N], out vec2 colPts[N], out int count, out int opaque) {
    // ~13% in from the edges: still on the tile for icons with transparent padding around it
    // (common, ~6-10%), and inside the rounded corners
    vec2 pts[N] = vec2[N](vec2(0.25, 0.14), vec2(0.50, 0.13), vec2(0.75, 0.14),
                          vec2(0.25, 0.86), vec2(0.50, 0.87), vec2(0.75, 0.86),
                          vec2(0.13, 0.35), vec2(0.13, 0.65), vec2(0.87, 0.35), vec2(0.87, 0.65));
    vec4 s[N];
    opaque = 0;
    for (int i = 0; i < N; i++) {
        s[i] = unpremul(texture(source, pts[i]));
        if (s[i].a > 0.9) opaque++;
    }
    count = 0;
    for (int i = 0; i < N; i++) {
        cols[i] = vec3(0.0);
        colPts[i] = vec2(0.0);
        if (s[i].a <= 0.9) continue;
        int support = 0;
        for (int j = 0; j < N; j++)
            if (j != i && s[j].a > 0.9 && distance(s[i].rgb, s[j].rgb) < 0.18) support++;
        if (support >= 2) { cols[count] = s[i].rgb; colPts[count] = pts[i]; count++; }
    }
}

// distance from c to the nearest tile colour; nearest = that colour
float nearestTile(vec3 c, vec3 cols[N], int count, out vec3 nearest) {
    float dmin = 1e9;
    nearest = vec3(0.0);
    for (int i = 0; i < N; i++) {
        if (i >= count) break;
        float d = distance(c, cols[i]);
        if (d < dmin) { dmin = d; nearest = cols[i]; }
    }
    return dmin;
}

// lowest alpha around uv at distance r, in 8 directions (how close the shape's edge is)
float minAlpha(vec2 uv, float r) {
    float m = 1.0;
    for (int k = 0; k < 8; k++) {
        float ang = float(k) * 0.7853982;
        m = min(m, texture(source, uv + r * vec2(cos(ang), sin(ang))).a);
    }
    return m;
}

// the original tile's colour at uv: the tile colours, weighted by how close they were sampled,
// with some of the saturation lost by averaging different hues put back (else e.g. orange + blue
// would average to grey)
vec3 tileAt(vec2 uv, vec3 cols[N], vec2 colPts[N], int count) {
    vec3 sum = vec3(0.0);
    float wsum = 0.0, satSum = 0.0;
    for (int i = 0; i < N; i++) {
        if (i >= count) break;
        vec2 dv = uv - colPts[i];
        float d2 = dot(dv, dv);
        float w = 1.0 / (d2 + 0.01);
        float mx = max(cols[i].r, max(cols[i].g, cols[i].b));
        sum += cols[i] * w;
        satSum += (mx > 0.0 ? chroma(cols[i]) / mx : 0.0) * w;
        wsum += w;
    }
    vec3 avg = sum / max(wsum, 1e-6);
    float mx = max(avg.r, max(avg.g, avg.b));
    float sat = mx > 0.0 ? chroma(avg) / mx : 0.0;
    float want = satSum / max(wsum, 1e-6);
    // scale the distance from the brightest channel to get back the wanted saturation
    // (capped: where the average is nearly grey its hue means little, and boosting it hard
    // turns the blend between two opposite colours into a garish seam)
    return sat > 0.001 ? vec3(mx) - (vec3(mx) - avg) * clamp(want / sat, 1.0, 1.5) : avg;
}

// does this (tile-coloured) pixel reach the icon's edge in a straight line through tile colour?
// (false for white enclosed by the logo, like the face of Brave's lion)
bool reachesEdge(vec2 uv, vec3 cols[N], int count) {
    vec3 n;
    for (int d = 0; d < 16; d++) {                             // 16 directions, so gaps between
        float a = float(d) * 0.3926991;                        // logo parts that open at an angle
        vec2 dir = vec2(cos(a), sin(a));                       // are found too
        bool clear = true;
        for (int k = 1; k <= 40; k++) {
            vec2 p = uv + dir * (float(k) * 0.02);
            if (p.x < 0.0 || p.y < 0.0 || p.x > 1.0 || p.y > 1.0) break;
            vec4 q = unpremul(texture(source, p));
            if (q.a < 0.5) break;                                  // left the icon: reached the edge
            if (nearestTile(q.rgb, cols, count, n) > 0.25) { clear = false; break; }
        }
        if (clear) return true;
    }
    return false;
}

void main() {
    vec3 cols[N];
    vec2 colPts[N];
    int count, opaque;
    tileColours(cols, colPts, count, opaque);

    vec4 c = unpremul(texture(source, qt_TexCoord0));
    if (opaque < 8 || count == 0) {                     // no full tile: leave as is
        fragColor = vec4(c.rgb, 1.0) * c.a * qt_Opacity;
        return;
    }

    // what kind of tile: white / dark / coloured (by its most colourful tile colour)
    vec3 accent = cols[0];
    float lsum = 0.0;
    for (int i = 0; i < N; i++) {
        if (i >= count) break;
        lsum += luma(cols[i]);
        if (chroma(cols[i]) > chroma(accent)) accent = cols[i];
    }
    float tileL = lsum / float(count);

    // two-tone tile (clearly different hues, e.g. CS2's orange + navy) vs. shades of one hue
    // (e.g. Steam's light-to-deep blue): only the latter gives a gradient logo; blending two
    // different hues across the logo looks muddy, so a two-tone tile's logo takes one colour
    bool twoTone = false;
    for (int i = 0; i < N; i++) {
        if (i >= count || chroma(cols[i]) < 0.15) continue;
        for (int j = i + 1; j < N; j++) {
            if (j >= count || chroma(cols[j]) < 0.15) continue;
            if (hueDist(hue(cols[i]), hue(cols[j])) > 0.15) twoTone = true;   // > 54 degrees apart
        }
    }
    bool whiteTile = tileL > 0.82 && chroma(accent) < 0.12;
    bool darkTile  = tileL < 0.22 && chroma(accent) < 0.20;

    // how much this pixel is tile
    vec3 nearest;
    float d = nearestTile(c.rgb, cols, count, nearest);
    float tile = 1.0 - smoothstep(0.10, 0.25, d);
    // a thin band along the icon's outer edge is always tile: icons often have a slightly
    // different coloured / soft border there, which would otherwise show as a thin outline
    float edgeBand = 1.0 - smoothstep(0.3, 0.9, minAlpha(qt_TexCoord0, 0.03));
    tile = max(tile, edgeBand);
    if (whiteTile && keepWhite > 0.5 && tile > 0.0 && !reachesEdge(qt_TexCoord0, cols, count)) tile = 0.0;

    // tile -> dark, with a subtle top-to-bottom gradient (the original's own shading isn't kept:
    // gradient tiles would come out banded)
    vec3 dark = clamp(darkColor.rgb + (0.5 - qt_TexCoord0.y) * 0.05, 0.0, 1.0);

    vec3 rgb;
    if (!whiteTile && !darkTile) {
        // Coloured tile. The logo's anti-aliased edge pixels are blends of logo and tile, so
        // instead of deciding per pixel (which looks choppy), measure how much of each pixel is
        // white / black logo: blending with white raises the lowest channel, with black lowers the
        // highest, in proportion. That share becomes the logo colour, the rest dark tile.
        vec3 T = tileAt(qt_TexCoord0, cols, colPts, count);         // the original tile here
        float mT = min(T.r, min(T.g, T.b)), MT = max(T.r, max(T.g, T.b));
        float aW = clamp((min(c.r, min(c.g, c.b)) - mT) / max(0.97 - mT, 0.05), 0.0, 1.0);
        float aB = clamp((MT - max(c.r, max(c.g, c.b))) / max(MT - 0.03, 0.05), 0.0, 1.0);
        // black logo only where it's near black (else darker parts of a gradient tile, e.g. the
        // bottom of Steam's, would count as logo)
        aB *= 1.0 - smoothstep(0.10, 0.22, max(c.r, max(c.g, c.b)));
        float wb = max(max(aW, aB) - 0.06, 0.0) / 0.94;           // ignore tiny shares (gradients)
        // logo parts in some other colour keep it
        float other = clamp((1.0 - tile) - wb, 0.0, 1.0);
        wb *= 1.0 - edgeBand;
        other *= 1.0 - edgeBand;
        float sum = wb + other;
        if (sum > 1.0) { wb /= sum; other /= sum; }

        // the logo's colour: the original tile's colour here (a gradient tile gives a gradient
        // logo; a two-tone tile one colour), brightened by `lift` keeping hue and saturation
        vec3 base = twoTone ? accent : T;
        float m = max(base.r, max(base.g, base.b));
        vec3 col = base / max(m, 0.001) * mix(m, 0.95, lift);
        // glossy highlight: a soft horizontal white band through the middle, from the centre left
        // to the centre right, fading out above and below
        float band = abs(qt_TexCoord0.y - 0.5);
        col = mix(col, vec3(1.0), highlight * exp(-pow(band / 0.16, 2.0)));

        rgb = dark * (1.0 - wb - other) + col * wb + c.rgb * other;
    } else {
        // white tile: the logo keeps its colours; dark tile: as it is (tile -> darkColor)
        rgb = mix(c.rgb, dark, tile);
    }

    // bevel: a thin light rim along the icon's outer edge, like the icon theme's own dark icons
    // (e.g. a terminal / Telegram): brightest at the top-left and bottom-right corners (equally),
    // fading along the edges to about half by their middle and to nothing at the top-right and
    // bottom-left corners. The line keeps the same thickness all the way round; only its opacity
    // changes.
    //   - outward direction of the edge: from the alpha gradient (8 directions, smooth)
    //   - thickness: alpha measured straight outward from the pixel (so convex corners don't get a
    //     thicker band), at two distances for a soft inward fade
    //   - strength: by position, distance from the top-left / bottom-right corner along x + y
    vec2 gsum = vec2(0.0);
    for (int k = 0; k < 8; k++) {
        float ang = float(k) * 0.7853982;
        vec2 dir = vec2(cos(ang), sin(ang));
        gsum += dir * texture(source, qt_TexCoord0 + dir * 0.02).a;
    }
    if (dot(gsum, gsum) > 1e-4) {
        vec2 n = normalize(-gsum);                                    // points out of the shape
        float onEdge = 0.6 * (1.0 - smoothstep(0.3, 0.95, texture(source, qt_TexCoord0 + n * 0.012).a))
                     + 0.4 * (1.0 - smoothstep(0.3, 0.95, texture(source, qt_TexCoord0 + n * 0.025).a));
        float s = qt_TexCoord0.x + qt_TexCoord0.y;                    // 0 top left .. 2 bottom right
        float light = max(1.0 - smoothstep(0.25, 1.05, s), 1.0 - smoothstep(0.25, 1.05, 2.0 - s));
        rgb = mix(rgb, vec3(1.0), rim * onEdge * light);
    }

    fragColor = vec4(rgb, 1.0) * c.a * qt_Opacity;
}
