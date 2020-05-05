#version 330 core


uniform vec2 resolution = vec2(800, 600);

vec3 lightColor = vec3(1.0, 0.6, 0.2);

uniform float height;
uniform float phase;
uniform float glowness;

uniform float time;




//	Simplex 3D Noise
//	by Ian McEwan, Ashima Arts
//
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

float snoise(vec3 v){
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //  x0 = x0 - 0. + 0.0 * C
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

// Permutations
  i = mod(i, 289.0 );
  vec4 p = permute( permute( permute(
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients
// ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
                                dot(p2,x2), dot(p3,x3) ) );
}

vec3 noiseCircle( vec2 _st, vec2 _center, float _radius, float _thickness, float _noiseRoughness, float _noiseStrength, float _timeOffset )
{
	vec2 center = vec2( 0.5, 0.5 );

	vec2 diff = _st - _center;

	float dist = length( diff );

	vec2 nDiff = normalize( diff );
	float angle = atan( nDiff.y, nDiff.x );
	vec2 npos2 = vec2( cos( angle ), sin( angle ) ) * _noiseRoughness;
	vec3 npos3 = vec3( npos2, time * 0.75 + _timeOffset );
	float noise = snoise( npos3 ) * _noiseStrength;

	float radius = _radius + noise;

	float len = _thickness / length( radius - dist );

	return vec3( len );
}










void main(void)
{


	//vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
/*
    vec4 l = (0.05 / abs(length(p) - glowness - 0.1)) * vec4(lightColor, 1.0);

    p = (gl_FragCoord.xy / resolution.xy);
    float sx = (height * 2) * sin(phase * p.x + time * 2.0);
    vec3 dx = (glowness / abs(40.0 * p.y - sx - 20.0)) * lightColor * 2;

    float sy = height * sin(phase * p.y + time * 2.0);
    vec3 dy = (glowness / abs(40.0 * p.x - sy - 20.0)) * lightColor * 2;


	vec4 finalColor = l * (vec4(dx, 1.0) + vec4(dy, 1.0));

	gl_FragColor = finalColor;*/

    vec2 st = gl_FragCoord.xy / resolution.xy;

	float aspect = resolution.y / resolution.x;

	// fix aspect
	st -= 0.5;
	st.y *= aspect;
	st += 0.5;

	vec2 center = vec2( 0.5, 0.5 );

	vec3 c1 = noiseCircle( st, center, (glowness / 4) + 0.1, (glowness / 100) + 0.001, phase / 10, height / 80, 0.0 ) * lightColor;
    lightColor = vec3(0.2, 0.6, 1.0);
	vec3 c2 = noiseCircle( st, center, (glowness / 4) + 0.1, (glowness / 100) + 0.001, phase / 10, height / 70, 1.234 ) * lightColor;
    lightColor = vec3(1.0, 0.2, 1.0);
	vec3 c3 = noiseCircle( st, center, (glowness / 4) + 0.1, (glowness / 100) + 0.001, phase / 10, height / 60, 5.678 ) * lightColor;


    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    p = (gl_FragCoord.xy / resolution.xy);

    lightColor = vec3(1.0, 0.6, 0.2);
    float sx = (height) * sin(phase * p.x + time * 2.0);
    vec3 dx = (glowness / abs(40.0 * p.y - sx)) * lightColor * 2;

    float sx2 = (height) * sin(phase * p.x + time * 2.0);
    vec3 dx2 = (glowness / abs(40.0 * p.y - sx - 40.0)) * lightColor * 2;

    float fsx = (height) * sin(phase * p.x + time * 2.0);
    vec3 fdx = (glowness / abs(40.0 * p.y)) * lightColor * 2;

    float fsx2 = (height) * sin(phase * p.x + time * 2.0);
    vec3 fdx2 = (glowness / abs(40.0 * p.y - 40.0)) * lightColor * 2;


	vec3 lines = dx + dx2 + fdx + fdx2;

	vec3 color = c3 + c2 + c1 + lines;

	gl_FragColor = vec4( color, 1.0 );
}
