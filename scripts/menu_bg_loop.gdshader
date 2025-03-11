shader_type canvas_item;

uniform float speed = 50.0;
uniform float time_offset = 0.0;

void fragment() {
    vec2 uv = UV;
    uv.x -= (TIME + time_offset) * speed * 0.001;
    uv.x = fract(uv.x); // makes background loop horizontally
    COLOR = texture(TEXTURE, uv);
}
