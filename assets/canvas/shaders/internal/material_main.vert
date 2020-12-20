/******************************************************************************************************
 * Derived from Canvas (https://github.com/grondag/canvas) material_main shader, Apache 2.0 license.  *
 * Modified to add PBR varyings and support for texture-based bump map generation.                    *
 * The modifications are licensed under the GNU Lesser General Public License version 3.              *
 ******************************************************************************************************/

#include canvas:shaders/internal/header.glsl
#include canvas:shaders/internal/varying.glsl
#include canvas:shaders/internal/vertex.glsl
#include canvas:shaders/internal/flags.glsl
#include canvas:shaders/internal/diffuse.glsl
#include canvas:shaders/internal/program.glsl
#include frex:shaders/api/context.glsl
#include frex:shaders/api/vertex.glsl
#include frex:shaders/api/sampler.glsl
#include respackopts:config_supplier
#include lumi:shaders/api/context_bump.glsl
#include lumi:shaders/internal/varying.glsl
#include lumi:shaders/internal/main_vert.glsl

#include canvas:apitarget

/******************************************************
  canvas:shaders/internal/material_main.vert
******************************************************/

void _cv_startVertex(inout frx_VertexData data, in int cv_programId) {
#include canvas:startvertex
}

void _cv_endVertex(inout frx_VertexData data, in int cv_programId) {
#include canvas:endvertex
}

void main() {
	frx_VertexData data = frx_VertexData(
	gl_Vertex,
	in_uv,
	in_color,
	(in_normal_flags.xyz - 127.0) / 127.0,
	in_lightmap.rg * 0.00390625 + 0.03125
	);

	// Adding +0.5 prevents striping or other strangeness in flag-dependent rendering
	// due to FP error on some cards/drivers.  Also made varying attribute invariant (rolls eyes at OpenGL)
	_cvv_flags = uint(in_normal_flags.w + 0.5);

    // pbrv_roughness = 1.0;
	// pbrv_metallic = 0.0;

	_cv_setupProgram();

#ifdef LUMI_BUMP
	startBump();
#endif

	int cv_programId = _cv_vertexProgramId();
	_cv_startVertex(data, cv_programId);

#ifdef LUMI_BUMP
	setupBump(data);
#endif

	if (_cvu_atlas[_CV_SPRITE_INFO_TEXTURE_SIZE] != 0.0) {
		float spriteIndex = in_material.x;
		// for sprite atlas textures, convert from normalized (0-1) to interpolated coordinates
		vec4 spriteBounds = texture2DLod(frxs_spriteInfo, vec2(0, spriteIndex / _cvu_atlas[_CV_SPRITE_INFO_TEXTURE_SIZE]), 0);

		float atlasHeight = _cvu_atlas[_CV_ATLAS_HEIGHT];
		float atlasWidth = _cvu_atlas[_CV_ATLAS_WIDTH];

		// snap sprite bounds to integer coordinates to correct for floating point error
		spriteBounds *= vec4(atlasWidth, atlasHeight, atlasWidth, atlasHeight);
		spriteBounds += vec4(0.5, 0.5, 0.5, 0.5);
		spriteBounds -= fract(spriteBounds);
		spriteBounds /= vec4(atlasWidth, atlasHeight, atlasWidth, atlasHeight);

		data.spriteUV = spriteBounds.xy + data.spriteUV * spriteBounds.zw;

	#ifdef LUMI_BUMP
		endBump(spriteBounds);
	#endif
	}

	data.spriteUV = _cv_textureCoord(data.spriteUV, 0);

	vec4 viewCoord = gl_ModelViewMatrix * data.vertex;
	gl_ClipVertex = viewCoord;
	gl_FogFragCoord = length(viewCoord.xyz);

	setVaryings(viewCoord);

	//data.normal *= gl_NormalMatrix;
	data.vertex = gl_ModelViewProjectionMatrix * data.vertex;

	gl_Position = data.vertex;

	_cv_endVertex(data, cv_programId);

	_cvv_texcoord = data.spriteUV;
	_cvv_color = data.color;
	_cvv_normal = data.normal;

#if DIFFUSE_SHADING_MODE != DIFFUSE_MODE_NONE
	_cvv_diffuse = _cv_diffuse(_cvv_normal);
#endif

#if AO_SHADING_MODE != AO_MODE_NONE
	_cvv_ao = in_lightmap.b / 255.0;
#endif

	_cvv_lightcoord = data.light;
}
