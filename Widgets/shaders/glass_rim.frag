#version 440
// Glass rim (tinted icons, lock screen field / buttons): a thin white highlight along the shape's
// outer edge, brightest at the top (lit from above), dimmest just above the middle, with a faint
// lift at the bottom. Works in pixels, so non-square shapes (a pill) get an even line too.
// The line has the same thickness all the way round: whether a pixel is within rimPx of the edge
// is measured straight outward (along the edge's normal, from the alpha gradient), so convex
// corners don't get a thicker band. Rendered supersampled (ThemedIcon), so it's anti-aliased.
//
// Compile after editing:
//   /usr/lib/qt6/bin/qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o glass_rim.frag.qsb glass_rim.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 texel;         // one pixel of the item, in texture coordinates (1 / width, 1 / height)
    float rimPx;        // rim width in pixels
    float strength;     // opacity at the top
};

layout(binding = 1) uniform sampler2D source;

// alpha at uv, 0 outside the texture (sampling clamps to the edge pixels otherwise, so a shape that
// touches its texture's border would seem to continue past it and get no rim there)
float alphaAt(vec2 uv) {
    if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return 0.0;
    return texture(source, uv).a;
}

void main() {
    float a = texture(source, qt_TexCoord0).a;
    if (a <= 0.0) { fragColor = vec4(0.0); return; }

    // outward direction of the edge, from the alpha gradient
    vec2 gsum = vec2(0.0);
    for (int k = 0; k < 8; k++) {
        float ang = float(k) * 0.7853982;
        vec2 dir = vec2(cos(ang), sin(ang));
        gsum += dir * alphaAt(qt_TexCoord0 + dir * max(rimPx, 1.5) * texel);
    }
    if (dot(gsum, gsum) < 1e-4) { fragColor = vec4(0.0); return; }   // deep inside: no rim
    vec2 n = normalize(-gsum);

    // within rimPx of the edge (looking straight outward)?
    float onRim = 1.0 - smoothstep(0.3, 0.9, alphaAt(qt_TexCoord0 + n * rimPx * texel));

    // vertical light: 1 at the top, 0.15 at 45%, 0.4 at the bottom
    float y = qt_TexCoord0.y;
    float light = y < 0.45 ? mix(1.0, 0.15, y / 0.45) : mix(0.15, 0.4, (y - 0.45) / 0.55);

    float k = strength * onRim * light * a;
    fragColor = vec4(vec3(k), k) * qt_Opacity;                      // premultiplied white
}
