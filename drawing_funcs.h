/*
 * Drawing functions list for main and helpers
 * CSF Assignment 2
 * Atticus Colwell
 * astude99@jhu.edu
 * Matthew Blackburn
 * mblackb8@jhu.edu
 */
#ifndef DRAWING_FUNCS_H
#define DRAWING_FUNCS_H

#include <stdint.h>
#include "image.h"

struct Rect {
  int32_t x, y, width, height;
};

int32_t in_bounds(struct Image *img,
                  int32_t x, int32_t y);

uint32_t compute_index(struct Image *img,
                       int32_t x, int32_t y);

uint8_t get_r(uint32_t color);

uint8_t get_g(uint32_t color);

uint8_t get_b(uint32_t color);

uint8_t get_a(uint32_t color);

uint8_t blend_components(uint32_t fg, uint32_t bg, uint32_t alpha);

uint32_t blend_colors(uint32_t fg, uint32_t bg);

void set_pixel(struct Image *img, uint32_t index, uint32_t color);

int64_t square(int64_t x);

int64_t square_dist(int64_t x1, int64_t y1, int64_t x2, int64_t y2);

void draw_pixel(struct Image *img,
                int32_t x, int32_t y,
                uint32_t color);

void draw_rect(struct Image *img,
               const struct Rect *rect,
               uint32_t color);

void draw_circle(struct Image *img,
                 int32_t x, int32_t y, int32_t r,
                 uint32_t color);

void draw_tile(struct Image *img,
               int32_t x, int32_t y,
               struct Image *tilemap,
               const struct Rect *tile);

void draw_sprite(struct Image *img,
                 int32_t x, int32_t y,
                 struct Image *spritemap,
                 const struct Rect *sprite);



#endif // DRAWING_FUNCS_H
