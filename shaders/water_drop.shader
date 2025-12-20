shader_type canvas_item;

// Shader para efecto de gota de agua en botones
// Crea una ilusión de relieve y luz sin cambiar el color base del botón

uniform float drop_size : hint_range(0.0, 1.0) = 0.45;
uniform float specular_intensity : hint_range(0.0, 1.0) = 0.8;
uniform float distortion : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	// Obtener el tamaño del botón para corregir el aspecto
	vec2 size = vec2(textureSize(TEXTURE, 0));
	float aspect = size.x / size.y;
	
	vec2 center = vec2(0.5, 0.5);
	vec2 rel_pos = UV - center;
	
	// Corregir la posición para que sea un círculo perfecto
	vec2 circle_pos = rel_pos;
	circle_pos.x *= aspect;
	
	float dist = length(circle_pos);
	
	if (dist < drop_size) {
		// Brillo especular desplazado
		vec2 light_pos = vec2(-0.2 * aspect, -0.2);
		float spec_dist = length(circle_pos - light_pos);
		float spec = smoothstep(0.12, 0.0, spec_dist) * (specular_intensity * 0.7);
		
		// Reflejo secundario (rim light)
		vec2 rim_light_pos = vec2(0.18 * aspect, 0.18);
		float rim = smoothstep(0.2, 0.0, length(circle_pos - rim_light_pos)) * 0.15;
		
		// Sombra interna
		float shadow = smoothstep(drop_size * 0.6, drop_size, dist) * 0.12;
		
		// Aplicar al color
		COLOR.rgb += vec3(spec + rim);
		COLOR.rgb -= vec3(shadow);
		
		// Brillo de cristal central
		float glass = (1.0 - dist / drop_size) * 0.07;
		COLOR.rgb += vec3(glass);
	}
}
