import sdl2, sdl2/[ttf, mixer], sdl2/image as sdlimage

template withSurface*(surf: SurfacePtr, body: untyped): untyped {.dirty.} =
  let it = surf
  if unlikely(it.isNil):
    quit "Surface was nil, error: " & $getError()
  body
  freeSurface(it)

template withSurface*(surf: SurfacePtr, name, body: untyped): untyped {.dirty.} =
  let `name` = surf
  if unlikely(`name`.isNil):
    quit "Surface was nil, error: " & $getError()
  body
  freeSurface(`name`)

template quitErr*(desc: string) =
  write(stderr, desc & ": ")
  write(stderr, getError())
  quit 1

template unwrap*(notFalse: bool, msg: string) =
  if not notFalse:
    quitErr "Error: " & msg

template unwrap*(notFalse: Bool32, msg: string) =
  if not notFalse.bool:
    quitErr "Error: " & msg

template unwrap*[T](notNil: ptr T, msg: string): ptr T =
  let it = notNil
  if it.isNil:
    quitErr "Error: " & msg
  it

proc toCstring*(c: char): cstring = # for rendering single chars
  var res = [c, '\0']
  result = cast[cstring](addr res)

const mods* = (
  KMOD_LCTRL.cint or KMOD_RCTRL.cint or
  KMOD_LSHIFT.cint or KMOD_RSHIFT.cint or
  KMOD_LALT.cint or KMOD_RALT.cint)

template modsHeldDown*: bool =
  (getModState().cint and mods) != 0

template rgb*(x: int32): Color =
  cast[Color]((x shl 8) or 0xFF)

template rgba*(x: int32): Color =
  cast[Color](x)

template draw*(renderer: RendererPtr, texture: TexturePtr, src, dest: var Rect) =
  renderer.copy(texture, addr src, addr dest)

proc draw*(renderer: RendererPtr, texture: TexturePtr, src, dest: Rect) =
  var
    src = src
    dest = dest
  renderer.draw(texture, src, dest)

proc draw*(renderer: RendererPtr, texture: TexturePtr, dest: var Rect) =
  renderer.copy(texture, nil, addr dest)

template draw*(renderer: RendererPtr, texture: TexturePtr, dest: Rect{`let`}) =
  renderer.copy(texture, nil, unsafeAddr dest)

proc draw*(renderer: RendererPtr, texture: TexturePtr, dest: Rect) =
  var dest = dest
  renderer.draw(texture, dest)

proc draw*(renderer: RendererPtr, texture: TexturePtr, x, y: cint) =
  var
    dest = rect(x, y, 0, 0)
  texture.queryTexture(nil, nil, addr dest.w, addr dest.h)
  renderer.copy(texture, nil, addr dest)

template withSurfaceToTexture*(renderer: RendererPtr, surface: SurfacePtr, body) =
  let surf = surface
  let texture {.inject.} = createTextureFromSurface(renderer, surf)
  surf.destroy()
  body
  texture.destroy()

template withTextSolid*(renderer: RendererPtr, font: FontPtr, text: cstring, color: Color, body) =
  renderer.withSurfaceToTexture(renderTextSolid(font, text, color), body)

template withTextShaded*(renderer: RendererPtr, font: FontPtr, text: cstring, color: Color, body) =
  renderer.withSurfaceToTexture(renderTextShaded(font, text, color), body)

template withTextBlended*(renderer: RendererPtr, font: FontPtr, text: cstring, color: Color, body) =
  renderer.withSurfaceToTexture(renderTextBlended(font, text, color), body)

template withTextBlendedWrapped*(renderer: RendererPtr, font: FontPtr, text: cstring, color: Color, wrap: uint32, body) =
  renderer.withSurfaceToTexture(renderTextBlendedWrapped(font, text, color, wrap), body)

proc drawRect*(renderer: RendererPtr, rect: Rect) =
  renderer.drawRect(unsafeAddr rect)

proc stopMusic*(music: var MusicPtr) =
  discard haltMusic()
  freeMusic(music)
  music = nil

proc setMusic*(music: var MusicPtr, file: cstring) =
  if not music.isNil:
    music.stopMusic()
  music = loadMus(file)
  if unlikely(music.isNil):
    quitErr "Couldn't load music " & $file

proc loopMusic*(music: MusicPtr): cint {.discardable, inline.} =
  playMusic(music, -1)

proc playMusic*(music: MusicPtr): cint {.discardable, inline.} =
  playMusic(music, 1)

proc playSound*(chunk: ChunkPtr): cint {.discardable, inline.} =
  playChannel(-1, chunk, 0)
