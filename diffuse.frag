vec4 lovrmain() {
  const vec3 LightWorld = vec3(1, 2, 1);
  vec3 lightVec = PositionWorld - LightWorld;
  float dist = distance(LightWorld, PositionWorld);
  float diffuse_reflected = dot(normalize(Normal), normalize(-lightVec));
  float diffuse = max(0.5 + 0.3 * diffuse_reflected, 0.);
  vec4 surface_color = DefaultColor;
  vec3 color = surface_color.rgb * diffuse;
  return vec4(color, surface_color.a);
}
