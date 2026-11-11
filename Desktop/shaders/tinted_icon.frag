#version 440
// iOS-style tinted icon: every icon becomes a dark, translucent accent tile with a bright accent
// glyph on it, whatever its original colours.
//
// The tile's colours are sampled just inside the icon's edge (any colour seen at 3+ points, so
// gradient and two-tone tiles work); pixels that differ from all of them are the glyph. Icons
// without a full tile (e.g. a folder shape) are treated as all glyph.
//
// Compile after editing:
//   /usr/lib/qt6/bin/qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o tinted_icon.frag.qsb tinted_icon.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 tint;          // Theme.accent
    float tileOpacity;  // how solid the dark tile is (the glass shows through the rest)
    float gloss;        // strength of the sheen across the top
    float glyphScale;   // < 1 shrinks the glyph towards the centre (for glyphs that run off the tile)
};

layout(binding = 1) uniform sampler2D source;

vec4 unpremul(vec4 c) { return c.a > 0.0 ? vec4(c.rgb / c.a, c.a) : vec4(0.0); }

void main() {
    // --- the tile's colours: samples just inside the edge. A colour counts as tile if it shows
    //     up at 3+ of the sample points, so two-tone and gradient tiles are fully covered, while a
    //     glyph that merely touches the edge (one or two points) still counts as glyph.
    const int N = 10;
    vec2 pts[N] = vec2[N](vec2(0.22, 0.10), vec2(0.50, 0.08), vec2(0.78, 0.10),
                          vec2(0.22, 0.90), vec2(0.50, 0.92), vec2(0.78, 0.90),
                          vec2(0.08, 0.35), vec2(0.08, 0.65), vec2(0.92, 0.35), vec2(0.92, 0.65));
    vec4 s[N];
    int opaque = 0;
    for (int i = 0; i < N; i++) {
        s[i] = unpremul(texture(source, pts[i]));
        if (s[i].a > 0.9) opaque++;
    }
    // no full tile (e.g. a folder shape): the whole shape is glyph
    bool hasTile = opaque >= 8;

    // --- this pixel. The tile keeps the icon's own shape (c); the glyph is read from a point
    //     scaled out from the centre (g), so glyphScale < 1 draws it smaller, inside the tile.
    vec4 c = unpremul(texture(source, qt_TexCoord0));
    float glyph = 1.0;
    if (hasTile) {
        vec2 guv = 0.5 + (qt_TexCoord0 - 0.5) / glyphScale;
        bool inside = all(greaterThanEqual(guv, vec2(0.0))) && all(lessThanEqual(guv, vec2(1.0)));
        vec4 g = inside ? unpremul(texture(source, guv)) : vec4(0.0);
        // glyph amount = how far it is from the nearest tile colour
        float dmin = 1e9;
        for (int i = 0; i < N; i++) {
            if (s[i].a <= 0.9) continue;
            int support = 0;
            for (int j = 0; j < N; j++)
                if (j != i && s[j].a > 0.9 && distance(s[i].rgb, s[j].rgb) < 0.18) support++;
            if (support >= 2) dmin = min(dmin, distance(g.rgb, s[i].rgb));
        }
        // only where the scaled icon is opaque: its soft outer edge would otherwise show as a
        // faint outline when shrunk
        glyph = dmin < 1e8 ? smoothstep(0.14, 0.32, dmin) * smoothstep(0.85, 1.0, g.a) : 0.0;
    }

    // --- colours: vertical gradients, lighter at the top
    float y = qt_TexCoord0.y;
    vec3 tileCol  = mix(tint.rgb * 0.32, tint.rgb * 0.14, y);
    vec3 glyphCol = mix(mix(tint.rgb, vec3(1.0), 0.40), tint.rgb, y);

    // soft sheen over the top part
    float sheen = gloss * (1.0 - smoothstep(0.0, 0.55, y));
    tileCol  += vec3(sheen);
    glyphCol += vec3(sheen * 0.5);

    // premultiplied output: translucent tile + solid glyph, cut to the icon's shape
    float a = mix(tileOpacity, 1.0, glyph);
    vec3 rgb = tileCol * tileOpacity * (1.0 - glyph) + glyphCol * glyph;
    fragColor = vec4(rgb, a) * c.a * qt_Opacity;
}
