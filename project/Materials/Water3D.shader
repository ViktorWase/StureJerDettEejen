shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform sampler2D texture_normal : hint_normal;
uniform float normal_scale : hint_range(-16,16);
uniform sampler2D texture_detail_albedo : hint_albedo;
uniform sampler2D texture_detail_normal : hint_normal;
uniform sampler2D texture_detail_mask : hint_white;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

/* user defined */
uniform float time;
uniform vec2 offset;
uniform vec2 size;


void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}




void fragment() {
	vec2 base_uv = UV;
	
	vec2 uv = UV + offset;
	vec2 v = uv*size/vec2(128,128);
	v.x = v.x + 0.12*(1.0 + cos(uv.x*1.312+time))/2.0;
	v.y = v.y + 0.08*(1.0 + sin(uv.y*3.333+time*1.2))/2.0;
	base_uv = v;
	
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	NORMALMAP = texture(texture_normal,base_uv).rgb;
	NORMALMAP_DEPTH = normal_scale;
	vec4 detail_tex = texture(texture_detail_albedo,base_uv);
	vec4 detail_norm_tex = texture(texture_detail_normal,base_uv);
	vec4 detail_mask_tex = texture(texture_detail_mask,base_uv);
	vec3 detail = mix(ALBEDO.rgb,detail_tex.rgb,detail_tex.a);
	vec3 detail_norm = mix(NORMALMAP,detail_norm_tex.rgb,detail_tex.a);
	NORMALMAP = mix(NORMALMAP,detail_norm,detail_mask_tex.r);
	ALBEDO.rgb = mix(ALBEDO.rgb,detail,detail_mask_tex.r);
}
