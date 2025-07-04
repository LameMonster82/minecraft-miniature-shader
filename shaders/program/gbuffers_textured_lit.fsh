#define gbuffers_textured_lit

#include "/shader.h"

uniform int entityId;
uniform sampler2D texture;
uniform vec3 fogColor;
uniform vec4 entityColor;

#ifdef DISTANT_HORIZONS_TERRAIN
uniform sampler2D depthtex0;
uniform float viewHeight;
uniform float viewWidth;
vec2 resolution = vec2(viewWidth, viewHeight);
#endif

varying float fogMix;
varying float isLava;
varying float torchStrength;
varying vec2 lightUV;
varying vec2 texUV;
varying vec3 worldPos;
varying vec4 ambient;
varying vec4 color;

#ifdef GLOWING_ORES
   varying float isOre;
#endif

#ifdef HAND_DYNAMIC_LIGHTING
   uniform int heldBlockLightValue;
#endif

#include "/common/math.glsl"
#include "/common/getTorchColor.fsh"

#ifdef ENABLE_SHADOWS
   uniform vec3 cameraPosition;
   uniform mat4 shadowModelView;
   uniform mat4 shadowProjection;
   uniform mat4 gbufferProjectionInverse;
   uniform sampler2D shadowtex1;

   varying vec3 sunColor;
   varying float diffuse;

   #include "/common/getSunStrength.fsh"
#endif

void main() {
	#ifdef DISTANT_HORIZONS_TERRAIN
	if(texture(depthtex0, gl_FragCoord.xy / resolution).r < 1.0){
      discard;
	}
	#endif
   vec4 albedo  = texture2D(texture, texUV);
   vec4 ambient = ambient;

   #ifdef GLOWING_ORES

      ambient.rgb = mix(
         ambient.rgb,
         vec3(1.0, 0.9, 0.9),
         isOre * 0.3333*squaredLength(rescale(albedo.rgb, vec3(0.59), vec3(1.0)))
      );

   #endif

   albedo *= color;

   #ifdef ENABLE_SHADOWS

      float sunStrength = max(0.75*isLava, getSunStrength());
      float blueness = (1.0 - sunStrength) * SHADOW_BLUENESS;

      ambient.rgb *= 1.0 - SHADOW_DARKNESS;
      ambient.g *= 1.0 + 0.3333*blueness;
      ambient.b *= 1.0 + blueness;

      float sunBrightness = max(0.0, SUN_BRIGHTNESS - 0.5*pow3(luma(albedo.rgb)));

      ambient.rgb *= 1.0 + (sunBrightness * sunStrength) * sunColor;

   #endif

   ambient.rgb += getTorchColor(ambient.rgb);

   // render thunder
   albedo.a = entityId == 11000.0 ? 0.15 : albedo.a;

   // render entity color changes (e.g taking damage)
   albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);

   albedo *= ambient;

   albedo.rgb = mix(albedo.rgb, fogColor, fogMix);

   gl_FragData[0] = albedo;
}