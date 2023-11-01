shader_type spatial;
render_mode depth_prepass_alpha;

uniform float density;
uniform float thickness;
uniform float waveSpeed;
uniform float waveIntensity;
uniform vec3 waveDirection;
uniform float shellExpBias;
uniform float shellLength;
uniform vec3 displacement;
uniform float displacementStr;
uniform float displacementCurvature;
uniform float attenuation;
uniform float thicknessCurve;
uniform float discolourationCurve;
uniform float AO_offset;
uniform float AO_scale : hint_range(0,1);
uniform float minNoise : hint_range(0,1);
uniform float maxNoise : hint_range(0,1);
uniform float discolourationStrength : hint_range(0,1);
uniform int shellIndex;
uniform int shellCount;
uniform vec4 colour : source_color;
uniform vec4 discolour : source_color;
//cheers
float iqint1(uint n) {
    // integer hash copied from Hugo Elias
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
	
    return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
}

float lerp(float start, float end, float delta) {
	return start*(1.-delta) + end*delta;
}
vec3 lerpVec(vec3 start, vec3 end, float delta) {
	return start*(1.-delta) + end*delta;
}

void vertex() {
	float height = float(shellIndex) / float(shellCount);
	float k = pow(height, displacementCurvature);
	height = pow(height, shellExpBias);
	float offset = sin((VERTEX.x*waveDirection.x)*10.+(VERTEX.y*waveDirection.y)*10.+(VERTEX.z*waveDirection.z)*10.+TIME*waveSpeed)/20.;
	VERTEX.xyz += offset*offset*waveIntensity;
	VERTEX.xyz += NORMAL.xyz * shellLength * height;
	VERTEX.xyz += displacement * k * displacementStr;
}

void fragment() {
	vec2 uvScale = UV*density;
	uvScale *= mat2(vec2(cos(PI/4.), sin(PI/4.)), vec2(-sin(PI/4.), cos(PI/4.)));
	uint y = uint(int(uvScale.y));
	uvScale += vec2(iqint1(y), 0);
	uint x = uint(int(uvScale.x));
	vec2 localUV = fract(uvScale) * 2. - 1.;
	float uvDist = length(localUV);
	uint seed = x + 100u * y + 100u * 10u;
	float v = lerp(minNoise, maxNoise, iqint1(seed));
	float h = float(shellIndex) / float(shellCount);
	bool shouldDiscard = (uvDist) > (thickness * pow(v, 2./thicknessCurve) - pow(h, thicknessCurve));
	if(shouldDiscard && shellIndex > 0) {
		discard;
	}
	float ambientOcclusion = pow(h, attenuation);
	ambientOcclusion += AO_offset;
	ambientOcclusion = clamp(ambientOcclusion, 0., 1.);
	//float finalV = v > 200. ? 1. : 0.;
	float g = pow(v, discolourationCurve)*discolourationStrength;
	g = h > iqint1(seed+1u) ? g : 0.;
	ALBEDO = vec3(lerpVec(colour.rgb, discolour.rgb, g)*lerp(1., ambientOcclusion, AO_scale));
	
}

void light() {
	vec3 halfLambert = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR * 0.5 + 0.5;
    DIFFUSE_LIGHT += vec3(halfLambert.x*halfLambert.x, halfLambert.y*halfLambert.y, halfLambert.z*halfLambert.z);
}
