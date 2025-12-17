shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

uniform float star_visibility : hint_range(0.0, 1.0) = 1.0;
uniform float twinkle_speed : hint_range(0.0, 5.0) = 1.0;
uniform float star_density : hint_range(0.0, 1.0) = 0.5;

// Pseudo-random number generator
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    if (star_visibility <= 0.01) {
        discard;
    }

    vec2 uv = UV * (100.0 + star_density * 200.0); // Scale UV for tiling
    vec2 id = floor(uv);
    vec2 f = fract(uv);
    
    float star_val = 0.0;
    
    // Check 3x3 grid for stars to handle edges
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 cell_id = id + neighbor;
            
            // Random position 0..1 in the neighbor cell
            vec2 point = vec2(random(cell_id), random(cell_id + vec2(10.0)));
            
            // Only create a star if random check passes (variable density)
            if (random(cell_id * 2.0) > 0.5) {
                // Check distance from current pixel to the star in neighbor cell
                vec2 diff = neighbor + point - f;
                float dist = length(diff);
                
                if (dist < 0.2) { // Star radius
                    // Random brightness
                    float brightness = random(cell_id + vec2(5.0));
                    
                    // Twinkle effect
                    float twinkle = sin(TIME * twinkle_speed + brightness * 20.0) * 0.4 + 0.6;
                    
                    // Smooth soft glow
                    float glow = max(0.0, 1.0 - dist / 0.2);
                    glow = pow(glow, 2.0); // Make it sharper
                    
                    star_val += glow * brightness * twinkle;
                }
            }
        }
    }
    
    vec3 color = vec3(1.0, 1.0, 1.0) * star_val;
    ALBEDO = color;
    ALPHA = clamp(star_val, 0.0, 1.0) * star_visibility;
}
