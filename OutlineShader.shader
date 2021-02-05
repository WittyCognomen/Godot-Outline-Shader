/*
	Outline Shader by Witty Cognomen
	
	A sobel edge detection based outline shader.
	
	Using sobel filter implementation by @arlez80
*/

shader_type canvas_item;

uniform sampler2D input;
uniform sampler2D noise;
uniform float line_pow = 2.0;
uniform vec4 line_tint: hint_color;
uniform float wiggle_magnitude = 16.0;
uniform float wiggle_psec = 16.0;
uniform float noise_magnitude = 0.8;
uniform float line_cutoff = 0.2;

/*
    Sobel edge detection implementation from: https://bitbucket.org/arlez80/sobel-shader/src/master/

	ガウシアンフィルタとSobel シェーダー by あるる（きのもと 結衣）
	Sobel with Gaussian filter Shader by @arlez80

	Provided under MIT License
*/

vec3 gaussian5x5( sampler2D tex, vec2 uv, vec2 pix_size )
{
	vec3 p = vec3( 0.0, 0.0, 0.0 );
	float coef[25] = { 
		0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625, 
		0.015625, 0.0625, 0.09375, 0.0625, 0.015625, 
		0.0234375, 0.09375, 0.140625, 0.09375, 0.0234375, 
		0.015625, 0.0625, 0.09375, 0.0625, 0.015625, 
		0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625
	};

	for( int y=-2; y<=2; y++ ) {
		for( int x=-2; x<=2; x++ ) {
			p += ( texture( tex, uv + vec2( float( x ), float( y ) ) * pix_size).rgb) * coef[(y+2)*5 + (x+2)];
		}
	}

	return p;
}

vec3 sobel(sampler2D tex, vec2 uv, vec2 pix_size){
	vec3 pix[9];
	
	for( int y=0; y<3; y ++ ) {
		for( int x=0; x<3; x ++ ) {
			pix[y*3+x] = gaussian5x5( input, uv + vec2( float( x-1 ), float( y-1 ) ) * pix_size, pix_size );
		}
	}

	vec3 sobel_src_x = (
		pix[0] * -1.0
	+	pix[3] * -2.0
	+	pix[6] * -1.0
	+	pix[2] * 1.0
	+	pix[5] * 2.0
	+	pix[8] * 1.0
	);
	vec3 sobel_src_y = (
		pix[0] * -1.0
	+	pix[1] * -2.0
	+	pix[2] * -1.0
	+	pix[6] * 1.0
	+	pix[7] * 2.0
	+	pix[8] * 1.0
	);
	
	return sqrt( sobel_src_x * sobel_src_x + sobel_src_y * sobel_src_y );
}

/* ========================================================================== */

void fragment() {
	vec2 sampNoise = texture(noise, SCREEN_UV*noise_magnitude+(TIME-mod(TIME, 1.0/wiggle_psec))).rg*SCREEN_PIXEL_SIZE*wiggle_magnitude;
	sampNoise -= SCREEN_PIXEL_SIZE*(wiggle_magnitude*0.5);
	
	vec3 sob_noise = sobel(input, SCREEN_UV+sampNoise, SCREEN_PIXEL_SIZE);
	float sob_noise_avg = max(sob_noise.r, max(sob_noise.g, sob_noise.b));
	
	vec4 in_col = texture(input, SCREEN_UV);
	
	vec4 outline = mix(vec4(line_tint.rgb,0.0), line_tint, pow(sob_noise_avg, line_pow)>line_cutoff?1.0:0.0);
	
	COLOR = vec4(mix(in_col.rgb, outline.rgb, outline.a).rgb, 1.0);
}