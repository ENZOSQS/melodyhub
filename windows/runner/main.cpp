#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter_windows.h>
#include <windows.h>

#include <algorithm>
#include <cmath>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  RECT work_area{};
  SystemParametersInfo(SPI_GETWORKAREA, 0, &work_area, 0);
  const int work_width = work_area.right - work_area.left;
  const int work_height = work_area.bottom - work_area.top;
  const POINT monitor_point = {work_area.left, work_area.top};
  const HMONITOR monitor = MonitorFromPoint(monitor_point, MONITOR_DEFAULTTONEAREST);
  const double scale = FlutterDesktopGetDpiForMonitor(monitor) / 96.0;

  // Keep the Windows preview in a phone-like portrait frame while fitting the
  // available work area and respecting the monitor's DPI scaling.
  constexpr double kPhoneWidth = 430.0;
  constexpr double kPhoneHeight = 932.0;
  constexpr double kPhoneAspectRatio = kPhoneWidth / kPhoneHeight;
  const double max_width = work_width * 0.92 / scale;
  const double max_height = work_height * 0.92 / scale;
  double height = std::min(kPhoneHeight, max_height);
  double width = height * kPhoneAspectRatio;
  if (width > max_width) {
    width = max_width;
    height = width / kPhoneAspectRatio;
  }
  Win32Window::Size size(static_cast<unsigned int>(std::lround(width)),
                         static_cast<unsigned int>(std::lround(height)));
  if (!window.Create(L"melodyhub", origin, size)) {
    return EXIT_FAILURE;
  }

  HWND handle = window.GetHandle();
  LONG_PTR style = GetWindowLongPtr(handle, GWL_STYLE);
  style &= ~(WS_THICKFRAME | WS_MAXIMIZEBOX);
  SetWindowLongPtr(handle, GWL_STYLE, style);
  SetWindowPos(handle, nullptr, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE |
                   SWP_FRAMECHANGED);

  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
