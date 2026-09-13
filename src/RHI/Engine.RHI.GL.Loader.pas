

unit Engine.RHI.GL.Loader;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$MINENUMSIZE 4}

interface

uses
  SysUtils;

type
  GLenum      = Cardinal;
  GLboolean   = Byte;
  GLbitfield  = Cardinal;
  GLint       = Integer;
  GLuint      = Cardinal;
  GLsizei     = Integer;
  GLfloat     = Single;
  GLdouble    = Double;
  GLintptr    = NativeInt;
  GLsizeiptr  = NativeInt;

  PGLint      = ^GLint;
  PGLuint     = ^GLuint;
  PGLsizei    = ^GLsizei;
  PGLfloat    = ^GLfloat;
  PPAnsiChar  = ^PAnsiChar;

  TGLDebugProc = procedure(source, atype: GLenum; id: GLuint; severity: GLenum;
    length: GLsizei; const message_: PAnsiChar; const userParam: Pointer); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};

  TGLGetProcAddress = function(const Name: PAnsiChar): Pointer of object;

  EGLLoaderError = class(Exception);

const
  GL_FALSE = 0;  GL_TRUE = 1;
  GL_NO_ERROR = 0;

  GL_VENDOR   = $1F00;  GL_RENDERER = $1F01;
  GL_VERSION  = $1F02;  GL_SHADING_LANGUAGE_VERSION = $8B8C;

  GL_DEPTH_BUFFER_BIT   = $00000100;
  GL_STENCIL_BUFFER_BIT = $00000400;
  GL_COLOR_BUFFER_BIT   = $00004000;

  GL_DEPTH_TEST   = $0B71;  GL_BLEND      = $0BE2;
  GL_CULL_FACE    = $0B44;  GL_SCISSOR_TEST = $0C11;
  GL_MULTISAMPLE  = $809D;  GL_DEBUG_OUTPUT = $92E0;
  GL_DEBUG_OUTPUT_SYNCHRONOUS = $8242;
  GL_FRAMEBUFFER_SRGB = $8DB9;

  GL_ZERO = 0;  GL_ONE = 1;
  GL_SRC_ALPHA = $0302;  GL_ONE_MINUS_SRC_ALPHA = $0303;
  GL_SRC_COLOR = $0300;  GL_ONE_MINUS_SRC_COLOR = $0301;
  GL_DST_ALPHA = $0304;  GL_ONE_MINUS_DST_ALPHA = $0305;
  GL_FUNC_ADD = $8006;

  GL_NEVER = $0200;  GL_LESS = $0201;  GL_EQUAL = $0202;
  GL_LEQUAL = $0203; GL_GREATER = $0204; GL_ALWAYS = $0207;
  GL_BACK = $0405;   GL_FRONT = $0404;
  GL_CCW = $0901;    GL_CW = $0900;

  GL_BYTE = $1400;  GL_UNSIGNED_BYTE = $1401;
  GL_SHORT = $1402; GL_UNSIGNED_SHORT = $1403;
  GL_INT = $1404;   GL_UNSIGNED_INT = $1405;
  GL_FLOAT = $1406;

  GL_ARRAY_BUFFER = $8892;  GL_ELEMENT_ARRAY_BUFFER = $8893;
  GL_UNIFORM_BUFFER = $8A11;
  GL_STREAM_DRAW = $88E0;  GL_STATIC_DRAW = $88E4;  GL_DYNAMIC_DRAW = $88E8;

  GL_FRAGMENT_SHADER = $8B30;  GL_VERTEX_SHADER = $8B31;
  GL_COMPILE_STATUS = $8B81;   GL_LINK_STATUS = $8B82;
  GL_INFO_LOG_LENGTH = $8B84;

  GL_TEXTURE_2D = $0DE1;
  GL_TEXTURE0 = $84C0;
  GL_TEXTURE_MAG_FILTER = $2800;  GL_TEXTURE_MIN_FILTER = $2801;
  GL_TEXTURE_WRAP_S = $2802;      GL_TEXTURE_WRAP_T = $2803;
  GL_NEAREST = $2600;  GL_LINEAR = $2601;
  GL_NEAREST_MIPMAP_NEAREST = $2700;  GL_LINEAR_MIPMAP_LINEAR = $2703;
  GL_REPEAT = $2901;  GL_CLAMP_TO_EDGE = $812F;
  GL_MIRRORED_REPEAT = $8370;
  GL_RED = $1903;  GL_RGB = $1907;  GL_RGBA = $1908;
  GL_R8 = $8229;   GL_RGB8 = $8051; GL_RGBA8 = $8058;
  GL_SRGB8_ALPHA8 = $8C43;
  GL_UNPACK_ALIGNMENT = $0CF5;
  GL_PACK_ALIGNMENT = $0D05;
  GL_BGRA = $80E1;

  GL_FRAMEBUFFER = $8D40;
  GL_COLOR_ATTACHMENT0 = $8CE0;
  GL_FRAMEBUFFER_COMPLETE = $8CD5;

  GL_POINTS = $0000;  GL_LINES = $0001;  GL_LINE_STRIP = $0003;
  GL_TRIANGLES = $0004;  GL_TRIANGLE_STRIP = $0005;  GL_TRIANGLE_FAN = $0006;

  GL_DEBUG_SEVERITY_HIGH = $9146;  GL_DEBUG_SEVERITY_MEDIUM = $9147;
  GL_DEBUG_SEVERITY_LOW = $9148;   GL_DEBUG_SEVERITY_NOTIFICATION = $826B;
  GL_DONT_CARE = $1100;

  GL_MAX_TEXTURE_SIZE = $0D33;
  GL_MAX_TEXTURE_IMAGE_UNITS = $8872;

type
  TglGetString = function(name: GLenum): PAnsiChar; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglGetIntegerv = procedure(pname: GLenum; data: PGLint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglGetError = function: GLenum; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglViewport = procedure(x, y: GLint; width, height: GLsizei); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglScissor = procedure(x, y: GLint; width, height: GLsizei); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglEnable = procedure(cap: GLenum); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglDisable = procedure(cap: GLenum); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglClearColor = procedure(red, green, blue, alpha: GLfloat); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglClear = procedure(mask: GLbitfield); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglBlendFunc = procedure(sfactor, dfactor: GLenum); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglBlendFuncSeparate = procedure(srcRGB, dstRGB, srcAlpha, dstAlpha: GLenum); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglBlendEquation = procedure(mode: GLenum); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglDepthFunc = procedure(func: GLenum); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglDepthMask = procedure(flag: GLboolean); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglCullFace = procedure(mode: GLenum); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglFrontFace = procedure(mode: GLenum); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglPixelStorei = procedure(pname: GLenum; param: GLint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglGenBuffers = procedure(n: GLsizei; buffers: PGLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglDeleteBuffers = procedure(n: GLsizei; const buffers: PGLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglBindBuffer = procedure(target: GLenum; buffer: GLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglBufferData = procedure(target: GLenum; size: GLsizeiptr; const data: Pointer; usage: GLenum); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglBufferSubData = procedure(target: GLenum; offset: GLintptr; size: GLsizeiptr; const data: Pointer); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglGenVertexArrays = procedure(n: GLsizei; arrays: PGLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglDeleteVertexArrays = procedure(n: GLsizei; const arrays: PGLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglBindVertexArray = procedure(arr: GLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglEnableVertexAttribArray = procedure(index: GLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglVertexAttribPointer = procedure(index: GLuint; size: GLint; atype: GLenum; normalized: GLboolean; stride: GLsizei; const pointer_: Pointer); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglVertexAttribIPointer = procedure(index: GLuint; size: GLint; atype: GLenum; stride: GLsizei; const pointer_: Pointer); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglCreateShader = function(shaderType: GLenum): GLuint; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglShaderSource = procedure(shader: GLuint; count: GLsizei; const str: PPAnsiChar; const length: PGLint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglCompileShader = procedure(shader: GLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglGetShaderiv = procedure(shader: GLuint; pname: GLenum; params: PGLint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglGetShaderInfoLog = procedure(shader: GLuint; maxLength: GLsizei; length: PGLsizei; infoLog: PAnsiChar); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglDeleteShader = procedure(shader: GLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglCreateProgram = function: GLuint; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglAttachShader = procedure(program_, shader: GLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglDetachShader = procedure(program_, shader: GLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglLinkProgram = procedure(program_: GLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglGetProgramiv = procedure(program_: GLuint; pname: GLenum; params: PGLint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglGetProgramInfoLog = procedure(program_: GLuint; maxLength: GLsizei; length: PGLsizei; infoLog: PAnsiChar); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglUseProgram = procedure(program_: GLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglDeleteProgram = procedure(program_: GLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglGetUniformLocation = function(program_: GLuint; const name: PAnsiChar): GLint; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglUniform1i = procedure(location: GLint; v0: GLint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglUniform1f = procedure(location: GLint; v0: GLfloat); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglUniform2f = procedure(location: GLint; v0, v1: GLfloat); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglUniform3f = procedure(location: GLint; v0, v1, v2: GLfloat); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglUniform4f = procedure(location: GLint; v0, v1, v2, v3: GLfloat); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglUniformMatrix4fv = procedure(location: GLint; count: GLsizei; transpose: GLboolean; const value: PGLfloat); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglGenTextures = procedure(n: GLsizei; textures: PGLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglDeleteTextures = procedure(n: GLsizei; const textures: PGLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglBindTexture = procedure(target: GLenum; texture: GLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglActiveTexture = procedure(texture: GLenum); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglTexImage2D = procedure(target: GLenum; level, internalFormat: GLint; width, height: GLsizei; border: GLint; format, atype: GLenum; const data: Pointer); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglTexSubImage2D = procedure(target: GLenum; level, xoffset, yoffset: GLint; width, height: GLsizei; format, atype: GLenum; const data: Pointer); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglTexParameteri = procedure(target: GLenum; pname: GLenum; param: GLint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglGenerateMipmap = procedure(target: GLenum); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglGenFramebuffers = procedure(n: GLsizei; framebuffers: PGLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglDeleteFramebuffers = procedure(n: GLsizei; const framebuffers: PGLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglBindFramebuffer = procedure(target: GLenum; framebuffer: GLuint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglFramebufferTexture2D = procedure(target, attachment, textarget: GLenum; texture: GLuint; level: GLint); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglCheckFramebufferStatus = function(target: GLenum): GLenum; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglReadPixels = procedure(x, y: GLint; width, height: GLsizei; format, atype: GLenum; pixels: Pointer); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglDrawArrays = procedure(mode: GLenum; first: GLint; count: GLsizei); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglDrawElements = procedure(mode: GLenum; count: GLsizei; atype: GLenum; const indices: Pointer); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglDebugMessageCallback = procedure(callback: TGLDebugProc; const userParam: Pointer); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TglDebugMessageControl = procedure(source, atype, severity: GLenum; count: GLsizei; const ids: PGLuint; enabled: GLboolean); {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};

var
  glGetString: TglGetString;
  glGetIntegerv: TglGetIntegerv;
  glGetError: TglGetError;
  glViewport: TglViewport;
  glScissor: TglScissor;
  glEnable: TglEnable;
  glDisable: TglDisable;
  glClearColor: TglClearColor;
  glClear: TglClear;
  glBlendFunc: TglBlendFunc;
  glBlendFuncSeparate: TglBlendFuncSeparate;
  glBlendEquation: TglBlendEquation;
  glDepthFunc: TglDepthFunc;
  glDepthMask: TglDepthMask;
  glCullFace: TglCullFace;
  glFrontFace: TglFrontFace;
  glPixelStorei: TglPixelStorei;
  glGenBuffers: TglGenBuffers;
  glDeleteBuffers: TglDeleteBuffers;
  glBindBuffer: TglBindBuffer;
  glBufferData: TglBufferData;
  glBufferSubData: TglBufferSubData;
  glGenVertexArrays: TglGenVertexArrays;
  glDeleteVertexArrays: TglDeleteVertexArrays;
  glBindVertexArray: TglBindVertexArray;
  glEnableVertexAttribArray: TglEnableVertexAttribArray;
  glVertexAttribPointer: TglVertexAttribPointer;
  glVertexAttribIPointer: TglVertexAttribIPointer;
  glCreateShader: TglCreateShader;
  glShaderSource: TglShaderSource;
  glCompileShader: TglCompileShader;
  glGetShaderiv: TglGetShaderiv;
  glGetShaderInfoLog: TglGetShaderInfoLog;
  glDeleteShader: TglDeleteShader;
  glCreateProgram: TglCreateProgram;
  glAttachShader: TglAttachShader;
  glDetachShader: TglDetachShader;
  glLinkProgram: TglLinkProgram;
  glGetProgramiv: TglGetProgramiv;
  glGetProgramInfoLog: TglGetProgramInfoLog;
  glUseProgram: TglUseProgram;
  glDeleteProgram: TglDeleteProgram;
  glGetUniformLocation: TglGetUniformLocation;
  glUniform1i: TglUniform1i;
  glUniform1f: TglUniform1f;
  glUniform2f: TglUniform2f;
  glUniform3f: TglUniform3f;
  glUniform4f: TglUniform4f;
  glUniformMatrix4fv: TglUniformMatrix4fv;
  glGenTextures: TglGenTextures;
  glDeleteTextures: TglDeleteTextures;
  glBindTexture: TglBindTexture;
  glActiveTexture: TglActiveTexture;
  glTexImage2D: TglTexImage2D;
  glTexSubImage2D: TglTexSubImage2D;
  glTexParameteri: TglTexParameteri;
  glGenerateMipmap: TglGenerateMipmap;
  glGenFramebuffers: TglGenFramebuffers;
  glDeleteFramebuffers: TglDeleteFramebuffers;
  glBindFramebuffer: TglBindFramebuffer;
  glFramebufferTexture2D: TglFramebufferTexture2D;
  glCheckFramebufferStatus: TglCheckFramebufferStatus;
  glReadPixels: TglReadPixels;
  glDrawArrays: TglDrawArrays;
  glDrawElements: TglDrawElements;
  glDebugMessageCallback: TglDebugMessageCallback;
  glDebugMessageControl: TglDebugMessageControl;

procedure LoadGL(const Get: TGLGetProcAddress);
function GLLoaded: Boolean;

function GLHasDebugOutput: Boolean;

function GLErrorName(const E: GLenum): string;

implementation

var
  GLoaded: Boolean = False;

function GLLoaded: Boolean;
begin
  Result := GLoaded;
end;

function GLHasDebugOutput: Boolean;
begin
  Result := GLoaded and Assigned(glDebugMessageCallback);
end;

function GLErrorName(const E: GLenum): string;
begin
  case E of
    0:      Result := 'GL_NO_ERROR';
    $0500:  Result := 'GL_INVALID_ENUM';
    $0501:  Result := 'GL_INVALID_VALUE';
    $0502:  Result := 'GL_INVALID_OPERATION';
    $0503:  Result := 'GL_STACK_OVERFLOW';
    $0504:  Result := 'GL_STACK_UNDERFLOW';
    $0505:  Result := 'GL_OUT_OF_MEMORY';
    $0506:  Result := 'GL_INVALID_FRAMEBUFFER_OPERATION';
  else
    Result := '0x' + IntToHex(E, 4);
  end;
end;

procedure Need(const P: Pointer; const Name: string);
begin
  if PPointer(P)^ = nil then
    raise EGLLoaderError.CreateFmt(
      'OpenGL: simbolo "%s" nao encontrado. O driver provavelmente nao ' +
      'suporta OpenGL 3.3 core.', [Name]);
end;

procedure LoadGL(const Get: TGLGetProcAddress);
begin
  if not Assigned(Get) then
    raise EGLLoaderError.Create('LoadGL: resolvedor de simbolo nao fornecido');

  glGetString := Get('glGetString');
  glGetIntegerv := Get('glGetIntegerv');
  glGetError := Get('glGetError');
  glViewport := Get('glViewport');
  glScissor := Get('glScissor');
  glEnable := Get('glEnable');
  glDisable := Get('glDisable');
  glClearColor := Get('glClearColor');
  glClear := Get('glClear');
  glBlendFunc := Get('glBlendFunc');
  glBlendFuncSeparate := Get('glBlendFuncSeparate');
  glBlendEquation := Get('glBlendEquation');
  glDepthFunc := Get('glDepthFunc');
  glDepthMask := Get('glDepthMask');
  glCullFace := Get('glCullFace');
  glFrontFace := Get('glFrontFace');
  glPixelStorei := Get('glPixelStorei');
  glGenBuffers := Get('glGenBuffers');
  glDeleteBuffers := Get('glDeleteBuffers');
  glBindBuffer := Get('glBindBuffer');
  glBufferData := Get('glBufferData');
  glBufferSubData := Get('glBufferSubData');
  glGenVertexArrays := Get('glGenVertexArrays');
  glDeleteVertexArrays := Get('glDeleteVertexArrays');
  glBindVertexArray := Get('glBindVertexArray');
  glEnableVertexAttribArray := Get('glEnableVertexAttribArray');
  glVertexAttribPointer := Get('glVertexAttribPointer');
  glVertexAttribIPointer := Get('glVertexAttribIPointer');
  glCreateShader := Get('glCreateShader');
  glShaderSource := Get('glShaderSource');
  glCompileShader := Get('glCompileShader');
  glGetShaderiv := Get('glGetShaderiv');
  glGetShaderInfoLog := Get('glGetShaderInfoLog');
  glDeleteShader := Get('glDeleteShader');
  glCreateProgram := Get('glCreateProgram');
  glAttachShader := Get('glAttachShader');
  glDetachShader := Get('glDetachShader');
  glLinkProgram := Get('glLinkProgram');
  glGetProgramiv := Get('glGetProgramiv');
  glGetProgramInfoLog := Get('glGetProgramInfoLog');
  glUseProgram := Get('glUseProgram');
  glDeleteProgram := Get('glDeleteProgram');
  glGetUniformLocation := Get('glGetUniformLocation');
  glUniform1i := Get('glUniform1i');
  glUniform1f := Get('glUniform1f');
  glUniform2f := Get('glUniform2f');
  glUniform3f := Get('glUniform3f');
  glUniform4f := Get('glUniform4f');
  glUniformMatrix4fv := Get('glUniformMatrix4fv');
  glGenTextures := Get('glGenTextures');
  glDeleteTextures := Get('glDeleteTextures');
  glBindTexture := Get('glBindTexture');
  glActiveTexture := Get('glActiveTexture');
  glTexImage2D := Get('glTexImage2D');
  glTexSubImage2D := Get('glTexSubImage2D');
  glTexParameteri := Get('glTexParameteri');
  glGenerateMipmap := Get('glGenerateMipmap');
  glGenFramebuffers := Get('glGenFramebuffers');
  glDeleteFramebuffers := Get('glDeleteFramebuffers');
  glBindFramebuffer := Get('glBindFramebuffer');
  glFramebufferTexture2D := Get('glFramebufferTexture2D');
  glCheckFramebufferStatus := Get('glCheckFramebufferStatus');
  glReadPixels := Get('glReadPixels');
  glDrawArrays := Get('glDrawArrays');
  glDrawElements := Get('glDrawElements');
  glDebugMessageCallback := Get('glDebugMessageCallback');
  glDebugMessageControl := Get('glDebugMessageControl');

  Need(@glGetString, 'glGetString');
  Need(@glGetIntegerv, 'glGetIntegerv');
  Need(@glGetError, 'glGetError');
  Need(@glViewport, 'glViewport');
  Need(@glScissor, 'glScissor');
  Need(@glEnable, 'glEnable');
  Need(@glDisable, 'glDisable');
  Need(@glClearColor, 'glClearColor');
  Need(@glClear, 'glClear');
  Need(@glBlendFunc, 'glBlendFunc');
  Need(@glBlendFuncSeparate, 'glBlendFuncSeparate');
  Need(@glBlendEquation, 'glBlendEquation');
  Need(@glDepthFunc, 'glDepthFunc');
  Need(@glDepthMask, 'glDepthMask');
  Need(@glCullFace, 'glCullFace');
  Need(@glFrontFace, 'glFrontFace');
  Need(@glPixelStorei, 'glPixelStorei');
  Need(@glGenBuffers, 'glGenBuffers');
  Need(@glDeleteBuffers, 'glDeleteBuffers');
  Need(@glBindBuffer, 'glBindBuffer');
  Need(@glBufferData, 'glBufferData');
  Need(@glBufferSubData, 'glBufferSubData');
  Need(@glGenVertexArrays, 'glGenVertexArrays');
  Need(@glDeleteVertexArrays, 'glDeleteVertexArrays');
  Need(@glBindVertexArray, 'glBindVertexArray');
  Need(@glEnableVertexAttribArray, 'glEnableVertexAttribArray');
  Need(@glVertexAttribPointer, 'glVertexAttribPointer');
  Need(@glVertexAttribIPointer, 'glVertexAttribIPointer');
  Need(@glCreateShader, 'glCreateShader');
  Need(@glShaderSource, 'glShaderSource');
  Need(@glCompileShader, 'glCompileShader');
  Need(@glGetShaderiv, 'glGetShaderiv');
  Need(@glGetShaderInfoLog, 'glGetShaderInfoLog');
  Need(@glDeleteShader, 'glDeleteShader');
  Need(@glCreateProgram, 'glCreateProgram');
  Need(@glAttachShader, 'glAttachShader');
  Need(@glDetachShader, 'glDetachShader');
  Need(@glLinkProgram, 'glLinkProgram');
  Need(@glGetProgramiv, 'glGetProgramiv');
  Need(@glGetProgramInfoLog, 'glGetProgramInfoLog');
  Need(@glUseProgram, 'glUseProgram');
  Need(@glDeleteProgram, 'glDeleteProgram');
  Need(@glGetUniformLocation, 'glGetUniformLocation');
  Need(@glUniform1i, 'glUniform1i');
  Need(@glUniform1f, 'glUniform1f');
  Need(@glUniform2f, 'glUniform2f');
  Need(@glUniform3f, 'glUniform3f');
  Need(@glUniform4f, 'glUniform4f');
  Need(@glUniformMatrix4fv, 'glUniformMatrix4fv');
  Need(@glGenTextures, 'glGenTextures');
  Need(@glDeleteTextures, 'glDeleteTextures');
  Need(@glBindTexture, 'glBindTexture');
  Need(@glActiveTexture, 'glActiveTexture');
  Need(@glTexImage2D, 'glTexImage2D');
  Need(@glTexSubImage2D, 'glTexSubImage2D');
  Need(@glTexParameteri, 'glTexParameteri');
  Need(@glGenerateMipmap, 'glGenerateMipmap');
  Need(@glGenFramebuffers, 'glGenFramebuffers');
  Need(@glDeleteFramebuffers, 'glDeleteFramebuffers');
  Need(@glBindFramebuffer, 'glBindFramebuffer');
  Need(@glFramebufferTexture2D, 'glFramebufferTexture2D');
  Need(@glCheckFramebufferStatus, 'glCheckFramebufferStatus');
  Need(@glReadPixels, 'glReadPixels');
  Need(@glDrawArrays, 'glDrawArrays');
  Need(@glDrawElements, 'glDrawElements');

  GLoaded := True;
end;

end.
