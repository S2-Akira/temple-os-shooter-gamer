#define MAX_ENEMIES 20
#define MAX_BULLETS 20
#define MAX_POWERUPS 10

typedef struct {
  I64 x, y, w, h;
  I64 dx, dy;
  U8 alive;
  U8 type;
  I64 hp;
} Entity;

Entity player;
Entity bullets[MAX_BULLETS];
Entity enemies[MAX_ENEMIES];
Entity powerups[MAX_POWERUPS];

I64 score = 0;
I64 level = 1;
U8 running = TRUE;
U8 paused = FALSE;

U0 InitEntity(Entity* e, I64 x, I64 y, I64 w, I64 h, I64 dx, I64 dy, U8 type, I64 hp) {
  e->x = x; e->y = y; e->w = w; e->h = h;
  e->dx = dx; e->dy = dy; e->type = type;
  e->alive = TRUE; e->hp = hp;
}

U0 DrawEntity(Entity* e, U8 color) {
  if (!e->alive) return;
  DrawRectFill(e->x, e->y, e->w, e->h, color);
}

U8 CheckCollision(Entity* a, Entity* b) {
  return a->alive && b->alive &&
         a->x < b->x + b->w &&
         a->x + a->w > b->x &&
         a->y < b->y + b->h &&
         a->y + a->h > b->y;
}

U0 ClearScreen() { Cls(0); }

U0 SpawnEnemyWave(I64 count) {
  I64 i;
  for (i=0; i < count; i++) {
    InitEntity(&enemies[i], (i*30)%600 + 20, 20 + (i/10)*40, 20, 20, 0, 1 + level/2, 1, 3);
  }
}

U0 FireBullet(I64 x, I64 y, I64 dx, I64 dy) {
  I64 i;
  for (i=0; i < MAX_BULLETS; i++) {
    if (!bullets[i].alive) {
      InitEntity(&bullets[i], x, y, 5, 10, dx, dy, 1, 1);
      Beep(1000, 20);
      break;
    }
  }
}

U0 UpdateEntity(Entity* e) {
  if (!e->alive) return;
  e->x += e->dx;
  e->y += e->dy;
  // Keep inside screen horizontally
  if (e->x < 0) e->x = 0;
  else if (e->x + e->w > 640) e->x = 640 - e->w;
  // Deactivate if offscreen vertically
  if (e->y < -e->h || e->y > 480) e->alive = FALSE;
}

U0 PlayerControl() {
  if (KeyReady()) {
    U8 k = GetKey();
    if (k == SC_LEFT) player.dx = -8;
    else if (k == SC_RIGHT) player.dx = 8;
    else player.dx = 0;

    if (k == ' ') FireBullet(player.x + player.w/2 - 2, player.y, 0, -10);
    if (k == SC_ESC) running = FALSE;
    if (k == 'P' || k == 'p') paused = !paused;
  } else player.dx = 0;
}

U0 GameLoop() {
  while(running) {
    if (!paused) {
      PlayerControl();
      UpdateEntity(&player);

      I64 i, j;

      for (i=0; i<MAX_BULLETS; i++) UpdateEntity(&bullets[i]);
      for (i=0; i<MAX_ENEMIES; i++) {
        if(enemies[i].alive) {
          UpdateEntity(&enemies[i]);
          // Enemy AI: simple downward movement and random shots
          if (RandU16() % 100 < 5) {
            FireBullet(enemies[i].x + enemies[i].w/2, enemies[i].y + enemies[i].h, 0, 5);
          }
        }
      }

      // Collisions
      for(i=0; i<MAX_BULLETS; i++) {
        if(bullets[i].alive) {
          // Bullet hits enemy
          for(j=0; j<MAX_ENEMIES; j++) {
            if(enemies[j].alive && CheckCollision(&bullets[i], &enemies[j])) {
              bullets[i].alive = FALSE;
              enemies[j].hp--;
              if(enemies[j].hp <= 0) {
                enemies[j].alive = FALSE;
                score += 10;
                Beep(1500, 30);
              }
            }
          }
          // Bullet hits player (enemy bullets)
          if(CheckCollision(&bullets[i], &player) && bullets[i].type == 1) {
            player.hp--;
            bullets[i].alive = FALSE;
            Beep(600, 40);
            if (player.hp <= 0) running = FALSE;
          }
        }
      }
    }

    ClearScreen();

    DrawEntity(&player, 9);
    I64 i;
    for(i=0; i<MAX_BULLETS; i++) {
      DrawEntity(&bullets[i], bullets[i].type == 1 ? 10 : 12);
    }
    for(i=0; i<MAX_ENEMIES; i++) DrawEntity(&enemies[i], 12);

    DrawText(10,10,"Score:%d  Level:%d  Health:%d", score, level, player.hp);
    if(paused) DrawText(280, 220, "PAUSED");

    Sleep(0);
  }
}

U0 Main() {
  InitEntity(&player, 310, 460, 20, 15, 0, 0, 0, 5);
  for (I64 i=0; i<MAX_BULLETS; i++) bullets[i].alive = FALSE;
  for (I64 i=0; i<MAX_ENEMIES; i++) enemies[i].alive = FALSE;

  SpawnEnemyWave(15);
  GameLoop();

  ClearScreen();
  DrawText(280, 220, "GAME OVER");
  DrawText(260, 250, "FINAL SCORE: %d", score);
  DrawText(220, 280, "Press any key to exit...");
  GetCharWait();
}

Main;
