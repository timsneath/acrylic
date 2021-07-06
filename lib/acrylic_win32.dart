// Matching Win32 casing, rather than Dart casing, for Win32 APIs

// ignore_for_file: camel_case_types
// ignore_for_file: constant_identifier_names
// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

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

class ACCENT_STATE {
  static const ACCENT_DISABLED = 0;
  static const ACCENT_ENABLE_GRADIENT = 1;
  static const ACCENT_ENABLE_TRANSPARENTGRADIENT = 2;
  static const ACCENT_ENABLE_BLURBEHIND = 3;
  static const ACCENT_ENABLE_ACRYLICBLURBEHIND = 4;
  static const ACCENT_ENABLE_HOSTBACKDROP = 5;
  static const ACCENT_INVALID_STATE = 6;
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

  factory Rect.fromRECT(RECT rect) {
    return Rect(rect.left, rect.right, rect.top, rect.bottom);
  }
}

class AcrylicWin32 {
  late final setWindowsCompositionAttributeDart SetWindowCompositionAttribute;

  Rect? restoredWindowSize;

  void initUndocumentedWin32APIs() {
    final user32 = 'user32.dll'.toNativeUtf16();
    final hModule = GetModuleHandle(user32);
    if (hModule == NULL) throw Exception('Could not load kernel32.dll');
    free(user32);

    final ansi = 'SetWindowCompositionAttribute'.toANSI();
    final pSetWindowCompositionAttribute = GetProcAddress(hModule, ansi);
    free(ansi);

    if (pSetWindowCompositionAttribute != NULL) {
      print('pSetWindowCompositionAttribute() is available on this system.');
      SetWindowCompositionAttribute = Pointer<
                  NativeFunction<
                      setWindowsCompositionAttributeNative>>.fromAddress(
              pSetWindowCompositionAttribute)
          .asFunction<setWindowsCompositionAttributeDart>();
    }
  }

  AcrylicWin32({bool shouldDrawCustomFrame = true}) {
    initUndocumentedWin32APIs();

    if (shouldDrawCustomFrame) {
      final pRect = calloc<RECT>();
      final pMargins = calloc<MARGINS>()
        ..ref.cxLeftWidth = 0
        ..ref.cxRightWidth = 0
        ..ref.cyTopHeight = 1
        ..ref.cyBottomHeight = 0;

      try {
        final handle = findFlutterWindowHandle();

        // Install window handler
        // SetWindowSubclass(handle,
        //     Pointer.fromFunction<SubclassProc>(subclassWindowProc, 0), 1, 0);

        // Set window properties
        GetWindowRect(handle, pRect);
        SetWindowLongPtr(handle, GWL_STYLE, WS_POPUP | WS_VISIBLE | WS_CAPTION);
        DwmExtendFrameIntoClientArea(handle, pMargins);
        SetWindowPos(
            handle,
            NULL,
            pRect.ref.left,
            pRect.ref.top,
            pRect.ref.right - pRect.ref.left,
            pRect.ref.bottom - pRect.ref.top,
            SWP_NOZORDER |
                SWP_NOOWNERZORDER |
                SWP_NOMOVE |
                SWP_NOSIZE |
                SWP_FRAMECHANGED);
      } finally {
        free(pRect);
        free(pMargins);
      }
    }
  }

  static int findFlutterWindowHandle() {
    final className = 'FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf16();
    final windowName = 'demo'.toNativeUtf16();
    try {
      final handle = FindWindow(className, windowName);
      if (handle == 0) {
        throw Exception("Couldn't find Flutter window.");
      } else {
        return handle;
      }
    } finally {
      free(className);
      free(windowName);
    }
  }

  static int subclassWindowProc(int hwnd, int message, int wParam, int lParam,
      int uIdSubclass, int dwRefData) {
    print('in subclass');
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
          free(rcFrame);
        }
    }

    return DefSubclassProc(hwnd, message, wParam, lParam);
  }

  void setEffect(int r, int g, int b, int a, int accentState) {
    final hwnd = findFlutterWindowHandle();

    final accent = calloc<ACCENT_POLICY>();
    final data = calloc<WINDOWCOMPOSITIONATTRIBDATA>();
    try {
      accent.ref.accentState = accentState;
      accent.ref.accentFlags = 2;
      accent.ref.gradientColor = (a << 24) + (b << 16) + (g << 8) + r;
      accent.ref.animationID = 0;
      data.ref.attrib = WINDOWCOMPOSITIONATTRIB.WCA_ACCENT_POLICY;
      data.ref.pvData = accent;
      data.ref.cbData = sizeOf<ACCENT_POLICY>();
      SetWindowCompositionAttribute(hwnd, data.ref);
    } finally {
      free(accent);
      free(data);
    }
  }
}
