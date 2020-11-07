shader_type canvas_item;

uniform float time;
uniform vec2 offset;
uniform vec2 size;

void fragment(){
	vec2 uv = UV + offset;
	vec2 v = uv*size/vec2(128,128);
	v.x = mod(v.x + 0.12*(1.0 + cos(uv.x*1.312+time))/2.0, 1.0);
	v.y = mod(v.y + 0.08*(1.0 + sin(uv.y*3.333+time*1.2))/2.0, 1.0);
	COLOR = texture(TEXTURE, v);
}