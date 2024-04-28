package("lsquic")
    set_homepage("https://github.com/litespeedtech/lsquic")
    set_description("LiteSpeed QUIC and HTTP/3 Library")
    set_license("MIT")

    add_urls("https://github.com/litespeedtech/lsquic/archive/refs/tags/$(version).tar.gz",
             "https://github.com/litespeedtech/lsquic.git")

    add_versions("v4.0.8", "f18ff2fa0addc1c51833304b3d3ff0979ecf5f53f54f96bcd3442a40cfcd440b")

    add_deps("cmake")
    add_deps("zlib", "boringssl", "ls-qpack", "ls-hpack")

    add_includedirs("include/lsquic")

    on_install("windows|!arm64", "linux", "macosx", function (package)
        local opt = {}
        opt.packagedeps = {"ls-qpack", "ls-hpack"}
        if package:is_plat("windows") then
            opt.cxflags = "-DWIN32"
            -- https://github.com/litespeedtech/lsquic/issues/433
            package:add("defines", "WIN32", "WIN32_LEAN_AND_MEAN")
        end

        io.replace("src/liblsquic/CMakeLists.txt", "ls-qpack/lsqpack.c", "", {plain = true})
        io.replace("src/liblsquic/CMakeLists.txt", "../lshpack/lshpack.c", "", {plain = true})
        io.replace("CMakeLists.txt", "-WX", "", {plain = true})

        local boringssl_path = package:dep("boringssl"):installdir()

        local configs = {
            "-DLSQUIC_BIN=OFF",
            "-DLSQUIC_TESTS=OFF",
            "-DBORINGSSL_DIR=" .. boringssl_path,
            "-DBORINGSSL_LIB=" .. path.join(boringssl_path, "lib"),
        }

        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:is_debug() and "Debug" or "Release"))
        table.insert(configs, "-DLSQUIC_SHARED_LIB=" .. (package:config("shared") and "ON" or "OFF"))
        import("package.tools.cmake").install(package, configs, opt)

        os.vcp("**.dll", package:installdir("bin"))
    end)

    on_test(function (package)
        assert(package:has_cfuncs("lsquic_global_init", {includes = "lsquic.h"}))
    end)