/*
 * Assembly-language implementations of the drawing functions
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

140737488343744 - rdi

140737488343752 - r14

140737471578351 - img 

140737471578359 - img.data



 */ 


.globl set_pixel
set_pixel:

    pushq %r12                          /* save r12 */
    pushq %r14                          /* save r14 */
    subq $8, %rsp                      /* allocate stack space */
    movl %edx, %r12d                    /* move fg color to r12d */
    leaq IMAGE_DATA_OFFSET(%rdi), %r14  /* load image data address */
    leaq (%r14, %rsi, 4), %r14          /* calculate pixel address */

    /* blend color */
    movl %r12d, %edi                    /* set fg color for blend_colors */
    movl (%r14), %esi                   /* load bg color */
    call blend_colors                   /* blend colors */
    movl %eax, (%r14)                   /* store blended color */

    movq $0, %rax                       /* clear rax */
    addq $8, %rsp                      /* deallocate stack space */
    popq %r14                           /* restore r14 */
    popq %r12                           /* restore r12 */

    ret                                 /* return */




.globl get_r
get_r:
    movq %rdi, %rax               /* Copy color into %rax */
    shrq $24, %rax                /* Shift right by 24 bits to isolate the red component */
    andq $0xFF, %rax              /* Mask with 0xFF to get the lower 8 bits */
    ret                           /* Return the red component */

.globl get_g
get_g:
    movq %rdi, %rax               /* Copy color into %rax */
    shrq $16, %rax                /* Shift right by 16 bits to isolate the green component */
    andq $0xFF, %rax              /* Mask with 0xFF */
    ret                           /* Return the green component */

.globl get_b
get_b:
    movq %rdi, %rax               /* Copy color into %rax */
    shrq $8, %rax                 /* Shift right by 8 bits to isolate the blue component */
    andq $0xFF, %rax              /* Mask with 0xFF */
    ret                           /* Return the blue component */

.globl get_a
get_a:
    movq %rdi, %rax               /* Copy color into %rax */
    andq $0xFF, %rax              /* mask with 0xFF to get the a component */
    ret                           /* Return the alpha component */

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

.globl in_bounds
in_bounds:

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
    ret

.globl compute_index
compute_index:
    pushq %rbp
    movq %rsp, %rbp

    movl IMAGE_WIDTH_OFFSET(%rdi), %eax    /* Load img->width */
    imulq %rdx, %rax                       /* img->width * y */
    addq %rsi, %rax                        /* Add x */

    popq %rbp
    ret


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

    ret    

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
	/* TODO: implement */
	ret

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
	/* TODO: implement */
	ret

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
draw_sprite:
	/* TODO: implement */
	ret

/*
vim:ft=gas:
*/
