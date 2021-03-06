local app = require 'sdl_app'

local BIT = require 'bit'
-- LuaJIT compatible bit functions
local bit = BIT.bit

local gl = require 'luagl'
require 'GL/defs'
local surface = require 'SDL/surface'
local texture = require 'SDL/texture'
local shader = require 'SDL/shader'
local ttf = require 'SDL/fonts/ttf'

local matrixModule = require 'utils/matrix'
local matrix = matrixModule.new
local matrixBase = matrixModule.new()

local quad = require 'shapes/quad_gui'

local gui = require 'gui'

-- useful shortcuts for matrix transformations
local R,T,S = matrixBase.rotate, matrixBase.translate, matrixBase.scale

local window = {
	x = 512,
	y = 128,
	width = 1024,
	height = 786,
	bpp = 32,
	flags = SDL.SDL_OPENGL,
	caption = 'PackPub Example',
	class = 'Example',
	fullScreen = false,
}

if window.fullScreen then
	window.flags = bit.bor(window.flags, SDL.SDL_FULLSCREEN)
end

local screenAspectRatio = window.width/window.height

local shaders = {}
local fonts = {}
local textures = {}
local shapes = {}
local windows = {}

local fontColor = {r=1, g=1, b=1, a=1}

local function printLeftAligned(x, y, color, size, text)
	fonts.font1.print(x, y-size/2, color, size, text)
end

local function createWindow(...)
	return gui.create('window', ...)
end

local function createButton(...)
	return gui.create('button', ...)
end

local function createEditbox(...)
	return gui.create('editbox', ...)
end

local function prepareScene()
	gui.prepare(window, fonts.font1, 'abstract_stencil')

	windows.window1 = createWindow {
		properties = {
			x = 32,
			y = 32,
			z = 1,
			width = 640,
			height = 480,
			color = {0.2,0.3,0.5,1},
			name = 'Window 1',
			clip = true,
		},
		children = {
			createWindow {
				properties = {
					x = 0,
					y = 0,
					z = 20,
					width = 320,
					height = 200,
					relativeX = -0.25,
					relativeY = -0.25,
					color = {0.7,0.3,0.5,1},
					name = 'Window 2',
				},
				children = {
					createButton {
						properties = {
							x = -20,
							y = 4,
							z = 40,
							width = 100,
							height = 32,
							color = {0.7,0.7,0.5,1},
							caption = 'A button',
							name = 'Button 1',
						}
					},
					createEditbox {
						properties = {
							x = 8,
							y = -32,
							z = 40,
							width = 304,
							height = 32,
							color = {0.7,0.7,0.7,1},
							relativeX = -0.5,
							name = 'Editbox 1',
						}
					}
				}
			},
		}
	}

	gui.add(windows.window1)
	gui.topWindow.update()
end

local function drawScene()
	gl.Enable(gl_enum.GL_CULL_FACE)
	gl.Enable(gl_enum.GL_DEPTH_TEST)

	gui.update()
	gui.draw()

	gl.Disable(gl_enum.GL_DEPTH_TEST)
	gl.Disable(gl_enum.GL_CULL_FACE)
end

local keyStates = {}
local keyModStates = {}

-- a list of key modifiers paired with their scan codes
local modKeysScanCodes = {
	[SDL.KMOD_LSHIFT]=SDL.SDLK_LSHIFT, [SDL.KMOD_RSHIFT]=SDL.SDLK_RSHIFT,
	[SDL.KMOD_LCTRL]=SDLK_LCTRL, [SDL.KMOD_RCTRL]=SDL.SDLK_RCTRLT,
	[SDL.KMOD_LALT]=SDL.SDLK_LALT, [SDL.KMOD_RALT]=SDL.SDLK_RALT,
	[SDL.KMOD_LMETA]=SDL.SDLK_LMETA, [SDL.KMOD_RMETA]=SDL.SDLK_RMETA,
	[SDL.KMOD_NUM]=SDL.SDLK_NUMLOCK,
	[SDL.KMOD_CAPS]=SDL.SDLK_CAPSLOCK,
	[SDL.KMOD_MODE]=SDL.SDLK_MODE,
}

local function processModKeys()
	local modState = SDL.SDL_GetModState()
	for keyMod, keySym in pairs(modKeysScanCodes) do
		-- apply binary and operator to obtain modifier key state
		keyModStates[keySym] = (bit.band(modState, keyMod) > 0)
	end
end

local events
events = {
	startup = function()
		
		SDL.TTF_Init()
		local screen = surface.wrap(window.screen, false)

		gl.InitGLEW()
		assert(gl.IsSupported("GL_VERSION_3_0 GL_ARB_vertex_shader GL_ARB_fragment_shader"), "Your GPU doesn't support GLSL 3.3")

		-- show mouse cursor
		SDL.SDL_ShowCursor(1)

		-- enable blending
   		gl.Enable(gl_enum.GL_BLEND)
		gl.BlendFunc(gl_enum.GL_SRC_ALPHA, gl_enum.GL_ONE_MINUS_SRC_ALPHA)
		gl.BlendEquation(gl_enum.GL_FUNC_ADD)

		gl.ClearColor(0.1, 0.1, 0.1, 1)

		gl.CullFace(gl_enum.GL_FRONT)

		textures.rocks = texture.load('../../common/assets/rock.png')
		textures.rocks_normalmap = texture.load('../../common/assets/rock_n.png')
		fonts.font1 = ttf.load('../../common/assets/DejaVuSans.ttf', 128, nil, true)

		prepareScene()
	end,
	idle = function()
		-- clears the screen

		-- setup stencil write mask so you can erase stencil buffer as well
    	gl.StencilMask(0xFF)
		gl.Clear(bit.bor(gl_enum.GL_COLOR_BUFFER_BIT, gl_enum.GL_DEPTH_BUFFER_BIT, gl_enum.GL_STENCIL_BUFFER_BIT))
    	gl.StencilMask(0x00)

		processModKeys()

		drawScene()

		-- flip content of the back-buffer into front-buffer (screen) - similar to SDL.SDL_Flip function
		SDL.SDL_GL_SwapBuffers()
	end,
	[SDL.SDL_ACTIVEEVENT] = function(event_struct)
		local event = event_struct.active
		--[[
		if SDL.And(event.state, SDL.SDL_APPINPUTFOCUS) > 0 then
			if event.gain == 1 then
				SDL.SDL_WarpMouse(mouseState.centerX, mouseState.centerY)
				events[SDL.SDL_MOUSEMOTION] = mouseMotionHandler
			else
				events[SDL.SDL_MOUSEMOTION] = false
			end
		end
		--]]
	end,
	
	[SDL.SDL_MOUSEMOTION] = function(event_struct)
		local event = event_struct.motion
		gui.invoke('mouseMove', event.x, event.y)
	end,
	[SDL.SDL_MOUSEBUTTONDOWN] = function(event_struct)
    	local event = event_struct.button
		gui.invoke('mouseButtonDown', event.x, event.y, event.button)
	end,
	[SDL.SDL_MOUSEBUTTONUP] = function(event_struct)
		local event = event_struct.button
		gui.invoke('mouseButtonUp', event.x, event.y, event.button)
	end,

	[SDL.SDL_KEYDOWN] = function(event_struct) 
		local event = event_struct.key
		local keySym = event.keysym.sym
		local keyMod = event.keysym.mod
		
		keyStates[keySym] = true
		gui.invoke('keyDown', keySym, keyMod)

	    -- send SDL_QUIT event on Escape key
		if keySym == SDL.SDLK_ESCAPE then
			local event = SDL.SDL_Event_local()
			event.type = SDL.SDL_QUIT
			SDL.SDL_PushEvent(event)
		end
	end,
	[SDL.SDL_KEYUP] = function(event_struct) 
		local event = event_struct.key
		local keySym = event.keysym.sym
		local keyMod = event.keysym.mod

		keyStates[keySym] = false
		gui.invoke('keyUp', keySym, keyMod)
	end,
	cleanup = function()
		fonts.font1.delete()
		SDL.TTF_Quit()
	end,
}

app.main(window, events)

