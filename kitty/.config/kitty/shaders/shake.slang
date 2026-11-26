#language slang 2026

import kitty_custom_shader_types;

static const float SHAKE_PX = 15.0;

public float4 fragment_main(
    float4 original, KittyTextures tex, KittyCustomShaderData state
) {
    float4 bounds = state.bell_window_geometry;
    if (bounds.z <= 0.0 || bounds.w <= 0.0) {
        return original;
    }

    float2 within = (tex.pos - bounds.xy) / bounds.zw;
    if (any(within < 0.0) || any(within >= 1.0)) {
        return original;
    }

    float sign = (state.frame_counter % 2u == 0u) ? 1.0 : -1.0;
    float displacement = sign * SHAKE_PX * (1.0 - tex.animation_progress);
    float2 location = tex.pos - float2(
        displacement / float(state.viewport_size_pixels.x), 0.0
    );

    float4 pixel = tex.backbuffer.Sample(location);
    pixel.rgb /= max(pixel.a, 0.000001);
    return pixel;
}

