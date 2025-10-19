#include <stdbool.h>
#include <stdio.h>

#include <leo/leo.h>

typedef struct
{
    int rect_width;
    int rect_height;
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
    if (leo_IsKeyReleased(KEY_ESCAPE) || ctx->frame >= 1)
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

int main(void)
{
    GameState state = {
        .rect_width = 240,
        .rect_height = 140,
    };

    leo_GameConfig config = {
        .window_width = 1280,
        .window_height = 720,
        .window_title = "Leo Engine Pong",
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
