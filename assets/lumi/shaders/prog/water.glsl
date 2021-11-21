#include lumi:shaders/common/texconst.glsl

/*******************************************************
 *  lumi:shaders/prog/water.glsl
 *******************************************************/

#ifndef POST_SHADER
float sampleWaterNoise(sampler2D natureTexture, vec3 worldPos, vec2 uvMove)
{
	vec2 moveA = vec2(1., -1.) * frx_renderSeconds;
	vec2 moveB = vec2(1.) * frx_renderSeconds;

	vec2 uv = worldPos.xz;
	uv.y += worldPos.y;

	vec4 uvuv = vec4(uv + moveA, uv - moveB);
	uvuv *= WATER_SAMPLING_ZOOM * WATER_BLOCK_RES / WATER_TEXSIZE;

	float A = texture(natureTexture, uvuv.xy + uvMove).g;
	float B = texture(natureTexture, uvuv.zw + uvMove).b;

	return 1.0 - (A * 0.75 + B * 0.25);
}

vec3 sampleWaterNormal(sampler2D natureTexture, vec3 normal, vec3 tangent, vec3 bitangent, vec3 fragWorldPos)
{
	const float slope = 1. / 32.;
	const float oneBlock = WATER_BLOCK_RES / WATER_TEXSIZE;
	const float amplitude = 0.02;

	vec3 tmove = tangent * slope;
	vec3 bmove = bitangent * slope;
	vec2 uvMove = vec2(0.0, oneBlock * slope);

	vec3 origin = amplitude * sampleWaterNoise(natureTexture, fragWorldPos, uvMove.xx) * normal;
	vec3 tside  = amplitude * sampleWaterNoise(natureTexture, fragWorldPos, uvMove.yx) * normal + tmove - origin;
	vec3 bside  = amplitude * sampleWaterNoise(natureTexture, fragWorldPos, uvMove.xy) * normal + bmove - origin;

	vec3 eyePos = fragWorldPos - frx_cameraPos;
	float farBlend = l2_clampScale(0., 512. * 512., dot(eyePos, eyePos));
	vec3 noisyNormal = normalize(mix(cross(tside, bside), normal, farBlend));

	return noisyNormal;
}
#endif
