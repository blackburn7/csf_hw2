#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "image.h"
#include "drawing_funcs.h"
#include "tctest.h"

// an expected color identified by a (non-zero) character code
typedef struct {
  char c;
  uint32_t color;
} ExpectedColor;

// struct representing a "picture" of an expected image
typedef struct {
  ExpectedColor colors[20];
  const char *pic;
} Picture;

typedef struct {
  struct Image small;
  struct Image large;
  struct Image tilemap;
  struct Image spritemap;
} TestObjs;

// dimensions and pixel index computation for "small" test image (objs->small)
#define SMALL_W        8
#define SMALL_H        6
#define SMALL_IDX(x,y) ((y)*SMALL_W + (x))

// dimensions of the "large" test image
#define LARGE_W        24
#define LARGE_H        20

// create test fixture data
TestObjs *setup(void) {
  TestObjs *objs = (TestObjs *) malloc(sizeof(TestObjs));
  init_image(&objs->small, SMALL_W, SMALL_H);
  init_image(&objs->large, LARGE_W, LARGE_H);
  objs->tilemap.data = NULL;
  objs->spritemap.data = NULL;
  return objs;
}

// clean up test fixture data
void cleanup(TestObjs *objs) {
  free(objs->small.data);
  free(objs->large.data);
  free(objs->tilemap.data);
  free(objs->spritemap.data);

  free(objs);
}

uint32_t lookup_color(char c, const ExpectedColor *colors) {
  for (unsigned i = 0; ; i++) {
    assert(colors[i].c != 0);
    if (colors[i].c == c) {
      return colors[i].color;
    }
  }
}

void check_picture(struct Image *img, Picture *p) {
  unsigned num_pixels = img->width * img->height;
  assert(strlen(p->pic) == num_pixels);

  for (unsigned i = 0; i < num_pixels; i++) {
    char c = p->pic[i];
    uint32_t expected_color = lookup_color(c, p->colors);
    uint32_t actual_color = img->data[i];
    ASSERT(actual_color == expected_color);
  }
}

// prototypes of test functions
void test_draw_pixel(TestObjs *objs);
// void test_draw_rect(TestObjs *objs);
// void test_draw_circle(TestObjs *objs);
// void test_draw_circle_clip(TestObjs *objs);
// void test_draw_tile(TestObjs *objs);
// void test_draw_sprite(TestObjs *objs);
void test_color_extraction(TestObjs *objs);
void test_compute_index(TestObjs *objs);
void test_in_bounds(TestObjs *objs);
void test_blend_components();
void test_blend_colors();
//void test_square_dist();
//void test_square();
void test_set_pixel();

int main(int argc, char **argv) {
  if (argc > 1) {
    // user specified a specific test function to run
    tctest_testname_to_execute = argv[1];
  }

  TEST_INIT();

  TEST(test_draw_pixel);
  //TEST(test_draw_rect);
  //TEST(test_draw_circle);
  //TEST(test_draw_circle_clip);
  //TEST(test_draw_tile);
  //TEST(test_draw_sprite);
  TEST(test_color_extraction);
  TEST(test_compute_index);
  TEST(test_in_bounds);
  TEST(test_blend_components);
  TEST(test_blend_colors);
  /*TEST(test_square_dist);
  TEST(test_square); */
  TEST(test_set_pixel);
  TEST_FINI();
}

void test_in_bounds(TestObjs *objs) {
    // coords inside
    ASSERT(in_bounds(&objs->large, 10, 10) == 1);

    // coords at the edge
    ASSERT(in_bounds(&objs->large, LARGE_W - 1, LARGE_H - 1) == 1);

    // coords outside bounds
    ASSERT(in_bounds(&objs->large, LARGE_W, LARGE_H) == 0);

    // x in, y below 0
    ASSERT(in_bounds(&objs->large, 10, -1) == 0);

    // x in, y above max
    ASSERT(in_bounds(&objs->large, 10, LARGE_H) == 0);

    // x exceeds, y in
    ASSERT(in_bounds(&objs->large, LARGE_W, 10) == 0);

    // x negative, y in
    ASSERT(in_bounds(&objs->large, -1, 10) == 0);

    // x 0, y above top
    ASSERT(in_bounds(&objs->large, 0, -1) == 0);

    // x right edge, y below bottom
    ASSERT(in_bounds(&objs->large, LARGE_W - 1, LARGE_H) == 0);

    // x far right, y in
    ASSERT(in_bounds(&objs->large, LARGE_W + 100, 10) == 0);

    // x, y far outside
    ASSERT(in_bounds(&objs->large, LARGE_W + 100, LARGE_H + 100) == 0);
}

void test_color_extraction(TestObjs *objs) {
  // Test get_r function
  ASSERT(get_r(0xFF000000) == 0xFF);
  ASSERT(get_r(0x00FF00FF) == 0x00);
  ASSERT(get_r(0x80ABCDEF) == 0x80);

  // Test get_g function
  ASSERT(get_g(0x00FF0000) == 0xFF);
  ASSERT(get_g(0xFF0000FF) == 0x00);
  ASSERT(get_g(0x12345678) == 0x34);

  // Test get_b function
  ASSERT(get_b(0x0000FF00) == 0xFF);
  ASSERT(get_b(0xFFFF0000) == 0x00);
  ASSERT(get_b(0x87654321) == 0x43);

  // Test get_a function
  ASSERT(get_a(0x000000FF) == 0xFF);
  ASSERT(get_a(0x00000000) == 0x00);
  ASSERT(get_a(0x0000007F) == 0x7F);
}

void test_blend_components() {
  // Full opacity
  ASSERT(blend_components(100, 50, 255) == 100);

  // No opacity
  ASSERT(blend_components(100, 50, 0) == 50);

  // 50% opacity
  ASSERT(blend_components(100, 0, 127) == 49);

  // 25% opacity of fg over bg
  ASSERT(blend_components(100, 200, 64) == 174);

  // 75% opacity of fg over bg
  ASSERT(blend_components(200, 100, 191) == 174);
}
/*
void test_square() {
  ASSERT(square(5) == 25);

  ASSERT(square(4) == 16);

  ASSERT(square(0) == 0);
}

void test_square_dist() {
  ASSERT(square_dist(3, 4, 0, 0) == 25); 

  ASSERT(square_dist(1, 1, 4, 5) == 25);
}
 */
void test_blend_colors() {
  // Fully opaque fg
  ASSERT(blend_colors(0xFF0000FF, 0x00FF00FF) == 0xFF0000FF);

  // Fully transparent fg
  ASSERT(blend_colors(0x00000000, 0x00FF00FF) == 0x00FF00FF);

  // 50% opacity red over green 
  ASSERT(blend_colors(0xFF00007F, 0x00FF00FF) == 0x7f8000FF);

  // 50% opacity blue over red 
  ASSERT(blend_colors(0x0000FF7F, 0xFF0000FF) == 0x80007FFF);

  // 25% opacity green over blue 
  ASSERT(blend_colors(0x00FF003F, 0x0000FFFF) == 0x003FC0FF);

  // 75% opacity blue over green 
  ASSERT(blend_colors(0x0000FFBF, 0x00FF00FF) == 0x0040BFFF);

  // 100% opacity, green over green
  ASSERT(blend_colors(0x00FF00FF, 0x00FF00FF) == 0x00FF00FF);

  // 0% opacity, red over blue
  ASSERT(blend_colors(0x0000FF00, 0xFF0000FF) == 0xFF0000FF);

  // Test blending two fully opaque colors
  ASSERT(blend_colors(0xFFFFFFFF, 0x000000FF) == 0xFFFFFFFF);

  // Test blending with the foreground fully transparent
  ASSERT(blend_colors(0x0000FF00, 0xFF0000FF) == 0xFF0000FF);
}

void test_set_pixel() {
  struct Image img;
  img.width = 2;
  img.height = 2;
  img.data = (uint32_t[4]){ 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF }; // White bg

  // fully opaque color
  set_pixel(&img, 0, 0xFF0000FF); // Set top-left pixel to red

  ASSERT(img.data[0] == 0xFF0000FF);

  // fully transparent color
  set_pixel(&img, 1, 0x00000000); 
  ASSERT(img.data[1] == 0xFFFFFFFF);

  // Set pixel with a non transparent color
  set_pixel(&img, 2, 0x8000FF00); 
  ASSERT((img.data[2] & 0x0000FF00) > 0); 

  // Overwrite one with another
  set_pixel(&img, 0, 0xFFFF00FF); 
  ASSERT(img.data[0] == 0xFFFF00FF);

  // edge of img case
  set_pixel(&img, 3, 0xFF00FFFF); 
  ASSERT(img.data[3] == 0xFF00FFFF);
}

void test_compute_index(TestObjs *objs) {
  // mid range
  ASSERT(compute_index(&objs->large, 10, 12) == 298);
 
  // first
  ASSERT(compute_index(&objs->large, 0, 0) == 0);

  // bottom right
  ASSERT(compute_index(&objs->large, LARGE_W - 1, LARGE_H - 1) == 479);

  // new row pixel
  ASSERT(compute_index(&objs->large, 0, 1) == 24);

  // last pixel of a row
  ASSERT(compute_index(&objs->large, LARGE_W - 1, 0) == 23);
}

void test_draw_pixel(TestObjs *objs) {
  // initially objs->small pixels are opaque black
  ASSERT(objs->small.data[SMALL_IDX(3, 2)] == 0x000000FFU);
  ASSERT(objs->small.data[SMALL_IDX(5, 4)] == 0x000000FFU);

  // test drawing completely opaque pixels
  draw_pixel(&objs->small, 3, 2, 0xFF0000FF); // opaque red
  ASSERT(objs->small.data[SMALL_IDX(3, 2)] == 0xFF0000FF);
  draw_pixel(&objs->small, 5, 4, 0x800080FF); // opaque magenta (half-intensity)
  ASSERT(objs->small.data[SMALL_IDX(5, 4)] == 0x800080FF);

  // test color blending
  draw_pixel(&objs->small, 3, 2, 0x00FF0080); // half-opaque full-intensity green
  ASSERT(objs->small.data[SMALL_IDX(3, 2)] == 0x7F8000FF);
  draw_pixel(&objs->small, 4, 2, 0x0000FF40); // 1/4-opaque full-intensity blue
  ASSERT(objs->small.data[SMALL_IDX(4, 2)] == 0x000040FF);
} 

/*
void test_draw_rect(TestObjs *objs) {
  struct Rect red_rect = { .x = 2, .y = 2, .width=3, .height=3 };
  struct Rect blue_rect = { .x = 3, .y = 3, .width=3, .height=3 };
  draw_rect(&objs->small, &red_rect, 0xFF0000FF); // red is full-intensity, full opacity
  draw_rect(&objs->small, &blue_rect, 0x0000FF80); // blue is full-intensity, half opacity

  const uint32_t red   = 0xFF0000FF; // expected full red color
  const uint32_t blue  = 0x000080FF; // expected full blue color
  const uint32_t blend = 0x7F0080FF; // expected red/blue blend color
  const uint32_t black = 0x000000FF; // expected black (background) color

  Picture expected = {
    { {'r', red}, {'b', blue}, {'n', blend}, {' ', black} },
    "        "
    "        "
    "  rrr   "
    "  rnnb  "
    "  rnnb  "
    "   bbb  "
  };

  check_picture(&objs->small, &expected);
}

void test_draw_circle(TestObjs *objs) {
  Picture expected = {
    { {' ', 0x000000FF}, {'x', 0x00FF00FF} },
    "   x    "
    "  xxx   "
    " xxxxx  "
    "  xxx   "
    "   x    "
    "        "
  };

  draw_circle(&objs->small, 3, 2, 2, 0x00FF00FF);

  check_picture(&objs->small, &expected);
}

void test_draw_circle_clip(TestObjs *objs) {
  Picture expected = {
    { {' ', 0x000000FF}, {'x', 0x00FF00FF} },
    " xxxxxxx"
    " xxxxxxx"
    "xxxxxxxx"
    " xxxxxxx"
    " xxxxxxx"
    "  xxxxx "
  };

  draw_circle(&objs->small, 4, 2, 4, 0x00FF00FF);

  check_picture(&objs->small, &expected);
}

void test_draw_tile(TestObjs *objs) {
  ASSERT(read_image("img/PrtMimi.png", &objs->tilemap) == IMG_SUCCESS);

  struct Rect r = { .x = 4, .y = 2, .width = 16, .height = 18 };
  draw_rect(&objs->large, &r, 0x1020D0FF);

  struct Rect grass = { .x = 0, .y = 16, .width = 16, .height = 16 };
  draw_tile(&objs->large, 3, 2, &objs->tilemap, &grass);

  Picture pic = {
    {
      { ' ', 0x000000ff },
      { 'a', 0x52ad52ff },
      { 'b', 0x1020d0ff },
      { 'c', 0x257b4aff },
      { 'd', 0x0c523aff },
    },
    "                        "
    "                        "
    "             a     b    "
    "            a      b    "
    "            a     ab    "
    "           ac      b    "
    "           ac a    b    "
    "      a a  ad  a   b    "
    "     a  a aad  aa ab    "
    "     a  a acd aaacab    "
    "    aa  cdacdaddaadb    "
    "     aa cdaddaaddadb    "
    "     da ccaddcaddadb    "
    "    adcaacdaddddcadb    "
    "   aaccacadcaddccaab    "
    "   aacdacddcaadcaaab    "
    "   aaaddddaddaccaacb    "
    "   aaacddcaadacaaadb    "
    "    bbbbbbbbbbbbbbbb    "
    "    bbbbbbbbbbbbbbbb    "
  };

  check_picture(&objs->large, &pic);
}

void test_draw_sprite(TestObjs *objs) {
  ASSERT(read_image("img/NpcGuest.png", &objs->spritemap) == IMG_SUCCESS);

  struct Rect r = { .x = 1, .y = 1, .width = 14, .height = 14 };
  draw_rect(&objs->large, &r, 0x800080FF);

  struct Rect sue = { .x = 128, .y = 136, .width = 16, .height = 15 };
  draw_sprite(&objs->large, 4, 2, &objs->spritemap, &sue);

  Picture pic = {
    {
      { ' ', 0x000000ff },
      { 'a', 0x800080ff },
      { 'b', 0x9cadc1ff },
      { 'c', 0xefeae2ff },
      { 'd', 0x100000ff },
      { 'e', 0x264c80ff },
      { 'f', 0x314e90ff },
    },
    "                        "
    " aaaaaaaaaaaaaa         "
    " aaaaaaaaaaaaaa         "
    " aaaaaaaaaaaaaa         "
    " aaaaaaabccccccbc       "
    " aaaaacccccccccccc      "
    " aaaacbddcccddcbccc     "
    " aaacbbbeccccedbccc     "
    " aaacbbceccccebbbccc    "
    " aaabbbccccccccbbccc    "
    " aaaabbbcccccccb ccb    "
    " aaaabaaaaabbaa  cb     "
    " aaaaaaaaafffea         "
    " aaaaaaaaaffeea         "
    " aaaaaaacffffcc         "
    "        cffffccb        "
    "         bbbbbbb        "
    "                        "
    "                        "
    "                        "
  };

  check_picture(&objs->large, &pic);
}
*/
