shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never;

uniform float star_visibility : hint_range(0.0, 1.0) = 1.0;
uniform float star_density : hint_range(0.0, 1.0) = 0.5;
uniform float star_size : hint_range(0.0, 0.1) = 0.01;
uniform float twinkle_speed : hint_range(0.0, 5.0) = 1.0;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float star(vec2 uv, float seed) {
    vec2 star_pos = vec2(random(vec2(seed, seed * 2.0)), random(vec2(seed * 3.0, seed * 4.0)));
    float dist = distance(uv, star_pos);
    float star_brightness = random(vec2(seed * 5.0, seed * 6.0));
    
    float twinkle = sin(TIME * twinkle_speed + seed * 10.0) * 0.3 + 0.7;
    
    float star_val = smoothstep(star_size, 0.0, dist) * star_brightness * twinkle;
    return star_val;
}

void fragment() {
    vec2 uv = UV;
    vec3 color = vec3(0.0);
    
    int num_stars = int(star_density * 200.0);
    
    for (int i = 0; i < num_stars; i++) {
        float seed = float(i) * 0.1;
        float star_val = star(uv, seed);
        
        float star_color_rand = random(vec2(seed * 7.0, seed * 8.0));
        vec3 star_color;
        if (star_color_rand > 0.95) {
            star_color = vec3(0.8, 0.9, 1.0);
        } else if (star_color_rand > 0.9) {
            star_color = vec3(1.0, 0.9, 0.8);
        } else {
            star_color = vec3(1.0, 1.0, 1.0);
        }
        
        color += star_color * star_val;
    }
    
    ALBEDO = color * star_visibility;
    ALPHA = star_visibility;
}
