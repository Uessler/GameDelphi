

unit Engine.Platform.SDL2;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$MINENUMSIZE 4}
{$ALIGN 4}

interface

const
{$IFDEF MSWINDOWS}
  SDL_LIB = 'SDL2.dll';
{$ELSE}
  SDL_LIB = 'libSDL2-2.0.so.0';
{$ENDIF}

const
  SDL_INIT_TIMER    = $00000001;
  SDL_INIT_VIDEO    = $00000020;
  SDL_INIT_EVENTS   = $00004000;

const
  SDL_WINDOWPOS_CENTERED      = $2FFF0000;

  SDL_WINDOW_FULLSCREEN       = $00000001;
  SDL_WINDOW_OPENGL           = $00000002;
  SDL_WINDOW_SHOWN            = $00000004;
  SDL_WINDOW_HIDDEN           = $00000008;
  SDL_WINDOW_RESIZABLE        = $00000020;
  SDL_WINDOW_MINIMIZED        = $00000040;
  SDL_WINDOW_MAXIMIZED        = $00000080;
  SDL_WINDOW_ALLOW_HIGHDPI    = $00002000;

const
  SDL_GL_RED_SIZE             = 0;
  SDL_GL_GREEN_SIZE           = 1;
  SDL_GL_BLUE_SIZE            = 2;
  SDL_GL_ALPHA_SIZE           = 3;
  SDL_GL_DOUBLEBUFFER         = 5;
  SDL_GL_DEPTH_SIZE           = 6;
  SDL_GL_STENCIL_SIZE         = 7;
  SDL_GL_MULTISAMPLEBUFFERS   = 13;
  SDL_GL_MULTISAMPLESAMPLES   = 14;
  SDL_GL_CONTEXT_MAJOR_VERSION = 17;
  SDL_GL_CONTEXT_MINOR_VERSION = 18;
  SDL_GL_CONTEXT_FLAGS        = 20;
  SDL_GL_CONTEXT_PROFILE_MASK = 21;

  SDL_GL_CONTEXT_PROFILE_CORE          = $0001;
  SDL_GL_CONTEXT_PROFILE_COMPATIBILITY = $0002;
  SDL_GL_CONTEXT_DEBUG_FLAG            = $0001;

const
  SDL_EV_QUIT             = $100;
  SDL_EV_WINDOWEVENT      = $200;
  SDL_EV_KEYDOWN          = $300;
  SDL_EV_KEYUP            = $301;
  SDL_EV_TEXTINPUT        = $303;
  SDL_EV_MOUSEMOTION      = $400;
  SDL_EV_MOUSEBUTTONDOWN  = $401;
  SDL_EV_MOUSEBUTTONUP    = $402;
  SDL_EV_MOUSEWHEEL       = $403;

  SDL_WINDOWEVENT_SHOWN         = 1;
  SDL_WINDOWEVENT_HIDDEN        = 2;
  SDL_WINDOWEVENT_RESIZED       = 5;
  SDL_WINDOWEVENT_SIZE_CHANGED  = 6;
  SDL_WINDOWEVENT_MINIMIZED     = 7;
  SDL_WINDOWEVENT_RESTORED      = 9;
  SDL_WINDOWEVENT_FOCUS_GAINED  = 12;
  SDL_WINDOWEVENT_FOCUS_LOST    = 13;
  SDL_WINDOWEVENT_CLOSE         = 14;

const
  SDL_BUTTON_LEFT   = 1;
  SDL_BUTTON_MIDDLE = 2;
  SDL_BUTTON_RIGHT  = 3;
  SDL_BUTTON_X1     = 4;
  SDL_BUTTON_X2     = 5;

const
  SDL_NUM_SCANCODES = 512;

  SDL_SCANCODE_A = 4;   SDL_SCANCODE_B = 5;   SDL_SCANCODE_C = 6;
  SDL_SCANCODE_D = 7;   SDL_SCANCODE_E = 8;   SDL_SCANCODE_F = 9;
  SDL_SCANCODE_G = 10;  SDL_SCANCODE_H = 11;  SDL_SCANCODE_I = 12;
  SDL_SCANCODE_J = 13;  SDL_SCANCODE_K = 14;  SDL_SCANCODE_L = 15;
  SDL_SCANCODE_M = 16;  SDL_SCANCODE_N = 17;  SDL_SCANCODE_O = 18;
  SDL_SCANCODE_P = 19;  SDL_SCANCODE_Q = 20;  SDL_SCANCODE_R = 21;
  SDL_SCANCODE_S = 22;  SDL_SCANCODE_T = 23;  SDL_SCANCODE_U = 24;
  SDL_SCANCODE_V = 25;  SDL_SCANCODE_W = 26;  SDL_SCANCODE_X = 27;
  SDL_SCANCODE_Y = 28;  SDL_SCANCODE_Z = 29;

  SDL_SCANCODE_1 = 30;  SDL_SCANCODE_2 = 31;  SDL_SCANCODE_3 = 32;
  SDL_SCANCODE_4 = 33;  SDL_SCANCODE_5 = 34;  SDL_SCANCODE_6 = 35;
  SDL_SCANCODE_7 = 36;  SDL_SCANCODE_8 = 37;  SDL_SCANCODE_9 = 38;
  SDL_SCANCODE_0 = 39;

  SDL_SCANCODE_RETURN    = 40;
  SDL_SCANCODE_ESCAPE    = 41;
  SDL_SCANCODE_BACKSPACE = 42;
  SDL_SCANCODE_TAB       = 43;
  SDL_SCANCODE_SPACE     = 44;

  SDL_SCANCODE_F1  = 58;  SDL_SCANCODE_F2  = 59;  SDL_SCANCODE_F3  = 60;
  SDL_SCANCODE_F4  = 61;  SDL_SCANCODE_F5  = 62;  SDL_SCANCODE_F6  = 63;
  SDL_SCANCODE_F7  = 64;  SDL_SCANCODE_F8  = 65;  SDL_SCANCODE_F9  = 66;
  SDL_SCANCODE_F10 = 67;  SDL_SCANCODE_F11 = 68;  SDL_SCANCODE_F12 = 69;

  SDL_SCANCODE_RIGHT = 79;
  SDL_SCANCODE_LEFT  = 80;
  SDL_SCANCODE_DOWN  = 81;
  SDL_SCANCODE_UP    = 82;

  SDL_SCANCODE_LCTRL  = 224;
  SDL_SCANCODE_LSHIFT = 225;
  SDL_SCANCODE_LALT   = 226;
  SDL_SCANCODE_RCTRL  = 228;
  SDL_SCANCODE_RSHIFT = 229;
  SDL_SCANCODE_RALT   = 230;

type
  TSDL_Window = Pointer;
  TSDL_GLContext = Pointer;

  TSDL_Keysym = record
    Scancode: Integer;
    Sym: Integer;
    Modifiers: Word;
    Unused: Cardinal;
  end;

  TSDL_KeyboardEvent = record
    Kind: Cardinal;
    Timestamp: Cardinal;
    WindowID: Cardinal;
    State: Byte;
    Repeated: Byte;
    Padding2: Byte;
    Padding3: Byte;
    Keysym: TSDL_Keysym;
  end;

  TSDL_MouseMotionEvent = record
    Kind: Cardinal;
    Timestamp: Cardinal;
    WindowID: Cardinal;
    Which: Cardinal;
    State: Cardinal;
    X, Y: Integer;
    XRel, YRel: Integer;
  end;

  TSDL_MouseButtonEvent = record
    Kind: Cardinal;
    Timestamp: Cardinal;
    WindowID: Cardinal;
    Which: Cardinal;
    Button: Byte;
    State: Byte;
    Clicks: Byte;
    Padding1: Byte;
    X, Y: Integer;
  end;

  TSDL_MouseWheelEvent = record
    Kind: Cardinal;
    Timestamp: Cardinal;
    WindowID: Cardinal;
    Which: Cardinal;
    X, Y: Integer;
    Direction: Cardinal;
  end;

  TSDL_WindowEvent = record
    Kind: Cardinal;
    Timestamp: Cardinal;
    WindowID: Cardinal;
    Event: Byte;
    Padding1: Byte;
    Padding2: Byte;
    Padding3: Byte;
    Data1: Integer;
    Data2: Integer;
  end;

  TSDL_Event = record
    case Integer of
      0: (Kind: Cardinal);
      1: (Key: TSDL_KeyboardEvent);
      2: (Motion: TSDL_MouseMotionEvent);
      3: (Button: TSDL_MouseButtonEvent);
      4: (Wheel: TSDL_MouseWheelEvent);
      5: (Window: TSDL_WindowEvent);
      6: (Padding: array [0 .. 55] of Byte);
  end;
  PSDL_Event = ^TSDL_Event;

const

  SDL_HINT_VIDEO_FOREIGN_WINDOW_OPENGL = 'SDL_VIDEO_FOREIGN_WINDOW_OPENGL';

function SDL_SetHint(const Name, Value: PAnsiChar): Integer; cdecl;
  external SDL_LIB;

function SDL_Init(Flags: Cardinal): Integer; cdecl; external SDL_LIB;
procedure SDL_Quit; cdecl; external SDL_LIB;
function SDL_GetError: PAnsiChar; cdecl; external SDL_LIB;

function SDL_CreateWindow(const Title: PAnsiChar; X, Y, W, H: Integer;
  Flags: Cardinal): TSDL_Window; cdecl; external SDL_LIB;

function SDL_CreateWindowFrom(const Data: Pointer): TSDL_Window; cdecl;
  external SDL_LIB;
procedure SDL_DestroyWindow(Window: TSDL_Window); cdecl; external SDL_LIB;
procedure SDL_SetWindowTitle(Window: TSDL_Window; const Title: PAnsiChar); cdecl;
  external SDL_LIB;
procedure SDL_GetWindowSize(Window: TSDL_Window; out W, H: Integer); cdecl;
  external SDL_LIB;

function SDL_GL_LoadLibrary(const Path: PAnsiChar): Integer; cdecl;
  external SDL_LIB;
procedure SDL_GL_UnloadLibrary; cdecl; external SDL_LIB;

function SDL_GL_SetAttribute(Attr, Value: Integer): Integer; cdecl; external SDL_LIB;
function SDL_GL_CreateContext(Window: TSDL_Window): TSDL_GLContext; cdecl;
  external SDL_LIB;
procedure SDL_GL_DeleteContext(Context: TSDL_GLContext); cdecl; external SDL_LIB;
function SDL_GL_MakeCurrent(Window: TSDL_Window; Context: TSDL_GLContext): Integer;
  cdecl; external SDL_LIB;
function SDL_GL_SetSwapInterval(Interval: Integer): Integer; cdecl; external SDL_LIB;

function SDL_GL_GetSwapInterval: Integer; cdecl; external SDL_LIB;
procedure SDL_GL_SwapWindow(Window: TSDL_Window); cdecl; external SDL_LIB;

function SDL_GL_GetProcAddress(const Proc: PAnsiChar): Pointer; cdecl;
  external SDL_LIB;

function SDL_PollEvent(out Event: TSDL_Event): Integer; cdecl; external SDL_LIB;

function SDL_GetPerformanceCounter: UInt64; cdecl; external SDL_LIB;
function SDL_GetPerformanceFrequency: UInt64; cdecl; external SDL_LIB;
procedure SDL_Delay(MS: Cardinal); cdecl; external SDL_LIB;

implementation

end.
