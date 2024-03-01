/*
 * Assembly-language implementations of the drawing functions
 * CSF Assignment 2
 * Atticus Colwell
 * acolwel2@jhu.edu
 * Matthew Blackburn
 * mblackb8@jhu.edu
 */

/* Offsets of struct Image fields */
#define IMAGE_WIDTH_OFFSET   0
#define IMAGE_HEIGHT_OFFSET  4
#define IMAGE_DATA_OFFSET    8

/* Offsets of struct Rect fields */
#define RECT_X_OFFSET        0
#define RECT_Y_OFFSET        4
#define RECT_WIDTH_OFFSET    8
#define RECT_HEIGHT_OFFSET   12

	.section .text

/***********************************************************************
   Helper functions
   You should declare these as .globl so that
   they can be called from the unit test code.
 ***********************************************************************/

/*
 * Set a specific pixel in the image to a given color.
 *
 * Parameters:
 *   %rdi - pointer to struct Image
 *   %rsi - index of the pixel within the image's data array
 *   %edx - uint32_t color value
 */
    .globl set_pixel
set_pixel:

  pushq %rbp                /* Save base pointer, set it to stack pointer */
  movq %rsp, %rbp           /* Stack frame setup */

  pushq %r12                /* Save used registers */
  pushq %r13
  pushq %r14

  movq %rdi, %r12           /* %rdi contains img pointer, move to %r12 */
  movq %rsi, %r13           /* %rsi contains index, move to %r13 */
  movl %edx, %r14d          /* %edx contains color, move to %r14d */

  /* Get background color from image data at index */
  movq IMAGE_DATA_OFFSET(%r12), %r12   /* Adjust %r12 to point to img->data */
  movl (%r12,%r13,4), %esi             /* Load bg color into %esi */
  
  movl %r14d, %edi                     /* Move new color into %edi for blend_colors */
  call blend_colors                    /* Blend fg and bg colors */
  movl %eax, (%r12,%r13,4)             /* Store blended color back into img->data[index] */

  popq %r14                            /* Restore registers */
  popq %r13
  popq %r12

  popq %rbp                            /* Restore base pointer */
  ret                                  /* Return */

/*
 * Extract the red component from a 32-bit color value.
 *
 * Parameter:
 *   %rdi - uint32_t color value
 *
 * Returns:
 *   The 8-bit red component of the color value.
 */
    .globl get_r
get_r:
    movq %rdi, %rax               /* Copy color into %rax */
    shrq $24, %rax                /* Shift right by 24 bits to isolate the red component */
    andq $0xFF, %rax              /* Mask with 0xFF to get the lower 8 bits */
    ret                           /* Return the red component */

/*
 * Extract the green component from a 32-bit color value.
 *
 * Parameter:
 *   %rdi - uint32_t color value
 *
 * Returns:
 *   The 8-bit green component of the color value, isolated and
 *   right-shifted to the least significant byte position.
 */
    .globl get_g
get_g:
    movq %rdi, %rax               /* Copy color into %rax */
    shrq $16, %rax                /* Shift right by 16 bits to isolate the green component */
    andq $0xFF, %rax              /* Mask with 0xFF */
    ret                           /* Return the green component */

/*
 * Extract the blue component from a 32-bit color value.
 *
 * Parameter:
 *   %rdi - uint32_t color value
 *
 * Returns:
 *   The 8-bit blue component of the color value.
 */
    .globl get_b
get_b:
    movq %rdi, %rax               /* Copy color into %rax */
    shrq $8, %rax                 /* Shift right by 8 bits to isolate the blue component */
    andq $0xFF, %rax              /* Mask with 0xFF */
    ret                           /* Return the blue component */

/*
 * Extract the alpha (transparency) component from a 32-bit color value.
 *
 * Parameter:
 *   %rdi - uint32_t color value
 *
 * Returns:
 *   The 8-bit alpha component of the color value.
 */
    .globl get_a
get_a:
    movq %rdi, %rax               /* Copy color into %rax */
    andq $0xFF, %rax              /* mask with 0xFF to get the a component */
    ret                           /* Return the alpha component */

/*
 * Blend two color components based on an alpha value.
 *
 * Parameters:
 *   %rdi - fg color component
 *   %rsi - bg color component
 *   %rdx - alpha value for the fg color component
 *
 * Returns:
 *   The blended color component.
 */
    .globl blend_components
blend_components:
    movq %rdi, %rax               /* Copy foreground component into %rax */
    imulq %rdx, %rax              /* Multiply fg component by alpha */

    movq $255, %r10               /* Move 255 into %r10 */
    subq %rdx, %r10               /* Subtract alpha from 255 */
    imulq %rsi, %r10              /* Multiply bg with (255 - alpha) */
    addq %r10, %rax               /* add (alpha * fg) with  (255 - alpha) * bg */

    movq $0, %rdx                 /* set rdx to zero for division */
    movq $255, %r11               /* set r11 to 255 */
    idivq %r11                    /* divide rax by 255 */


    ret                           /* Return the blended component */

/*
 * Check if a given (x, y) coordinate is within the bounds of the image.
 *
 * Parameters:
 *   %rdi - pointer to struct Image
 *   %esi - x coordinate (pixel column)
 *   %edx - y coordinate (pixel row)
 *
 * Returns:
 *   1 if the coordinate is within bounds, 0 otherwise.
 */
    .globl in_bounds
in_bounds:

    pushq %r12
    pushq %r13 

    movl IMAGE_WIDTH_OFFSET(%edi), %r12d    /* Load img->width */
    movl IMAGE_HEIGHT_OFFSET(%edi), %r13d   /* Load img->height */
    cmpl %r12d, %esi                        /* Compare x with img->width */
    jae .Lout_of_bounds                     /* Jump if x >= img->width */
    cmpl %r13d, %edx                        /* Compare y with img->height */
    jae .Lout_of_bounds                     /* Jump if y >= img->height */
    movl $0, %r10d
    cmp %r10d, %esi                         /* Check if x < 0 */
    jb .Lout_of_bounds                      /* Jump if x < 0 */
    cmp %r10d, %edx                         /* Check if y < 0 */
    jb .Lout_of_bounds                      /* Jump if y < 0 */

    movl $1, %eax                           /* In bounds, return 1 */
    jmp .Lin_bounds_end

.Lout_of_bounds:
    movl $0, %eax                           /* Out of bounds, return 0 */

.Lin_bounds_end:
    popq %r13
    popq %r12
    ret

/*
 * Compute the index in the image's data array for a given (x, y) coordinate.
 *
 * Parameters:
 *   %rdi - pointer to struct Image
 *   %rsi - x coordinate (pixel column)
 *   %rdx - y coordinate (pixel row)
 *
 * Returns:
 *   The index in the image's data array corresponding to the (x, y) coordinate.
 */
    .globl compute_index
compute_index:
    pushq %rbp
    movq %rsp, %rbp

    movl IMAGE_WIDTH_OFFSET(%rdi), %eax    /* Load img->width */
    imulq %rdx, %rax                       /* img->width * y */
    addq %rsi, %rax                        /* Add x */

    popq %rbp
    ret

/*
 * Blend two 32-bit color values.
 *
 * Parameters:
 *   %rdi - fg color value
 *   %rsi - bg color value
 *
 * Returns:
 *   The blended 32-bit color value.
 */
    .globl blend_colors
blend_colors:
    pushq %r12                            /* save r12 */
    pushq %r13                            /* save r13 */
    pushq %r14                            /* save r14 */
    pushq %r15                            /* save r15 */
    pushq %rbx                            /* save rbx */

    pushq %rbp                            /* save rbp */
    movq %rsp, %rbp                       /* setup new stack frame */
    subq $32, %rsp                        /* allocate local variables */

    /* setup fg and bg colors */
    movq %rdi, %r12                       /* fg color to r12 */
    movq %rsi, %r13                       /* bg color to r13 */
    
    /* extract alpha component */
    call get_a                            /* get alpha from fg */
    movq %rax, %r14                       /* store alpha in r14 */

    /* blend red component */
    call get_r                            /* get red from fg */
    movq %rax, %r15                       /* store fg red in r15 */
    movq %r13, %rdi                       /* set bg as param for get_r */
    call get_r                            /* get red from bg */
    movq %rax, %rbx                       /* store bg red in rbx */
    movq %r15, %rdi                       /* set fg red as param for blend_components */
    movq %rbx, %rsi                       /* set bg red as second param */
    movq %r14, %rdx                       /* alpha as third param */
    call blend_components                 /* blend red components */
    movb %al, 3(%rbp)                     /* store blended red at lowest byte */

    /* blend green component */
    movq %r12, %rdi                       /* set fg as param for get_g */
    call get_g                            /* get green from fg */
    movq %rax, %r15                       /* store fg green in r15 */
    movq %r13, %rdi                       /* set bg as param for get_g */
    call get_g                            /* get green from bg */
    movq %rax, %rbx                       /* store bg green in rbx */
    movq %r15, %rdi                       /* set fg green as param */
    movq %rbx, %rsi                       /* set bg green as second param */
    movq %r14, %rdx                       /* alpha as third param */
    call blend_components                 /* blend green components */
    movb %al, 2(%rbp)                     /* store blended green */

    /* blend blue component */
    movq %r12, %rdi                       /* set fg as param for get_b */
    call get_b                            /* get blue from fg */
    movq %rax, %r15                       /* store fg blue in r15 */
    movq %r13, %rdi                       /* set bg as param for get_b */
    call get_b                            /* get blue from bg */
    movq %rax, %rbx                       /* store bg blue in rbx */
    movq %r15, %rdi                       /* set fg blue as param */
    movq %rbx, %rsi                       /* set bg blue as second param */
    movq %r14, %rdx                       /* alpha as third param */
    call blend_components                 /* blend blue components */
    movb %al, 1(%rbp)                     /* store blended blue */

    /* set full opacity */
    movb $0xFF, (%rbp)                    /* set highest byte to 0xFF for full opacity */

    movl (%rbp), %eax                     /* move blended color to eax */

    addq $32, %rsp                        /* deallocate local variables */
    popq %rbp                             /* restore rbp */
    popq %rbx                             /* restore rbx */
    popq %r15                             /* restore r15 */
    popq %r14                             /* restore r14 */
    popq %r13                             /* restore r13 */
    popq %r12                             /* restore r12 */

    ret                                   /* return */

    .globl square
square:
    movq %rdi, %rax        /* move x into rax */
    imulq %rdi, %rax       /* multi rax by x, result in rax */
    ret                    /* Return*/


    .globl square_dist
square_dist:
    pushq %rbp             /* save */
    movq %rsp, %rbp        /* set base */

    /* Calculate x1 - x2 */
    movq %rdi, %rax        /* bring x1 into rax */
    subq %rdx, %rax        /* rax = x1 - x2 */
    movq %rax, %rdi        /* arg for square */
    call square            /* call square(x1 - x2) */
    movq %rax, %rbx        /* store square(x1 - x2) in rbx */

    /* Calculate y1 - y2 */
    movq %rsi, %rax        /* bring y1 into rax */
    subq %rcx, %rax        /* rax = y1 - y2 */
    movq %rax, %rdi        /* arg for square */
    call square            /* call square(y1 - y2) */
    /* rax now contains square(y1 - y2) */

    addq %rbx, %rax        /* add square(x1 - x2) to square(y1 - y2) */

    popq %rbp              /* restore base */
    ret                    /* Return */


/***********************************************************************
   Public API functions
 ***********************************************************************/

/*
 * Draw a pixel.
 *
 * Parameters:
 *   %rdi     - pointer to struct Image
 *   %esi     - x coordinate (pixel column)
 *   %edx     - y coordinate (pixel row)
 *   %ecx     - uint32_t color value
 */
    .globl draw_pixel
draw_pixel:

  pushq %rbp                          /* Save base pointer, set it to stack pointer */
  movq %rsp, %rbp                     /* Stack frame setup */

  pushq %r12                          /* Save used registers */
  pushq %r13
  pushq %r14

  movq %rdi, %r12                     /* %rdi contains img pointer, move to %r12 */
  movl %edx, %r14d                    /* %edx contains y coordinate, move to %r14d */
  movl %esi, %r13d                    /* %esi contains x coordinate, move to %r13d */

  /* Check bounds */
  movq %r12, %rdi                     /* Prepare arguments for in_bounds */
  movl %r14d, %edx                    /* y coordinate */
  movl %r13d, %esi                    /* x coordinate */
  call in_bounds                      /* Call in_bounds function */
  testl %eax, %eax                    /* test if in_bounds returned true (non-zero) */
  jz .Lstop_draw_pixel                /* If not in bounds then jump to end */

  /* Compute index */
  movl %r14d, %edx                    /* y coordinate */
  movl %r13d, %esi                    /* x coordinate */
  movq %r12, %rdi                     /* prep arguments for compute_index */
  call compute_index                  /* Call compute_index function */
  /* %rax now contains the computed index */

  /* Set pixel color */
  movq %r12, %rdi                     /* 1st arg for set_pixel which is img pointer */
  movq %rax, %rsi                     /* 2nd arg for set_pixel which is index */
  movl %ecx, %edx                     /* 3rd arg for set_pixel which is color */
  call set_pixel                      /* Call set_pixel function */

.Lstop_draw_pixel:
  popq %r14                           /* Restore registers */
  popq %r13
  popq %r12

  popq %rbp                           /* Restore base pointer */
  ret                                 /* Return */


/*
 * Draw a rectangle.
 * The rectangle has rect->x,rect->y as its upper left corner,
 * is rect->width pixels wide, and rect->height pixels high.
 *
 * Parameters:
 *   %rdi     - pointer to struct Image
 *   %rsi     - pointer to struct Rect
 *   %edx     - uint32_t color value
 */
    .globl draw_rect          
draw_rect:
    /* save registers and set up stack frame */
    pushq %r12            /* save r12 */
    pushq %r13            /* save r13 */
    pushq %r14            /* save r14 */
    pushq %r15            /* save r15 */
    pushq %rbx            /* save rbx */
    pushq %rbp            /* save rbp */
    movq %rsp, %rbp       /* set base pointer */
    subq $8, %rsp         /* allocate stack space */

    /* store function arguments */
    movq %rdi, %r12       /* image pointer to r12 */
    movq %rsi, %r13       /* rect pointer to r13 */
    movl %edx, %r14d      /* color to r14d */

    /* initialize loop variables */
    movl RECT_Y_OFFSET(%r13), %r15d /* load rect->y to r15d */
    movl RECT_HEIGHT_OFFSET(%r13), %ebx /* load rect->height to ebx */
    addl %r15d, %ebx      /* calculate y_end, store in ebx */

.LheightLoop:
    cmp %ebx, %r15d       /* compare y with y_end */
    jge .Lend_draw_rec    /* exit loop if y >= y_end */
    movl RECT_X_OFFSET(%r13), %r10d /* load rect->x to r10d */
    movl %r10d, -8(%rbp)  /* store current x */
    movl RECT_WIDTH_OFFSET(%r13), %r11d /* load rect->width to r11d */
    addl %r11d, %r10d     /* calculate x_end, store in r10d */
    movl %r10d, -4(%rbp)  /* store x_end */

    /* reset x for width loop */
    movl RECT_X_OFFSET(%r13), %r11d /* reset current x to rect->x */

.LwidthLoop:
    movl -8(%rbp), %r11d  /* load current x */
    cmp -4(%rbp), %r11d   /* compare x with x_end */
    jge .LendWidthLoop    /* exit loop if x >= x_end */
    
    /* in bounds check */
    movq %r12, %rdi       /* set image pointer for in_bounds */
    movl %r11d, %esi      /* set x for in_bounds */
    movl %r15d, %edx      /* set y for in_bounds */
    call in_bounds        /* call in_bounds function */
    testl %eax, %eax      /* test in_bounds result */
    jz .LpixelSkip        /* skip if out of bounds */

    /* compute index */
    movq %r12, %rdi       /* set image pointer for compute_index */
    movl %r11d, %esi      /* set x for compute_index */
    movl %r15d, %edx      /* set y for compute_index */
    call compute_index    /* call compute_index function */

    /* set pixel */
    movq %r12, %rdi       /* set image pointer for set_pixel */
    movq %rax, %rsi       /* set pixel index for set_pixel */
    movl %r14d, %edx      /* set color for set_pixel */
    call set_pixel        /* call set_pixel function */

.LpixelSkip:
    addl $1, -8(%rbp)     /* increment current x */
    jmp .LwidthLoop       /* continue width loop */

.LendWidthLoop:
    addl $1, %r15d        /* increment current y */
    jmp .LheightLoop      /* continue height loop */

.Lend_draw_rec:
    /* restore stack and registers */
    addq $8, %rsp         /* deallocate stack space */
    popq %rbp             /* restore base pointer */
    popq %rbx             /* restore rbx */
    popq %r15             /* restore r15 */
    popq %r14             /* restore r14 */
    popq %r13             /* restore r13 */
    popq %r12             /* restore r12 */
    ret                   /* return */



/*
 * Draw a circle.
 * The circle has x,y as its center and has r as its radius.
 *
 * Parameters:
 *   %rdi     - pointer to struct Image
 *   %esi     - x coordinate of circle's center
 *   %edx     - y coordinate of circle's center
 *   %ecx     - radius of circle
 *   %r8d     - uint32_t color value
 */
	.globl draw_circle
.globl draw_circle
draw_circle:
    pushq %rbp                        /* save base pointer */
    movq %rsp, %rbp                   /* set up stack frame */
    pushq %r12                        /* save registers */
    pushq %r13
    pushq %r14
    pushq %r15
    pushq %rbx

    movq %rdi, %r12                   /* img pointer to r12 */
    movl %esi, %r13d                  /* x center to r13d */
    movl %edx, %r14d                  /* y center to r14d */
    movl %ecx, %r15d                  /* radius to r15d */
    movl %r8d, %ebx                   /* color to ebx */

    /* calculate starting y (i = y - r) */
    movl %r14d, %eax
    subl %r15d, %eax
    movl %eax, %r8d                   /* store start y in r8d */

.y_loop:                              /* start of y loop */
    /* calculate ending y (i <= y + r) */
    movl %r14d, %eax
    addl %r15d, %eax
    cmpl %r8d, %eax
    jg .end_y_loop                    /* end y loop if i > y + r */

    /* calculate starting x (j = x - r) */
    movl %r13d, %eax
    subl %r15d, %eax
    movl %eax, %r9d                   /* store start x in r9d */

.x_loop:                              /* start of x loop */
    /* calculate ending x (j <= x + r) */
    movl %r13d, %eax
    addl %r15d, %eax
    cmpl %r9d, %eax
    jg .end_x_loop                    /* end x loop if j > x + r */

    /* call square_dist(x, y, j, i) */
    movl %r13d, %edi                  /* x center */
    movl %r14d, %esi                  /* y center */
    movl %r9d, %edx                   /* current x (j) */
    movl %r8d, %ecx                   /* current y (i) */
    call square_dist
    /* compare result with r^2 */
    imull %r15d, %r15d                /* r * r */
    cmpl %eax, %r15d
    jg .pixel_outside                 /* skip if result > r^2 */

    /* pixel is inside circle, call draw_pixel(img, j, i, color) */
    movq %r12, %rdi                   /* img pointer */
    movl %r9d, %esi                   /* current x (j) */
    movl %r8d, %edx                   /* current y (i) */
    movl %ebx, %ecx                   /* color */
    call draw_pixel

.pixel_outside:
    incl %r9d                         /* increment x */
    jmp .x_loop                       /* jump back to start of x loop */

.end_x_loop:
    incl %r8d                         /* increment y */
    jmp .y_loop                       /* jump back to start of y loop */

.end_y_loop:
    popq %rbx                         /* restore rbx */
    popq %r15                         /* restore r15 */
    popq %r14                         /* restore r14 */
    popq %r13                         /* restore r13 */
    popq %r12                         /* restore r12 */
    popq %rbp                         /* restore base pointer */
    ret                               /* return from function */
/*
 * Draw a tile by copying all pixels in the region
 * enclosed by the tile parameter in the tilemap image
 * to the specified x/y coordinates of the destination image.
 * No blending of the tile pixel colors with the background
 * colors should be done.
 *
 * Parameters:
 *   %rdi - pointer to Image (dest image)
 *   %esi - x coordinate of location where tile should be copied
 *   %edx - y coordinate of location where tile should be copied
 *   %rcx - pointer to Image (the tilemap)
 *   %r8  - pointer to Rect (the tile)
 */
	.globl draw_tile
draw_tile:
	/* TODO: implement */
	ret

/*
 * Draw a sprite by copying all pixels in the region
 * enclosed by the sprite parameter in the spritemap image
 * to the specified x/y coordinates of the destination image.
 * The alpha values of the sprite pixels should be used to
 * blend the sprite pixel colors with the background
 * pixel colors.
 *
 * Parameters:
 *   %rdi - pointer to Image (dest image)
 *   %esi - x coordinate of location where sprite should be copied
 *   %edx - y coordinate of location where sprite should be copied
 *   %rcx - pointer to Image (the spritemap)
 *   %r8  - pointer to Rect (the sprite)
 */
	.globl draw_sprite
.globl draw_sprite
draw_sprite:
    pushq %rbp                          /* preserve base pointer */
    movq %rsp, %rbp                     /* set up stack frame */
    subq $64, %rsp                      /* allocate stack space for locals */

    movq %rdi, -8(%rbp)                 /* store img pointer */
    movl %esi, -12(%rbp)                /* store x coord */
    movl %edx, -16(%rbp)                /* store y coord */
    movq %rcx, -24(%rbp)                /* store spritemap pointer */
    movq %r8, -32(%rbp)                 /* store sprite pointer */

    movl $0, -36(%rbp)                  /* y_sprite counter init */
    movl RECT_HEIGHT_OFFSET(%r8), %eax  /* load sprite height */
    movl %eax, -40(%rbp)                /* store height in stack */

.Lheight_loop:
    movl -36(%rbp), %eax                /* load y_sprite counter */
    movl -40(%rbp), %edx                /* load stored height */
    cmp %edx, %eax                      /* compare counter with height */
    jge .Lheight_loop_end              /* exit loop if counter >= height */

    movl $0, -44(%rbp)                  /* x_sprite counter init */
    movl RECT_WIDTH_OFFSET(%r8), %eax   /* load sprite width */
    movl %eax, -48(%rbp)                /* store width in stack */

.Lwidth_loop:
    movl -44(%rbp), %eax                /* load x_sprite counter */
    movl -48(%rbp), %edx                /* load stored width */
    cmp %edx, %eax                      /* compare counter with width */
    jge .Lwidth_loop_end               /* exit loop if counter >= width */

    /* in bounds check for img */
    movl -12(%rbp), %edi                /* load x coord */
    addl %eax, %edi                     /* add x_sprite counter */
    movl -16(%rbp), %esi                /* load y coord */
    addl -36(%rbp), %esi                /* add y_sprite counter */
    movq -8(%rbp), %rdi                 /* load img pointer */
    call in_bounds                      /* check bounds */
    testl %eax, %eax
    je .Lskip_pixel                     /* skip if out of bounds */

    /* compute source index and get color */
    movl -44(%rbp), %edx                /* load x_sprite counter */
    addl RECT_X_OFFSET(%r8), %edx       /* add sprite.x offset */
    movl -36(%rbp), %ecx                /* load y_sprite counter */
    addl RECT_Y_OFFSET(%r8), %ecx       /* add sprite.y offset */
    movq -24(%rbp), %rdi                /* load spritemap pointer */
    call compute_index                  /* compute source index */
    movq -24(%rbp), %rdi                /* reload spritemap pointer */
    movl (%rdi, %rax, 4), %ecx          /* get source pixel color */

    /* set pixel in destination image using set_pixel */
    movl -12(%rbp), %esi                /* load x coord */
    addl -44(%rbp), %esi                /* add x_sprite counter */
    movl -16(%rbp), %edx                /* load y coord */
    addl -36(%rbp), %edx                /* add y_sprite counter */
    movq -8(%rbp), %rdi                 /* load img pointer */
    movl %ecx, %eax                     /* move sprite color to eax */
    call set_pixel                      /* set pixel in img */

.Lskip_pixel:
    addl $1, -44(%rbp)                  /* increment x_sprite counter */
    jmp .Lwidth_loop                    /* continue width loop */

.Lwidth_loop_end:
    addl $1, -36(%rbp)                  /* increment y_sprite counter */
    jmp .Lheight_loop                   /* continue height loop */

.Lheight_loop_end:
    addq $64, %rsp                      /* deallocate stack space */
    popq %rbp                           /* restore base pointer */
    ret                                 /* return from function */

/*
vim:ft=gas:
*/
