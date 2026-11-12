#version 440
// Dark-mode icon: white parts of the icon become darkColor, everything else keeps its colours.
// So white symbols on coloured tiles (Telegram's plane, Discord's logo, Steam's) turn dark, and
// white tiles (Brave, VSCodium) turn dark with their coloured logo on top.
// Icons on a near-black tile (e.g. a terminal) are left alone: their white symbol would disappear.
// keepWhite (per icon): white that's enclosed by the logo (no straight white path to the icon's
// edge), like the face of Brave's lion, stays white. (Not the default: white background enclosed
// by a logo, e.g. between VSCodium's branches, looks the same to the shader.)
//
// Anti-aliased edges: an edge pixel is a blend of white and the colour next to it, c = mix(T, white, a).
// Blending with white raises the lowest channel linearly, so a = (min(c) - min(T)) / (min(W) - min(T)),
// with T = the least-white colour nearby and W = the white nearby (often off-white). Only that white
// share is swapped for darkColor, so edges stay smooth instead of being cut at a threshold.
//
// Compile after editing:
//   /usr/lib/qt6/bin/qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o dark_icon.frag.qsb dark_icon.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 darkColor;     // Theme.desktop_icon_dark_color
    float keepWhite;    // 1: keep white enclosed by the logo (see above)
    float rimStrength;  // 0..1: light bevel along the edge (Theme.dark_icon_rim), 0 = none
};

layout(binding = 1) uniform sampler2D source;

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }
float chroma(vec3 c) { return max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b)); }
float minc(vec3 c) { return min(c.r, min(c.g, c.b)); }
vec3 unpremul(vec4 p) { return p.a > 0.0 ? p.rgb / p.a : vec3(0.0); }

// is there a straight path of white from uv to the icon's edge (checked in 16 directions)?
bool reachesEdge(vec2 uv) {
    for (int d = 0; d < 16; d++) {
        float ang = float(d) * 0.3926991;
        vec2 dir = vec2(cos(ang), sin(ang));
        bool clear = true;
        for (int k = 1; k <= 40; k++) {
            vec2 q = uv + dir * (float(k) * 0.02);
            if (q.x < 0.0 || q.y < 0.0 || q.x > 1.0 || q.y > 1.0) break;
            vec4 s = texture(source, q);
            if (s.a < 0.5) break;                            // left the icon: reached the edge
            if (minc(unpremul(s)) < 0.55) { clear = false; break; }   // blocked by the logo (pale tints pass)
        }
        if (clear) return true;
    }
    return false;
}

void main() {
    vec4 p = texture(source, qt_TexCoord0);
    vec3 c = unpremul(p);

    // near-black, colourless tile (from the middle of each edge): leave the icon as it is
    vec2 pts[4] = vec2[4](vec2(0.5, 0.13), vec2(0.5, 0.87), vec2(0.13, 0.5), vec2(0.87, 0.5));
    float tl = 0.0, tc = 0.0, n = 0.0;
    for (int i = 0; i < 4; i++) {
        vec4 q = texture(source, pts[i]);
        if (q.a > 0.9) { vec3 u = unpremul(q); tl += luma(u); tc += chroma(u); n += 1.0; }
    }
    if (n > 0.0 && tl / n < 0.25 && tc / n < 0.12) {
        fragColor = p * qt_Opacity;
        return;
    }

    // nearby (two rings of samples): tMin = the least-white colour's lowest channel,
    // wMax = the white's level (icons' "white" is often off-white, e.g. 0.96)
    float tMin = minc(c), wMax = minc(c);
    for (int ring = 1; ring <= 2; ring++) {
        float r = 0.045 * float(ring);
        for (int k = 0; k < 12; k++) {
            float ang = float(k) * 0.5235988;
            vec4 q = texture(source, qt_TexCoord0 + r * vec2(cos(ang), sin(ang)));
            if (q.a > 0.9) { float m = minc(unpremul(q)); tMin = min(tMin, m); wMax = max(wMax, m); }
        }
    }
    wMax = max(wMax, 0.75);

    // white share of this pixel
    // (blended between "uniform area: white or not" and the edge estimate, so there's no seam
    // where one takes over from the other)
    float aFlat = smoothstep(0.7, 0.85, minc(c));
    float aEdge = clamp((minc(c) - tMin) / max(wMax - tMin, 0.001), 0.0, 1.0);
    float a = mix(aFlat, aEdge, smoothstep(0.10, 0.30, wMax - tMin));
    a = max(a - 0.08, 0.0) / 0.92;          // ignore tiny shares (lighter parts of gradient tiles)
    a *= smoothstep(0.55, 0.75, wMax);      // no white around at all: nothing to darken
    if (keepWhite > 0.5 && a > 0.0 && !reachesEdge(qt_TexCoord0)) a = 0.0;

    // the icon's outer rim: icon themes often give it a light grey lip (e.g. along the bottom),
    // which isn't white enough to count above and would stay as a light line. Light, colourless
    // pixels in a thin band along the edge go dark too.
    float edgeA = min(min(texture(source, qt_TexCoord0 + vec2(0.03, 0.0)).a, texture(source, qt_TexCoord0 - vec2(0.03, 0.0)).a),
                      min(texture(source, qt_TexCoord0 + vec2(0.0, 0.03)).a, texture(source, qt_TexCoord0 - vec2(0.0, 0.03)).a));
    float rim = (1.0 - smoothstep(0.3, 0.9, edgeA)) * smoothstep(0.45, 0.7, minc(c)) * (1.0 - smoothstep(0.15, 0.3, chroma(c)));
    a = max(a, rim);

    // swap the white share for darkColor: c = T + a (W - T)  ->  T + a (dark - T).
    // W tends to the pixel itself as a -> 1, so fully white pixels land exactly on darkColor
    // (whatever the tile's own off-white shading), with no lighter halo next to the glyph
    vec3 W = mix(vec3(wMax), c, a * a);
    vec3 rgb = clamp(c - a * (W - darkColor.rgb), 0.0, 1.0);

    // bevel: a thin light rim along the icon's outer edge (same as colored_icon.frag), brightest at
    // the top-left and bottom-right corners, fading along the edges to nothing at the top-right and
    // bottom-left. Same thickness all the way round (measured straight outward).
    vec2 gsum = vec2(0.0);
    for (int k = 0; k < 8; k++) {
        float ang = float(k) * 0.7853982;
        vec2 dir = vec2(cos(ang), sin(ang));
        gsum += dir * texture(source, qt_TexCoord0 + dir * 0.02).a;
    }
    if (rimStrength > 0.0 && dot(gsum, gsum) > 1e-4) {
        vec2 n = normalize(-gsum);                                    // points out of the shape
        float onEdge = 0.6 * (1.0 - smoothstep(0.3, 0.95, texture(source, qt_TexCoord0 + n * 0.012).a))
                     + 0.4 * (1.0 - smoothstep(0.3, 0.95, texture(source, qt_TexCoord0 + n * 0.025).a));
        float s = qt_TexCoord0.x + qt_TexCoord0.y;                    // 0 top left .. 2 bottom right
        float light = max(1.0 - smoothstep(0.25, 1.05, s), 1.0 - smoothstep(0.25, 1.05, 2.0 - s));
        rgb = mix(rgb, vec3(1.0), rimStrength * onEdge * light);
    }

    fragColor = vec4(rgb, 1.0) * p.a * qt_Opacity;
}
