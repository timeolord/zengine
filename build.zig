const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const link_static = b.option(bool, "static", "Build the library as a single static executable") orelse false;
    const use_llvm = b.option(bool, "llvm", "Build the game using LLVM") orelse false;
    const use_valgrind = b.option(bool, "valgrind", "Build the game with valgrind support") orelse false;
    const options = b.addOptions();
    options.addOption(bool, "link_static", link_static);
    options.addOption(bool, "use_llvm", use_llvm);
    options.addOption(bool, "use_valgrind", use_valgrind);

    // deps:

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .linkage = if (link_static) std.builtin.LinkMode.static else std.builtin.LinkMode.dynamic,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    // modules:

    const sti = b.addModule("sti", .{
        .root_source_file = b.path("src/sti.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    sti.addImport("raylib", raylib);
    sti.addImport("sti", sti);

    const constants = b.addModule("constants", .{
        .root_source_file = b.path("src/constants.zig"),
        .target = target,
        .optimize = optimize,
    });
    constants.addImport("sti", sti);
    sti.addImport("constants", constants);

    const exe_mod = b.addModule("recursive_engine", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .valgrind = use_valgrind,
    });

    const exe = b.addExecutable(.{
        .name = "recursive_engine",
        .root_module = exe_mod,
        .use_llvm = use_llvm,
    });

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("sti", sti);
    exe.root_module.addImport("constants", constants);
    exe.root_module.addOptions("config", options);
    const install_cmd = b.addInstallArtifact(exe, .{});

    var game_lib: *std.Build.Step.Compile = undefined;
    var lib_cmd: *std.Build.Step.InstallArtifact = undefined;
    if (link_static) {
        b.installArtifact(exe);
    } else {
        const lib_mod = b.addModule("recursive_engine", .{
            .root_source_file = b.path("src/game.zig"),
            .target = target,
            .optimize = optimize,
            .valgrind = use_valgrind,
        });

        game_lib = b.addLibrary(.{
            .name = "game",
            .linkage = .dynamic,
            .root_module = lib_mod,
            .use_llvm = use_llvm,
        });

        game_lib.linkLibrary(raylib_artifact);
        game_lib.root_module.addImport("raylib", raylib);
        game_lib.root_module.addImport("sti", sti);
        game_lib.root_module.addImport("constants", constants);
        game_lib.root_module.addOptions("config", options);
        b.installArtifact(game_lib);

        lib_cmd = b.addInstallArtifact(game_lib, .{});
    }

    // tests:

    const sti_tests = b.addTest(.{ .root_module = sti });
    const run_sti_tests = b.addRunArtifact(sti_tests);

    // steps:

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_sti_tests.step);

    const exe_step = b.step("runner", "Compile the wrapper runner executable");
    exe_step.dependOn(&install_cmd.step);

    const check = b.step("check", "Check if recursive_engine compiles");
    check.dependOn(&exe.step);
    if (!link_static) {
        check.dependOn(&game_lib.step);
    }

    const all_step = b.step("all", "Compile the game and wrapper");
    all_step.dependOn(exe_step);
    all_step.dependOn(test_step);
    if (!link_static) {
        all_step.dependOn(&lib_cmd.step);
    }
}
