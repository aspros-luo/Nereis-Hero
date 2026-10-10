shader_type canvas_item;

uniform float effect_strength : hint_range(0.0, 1.0) = 1.0;
uniform float burst_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec2 centered = (UV - vec2(0.5)) * 2.0;
    float radius = length(centered);
    float angle = atan(centered.y, centered.x);

    // Restrained violet-black edge vignette; keep the combat center readable.
    float vignette = smoothstep(0.18, 1.24, radius);
    float ring_radius = 0.48 + sin(TIME * 1.7) * 0.012;
    float ring = 1.0 - smoothstep(0.006, 0.028, abs(radius - ring_radius));
    float outer_ring = 1.0 - smoothstep(0.006, 0.032, abs(radius - (0.78 + cos(TIME * 1.1) * 0.014)));

    // Fine spokes and sparse crystal-like glints, strongest on activation.
    float rays = pow(max(cos(angle * 24.0), 0.0), 32.0);
    float ray_edge = smoothstep(0.25, 0.72, radius) * (1.0 - smoothstep(0.86, 1.3, radius));
    float radial_alpha = rays * ray_edge * (0.018 + 0.12 * burst_strength);
    vec2 cell = floor(UV * vec2(28.0, 16.0));
    float hash_value = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
    float glint = step(0.992, hash_value) * (0.5 + 0.5 * sin(TIME * 3.0 + hash_value * 32.0));
    glint *= smoothstep(0.18, 0.62, radius);

    float alpha = 0.045 + vignette * 0.07 + ring * 0.018 + outer_ring * 0.008;
    alpha += radial_alpha + glint * (0.018 + 0.13 * burst_strength) + burst_strength * 0.035;
    vec3 deep_violet = vec3(0.075, 0.012, 0.16);
    vec3 crystal_glow = vec3(0.33, 0.20, 0.62);
    float glow = clamp(ring * 0.55 + radial_alpha * 4.0 + glint * 0.7, 0.0, 1.0);
    COLOR = vec4(mix(deep_violet, crystal_glow, glow), clamp(alpha, 0.0, 0.22) * effect_strength);
}
