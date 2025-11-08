#include <leo/leo.h>
#include <leo/graphics.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#if defined(_WIN32)
#include <direct.h>
#include <windows.h>
#define getcwd _getcwd
#else
#include <unistd.h>
#endif

typedef struct
{
    float x, y;
    float vel_x, vel_y;
    leo_Color color;
    float radius;
} Ball;

typedef struct
{
    float x, y;
    float speed;
    leo_Color color;
} Player;

typedef struct
{
    Player player;
    Ball balls[50];
    int num_balls;
    
    // Background grid animation
    float grid_offset;
    
    // Timing
    double update_time;
    double render_time;
    double frame_time;
    double last_frame_time;
    
    bool one_frame;
} GameState;

/* ----------------------------------------------------------
   Transition callbacks
   ---------------------------------------------------------- */
static void on_fade_out_complete(void)
{
    exit(0);
}

/* ----------------------------------------------------------
   Timing helpers
   ---------------------------------------------------------- */
static double get_time_ms(void)
{
#if defined(_WIN32)
    static LARGE_INTEGER freq;
    static BOOL freq_set = FALSE;
    LARGE_INTEGER counter;

    if (!freq_set)
    {
        QueryPerformanceFrequency(&freq);
        freq_set = TRUE;
    }

    QueryPerformanceCounter(&counter);
    return (double)counter.QuadPart * 1000.0 / (double)freq.QuadPart;
#else
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1000000.0;
#endif
}

/* ----------------------------------------------------------
   Setup
   ---------------------------------------------------------- */
static bool demo_setup(leo_GameContext *ctx)
{
    GameState *state = (GameState *)ctx->user_data;

    printf("=== Performance Test Setup ===\n");

    // Initialize player
    state->player.x = 640.0f;
    state->player.y = 360.0f;
    state->player.speed = 400.0f;
    state->player.color = (leo_Color){255, 255, 255, 255}; // White

    // Initialize bouncing balls
    state->num_balls = 50;
    srand((unsigned int)time(NULL));
    
    for (int i = 0; i < state->num_balls; i++)
    {
        Ball *ball = &state->balls[i];
        ball->x = (float)(rand() % 1280);
        ball->y = (float)(rand() % 720);
        ball->vel_x = ((float)(rand() % 200) - 100) * 2.0f; // -200 to 200
        ball->vel_y = ((float)(rand() % 200) - 100) * 2.0f;
        ball->radius = 10.0f + (float)(rand() % 20); // 10-30 radius
        
        // Random bright colors
        ball->color = (leo_Color){
            (unsigned char)(128 + rand() % 128), // 128-255
            (unsigned char)(128 + rand() % 128),
            (unsigned char)(128 + rand() % 128),
            255
        };
    }

    state->grid_offset = 0.0f;

    // Disable automatic ESCAPE key exit
    leo_SetExitKey(-1);

    // Start fade-in transition
    leo_StartFadeIn(1.0f, LEO_BLACK);

    printf("✅ Performance test setup complete\n");
    return true;
}

/* ----------------------------------------------------------
   Update
   ---------------------------------------------------------- */
static void demo_update(leo_GameContext *ctx)
{
    GameState *state = (GameState *)ctx->user_data;
    float dt = ctx->dt;

    // Update transitions
    leo_UpdateTransitions(dt);

    // Handle ESCAPE key for fade-out and quit
    if (leo_IsKeyPressed(KEY_ESCAPE) && !leo_IsTransitioning())
    {
        leo_StartFadeOut(1.0f, LEO_BLACK, on_fade_out_complete);
    }

    // Measure frame time
    double current_time = get_time_ms();
    if (state->last_frame_time > 0)
    {
        state->frame_time = current_time - state->last_frame_time;
    }
    state->last_frame_time = current_time;

    double start_time = get_time_ms();

    // Update player movement
    float dx = 0, dy = 0;
    if (leo_IsKeyDown(KEY_A) || leo_IsKeyDown(KEY_LEFT))
        dx = -1;
    if (leo_IsKeyDown(KEY_D) || leo_IsKeyDown(KEY_RIGHT))
        dx = 1;
    if (leo_IsKeyDown(KEY_W) || leo_IsKeyDown(KEY_UP))
        dy = -1;
    if (leo_IsKeyDown(KEY_S) || leo_IsKeyDown(KEY_DOWN))
        dy = 1;

    state->player.x += dx * state->player.speed * dt;
    state->player.y += dy * state->player.speed * dt;

    // Keep player on screen
    if (state->player.x < 20) state->player.x = 20;
    if (state->player.x > 1260) state->player.x = 1260;
    if (state->player.y < 20) state->player.y = 20;
    if (state->player.y > 700) state->player.y = 700;

    // Update bouncing balls
    for (int i = 0; i < state->num_balls; i++)
    {
        Ball *ball = &state->balls[i];
        
        ball->x += ball->vel_x * dt;
        ball->y += ball->vel_y * dt;
        
        // Bounce off walls
        if (ball->x <= ball->radius || ball->x >= 1280 - ball->radius)
        {
            ball->vel_x = -ball->vel_x;
            ball->x = (ball->x <= ball->radius) ? ball->radius : 1280 - ball->radius;
        }
        if (ball->y <= ball->radius || ball->y >= 720 - ball->radius)
        {
            ball->vel_y = -ball->vel_y;
            ball->y = (ball->y <= ball->radius) ? ball->radius : 720 - ball->radius;
        }
    }

    // Animate background grid
    state->grid_offset += 50.0f * dt;
    if (state->grid_offset >= 50.0f)
        state->grid_offset -= 50.0f;

    state->update_time = get_time_ms() - start_time;

    // Escape hatch (CI/CD)
    if (state->one_frame && ctx->frame >= 1)
    {
        leo_GameQuit(ctx);
    }
}

/* ----------------------------------------------------------
   Render
   ---------------------------------------------------------- */
static void demo_render_ui(leo_GameContext *ctx)
{
    GameState *state = (GameState *)ctx->user_data;

    double render_start = get_time_ms();

    // Draw animated background grid
    leo_Color grid_color = {40, 40, 80, 255};
    for (int x = (int)(-state->grid_offset); x < 1280; x += 50)
    {
        leo_DrawLine(x, 0, x, 720, grid_color);
    }
    for (int y = (int)(-state->grid_offset); y < 720; y += 50)
    {
        leo_DrawLine(0, y, 1280, y, grid_color);
    }

    // Draw bouncing balls
    for (int i = 0; i < state->num_balls; i++)
    {
        Ball *ball = &state->balls[i];
        leo_DrawCircleFilled((int)ball->x, (int)ball->y, ball->radius, ball->color);
        leo_DrawCircle((int)ball->x, (int)ball->y, ball->radius, LEO_WHITE);
    }

    // Draw player as a bright square with outline
    leo_DrawRectangle((int)(state->player.x - 20), (int)(state->player.y - 20), 40, 40, state->player.color);
    leo_DrawRectangleLines((int)(state->player.x - 20), (int)(state->player.y - 20), 40, 40, LEO_YELLOW);

    // Draw player trail effect
    for (int i = 1; i <= 5; i++)
    {
        leo_Color trail_color = {255, 255, 0, (unsigned char)(50 / i)};
        leo_DrawRectangle((int)(state->player.x - 15 - i*2), (int)(state->player.y - 15 - i*2), 
                         30 + i*4, 30 + i*4, trail_color);
    }

    state->render_time = get_time_ms() - render_start;

    // UI overlay with performance info
    leo_DrawFPS(20, 32);

    // Timing info with color coding
    char timing_text[256];
    sprintf(timing_text, "Frame: %.2fms (%.1f FPS)", state->frame_time, 1000.0 / state->frame_time);
    leo_Color fps_color = (state->frame_time > 20.0) ? LEO_RED : LEO_GREEN;
    leo_DrawText(timing_text, 20, 60, 16, fps_color);

    sprintf(timing_text, "Update: %.2fms", state->update_time);
    leo_DrawText(timing_text, 20, 80, 16, LEO_GREEN);

    sprintf(timing_text, "Render: %.2fms", state->render_time);
    leo_DrawText(timing_text, 20, 100, 16, LEO_GREEN);

    leo_DrawText("PERFORMANCE TEST - Use WASD to move", 20, 140, 20, LEO_YELLOW);
    leo_DrawText("Watch for smooth movement and stable FPS", 20, 170, 16, LEO_WHITE);
    leo_DrawText("Press ESC to quit", 20, 190, 16, LEO_GRAY);

    // Render transitions (call this last to cover everything)
    leo_RenderTransitions();
}

static void demo_shutdown(leo_GameContext *ctx)
{
    // Nothing to cleanup in this simple test
}

/* ----------------------------------------------------------
   Entrypoint
   ---------------------------------------------------------- */
int main(int argc, char **argv)
{
    GameState state = {0};
    
    // Check for one-frame mode (for CI/CD testing)
    for (int i = 1; i < argc; i++)
    {
        if (strcmp(argv[i], "--one-frame") == 0 || strcmp(argv[i], "-1") == 0)
        {
            state.one_frame = true;
            break;
        }
    }

    leo_GameConfig cfg = {
        .window_width = 1280,
        .window_height = 720,
        .window_title = "Leo Engine - Performance Test",
        .target_fps = 60,
        .logical_width = 0,
        .logical_height = 0,
        .presentation = LEO_LOGICAL_PRESENTATION_LETTERBOX,
        .scale_mode = LEO_SCALE_NEAREST,
        .clear_color = {20, 20, 40, 255}, // Dark blue background
        .start_paused = false,
        .user_data = &state,
    };

    leo_GameCallbacks cb = {
        .on_setup = demo_setup,
        .on_update = demo_update,
        .on_render_ui = demo_render_ui,
        .on_shutdown = demo_shutdown,
    };

    return leo_GameRun(&cfg, &cb);
}
