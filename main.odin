package main

import "vendor:glfw"
import gl "vendor:OpenGL"

zoom : f32 = .6

@(optimization_mode="speed") scroll_callback :: proc "c" (window : glfw.WindowHandle, scroll_x, scroll_y : f64) #no_bounds_check do zoom = max(zoom * f32(scroll_y * .1 + 1), .3) // Some of this stuff could maby be done inside the vertex shader.

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
    // glfw.WindowHint(glfw.DECORATED, 0)
    glfw.WindowHint(glfw.MAXIMIZED, 1)
    // glfw.WindowHint(glfw.TRANSPARENT_FRAMEBUFFER, 1)
    window := glfw.CreateWindow(1024, 768, "mandelbrot", nil, nil)
    assert(window != nil)
    defer glfw.DestroyWindow(window)
    glfw.SetWindowSizeLimits(window, 512, 384, glfw.DONT_CARE, glfw.DONT_CARE)
    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)
    gl.load_up_to(4, 6, glfw.gl_set_proc_address)
    glfw.SetScrollCallback(window, scroll_callback)
    // TODO: Precompile the shaders to SPIR-V rather than compiling them at runtime.
    vertex_shader_source :: string(#load("shaders/vertex.glsl"))
    fragment_shader_source :: string(#load("shaders/fragment.glsl"))
    shader_program, shader_program_ok := gl.load_shaders_source(vertex_shader_source, fragment_shader_source)
    assert(shader_program_ok)
    defer gl.DeleteProgram(shader_program)
    offset_uniform_location := gl.GetUniformLocation(shader_program, "offset")
    zoom_uniform_location := gl.GetUniformLocation(shader_program, "zoom")
    gl.UseProgram(shader_program)
    // We do a little trolling.
    VAO : u32 = ---
    gl.GenVertexArrays(1, &VAO)
    defer gl.DeleteVertexArrays(1, &VAO)
    gl.BindVertexArray(VAO)
    defer gl.BindVertexArray(0)
    frame_buffer_width, frame_buffer_height : i32 = ---, ---
    // TODO: Clean up line 52 - 79. Thanks baby.
    // Some of the stuff could maby be done inside the vertex shader.
    previous_cursor_x, previous_cursor_y, current_cursor_x, current_cursor_y : f64 = ---, ---, ---, ---
    offset_x, offset_y : f32 = -.3, 0
    moving : bool = ---
    for {
        if glfw.WindowShouldClose(window) do break
        frame_buffer_width, frame_buffer_height = glfw.GetFramebufferSize(window)
        // TODO: It's unnecessary to update the viewport every frame even though the frame buffer size doesn't change.
        // Consider using some callback function for this.
        update_viewport(frame_buffer_width, frame_buffer_height)
        // TODO: Set some boundaries for moving around.
        if glfw.GetMouseButton(window, glfw.MOUSE_BUTTON_LEFT) == glfw.PRESS {
            previous_cursor_x, previous_cursor_y = current_cursor_x, current_cursor_y
            current_cursor_x, current_cursor_y = glfw.GetCursorPos(window)
            current_cursor_x /= f64(frame_buffer_width)
            current_cursor_y /= f64(frame_buffer_height)
            if moving {
                if frame_buffer_width > frame_buffer_height {
                    offset_x += f32(previous_cursor_x - current_cursor_x) / zoom * f32(frame_buffer_width) / f32(frame_buffer_height)
                    offset_y -= f32(previous_cursor_y - current_cursor_y) / zoom
                }
                else {
                    offset_x += f32(previous_cursor_x - current_cursor_x) / zoom
                    offset_y -= f32(previous_cursor_y - current_cursor_y) / zoom * f32(frame_buffer_height) / f32(frame_buffer_width)
                }
            }
            else do moving = true
        }
        else do moving = false
        gl.Uniform2f(offset_uniform_location, offset_x, offset_y)
        gl.Uniform1f(zoom_uniform_location, zoom)
        gl.Clear(gl.COLOR_BUFFER_BIT)
        gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4)
        glfw.SwapBuffers(window)
        glfw.PollEvents() // glfw.WaitEvents()
    }
}