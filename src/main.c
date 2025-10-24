#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <getopt.h>
#include <leo/leo.h>

typedef struct
{
    int rect_width;
    int rect_height;
    bool one_frame;
    leo_WindowMode window_mode;
} GameState;

static bool game_setup(leo_GameContext *ctx)
{
    GameState *state = ctx->user_data;
    state->rect_width = 240;
    state->rect_height = 140;
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

    const int screen_w = leo_GetScreenWidth();
    const int screen_h = leo_GetScreenHeight();
    const int x = (screen_w - state->rect_width) / 2;
    const int y = (screen_h - state->rect_height) / 2;
    const leo_Color rect_color = {255, 180, 60, 255};

    leo_DrawRectangle(x, y, state->rect_width, state->rect_height, rect_color);
}

static void game_shutdown(leo_GameContext *ctx)
{
    (void)ctx;
}

static void print_usage(const char *prog)
{
    fprintf(stderr, "Usage: %s [OPTIONS]\n", prog);
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  --one-frame, -1      Run for one frame only\n");
    fprintf(stderr, "  --windowed, -w       Start in windowed mode\n");
    fprintf(stderr, "  --fullscreen, -f     Start in fullscreen exclusive mode (default)\n");
    fprintf(stderr, "  --borderless, -b     Start in borderless fullscreen mode\n");
}

int main(int argc, char **argv)
{
    GameState state = {
        .rect_width = 240,
        .rect_height = 140,
        .one_frame = false,
        .window_mode = LEO_WINDOW_MODE_FULLSCREEN_EXCLUSIVE,
    };

    static struct option long_opts[] = {
        {"one-frame", no_argument, NULL, '1'},
        {"windowed", no_argument, NULL, 'w'},
        {"fullscreen", no_argument, NULL, 'f'},
        {"borderless", no_argument, NULL, 'b'},
        {NULL, 0, NULL, 0},
    };

    int opt;
    while ((opt = getopt_long(argc, argv, "1wfb", long_opts, NULL)) != -1)
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
        case '?':
        default:
            print_usage(argv[0]);
            return EXIT_FAILURE;
        }
    }

    leo_GameConfig config = {
        .window_width = 1280,
        .window_height = 720,
        .window_title = "Leo Engine Pong",
        .window_mode = state.window_mode,
        .target_fps = 60,
        .logical_width = 1280,
        .logical_height = 720,
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
