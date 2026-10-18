#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>

#include "app_links/app_links_plugin_c_api.h"
#include "flutter_window.h"
#include "utils.h"

// Judul jendela; dipakai juga untuk mencari jendela Korelasi yang sudah
// terbuka.
static const wchar_t kJudulJendela[] = L"korelasi";

// Mendaftarkan skema korelasi:// (alamat balik login Google, BOLT-40) di
// HKCU\Software\Classes\korelasi supaya browser bisa membuka Korelasi lagi.
// Ditulis setiap kali aplikasi jalan agar selalu menunjuk ke exe ini (juga
// sesudah pindah folder atau saat `flutter run`). HKCU tidak butuh hak admin.
static void DaftarkanSkemaKorelasi() {
  wchar_t exe[MAX_PATH];
  DWORD panjang = ::GetModuleFileNameW(nullptr, exe, MAX_PATH);
  if (panjang == 0 || panjang >= MAX_PATH) {
    return;
  }

  HKEY kunci;
  if (::RegCreateKeyExW(HKEY_CURRENT_USER, L"Software\\Classes\\korelasi", 0,
                        nullptr, 0, KEY_WRITE, nullptr, &kunci,
                        nullptr) != ERROR_SUCCESS) {
    return;
  }
  const std::wstring nama = L"URL:Korelasi";
  ::RegSetValueExW(kunci, nullptr, 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(nama.c_str()),
                   static_cast<DWORD>((nama.size() + 1) * sizeof(wchar_t)));
  ::RegSetValueExW(kunci, L"URL Protocol", 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(L""), sizeof(wchar_t));
  ::RegCloseKey(kunci);

  const std::wstring perintah = L"\"" + std::wstring(exe) + L"\" \"%1\"";
  ::RegSetKeyValueW(HKEY_CURRENT_USER,
                    L"Software\\Classes\\korelasi\\shell\\open\\command",
                    nullptr, REG_SZ, perintah.c_str(),
                    static_cast<DWORD>((perintah.size() + 1) * sizeof(wchar_t)));
}

// Bila Korelasi sudah terbuka (mis. browser membuka korelasi://login-callback
// sesudah login Google), kirim tautannya ke jendela itu lalu tampilkan
// jendelanya, alih-alih membuka jendela kedua. Pola dari dokumentasi app_links.
static bool KirimTautanKeJendelaLama() {
  HWND hwnd = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", kJudulJendela);
  if (hwnd == nullptr) {
    return false;
  }

  SendAppLink(hwnd);

  WINDOWPLACEMENT letak = {sizeof(WINDOWPLACEMENT)};
  ::GetWindowPlacement(hwnd, &letak);
  switch (letak.showCmd) {
    case SW_SHOWMAXIMIZED:
      ::ShowWindow(hwnd, SW_SHOWMAXIMIZED);
      break;
    case SW_SHOWMINIMIZED:
      ::ShowWindow(hwnd, SW_RESTORE);
      break;
    default:
      ::ShowWindow(hwnd, SW_NORMAL);
      break;
  }
  ::SetWindowPos(0, HWND_TOP, 0, 0, 0, 0,
                 SWP_SHOWWINDOW | SWP_NOSIZE | SWP_NOMOVE);
  ::SetForegroundWindow(hwnd);
  return true;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (KirimTautanKeJendelaLama()) {
    return EXIT_SUCCESS;
  }
  DaftarkanSkemaKorelasi();

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
  Win32Window::Size size(1280, 720);
  if (!window.Create(kJudulJendela, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
