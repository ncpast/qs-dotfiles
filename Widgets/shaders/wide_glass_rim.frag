#version 440
// Wide glass rim (lock screen password field, notification button row): a thin white highlight
// along the shape's outer edge, lit diagonally like colored_icon.frag's bevel: brightest at the
// top-left and bottom-right corners, fading along the edges to nothing towards the top-right and
// bottom-left. Made for wide shapes: glass_rim.frag's top-lit line stretches across their whole
// length, while here the highlights' reach is measured in the shape's short side (times `reach`),
// so a wide pill gets a highlight on each of its two ends. Works in pixels.
// The line has the same thickness all the way round: whether a pixel is within rimPx of the edge
// is measured straight outward (along the edge's normal, from the alpha gradient), so convex
// corners don't get a thicker band. Rendered supersampled by its users, so it's anti-aliased.
//
// Compile after editing:
//   /usr/lib/qt6/bin/qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o wide_glass_rim.frag.qsb wide_glass_rim.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 texel;         // one pixel of the item, in texture coordinates (1 / width, 1 / height)
    float rimPx;        // rim width in pixels
    float strength;     // opacity at its brightest (the top-left / bottom-right corners)
    float reach;        // how far the highlights extend from the corners, in short sides (1 = like the icons)
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

    // diagonal light, by distance (along x + y, in pixels) from the top-left / bottom-right corner,
    // in units of the short side times reach; same curves as colored_icon.frag (top left: soft,
    // reaching about the middle of a square's edges; bottom right: same strength, but shorter)
    vec2 size = 1.0 / texel;
    vec2 p = qt_TexCoord0 * size;
    float S = min(size.x, size.y) * max(reach, 0.01);
    float tl = 1.0 - smoothstep(0.25, 1.05, (p.x + p.y) / S);
    float br = 1.0 - smoothstep(0.2, 0.75, ((size.x - p.x) + (size.y - p.y)) / S);
    float light = max(tl, br);

    float k = strength * onRim * light * a;
    fragColor = vec4(vec3(k), k) * qt_Opacity;                      // premultiplied white
}
