import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

// ignore_for_file: constant_identifier_names
// ignore_for_file: camel_case_types

// Allegedly this is the documented alternative to
// SetWindowCompositionAttribute:
// https://docs.microsoft.com/en-us/windows/win32/api/dwmapi/nf-dwmapi-dwmsetwindowattribute

class WINDOWCOMPOSITIONATTRIB {
  static const WCA_UNDEFINED = 0;
  static const WCA_NCRENDERING_ENABLED = 1;
  static const WCA_NCRENDERING_POLICY = 2;
  static const WCA_TRANSITIONS_FORCEDISABLED = 3;
  static const WCA_ALLOW_NCPAINT = 4;
  static const WCA_CAPTION_BUTTON_BOUNDS = 5;
  static const WCA_NONCLIENT_RTL_LAYOUT = 6;
  static const WCA_FORCE_ICONIC_REPRESENTATION = 7;
  static const WCA_EXTENDED_FRAME_BOUNDS = 8;
  static const WCA_HAS_ICONIC_BITMAP = 9;
  static const WCA_THEME_ATTRIBUTES = 10;
  static const WCA_NCRENDERING_EXILED = 11;
  static const WCA_NCADORNMENTINFO = 12;
  static const WCA_EXCLUDED_FROM_LIVEPREVIEW = 13;
  static const WCA_VIDEO_OVERLAY_ACTIVE = 14;
  static const WCA_FORCE_ACTIVEWINDOW_APPEARANCE = 15;
  static const WCA_DISALLOW_PEEK = 16;
  static const WCA_CLOAK = 17;
  static const WCA_CLOAKED = 18;
  static const WCA_ACCENT_POLICY = 19;
  static const WCA_FREEZE_REPRESENTATION = 20;
  static const WCA_EVER_UNCLOAKED = 21;
  static const WCA_VISUAL_OWNER = 22;
  static const WCA_HOLOGRAPHIC = 23;
  static const WCA_EXCLUDED_FROM_DDA = 24;
  static const WCA_PASSIVEUPDATEMODE = 25;
  static const WCA_USEDARKMODECOLORS = 26;
  static const WCA_LAST = 27;
}

class WINDOWCOMPOSITIONATTRIBDATA extends Struct {
  @Uint32()
  external int attrib;
  external Pointer pvData;
  @IntPtr()
  external int cbData;
}

enum AccentState {
  ACCENT_DISABLED,
  ACCENT_ENABLE_GRADIENT,
  ACCENT_ENABLE_TRANSPARENTGRADIENT,
  ACCENT_ENABLE_BLURBEHIND,
  ACCENT_ENABLE_ACRYLICBLURBEHIND,
  ACCENT_ENABLE_HOSTBACKDROP,
  ACCENT_INVALID_STATE
}

class ACCENT_POLICY extends Struct {
  @Uint32()
  external int accentState;
  @Uint32()
  external int accentFlags;
  @Uint32()
  external int gradientColor;
  @Uint32()
  external int animationID;
}

typedef setWindowsCompositionAttributeNative = Int32 Function(
    IntPtr, WINDOWCOMPOSITIONATTRIBDATA);
typedef setWindowsCompositionAttributeDart = int Function(
    int, WINDOWCOMPOSITIONATTRIBDATA);

class Rect {
  final int left;
  final int top;
  final int right;
  final int bottom;

  const Rect(this.left, this.top, this.right, this.bottom);
}

int subclassWindowProc(int hwnd, int message, int wParam, int lParam,
    int uIdSubclass, int dwRefData) {
  switch (message) {
    case WM_NCCALCSIZE:
      if (wParam != FALSE) {
        SetWindowLongPtr(hwnd, 0, 0);
        return 1;
      }
      return 0;

    case WM_NCHITTEST:
      final window = calloc<RECT>();
      final rcFrame = calloc<RECT>();
      final mouseX = LOWORD(lParam);
      final mouseY = HIWORD(lParam);
      const width = 10;

      try {
        GetWindowRect(hwnd, window);
        AdjustWindowRectEx(
            rcFrame, WS_OVERLAPPEDWINDOW & ~WS_CAPTION, FALSE, NULL);
        const fOnResizeBorder = false;
        var x = 1, y = 1;

        if (mouseY >= window.ref.top && mouseY < window.ref.top + width) {
          x = 0;
        } else if (mouseY < window.ref.bottom &&
            mouseY >= window.ref.bottom - width) {
          x = 2;
        }
        if (mouseX >= window.ref.left && mouseX < window.ref.left + width) {
          y = 0;
        } else if (mouseX < window.ref.right &&
            mouseX >= window.ref.right - width) {
          y = 2;
        }
        final hitTests = [
          [HTTOPLEFT, fOnResizeBorder ? HTTOP : HTCAPTION, HTTOPRIGHT],
          [HTLEFT, HTNOWHERE, HTRIGHT],
          [HTBOTTOMLEFT, HTBOTTOM, HTBOTTOMRIGHT],
        ];
        return hitTests[x][y];
      } finally {
        free(window);
      }
  }

  return DefSubclassProc(hwnd, message, wParam, lParam);
}

class AcrylicWin32 {
  late final setWindowsCompositionAttributeDart
      funcSetWindowCompositionAttribute;

  late Rect initialRect;
  bool _isFullscreen = false;

  AcrylicWin32({bool shouldDrawCustomFrame = true}) {
    final user32 = 'user32.dll'.toNativeUtf16();
    final hModule = GetModuleHandle(user32);
    if (hModule == NULL) throw Exception('Could not load kernel32.dll');
    free(user32);

    final ansi = 'SetWindowCompositionAttribute'.toANSI();
    final pSetWindowCompositionAttribute = GetProcAddress(hModule, ansi);
    free(ansi);

    if (pSetWindowCompositionAttribute != NULL) {
      print('pSetWindowCompositionAttribute() is available on this system.');
      funcSetWindowCompositionAttribute = Pointer<
                  NativeFunction<
                      setWindowsCompositionAttributeNative>>.fromAddress(
              pSetWindowCompositionAttribute)
          .asFunction<setWindowsCompositionAttributeDart>();
    }

    if (shouldDrawCustomFrame) {
      final rect = calloc<RECT>();
      final margins = calloc<MARGINS>()
        ..ref.cxLeftWidth = 0
        ..ref.cxRightWidth = 0
        ..ref.cyTopHeight = 1
        ..ref.cyBottomHeight = 0;

      SetWindowSubclass(GetActiveWindow(),
          Pointer.fromFunction<SubclassProc>(subclassWindowProc, 0), 1, 0);
      GetWindowRect(GetActiveWindow(), rect);
      SetWindowLongPtr(
          GetActiveWindow(), GWL_STYLE, WS_POPUP | WS_CAPTION | WS_VISIBLE);
      DwmExtendFrameIntoClientArea(GetActiveWindow(), margins);
      SetWindowPos(
          GetActiveWindow(),
          NULL,
          rect.ref.left,
          rect.ref.top,
          rect.ref.right - rect.ref.left,
          rect.ref.bottom - rect.ref.top,
          SWP_NOZORDER |
              SWP_NOOWNERZORDER |
              SWP_NOMOVE |
              SWP_NOSIZE |
              SWP_FRAMECHANGED);
    }
  }

  void setEffect(int r, int g, int b, int a, int accentState) {
    final accent = calloc<ACCENT_POLICY>();
    final data = calloc<WINDOWCOMPOSITIONATTRIBDATA>();
    try {
      accent.ref.accentState = 0;
      accent.ref.accentFlags = 2;
      accent.ref.gradientColor = (a << 24) + (b << 16) + (g << 8) + r;
      accent.ref.animationID = 0;
      data.ref.attrib = WINDOWCOMPOSITIONATTRIB.WCA_ACCENT_POLICY;
      data.ref.pvData = accent;
      data.ref.cbData = sizeOf<ACCENT_POLICY>();
      funcSetWindowCompositionAttribute(GetActiveWindow(), data.ref);
    } finally {
      free(accent);
      free(data);
    }
  }

  void enterFullscreen() {
    if (!_isFullscreen) {
      _isFullscreen = true;

      final monitorInfo = calloc<MONITORINFO>()
        ..ref.cbSize = sizeOf<MONITORINFO>();
      final rect = calloc<RECT>();

      try {
        final hwnd = GetActiveWindow();
        final hMonitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);

        GetMonitorInfo(hMonitor, monitorInfo);
        SetWindowLongPtr(hwnd, GWL_STYLE, WS_POPUP | WS_VISIBLE);
        GetWindowRect(hwnd, rect);

        initialRect =
            Rect(rect.ref.left, rect.ref.top, rect.ref.right, rect.ref.bottom);

        SetWindowPos(
            hwnd,
            HWND_TOPMOST,
            monitorInfo.ref.rcMonitor.left,
            monitorInfo.ref.rcMonitor.top,
            monitorInfo.ref.rcMonitor.right - monitorInfo.ref.rcMonitor.left,
            monitorInfo.ref.rcMonitor.bottom - monitorInfo.ref.rcMonitor.top,
            SWP_SHOWWINDOW);
        ShowWindow(hwnd, SW_MAXIMIZE);
      } finally {
        free(monitorInfo);
        free(rect);
      }
    }
  }

  void exitFullscreen() {
    if (_isFullscreen) {
      _isFullscreen = false;

      final hwnd = GetActiveWindow();
      SetWindowLongPtr(hwnd, GWL_STYLE, WS_OVERLAPPEDWINDOW | WS_VISIBLE);
      SetWindowPos(
          hwnd,
          HWND_NOTOPMOST,
          initialRect.left,
          initialRect.top,
          initialRect.right - initialRect.left,
          initialRect.bottom - initialRect.top,
          SWP_SHOWWINDOW);
      ShowWindow(hwnd, SW_RESTORE);
    }
  }
}
