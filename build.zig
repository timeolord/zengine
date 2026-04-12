const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const link_static = b.option(bool, "static", "build a single static executable") orelse false;
    const use_llvm = b.option(bool, "llvm", "build with llvm") orelse false;
    const use_valgrind = b.option(bool, "valgrind", "build with valgrind support") orelse false;

    const options = b.addOptions();
    options.addOption(bool, "link_static", link_static);
    options.addOption(bool, "use_llvm", use_llvm);
    options.addOption(bool, "use_valgrind", use_valgrind);

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .linkage = if (link_static) std.builtin.LinkMode.static else std.builtin.LinkMode.dynamic,
    });
    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const sti = b.addModule("sti", .{
        .root_source_file = b.path("deps/zig-sti/src/sti.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    sti.addImport("sti", sti);

    const constants = b.addModule("constants", .{
        .root_source_file = b.path("src/constants.zig"),
        .target = target,
        .optimize = optimize,
    });
    constants.addImport("sti", sti);

    const exe_mod = b.addModule("zengine", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .valgrind = use_valgrind,
    });
    exe_mod.addImport("raylib", raylib);
    exe_mod.addImport("sti", sti);
    exe_mod.addImport("constants", constants);
    exe_mod.addOptions("config", options);

    const exe = b.addExecutable(.{
        .name = "zengine",
        .root_module = exe_mod,
        .use_llvm = use_llvm,
    });
    exe.linkLibrary(raylib_artifact);
    const install_exe = b.addInstallArtifact(exe, .{});

    var engine_lib: *std.Build.Step.Compile = undefined;
    var install_lib: *std.Build.Step.InstallArtifact = undefined;
    if (link_static) {
        b.installArtifact(exe);
    } else {
        const lib_mod = b.addModule("zengine_runtime", .{
            .root_source_file = b.path("src/game.zig"),
            .target = target,
            .optimize = optimize,
            .valgrind = use_valgrind,
        });
        lib_mod.addImport("raylib", raylib);
        lib_mod.addImport("sti", sti);
        lib_mod.addImport("constants", constants);
        lib_mod.addOptions("config", options);

        engine_lib = b.addLibrary(.{
            .name = "game",
            .linkage = .dynamic,
            .root_module = lib_mod,
            .use_llvm = use_llvm,
        });
        engine_lib.linkLibrary(raylib_artifact);
        b.installArtifact(engine_lib);
        install_lib = b.addInstallArtifact(engine_lib, .{});
    }

    const sti_tests = b.addTest(.{
        .name = "sti-tests",
        .root_module = sti,
    });
    const run_sti_tests = b.addRunArtifact(sti_tests);

    const check = b.step("check", "check that zengine compiles");
    check.dependOn(&exe.step);
    if (!link_static) {
        check.dependOn(&engine_lib.step);
    }

    const test_step = b.step("test", "run unit tests");
    test_step.dependOn(&run_sti_tests.step);

    const runner_step = b.step("runner", "compile the wrapper executable");
    runner_step.dependOn(&install_exe.step);

    const all_step = b.step("all", "build the engine and tests");
    all_step.dependOn(runner_step);
    all_step.dependOn(test_step);
    if (!link_static) {
        all_step.dependOn(&install_lib.step);
    }
}
