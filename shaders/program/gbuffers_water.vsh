#define gbuffers_water

#include "/shader.h"

attribute vec4 mc_Entity;

uniform float fogEnd;
uniform float fogStart;
uniform float frameTimeCounter;
uniform float near, far;
uniform float rainStrength;
uniform int fogShape;
uniform int isEyeInWater;
uniform int worldTime;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D lightmap;
uniform vec3 cameraPosition;

varying vec2 texUV;
varying vec2 lightUV;
varying vec3 worldPos;
varying vec4 color;
varying vec4 normal;
varying vec4 ambient;
varying float fogMix;
varying float isWater;
varying float waterTexStrength;
varying float torchStrength;

#include "/common/math.glsl"
#include "/common/getFogMix.vsh"
#include "/common/getWorldPosition.vsh"
#include "/common/getTorchStrength.vsh"
#include "/common/getWaterTextureStrength.vsh"
#include "/common/getWaterWave.vsh"

void main() {
   gl_Position = ftransform();

   color   = gl_Color;
   texUV   = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
   lightUV = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
   normal  = vec4(gl_Normal, 1.0);
   ambient = texture2D(lightmap, vec2(AMBIENT_UV.s, lightUV.t));

   #ifdef DISTANT_HORIZONS_WATER
      isWater = float(dhMaterialId == DH_BLOCK_WATER);
   #else
      isWater = float(mc_Entity.x == 10008.0);
   #endif

   torchStrength = getTorchStrength(lightUV.s);
   worldPos = getWorldPosition();
   fogMix = getFogMix(worldPos);

#ifndef DISTANT_HORIZONS_WATER
   if (isWater > 0.9) {
      float posRandom = random(floor(worldPos.xz) + floor(cameraPosition.xz));

      #if WATER_WAVE_SIZE > 0

         getWaterWave(normal, posRandom);

      #endif

      waterTexStrength = getWaterTextureStrength(posRandom);
   }
#endif

   // scale normal to 0..1
   normal = vec4(0.5 + 0.5*normal.xyz, 1.0);
}