/*
 * Drawing functions implementations for main and helpers
 * CSF Assignment 2
 * Atticus Colwell
 * acolwel2@jhu.edu
 * Matthew Blackburn
 * mblackb8@jhu.edu
 */

// C implementations of drawing functions (and helper functions)

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include "drawing_funcs.h"

////////////////////////////////////////////////////////////////////////
// Helper functions
////////////////////////////////////////////////////////////////////////

//
// Returns true if an x and y coordinate is in the bounds of an image.
//
// Parameters:
//   img   - pointer to struct Image
//   x     - x coordinate (pixel column)
//   y     - y coordinate (pixel row)
//
// Returns:
//   The a 1 or 0 to determine in bounds.
//
int32_t in_bounds(struct Image *img, int32_t x, int32_t y) {
  if (x >= 0 && x < img->width && y >= 0 && y < img->height) {
    return 1;
  } else {
    return 0;
  }
}

//
// Calculates index based off given x and y coordinates.
//
// Parameters:
//   img   - pointer to struct Image
//   x     - x coordinate (pixel column)
//   y     - y coordinate (pixel row)
//
// Returns:
//   The 32-bit index.
//
uint32_t compute_index(struct Image *img, int32_t x, int32_t y) {
  uint32_t index = x + (y * img->width);
  return index;
}

//
// Extracts the red component from a given 32-bit color value.
//
// Parameters:
//   color - 32-bit color value
//
// Returns:
//   The 8-bit red component of the color.
//
uint8_t get_r(uint32_t color) {
  // use 0xFF as bit mask that extracts most significant 8 bits of 
  uint8_t red_component = (color >> 24) & 0xFF;
  return red_component;
}

//
// Extracts the green component from a given 32-bit color value.
//
// Parameters:
//   color - 32-bit color value
//
// Returns:
//   The 8-bit green component of the color.
//
uint8_t get_g(uint32_t color) {
  // use 0xFF as bit mask that extracts upper middle significant 8 bits of 
  uint8_t green_component = (color >> 16) & 0xFF;
  return green_component;
}

//
// Extracts the blue component from a given 32-bit color value.
//
// Parameters:
//   color - 32-bit color value
//
// Returns:
//   The 8-bit blue component of the color.
//
uint8_t get_b(uint32_t color) {
  // use 0xFF as bit mask that extracts lower middle significant 8 bits of 
  uint8_t blue_component = (color >> 8) & 0xFF;
  return blue_component;
}

//
// Extracts the alpha (transparency) component from a given 32-bit color value.
//
// Parameters:
//   color - 32-bit color value
//
// Returns:
//   The 8-bit alpha component of the color.
//
uint8_t get_a(uint32_t color) {
  // use 0xFF as bit mask that extracts least significant 8 bits of 
  uint8_t alpha_component = color & 0xFF;
  return alpha_component;
}


//
// Blends two color components based on the given alpha value.
//
// Parameters:
//   fg    - foreground color component
//   bg    - background color component
//   alpha - alpha value used for blending
//
// Returns:
//   The blended color component.
//
uint8_t blend_components(uint32_t fg, uint32_t bg, uint32_t alpha) {
  return ((alpha * fg) + ((255 - alpha) * bg)) / 255;
}

//
// Blends two 32-bit colors based on the alpha component of the foreground color.
//
// Parameters:
//   fg - foreground color
//   bg - background color
//
// Returns:
//   The 32-bit blended color.
//
uint32_t blend_colors(uint32_t fg, uint32_t bg) {
  uint32_t blended_color = 0;

  uint32_t fg_alpha = get_a(fg);
  uint8_t blended_red = blend_components(get_r(fg), get_r(bg), fg_alpha);
  uint8_t blended_green = blend_components(get_g(fg), get_g(bg), fg_alpha);
  uint8_t blended_blue = blend_components(get_b(fg), get_b(bg), fg_alpha);
  blended_color |= blended_red;    // Red component in the most significant bits
  blended_color <<= 8;
  blended_color |= blended_green;  // Green component
  blended_color <<= 8;
  blended_color |= blended_blue;   // Blue component
  blended_color <<= 8;
  blended_color |= 0xFF; 


  return blended_color;
}

//
// Sets the color of a pixel in an image at the specified index by blending the new color with the existing color.
//
// Parameters:
//   img   - pointer to struct Image
//   index - index of the pixel within the image's data array
//   color - new color to set at the pixel
//
void set_pixel(struct Image *img, uint32_t index, uint32_t color) {
  // get foreground and backgorund colors
  uint32_t fg_color = color;
  uint32_t bg_color = img->data[index];

  // blend foreground color with background color at index
  uint32_t new_pixel = blend_colors(fg_color, bg_color);
  img->data[index] = new_pixel;
}

//
// Calculates the square of an integer.
//
// Parameters:
//   x - integer to square
//
// Returns:
//   The square of x.
//
int64_t square(int64_t x) {
  return x * x;
}

//
// Calculates the square of the distance between two points.
//
// Parameters:
//   x1, y1 - coordinates of the first point
//   x2, y2 - coordinates of the second point
//
// Returns:
//   The square of the distance between the two points.
//
int64_t square_dist(int64_t x1, int64_t y1, int64_t x2, int64_t y2) {
  return square(x1 - x2) + square(y1 - y2);
}



////////////////////////////////////////////////////////////////////////
// API functions
////////////////////////////////////////////////////////////////////////

//
// Draw a pixel.
//
// Parameters:
//   img   - pointer to struct Image
//   x     - x coordinate (pixel column)
//   y     - y coordinate (pixel row)
//   color - uint32_t color value
//
void draw_pixel(struct Image *img, int32_t x, int32_t y, uint32_t color) {
  if (in_bounds(img, x, y)) { // ensure x,y coordinate is within img bounds
    set_pixel(img, compute_index(img, x, y), color);
  }
}

//
// Draw a rectangle.
// The rectangle has rect->x,rect->y as its upper left corner,
// is rect->width pixels wide, and rect->height pixels high.
//
// Parameters:
//   img     - pointer to struct Image
//   rect    - pointer to struct Rect
//   color   - uint32_t color value
//
void draw_rect(struct Image *img,
               const struct Rect *rect,
               uint32_t color) {

  for (int y = rect->y; y < rect->y + rect->height; y++) {
    for (int x = rect->x; x < rect->x + rect->width; x++) {
      if (in_bounds(img, x, y)) {
        set_pixel(img, compute_index(img, x, y), color);
      }
    }
  }
}

//
// Draw a circle.
// The circle has x,y as its center and has r as its radius.
//
// Parameters:
//   img     - pointer to struct Image
//   x       - x coordinate of circle's center
//   y       - y coordinate of circle's center
//   r       - radius of circle
//   color   - uint32_t color value
//
void draw_circle(struct Image *img, int32_t x, int32_t y, int32_t r, uint32_t color) {
  // Iterate over the square that bounds the circle
  for (int i = y - r; i <= y + r; i++) {
    for (int j = x - r; j <= x + r; j++) {
      if (square_dist(x, y, j, i) <= r * r) {
        // Point is inside the circle, draw the pixel
        draw_pixel(img, j, i, color);
      }
    }
  }
}

//
// Draw a tile by copying all pixels in the region
// enclosed by the tile parameter in the tilemap image
// to the specified x/y coordinates of the destination image.
// No blending of the tile pixel colors with the background
// colors should be done.
//
// Parameters:
//   img     - pointer to Image (dest image)
//   x       - x coordinate of location where tile should be copied
//   y       - y coordinate of location where tile should be copied
//   tilemap - pointer to Image (the tilemap)
//   tile    - pointer to Rect (the tile)
//
void draw_tile(struct Image *img,
               int32_t X, int32_t Y,
               struct Image *tilemap,
               const struct Rect *tile) {

  // stop execution if out of bounds access to tilemap
  for (int y = 0; y < tile->height; y++) {
    for (int x = 0; x < tile->width; x++) {
      if (!in_bounds(tilemap, x + tile->x, y + tile->y)) {
        return;
      }
    }
  }
  // copy pixels from tile map to destination img 
  for (int y = 0; y < tile->height; y++) {
    for (int x = 0; x < tile->width; x++) {
      if (in_bounds(img, X + x, Y + y)) {
        img->data[compute_index(img, X + x, Y + y)] = tilemap->data[compute_index(tilemap, x + tile->x, y + tile->y)];
      }
    }
  }
}

//
// Draw a sprite by copying all pixels in the region
// enclosed by the sprite parameter in the spritemap image
// to the specified x/y coordinates of the destination image.
// The alpha values of the sprite pixels should be used to
// blend the sprite pixel colors with the background
// pixel colors.
//
// Parameters:
//   img       - pointer to Image (dest image)
//   x         - x coordinate of location where sprite should be copied
//   y         - y coordinate of location where sprite should be copied
//   spritemap - pointer to Image (the spritemap)
//   sprite    - pointer to Rect (the sprite)
//
void draw_sprite(struct Image *img,
                 int32_t x, int32_t y,
                 struct Image *spritemap,
                 const struct Rect *sprite) {

  // stop execution if out of bounds access to spritemap
  for (int y_sprite = 0; y_sprite < sprite->height; y_sprite++) {
    for (int x_sprite = 0; x_sprite < sprite->width; x_sprite++) {
      if (!in_bounds(spritemap, x_sprite + sprite->x, y_sprite + sprite->y)) {
        return;
      }
    }
  }
  // copy pixels from sprite map to destination img 
  for (int y_sprite = 0; y_sprite < sprite->height; y_sprite++) {
    for (int x_sprite = 0; x_sprite < sprite->width; x_sprite++) {
      if (in_bounds(img, x + x_sprite, y + y_sprite)) {
        uint32_t sprite_color = spritemap->data[compute_index(spritemap, x_sprite + sprite->x, y_sprite + sprite->y)];
        set_pixel(img, compute_index(img, x + x_sprite, y + y_sprite), sprite_color);
      }
    }
  }
}
