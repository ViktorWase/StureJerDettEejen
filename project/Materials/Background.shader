shader_type canvas_item;

uniform sampler2D noise;
uniform float time;
uniform vec2 offset;
uniform vec2 size;

void fragment(){
	vec2 uv = UV + offset;
	vec2 v = uv*size;

	float resolution = 20.0;
	float scale = 1.0;
	float intensity = 0.03;
	
	vec4 n = texture(noise, mod(uv*size/16.0, 1.0));
	float val = n.r;

	v.x += val*intensity*cos(uv.x*resolution + TIME*scale);
	v.y += val*intensity*sin(uv.x*resolution + TIME*scale);
	//v.y += 0.06*(1.0 + sin(uv.y*val*3.333+TIME*1.2))/2.0;
	COLOR = texture(TEXTURE, v);
}