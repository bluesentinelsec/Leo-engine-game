#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <getopt.h>
#include <leo/leo.h>
#include <leo/io.h>
#include <leo/lua_game.h>

static bool try_mount_resource_pack(const char *path, const char *password, int priority, bool verbose)
{
    if (!path || !*path)
        return false;

    if (verbose)
        printf("Attempting to mount resource pack: %s\n", path);

    if (leo_MountResourcePack(path, password, priority))
    {
        if (verbose)
            printf("Mounted resource pack: %s\n", path);
        return true;
    }

    if (verbose)
        fprintf(stderr, "Failed to mount resource pack '%s': %s\n", path, leo_GetError());
    return false;
}

static bool try_mount_resource_directory(const char *path, int priority, bool verbose)
{
    if (!path || !*path)
        return false;

    if (verbose)
        printf("Attempting to mount resource directory: %s\n", path);

    if (leo_MountDirectory(path, priority))
    {
        if (verbose)
            printf("Mounted resource directory: %s\n", path);
        return true;
    }

    if (verbose)
        fprintf(stderr, "Failed to mount resource directory '%s': %s\n", path, leo_GetError());
    return false;
}

static bool mount_resources(const char *override_path)
{
    const char *pack_password = "password";
    leo_ClearMounts();

    if (override_path)
    {
        bool mounted = try_mount_resource_pack(override_path, pack_password, 200, true) ||
                       try_mount_resource_directory(override_path, 150, true);
        if (!mounted)
        {
            fprintf(stderr,
                    "Could not mount override resource path '%s' as pack or directory. Aborting.\n",
                    override_path);
        }
        return mounted;
    }

    if (try_mount_resource_pack("resources.leopack", pack_password, 200, true))
    {
        return true;
    }

    if (try_mount_resource_directory("resources", 150, true))
    {
        return true;
    }

    fprintf(stderr, "Failed to mount default resource pack or directory. Aborting.\n");
    return false;
}

static void print_usage(const char *prog)
{
    fprintf(stderr, "Usage: %s [OPTIONS]\n", prog);
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  --one-frame, -1      Run for one frame only (for testing)\n");
    fprintf(stderr, "  --windowed, -w       Start in windowed mode\n");
    fprintf(stderr, "  --fullscreen, -f     Start in fullscreen exclusive mode\n");
    fprintf(stderr, "  --borderless, -b     Start in borderless fullscreen mode (default)\n");
    fprintf(stderr, "  --resource-path, -r  Override resource pack or directory\n");
    fprintf(stderr, "  --script, -s         Specify Lua script path (default: scripts/game.lua)\n");
    fprintf(stderr, "  --help, -h           Show this help message\n");
}

int main(int argc, char **argv)
{
    static struct option long_opts[] = {
        {"one-frame", no_argument, NULL, '1'},
        {"windowed", no_argument, NULL, 'w'},
        {"fullscreen", no_argument, NULL, 'f'},
        {"borderless", no_argument, NULL, 'b'},
        {"resource-path", required_argument, NULL, 'r'},
        {"script", required_argument, NULL, 's'},
        {"help", no_argument, NULL, 'h'},
        {NULL, 0, NULL, 0},
    };

    int opt;
    const char *resource_path_override = NULL;
    const char *script_path = "scripts/game.lua";
    leo_WindowMode window_mode = LEO_WINDOW_MODE_BORDERLESS_FULLSCREEN;
    bool one_frame = false;

    while ((opt = getopt_long(argc, argv, "1wfbr:s:h", long_opts, NULL)) != -1)
    {
        switch (opt)
        {
        case '1':
            one_frame = true;
            break;
        case 'w':
            window_mode = LEO_WINDOW_MODE_WINDOWED;
            break;
        case 'f':
            window_mode = LEO_WINDOW_MODE_FULLSCREEN_EXCLUSIVE;
            break;
        case 'b':
            window_mode = LEO_WINDOW_MODE_BORDERLESS_FULLSCREEN;
            break;
        case 'r':
            resource_path_override = optarg;
            break;
        case 's':
            script_path = optarg;
            break;
        case 'h':
            print_usage(argv[0]);
            return EXIT_SUCCESS;
        case '?':
        default:
            print_usage(argv[0]);
            return EXIT_FAILURE;
        }
    }

    if (!mount_resources(resource_path_override))
    {
        return EXIT_FAILURE;
    }

    leo_LuaGameConfig lua_cfg = {
        .window_title = "Leo Engine - Lua Game",
        .window_width = 800,
        .window_height = 600,
        .window_mode = window_mode,
        .target_fps = 60,
        .clear_color = {32, 32, 64, 255},
        .script_path = script_path,
        .user_data = NULL,
    };

    int lua_result = leo_LuaGameRun(&lua_cfg, NULL);
    if (lua_result != 0)
    {
        fprintf(stderr, "Leo Lua game terminated with error code %d\n", lua_result);
    }
    return lua_result;
}
