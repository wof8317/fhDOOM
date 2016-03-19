#include "global.inc"
#include "shadows.inc"
#include "shading.inc"

layout(binding = 1) uniform sampler2D normalMap;
layout(binding = 2) uniform sampler2D lightFalloff;
layout(binding = 3) uniform sampler2D lightTexture;
layout(binding = 4) uniform sampler2D diffuseMap;
layout(binding = 5) uniform sampler2D specularMap;

in vs_output
{
  vec4 color;
  vec2 texNormal;
  vec2 texDiffuse;
  vec2 texSpecular;
  vec4 texLight;
  vec3 L;
  vec3 V;
  vec3 H;
  vec4 shadow[6];
  vec3 toGlobalLightOrigin;  
} frag;

out vec4 result;

vec4 diffuse(vec2 texcoord, vec3 N, vec3 L) 
{
  return texture(diffuseMap, texcoord) * rpDiffuseColor * lambert(N, L);
}

vec4 specular(vec2 texcoord, vec3 N, vec3 L, vec3 V)
{
  vec4 spec = texture(specularMap, texcoord) * rpSpecularColor * rpSpecularScale;
  if(rpShading == 1) {
    spec *= phong(N, L, V, rpSpecularExp);
  } else {
    vec3 H = normalize(frag.H);
    spec *= blinn(N, H, rpSpecularExp);
  }

  return spec;
}

float shadow()
{
  float shadowness = 0;

  if(rpShadowMappingMode == 1)  
    shadowness = pointlightShadow(frag.shadow, frag.toGlobalLightOrigin);  
  else if(rpShadowMappingMode == 2)
    shadowness = projectedShadow(frag.shadow[0]); 

  return mix(1, rpShadowParams.y, shadowness);  
}

void main(void)
{  
  vec3 V = normalize(frag.V);
  vec3 L = normalize(frag.L);  
  vec2 offset = parallaxOffset(specularMap, frag.texSpecular.st, V);      
  vec3 N = normalize(2.0 * texture(normalMap, frag.texNormal + offset).agb - 1.0);

  result = vec4(0,0,0,0);
  result += diffuse(frag.texDiffuse + offset, N, L);
  result += specular(frag.texSpecular + offset, N, L, V);

  result *= frag.color;
  result *= texture2DProj(lightTexture, frag.texLight.xyw);
  result *= texture2D(lightFalloff, vec2(frag.texLight.z, 0.5));
  result *= shadow();
}
