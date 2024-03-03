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

    movl IMAGE_WIDTH_OFFSET(%rdi), %r12d    /* Load img->width */
    movl IMAGE_HEIGHT_OFFSET(%rdi), %r13d   /* Load img->height */
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
    pushq %rbx             /* save */

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

    popq %rbx              /* restore base */
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
    /* Save registers and set up stack frame */
    pushq %r12            /* save previous r12 */
    pushq %r13            /* save previous r13 */
    pushq %r14            /* save previous r14 */
    pushq %r15            /* save previous r15 */  
    pushq %rbx            /* save previous rbx */
    pushq %rbp            /* save previous rbp */
    movq %rsp, %rbp       /* set base pointer */
    subq $16, %rsp        /* allocate stack space for color and alignment */

    /* Store function arguments */
    movl %edx, %ebp       /* store color in ebp */
    movq %rsi, %r12       /* store rect pointer in r12 */
    movq %rdi, %r13       /* store image pointer in r13 */

    /* Initialize loop variables */
    movl RECT_Y_OFFSET(%r12), %ebx /* load rect->y into ebx */
    movl RECT_HEIGHT_OFFSET(%r12), %r14d /* load rect->height into r14d */
    addl %ebx, %r14d      /* calculate y_end, store in r14d */

    movl RECT_X_OFFSET(%r13), %r10d /* load rect->x into r10d */
    addl RECT_WIDTH_OFFSET(%r13), %r10d /* calculate rect->x + rect->width */
    movl %r10d, %r15d                   /* move x_end to r15d */


.LHeightRectLoop:
    cmp %r14d, %ebx       /* compare y with y_end */
    jge .EndDrawRectangle /* exit loop if y >= y_end */

    movl RECT_X_OFFSET(%r12), %r10d /* move rect->x to r10 */
    movl %r10d, -4(%rbp)  /* reset x to rect->x */

.LWidthRectLoop:
    cmp %r15d, -4(%rbp)  /* compare x with x_end */
    jge .WidthLoopEnd     /* exit loop if x >= x_end */
    
    /* In bounds check registers */
    movq %r13, %rdi       /* set image pointer from r13 for in_bounds */
    movl -4(%rbp), %esi      /* set x for in_bounds */
    movl %ebx, %edx      /* set y for in_bounds */
    call in_bounds        /* call in_bounds function */
    test %eax, %eax         /* test in_bounds result */
    jz .PixelSkip         /* skip if out of bounds */

    /* Compute index with registers */
    movq %r13, %rdi       /* set image pointer from r13 for compute_index */
    movl -4(%rbp), %esi      /* set x for compute_index */
    movl %ebx, %edx      /* set y for compute_index */
    call compute_index    /* call compute_index function */

    /* Set pixel with color from stack */
    movq %r13, %rdi       /* set image pointer from r13 for set_pixel */
    movq %rax, %rsi       /* set pixel index for set_pixel */
    movl %ebp, %edx   /* set color from stack for set_pixel */
    call set_pixel        /* call set_pixel function */

.PixelSkip:
    addl $1, -4(%rbp)     /* increment current x on stack */
    jmp .LWidthRectLoop        /* continue width loop */

.WidthLoopEnd:
    addl $1, %ebx        /* increment current y */
    jmp .LHeightRectLoop       /* continue height loop */

.EndDrawRectangle:
    /* Restore stack and registers */
    addq $16, %rsp        /* deallocate stack space */
    popq %rbp             /* restore previous rbp */
    popq %rbx             /* restore previous rbx */
    popq %r15             /* restore previous r15 */
    popq %r14             /* restore previous r14 */
    popq %r13             /* restore previous r13 */
    popq %r12             /* restore previous r12 */
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
draw_circle:
    pushq %rbp                        /* Save %rbp */
    movq %rsp, %rbp                   /* Set up %rbp */
    subq $24, %rsp                    /* Allocate local vars */
    pushq %r12                        /* Save %r12 */
    pushq %r13                        /* Save %r13 */
    pushq %r14                        /* Save %r14 */
    pushq %r15                        /* Save %r15 */
    pushq %rbx                        /* Save %rbx */

    movq %rdi, %r12                   /* img -> %r12 */
    movl %esi, %r13d                  /* x center -> %r13d */
    movl %edx, %r14d                  /* y center -> %r14d */
    movl %ecx, %r15d                  /* radius -> %r15d */
    movl %r8d, %ebx                   /* color -> %ebx */

    movl %r15d, %eax                  /* radius to %eax */
    imull %eax, %eax                  /* radius^2 */
    movl %eax, -24(%rbp)              /* Store radius^2 */

    movl %r14d, %eax                  /* y center to %eax */
    subl %r15d, %eax                  /* y - radius */
    movl %eax, -8(%rbp)               /* Store start y */

.y_loop:
    movl %r14d, %eax                  /* y center to %eax */
    addl %r15d, %eax                  /* y + radius */
    movl -8(%rbp), %ecx               /* Load current y */
    cmpl %eax, %ecx                   /* Compare y + radius, y */
    jg .end_y_loop                    /* Exit if y > y + radius */

    movl %r13d, %eax                  /* x center to %eax */
    subl %r15d, %eax                  /* x - radius */
    movl %eax, -16(%rbp)              /* Store start x */

.x_loop:
    movl %r13d, %eax                  /* x center to %eax */
    addl %r15d, %eax                  /* x + radius */
    movl -16(%rbp), %ecx              /* Load current x */
    cmpl %eax, %ecx                   /* Compare x + radius, x */
    jg .end_x_loop                    /* Exit if x > x + radius */

    movl %r13d, %edi                  /* x center to %edi */
    movl %r14d, %esi                  /* y center to %esi */
    movl -16(%rbp), %edx              /* current x to %edx */
    movl -8(%rbp), %ecx               /* current y to %ecx */
    call square_dist                  /* Call square_dist */

    movl -24(%rbp), %edx              /* Load radius^2 */
    cmpl %edx, %eax                   /* Compare radius^2, dist */
    jle .pixel_inside                 /* Inside circle */

.pixel_outside:
    movl -16(%rbp), %eax              /* Load current x */
    addl $1, %eax                         /* Increment x */
    movl %eax, -16(%rbp)              /* Store new x */
    jmp .x_loop                       /* Next x */

.pixel_inside:
    movq %r12, %rdi                   /* img to %rdi */
    movl -16(%rbp), %esi              /* current x to %esi */
    movl -8(%rbp), %edx               /* current y to %edx */
    movl %ebx, %ecx                   /* color to %ecx */
    call draw_pixel                   /* Draw pixel */
    jmp .pixel_outside                /* Next pixel */

.end_x_loop:
    movl -8(%rbp), %eax               /* Load current y */
    addl $1, %eax                         /* Increment y */
    movl %eax, -8(%rbp)               /* Store new y */
    jmp .y_loop                       /* Next y */

.end_y_loop:
    addq $24, %rsp                    /* Deallocate local vars */
    popq %rbx                         /* Restore %rbx */
    popq %r15                         /* Restore %r15 */
    popq %r14                         /* Restore %r14 */
    popq %r13                         /* Restore %r13 */
    popq %r12                         /* Restore %r12 */
    popq %rbp                         /* Restore %rbp */
    ret                               /* Return */

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
    /* couldnt complete */
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
draw_sprite:
    /* code was not functioning */
    ret

/*
vim:ft=gas:
*/ 