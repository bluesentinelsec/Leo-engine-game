#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <getopt.h>
#include <leo/leo.h>
#include <leo/io.h>
#include <leo/lua_game.h>

typedef struct
{
    int rect_width;
    int rect_height;
    bool one_frame;
    leo_WindowMode window_mode;
    leo_Texture2D background;
    bool background_ready;
} GameState;

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

static bool game_setup(leo_GameContext *ctx)
{
    GameState *state = ctx->user_data;
    state->rect_width = 240;
    state->rect_height = 140;

    state->background = leo_LoadTexture("images/background_1920x1080.png");
    state->background_ready = leo_IsTextureReady(state->background);
    if (!state->background_ready)
    {
        fprintf(stderr, "Failed to load background texture: %s\n", leo_GetError());
    }
    return true;
}

static void game_update(leo_GameContext *ctx)
{
    GameState *state = ctx->user_data;

    if (leo_IsKeyReleased(KEY_ESCAPE))
    {
        leo_GameQuit(ctx);
        return;
    }

    if (state->one_frame && ctx->frame >= 1)
    {
        leo_GameQuit(ctx);
    }
}

static void game_render(leo_GameContext *ctx)
{
    GameState *state = ctx->user_data;

    if (state->background_ready)
    {
        const int screen_w = leo_GetScreenWidth();
        const int screen_h = leo_GetScreenHeight();
        leo_Rectangle src = {0, 0, (float)state->background.width, (float)state->background.height};
        leo_Rectangle dest = {0, 0, (float)screen_w, (float)screen_h};
        leo_Vector2 origin = {0, 0};
        leo_DrawTexturePro(state->background, src, dest, origin, 0.0f, LEO_WHITE);
    }
}

static void game_shutdown(leo_GameContext *ctx)
{
    GameState *state = ctx->user_data;
    if (state->background_ready)
    {
        leo_UnloadTexture(&state->background);
        state->background_ready = false;
    }
}

static void print_usage(const char *prog)
{
    fprintf(stderr, "Usage: %s [OPTIONS]\n", prog);
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  --one-frame, -1      Run for one frame only\n");
    fprintf(stderr, "  --windowed, -w       Start in windowed mode\n");
    fprintf(stderr, "  --fullscreen, -f     Start in fullscreen exclusive mode (default)\n");
    fprintf(stderr, "  --borderless, -b     Start in borderless fullscreen mode\n");
    fprintf(stderr, "  --resource-path, -r  Override resource pack or directory\n");
    fprintf(stderr, "  --lua, -L            Run Lua entry point (scripts/game.lua)\n");
}

int main(int argc, char **argv)
{
    GameState state = {
        .rect_width = 240,
        .rect_height = 140,
        .one_frame = false,
        .window_mode = LEO_WINDOW_MODE_FULLSCREEN_EXCLUSIVE,
        .background = {0},
        .background_ready = false,
    };

    static struct option long_opts[] = {
        {"one-frame", no_argument, NULL, '1'},
        {"windowed", no_argument, NULL, 'w'},
        {"fullscreen", no_argument, NULL, 'f'},
        {"borderless", no_argument, NULL, 'b'},
        {"resource-path", required_argument, NULL, 'r'},
        {"lua", no_argument, NULL, 'L'},
        {NULL, 0, NULL, 0},
    };

    int opt;
    const char *resource_path_override = NULL;
    bool use_lua_entry = false;
    while ((opt = getopt_long(argc, argv, "1wfbr:L", long_opts, NULL)) != -1)
    {
        switch (opt)
        {
        case '1':
            state.one_frame = true;
            break;
        case 'w':
            state.window_mode = LEO_WINDOW_MODE_WINDOWED;
            break;
        case 'f':
            state.window_mode = LEO_WINDOW_MODE_FULLSCREEN_EXCLUSIVE;
            break;
        case 'b':
            state.window_mode = LEO_WINDOW_MODE_BORDERLESS_FULLSCREEN;
            break;
        case 'r':
            resource_path_override = optarg;
            break;
        case 'L':
            use_lua_entry = true;
            break;
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

    if (use_lua_entry)
    {
        leo_LuaGameConfig lua_cfg = {
            .window_title = "Leo Engine Lua Demo",
            .window_width = 1920,
            .window_height = 1080,
            .target_fps = 60,
            .clear_color = LEO_BLACK,
            .script_path = "scripts/game.lua",
            .user_data = NULL,
        };

        int lua_result = leo_LuaGameRun(&lua_cfg, NULL);
        if (lua_result != 0)
        {
            fprintf(stderr, "Leo Lua game terminated with error code %d\n", lua_result);
        }
        return lua_result;
    }

    leo_GameConfig config = {
        .window_width = 1920,
        .window_height = 1080,
        .window_title = "Leo Engine Pong",
        .window_mode = state.window_mode,
        .target_fps = 60,
        .logical_width = 1920,
        .logical_height = 1080,
        .presentation = LEO_LOGICAL_PRESENTATION_LETTERBOX,
        .scale_mode = LEO_SCALE_LINEAR,
        .clear_color = LEO_BLACK,
        .start_paused = false,
        .user_data = &state,
    };

    leo_GameCallbacks callbacks = {
        .on_setup = game_setup,
        .on_update = game_update,
        .on_render_ui = game_render,
        .on_shutdown = game_shutdown,
    };

    int result = leo_GameRun(&config, &callbacks);
    if (result != 0)
    {
        fprintf(stderr, "Leo Engine terminated with error code %d\n", result);
    }

    return result;
}
