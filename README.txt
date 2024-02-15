matthew blakcburn:
 - implemented rgba getter functions, compute_index, blend_components, blend_colors, draw_tile and draw_sprite
 - wrote unit tests for color blending

atticus colwell:
 - implemented draw_pixel, draw_rect, and draw_circle. Implemented base of draw_tile before being finished by matthew
 - Implemented helper functions square and square distance
 - wrote unit tests for all helper functions outside of color blending

interesting details:
 - Redid draw_circle twice, original method was a different algorithm for creating a circle but the test cases didn't seem 
 to match with its computing method.