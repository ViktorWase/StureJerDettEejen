shader_type canvas_item;

uniform vec3 tint;

void fragment(){
	vec2 v = UV;
	vec4 color = texture(TEXTURE, v);
	color = vec4(vec3(1.0,1.0,1.0)-color.rgb,color.a);
    color = vec4(color.rgb*tint, color.a);
	COLOR = color;
}