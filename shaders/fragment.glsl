#version 460 core

precision highp float;

in vec2 coordinates;
out vec4 color;

uniform float time;

#define ITERATIONS 8
#define POWER 6.

// https://glslsandbox.com/e#79488.0
float mandelbulb(vec3 position) {
    vec3 z = position;
    float r = 0., dr = 1., zr, theta, phi;
    for(int iteration = 0; iteration < ITERATIONS; iteration += 1) {
        r = length(z);
        if(r > 2.) break;
        theta = acos(z.z / r) + time;
        phi = atan(z.y, z.x) + time;
        dr = pow(r, POWER - 1.) * POWER * dr + 1.;
        zr = pow(r, POWER);
        theta *= POWER;
        phi *= POWER;
        z = vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta)) * zr + position;
    }
    return log(r) * r / dr * .5;
}

#define MARCH_ITERATIONS 50

void main() {
    vec3 camera_position = vec3(0., sin(time) * 2.5, cos(time) * 2.5);
    vec3 camera_direction = normalize(camera_position);
    vec3 ray_direction = normalize(vec3(0., -camera_direction.z, camera_direction.y) * coordinates.x + vec3(coordinates.y, 0., 0.) - camera_direction);
    vec3 ray = camera_position;
    vec3 m = vec3(1.);
    float d;
    for(int march_iteration = 0; march_iteration < MARCH_ITERATIONS; march_iteration += 1) {
        d = mandelbulb(ray);
        ray += ray_direction * d;
        m -= vec3(.02, .01, .01); // Values of this vec3 can't be higher than (1 / MARCH_ITERATIONS).
        if(d < .002) break;
    }
    color = vec4(m, 1.);
}