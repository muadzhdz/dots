// Faithful port of kitty's cursor_trail.c physics for Ghostty custom shader.
// https://github.com/kovidgoyal/kitty/blob/master/kitty/cursor_trail.c
// Tuned to match ~/.config/kitty/kitty.conf:
//   cursor_trail_decay 0.1 0.4
//   cursor_trail_start_threshold 1 1
//   cursor_trail_color none (use cursor color)

vec3 sRGBToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b) {
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);
    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

float getSdfQuad(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
    float s = 1.0;
    float d = dot(p - v0, p - v0);
    d = seg(p, v0, v1, s, d);
    d = seg(p, v1, v2, s, d);
    d = seg(p, v2, v3, s, d);
    d = seg(p, v3, v0, s, d);
    return s * sqrt(d);
}

vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float antialising(float distance) {
    return 1.0 - smoothstep(0.0, normalize(vec2(2.0, 2.0), 0.0).x, distance);
}

vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.0), rectangle.y - (rectangle.w / 2.0));
}

// kitty options (match kitty.conf)
const float DECAY_FAST = 0.1; // cursor_trail_decay fast
const float DECAY_SLOW = 0.4; // cursor_trail_decay slow
const float START_THRESHOLD = 1.0; // cursor_trail_start_threshold (cells)

// kitty's per-corner exponential step: 1 - exp2(-10 * dt / decay)
float trailStep(float dx, float dy, float dotVal, float minDot, float maxDot) {
    if (abs(dx) < 1e-6 && abs(dy) < 1e-6) {
        return 0.0;
    }
    float decay = (maxDot == minDot)
        ? DECAY_SLOW
        : DECAY_SLOW + (DECAY_FAST - DECAY_SLOW) * (dotVal - minDot) / (maxDot - minDot);
    float dt = iTime - iTimeCursorChange;
    return 1.0 - exp2(-10.0 * dt / decay);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif

    vec2 vu = normalize(fragCoord, 1.0);
    vec2 offsetFactor = vec2(-0.5, 0.5);

    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.0), normalize(iCurrentCursor.zw, 0.0));
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.0), normalize(iPreviousCursor.zw, 0.0));

    vec2 curr_center = getRectangleCenter(currentCursor);
    vec2 prev_center = getRectangleCenter(previousCursor);

    // skip if cursor moved less than the start threshold (kitty: per-axis, in cells)
    vec2 delta_cells = (curr_center - prev_center) / currentCursor.w;
    if (abs(delta_cells.x) <= START_THRESHOLD && abs(delta_cells.y) <= START_THRESHOLD) {
        return;
    }

    float dt = iTime - iTimeCursorChange;
    if (dt <= 0.0 || dt > 1.5) {
        return;
    }

    // corners, kitty corner_index: TR, BR, BL, TL
    vec2 curr_corners[4];
    curr_corners[0] = vec2(currentCursor.x + currentCursor.z, currentCursor.y);
    curr_corners[1] = vec2(currentCursor.x + currentCursor.z, currentCursor.y - currentCursor.w);
    curr_corners[2] = vec2(currentCursor.x, currentCursor.y - currentCursor.w);
    curr_corners[3] = vec2(currentCursor.x, currentCursor.y);

    vec2 prev_corners[4];
    prev_corners[0] = vec2(previousCursor.x + previousCursor.z, previousCursor.y);
    prev_corners[1] = vec2(previousCursor.x + previousCursor.z, previousCursor.y - previousCursor.w);
    prev_corners[2] = vec2(previousCursor.x, previousCursor.y - previousCursor.w);
    prev_corners[3] = vec2(previousCursor.x, previousCursor.y);

    // cursor diagonal * 0.5, for kitty's dot product normalization
    float cursor_diag_2 = length(vec2(currentCursor.z, currentCursor.w)) * 0.5;

    // per-corner dot product of movement direction and (corner - cursor center)
    float dx[4], dy[4], dotv[4];
    float min_dot = 1e30;
    float max_dot = -1e30;
    for (int i = 0; i < 4; i++) {
        dx[i] = curr_corners[i].x - prev_corners[i].x;
        dy[i] = curr_corners[i].y - prev_corners[i].y;
        if (abs(dx[i]) < 1e-6 && abs(dy[i]) < 1e-6) {
            dotv[i] = 0.0;
            continue;
        }
        vec2 corner_to_center = curr_corners[i] - curr_center;
        dotv[i] = (dx[i] * corner_to_center.x + dy[i] * corner_to_center.y)
                / (cursor_diag_2 * length(vec2(dx[i], dy[i])));
        min_dot = min(min_dot, dotv[i]);
        max_dot = max(max_dot, dotv[i]);
    }

    // trail corners chase the cursor corners with exponential decay
    vec2 trail_corners[4];
    for (int i = 0; i < 4; i++) {
        float s = trailStep(dx[i], dy[i], dotv[i], min_dot, max_dot);
        trail_corners[i] = prev_corners[i] + vec2(dx[i], dy[i]) * s;
    }

    // draw the trail quad
    float sdfTrail = getSdfQuad(vu, trail_corners[0], trail_corners[1], trail_corners[2], trail_corners[3]);
    float sdfCursor = getSdfRectangle(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);

    vec4 trail = vec4(sRGBToLinear(iCurrentCursorColor.rgb), iCurrentCursorColor.a);
    float trailAlpha = antialising(sdfTrail);
    vec4 newColor = mix(fragColor, trail, trailAlpha);

    // punch hole so the cursor itself is always drawn on top
    fragColor = mix(newColor, fragColor, step(sdfCursor, 0.0));
}
