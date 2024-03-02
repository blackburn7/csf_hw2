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
    /* Save registers and set up stack frame */
    pushq %r12            /* save previous r12 */
    pushq %r13            /* save previous r13 */
    pushq %r14            /* save previous r14 */
    pushq %rbx            /* save previous rbx */
    pushq %rbp            /* save previous rbp */
    movq %rsp, %rbp       /* set base pointer */
    subq $16, %rsp        /* allocate stack space for color and alignment */

    /* Store function arguments with switched roles */
    movq %rsi, %r12       /* store rect pointer in r12 */
    movq %rdi, %r13       /* store image pointer in r13 */
    movl %edx, -4(%rbp)   /* store color on stack */

    /* Initialize loop variables with switched registers */
    movl RECT_Y_OFFSET(%r12), %r14d /* load rect->y into r14d */
    movl RECT_HEIGHT_OFFSET(%r12), %ebx /* load rect->height into ebx */
    addl %r14d, %ebx      /* calculate y_end, store in ebx */

.HeightLoop:
    cmp %ebx, %r14d       /* compare y with y_end */
    jge .EndDrawRectangle /* exit loop if y >= y_end */
    movl RECT_X_OFFSET(%r12), %r10d /* load rect->x into r10d */
    movl %r10d, -8(%rbp)  /* store current x on stack */
    movl RECT_WIDTH_OFFSET(%r12), %r11d /* load rect->width into r11d */
    addl %r11d, %r10d     /* calculate x_end, store in r10d */
    movl %r10d, -12(%rbp) /* store x_end on stack */

    /* Reset x for width loop */
    movl RECT_X_OFFSET(%r12), %r11d /* reset current x to rect->x */

.WidthLoop:
    movl -8(%rbp), %r11d  /* load current x from stack */
    cmp -12(%rbp), %r11d  /* compare x with x_end */
    jge .WidthLoopEnd     /* exit loop if x >= x_end */
    
    /* In bounds check with switched registers */
    movq %r13, %rdi       /* set image pointer from r13 for in_bounds */
    movl %r11d, %esi      /* set x for in_bounds */
    movl %r14d, %edx      /* set y for in_bounds */
    call in_bounds        /* call in_bounds function */
    testl %eax, %eax      /* test in_bounds result */
    jz .PixelSkip         /* skip if out of bounds */

    /* Compute index with switched registers */
    movq %r13, %rdi       /* set image pointer from r13 for compute_index */
    movl %r11d, %esi      /* set x for compute_index */
    movl %r14d, %edx      /* set y for compute_index */
    call compute_index    /* call compute_index function */

    /* Set pixel with color from stack */
    movq %r13, %rdi       /* set image pointer from r13 for set_pixel */
    movq %rax, %rsi       /* set pixel index for set_pixel */
    movl -4(%rbp), %edx   /* set color from stack for set_pixel */
    call set_pixel        /* call set_pixel function */

.PixelSkip:
    addl $1, -8(%rbp)     /* increment current x on stack */
    jmp .WidthLoop        /* continue width loop */

.WidthLoopEnd:
    addl $1, %r14d        /* increment current y */
    jmp .HeightLoop       /* continue height loop */

.EndDrawRectangle:
    /* Restore stack and registers */
    addq $16, %rsp        /* deallocate stack space */
    popq %rbp             /* restore previous rbp */
    popq %rbx             /* restore previous rbx */
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
.globl draw_circle
draw_circle:
    pushq %rbp                        /* Save %rbp */
    movq %rsp, %rbp                   /* Set up %rbp */
    subq $26, %rsp                    /* Allocate local vars */
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
	draw_tile:
    pushq %rbp                          /* save bp */
    movq %rsp, %rbp                     /* setup frame */
    subq $64, %rsp                      /* alloc space */

    movq %rdi, -8(%rbp)                 /* store img ptr */
    movl %esi, -12(%rbp)                /* store x coord */
    movl %edx, -16(%rbp)                /* store y coord */
    movq %rcx, -24(%rbp)                /* store tilemap ptr */
    movq %r8, -32(%rbp)                 /* store tile ptr */

    /* bounds check */
    movl RECT_WIDTH_OFFSET(%r8), %eax   /* tile wd */
    addl RECT_X_OFFSET(%r8), %eax       /* add tile x */
    cmp IMAGE_WIDTH_OFFSET(%rcx), %eax  /* cmp with tilemap wd */
    jg .Lout_of_bounds_tile                  /* if out, jmp */

    movl RECT_HEIGHT_OFFSET(%r8), %eax  /* tile ht */
    addl RECT_Y_OFFSET(%r8), %eax       /* add tile y */
    cmp IMAGE_HEIGHT_OFFSET(%rcx), %eax /* cmp with tilemap ht */
    jg .Lout_of_bounds_tile                  /* if out, jmp */

    /* init loop ctrs */
    movl $0, -36(%rbp)                  /* y ctr */
.Lheight_loop:
    movl -36(%rbp), %eax                /* load y ctr */
    movl RECT_HEIGHT_OFFSET(%r8), %edx  /* tile ht */
    cmp %edx, %eax                      /* cmp y < ht */
    jge .Lheight_loop_end              /* if y >= ht, end */

    movl $0, -40(%rbp)                  /* x ctr */
.Lwidth_loop:
    movl -40(%rbp), %eax                /* load x ctr */
    movl RECT_WIDTH_OFFSET(%r8), %edx   /* tile wd */
    cmp %edx, %eax                      /* cmp x < wd */
    jge .Lwidth_loop_end               /* if x >= wd, end */

    /* in bounds check */
    movl -12(%rbp), %edi                /* x pos */
    addl %eax, %edi                     /* x + x ctr */
    movl -16(%rbp), %esi                /* y pos */
    addl -36(%rbp), %esi                /* y + y ctr */
    movq -8(%rbp), %rdi                 /* img ptr */
    call in_bounds                      /* check bounds */
    testl %eax, %eax
    je .Lskip_pixel                     /* if out, skip */

    /* compute src idx */
    movl RECT_X_OFFSET(%r8), %esi       /* tile x */
    addl -40(%rbp), %esi                /* tile x + x ctr */
    movl RECT_Y_OFFSET(%r8), %edx       /* tile y */
    addl -36(%rbp), %edx                /* tile y + y ctr */
    movq -24(%rbp), %rdi                /* tilemap ptr */
    call compute_index                  /* compute src idx */

    /* get color and set pixel */
    movq -24(%rbp), %rdi                /* tilemap ptr */
    movl (%rdi, %rax, 4), %eax          /* get color */
    movl -12(%rbp), %esi                /* x pos */
    addl -40(%rbp), %esi                /* x + x ctr */
    movl -16(%rbp), %edx                /* y pos */
    addl -36(%rbp), %edx                /* y + y ctr */
    movq -8(%rbp), %rdi                 /* img ptr */
    call set_pixel                      /* set pixel */

.Lskip_pixel:
    addl $1, -40(%rbp)                  /* inc x ctr */
    jmp .Lwidth_loop                    /* next x */

.Lwidth_loop_end:
    addl $1, -36(%rbp)                  /* inc y ctr */
    jmp .Lheight_loop                   /* next y */

.Lheight_loop_end:
.Lout_of_bounds_tile:
    addq $64, %rsp                      /* dealloc space */
    popq %rbp                           /* restore bp */
    ret                                 /* return */

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
    pushq %rbp             /* Preserve base pointer */
    movq %rsp, %rbp        /* Set base pointer */


    movq %rdi, %r12      /* save image pointer */
    movl %esi, %r13d     /* save x coord */
    movl %edx, %r14d     /* save y coord */
    movq %rcx, %r15      /* save spritemap pointer */
    movq %r8, %rbx       /* save sprite pointer */

    
    movl RECT_WIDTH_OFFSET(%rbx), %eax  /* Load sprite->width into eax */
    addl RECT_X_OFFSET(%rbx), %eax      /* Add sprite->x */
    cmp IMAGE_WIDTH_OFFSET(%r15), %eax  /* Compare that to spritemap->width */
    jg .Stile_out_of_bounds             /* If it's greater, out of bounds */

    movl RECT_HEIGHT_OFFSET(%rbx), %eax /* Load sprite->height into eax */
    addl RECT_Y_OFFSET(%rbx), %eax      /* Add sprite->y */
    cmp IMAGE_HEIGHT_OFFSET(%r15), %eax /* Compare that to spritemap->height  */
    jg .Stile_out_of_bounds             /* If it's greater, out of bounds */

    
    movl RECT_HEIGHT_OFFSET(%rbx), %ecx /* this is the height of the sprite */
    movl $0, %r8d                    /* height loop counter (i) */

Sheight_loop:
    cmp %ecx, %r8d                     /* compares i to sprite->height */
    jge .Lheight_loop_end              /* if i >= sprite->height, exit loop */

    movl RECT_WIDTH_OFFSET(%rbx), %edx  /* this is the width of the sprite */
    movl $0, %r9d                      /* width loop counter (j) (inner loop) */

Swidth_loop:
    cmp %edx , %r9d                      # Compare j < sprite->width
    jge .Swidth_loop_end                # If j >= sprite->width, exit loop


    cmp %edx , %r9d                     /* compares j to sprite->width */
    jge .Lwidth_loop_end                /* if j >= sprite->width, exit loop */


    movl %r13d, %esi                    /* Load x into %esi */
    addl %r9d, %esi                     /* Add j to %esi (it is now x + j) */
    movl %r14d, %edx                    /* Load y into %edx */
    addl %r8d, %edx                     /* Add i to %esi (it is now y + i) */

    movq %r12, %rdi                     /* moves img pointer to rdi */
    call in_bounds                      /* calls in_bounds */
    test %eax, %eax                     /* tests result of in_bounds */
    je .Swidth_loop_end                 /* if result is false, then end loop here */

    # Compute index_img
    call compute_index                  /* calls computer_index, registers already in the right place */
    movq %rax, %r10                     /* moves result (index_img) to r10 */

    # Compute index_tilemap
    movl RECT_X_OFFSET(%rbx), %esi      /* Load sprite->x into %esi */
    addl %r9d, %esi                     /* Add j to %esi (it is now sprite->x  + j) */
    movl RECT_Y_OFFSET(%rbx), %edx      /* Load sprite->y into %edx */
    addl %r8d, %edx                     /* Add i to %esi (it is now sprite->y  + i) */
    movq %r15, %rdi                     /* aligns spritemap pointer for computer_index */
    call compute_index                  /* call compute_index */
    movq %rax, %r11                     /* moves result (index_spritemap) to r11 */

    movq IMAGE_DATA_OFFSET(%r15), %rax   /* moves address of the spritemap data to rax */
    movl (%rax, %r11, 4), %edi  /* puts the data at index_spritemap into edi */

    movq IMAGE_DATA_OFFSET(%r12), %r11 /* moves address of the image data to rax */
    movl (%r11, %r10, 4), %esi /* puts the data at index_img into esi */

    call blend_colors /* calls blend_colors with edi and esi */

    movl %eax, (%r11, %r10, 4) /* moves result into image data at index_img */

    inc %r9d                            /* increment j for the next iteration */
    movl RECT_WIDTH_OFFSET(%rbx), %edx  /* makes sure that the upper bound on the loop is the same */
    jmp Swidth_loop                     /* keep iterating inner loop */

.Swidth_loop_end:
    inc %r8d                            /* increment j for the next iteration */
    jmp Sheight_loop                     /* keep iterating outer loop */

.Sheight_loop_end:
.Stile_out_of_bounds:
    popq %rbp
    ret

/*
vim:ft=gas:
*/
