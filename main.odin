package main

import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:time"

@(optimization_mode="speed") update_viewport :: #force_inline proc "c" (frame_buffer_width : i32, frame_buffer_height : i32) #no_bounds_check {
    if frame_buffer_width > frame_buffer_height do gl.Viewport(0, (frame_buffer_height - frame_buffer_width) / 2, frame_buffer_width, frame_buffer_width)
    else do gl.Viewport((frame_buffer_width - frame_buffer_height) / 2, 0, frame_buffer_height, frame_buffer_height)
}

@(optimization_mode="speed") main :: proc() #no_bounds_check {
    assert(bool(glfw.Init()))
    defer glfw.Terminate()
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, 1)
    glfw.WindowHint(glfw.MAXIMIZED, 1)
    glfw.WindowHint(glfw.CENTER_CURSOR, 0)
    // glfw.WindowHint(glfw.TRANSPARENT_FRAMEBUFFER, 1)
    window := glfw.CreateWindow(1024, 768, "fviewer", nil, nil)
    assert(window != nil)
    defer glfw.DestroyWindow(window)
    glfw.SetWindowSizeLimits(window, 512, 384, glfw.DONT_CARE, glfw.DONT_CARE)
    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)
    gl.load_up_to(4, 6, glfw.gl_set_proc_address)
    // TODO: Precompile the shaders to SPIR-V rather than compiling them at runtime.
    vertex_shader_source :: string(#load("shaders/vertex.glsl"))
    fragment_shader_source :: string(#load("shaders/fragment.glsl"))
    shader_program, shader_program_ok := gl.load_shaders_source(vertex_shader_source, fragment_shader_source)
    assert(shader_program_ok)
    defer gl.DeleteProgram(shader_program)
    time_uniform_location := gl.GetUniformLocation(shader_program, "time")
    gl.UseProgram(shader_program)
    // We do a little trolling.
    VAO : u32 = ---
    gl.GenVertexArrays(1, &VAO)
    defer gl.DeleteVertexArrays(1, &VAO)
    gl.BindVertexArray(VAO)
    defer gl.BindVertexArray(0)
    stopwatch : time.Stopwatch
    time.stopwatch_start(&stopwatch)
    frame_buffer_width, frame_buffer_height : i32 = ---, ---
    for {
        if glfw.WindowShouldClose(window) do break
        frame_buffer_width, frame_buffer_height = glfw.GetFramebufferSize(window)
        // TODO: It's unnecessary to update the viewport every frame even though the frame buffer size doesn't change.
        // Consider using some callback function for this.
        update_viewport(frame_buffer_width, frame_buffer_height)
        time := f32(time.duration_seconds(time.stopwatch_duration(stopwatch))) * .5
        gl.Uniform1f(time_uniform_location, time)
        gl.Clear(gl.COLOR_BUFFER_BIT)
        gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4)
        glfw.SwapBuffers(window)
        glfw.PollEvents() // glfw.WaitEvents()
    }
}