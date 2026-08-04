# --- Tools ---
TRIPLE   = i686-pc-windows-msvc
CXX      = clang-cl
LD       = lld-link

# --- Dependencies ---
# https://github.com/Jake-Shadle/xwin
XWIN_ROOT       = ./xwinSDK

# https://github.com/m417z/minhook (multihook branch) -- git submodule
MINHOOK_DIR     = ./minhook

# Modern Windows SDK no longer has D3DX9 headers
# Grab them from elder Windows SDK or DirectX 9 SDK
D3DX_INCLUDES   = ./d3d9x_headers

# --- Project Files ---
TARGET   = UnitXP_SP3.dll
SRCS     =  \
            coffTimeDateStamp.cpp \
            distanceBetween.cpp \
            dllmain.cpp \
            editCamera.cpp \
            edit_CWorld_Intersect.cpp \
            FPScap.cpp \
            gameEvent.cpp \
            gameQuit.cpp \
            gameSocket.cpp \
            inSight.cpp \
            LuaDebug.cpp \
            modernNameplateDistance.cpp \
            notifyOS.cpp \
            performanceProfiling.cpp \
            polyfill.cpp \
            sceneBegin_sceneEnd.cpp \
            screenshot.cpp \
            stb_image_write.cpp \
            targeting.cpp \
            timer.cpp \
            utf8_to_utf16.cpp \
            Vanilla1121_functions.cpp \
            weather.cpp \
            worldText.cpp \
            $(MINHOOK_DIR)/src/buffer.c \
            $(MINHOOK_DIR)/src/hde/hde32.c \
            $(MINHOOK_DIR)/src/hook.c \
            $(MINHOOK_DIR)/src/trampoline.c

OBJS = $(patsubst %.cpp,%.obj,$(patsubst %.c,%.obj,$(SRCS)))
LIBS     = user32.lib kernel32.lib gdi32.lib libcmt.lib

# --- Compiler & Linker Flags ---
# It seems /O2 would crash the game.
# As I read MinHook provided MSVC projects, it is /O1 for release and /Od for debug
CXXFLAGS = --target=$(TRIPLE) \
            /O1 \
            /MT /EHsc /W3 -Wno-microsoft-cast -Wno-unused-parameter -Wno-unused-variable -Wno-unused-function /nologo /hotpatch \
            /arch:SSE2 /fp:precise \
			/std:c++17 /Zc:__cplusplus \
            /DWIN32_LEAN_AND_MEAN /D_X86_ /D_WIN32 \
            /DNULL=0 \
            /Z7 /GS /Gy \
            -flto=thin \
            -imsvc "$(XWIN_ROOT)/crt/include" \
            -imsvc "$(XWIN_ROOT)/sdk/include/ucrt" \
            -imsvc "$(XWIN_ROOT)/sdk/include/um" \
            -imsvc "$(XWIN_ROOT)/sdk/include/shared" \
            -imsvc "$(MINHOOK_DIR)/include" \
            -imsvc "$(D3DX_INCLUDES)"

LDFLAGS  = /NOLOGO /DLL /MACHINE:X86 /OPT:REF /OPT:ICF /SAFESEH \
            /NXCOMPAT /FUNCTIONPADMIN \
            /DEBUG /PDB:"$(TARGET:.dll=.pdb)" /ignore:4099 \
            /LIBPATH:"$(XWIN_ROOT)/crt/lib/x86" \
            /LIBPATH:"$(XWIN_ROOT)/sdk/lib/ucrt/x86" \
            /LIBPATH:"$(XWIN_ROOT)/sdk/lib/um/x86"

# --- Build Rules ---

all: $(TARGET)

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) /OUT:$@ $(OBJS) $(LIBS)

%.obj: %.cpp
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) /c $< /Fo:$@

# MinHook's multihook sources use NTSTATUS/NTAPI and offsetof but only include
# <windows.h>, relying on it to pull those in transitively (true under MSVC, not
# under clang-cl + the xwin SDK). Force-include the headers that define them,
# windows.h first so winternl.h sees the base types it needs.
%.obj: %.c
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) /FIwindows.h /FIwinternl.h /FIstddef.h /c $< /Fo:$@

clean:
	rm -f $(OBJS) *.dll *.lib *.exp *.pdb

.PHONY: all clean