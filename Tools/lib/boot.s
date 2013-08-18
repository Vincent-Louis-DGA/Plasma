##################################################################
# TITLE: Boot Up Code
# AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
#	Modified by Adrian Jongenelen
# DATE CREATED: 1/12/02
# FILENAME: boot.asm
# PROJECT: Plasma CPU core
# COPYRIGHT: Software placed into the public domain by the author.
#    Software 'as is' without warranty.  Author liable for nothing.
# DESCRIPTION:
#   Jumps and links to main(), nothing else.
#	Intent is that this code is called externally,
#	eg, by a bootloader, or some other code that has linked boot_os.s
##################################################################
   #Reserve 512 bytes for stack
   #.comm InitStack, 512

   .text
   .align 2
   .global entry
   .ent	entry
entry:
   .set noreorder

   jal   main
   nop
$L1:
   j $L1

   .end entry

###################################################
   .global OS_AsmInterruptEnable
   .ent OS_AsmInterruptEnable
OS_AsmInterruptEnable:
   .set noreorder
   mfc0  $2, $12
   jr    $31
   mtc0  $4, $12            #STATUS=1; enable interrupts
   #nop
   .set reorder
   .end OS_AsmInterruptEnable

###################################################
   .global   setjmp
   .ent     setjmp
setjmp:
   .set noreorder
   sw    $16, 0($4)   #s0
   sw    $17, 4($4)   #s1
   sw    $18, 8($4)   #s2
   sw    $19, 12($4)  #s3
   sw    $20, 16($4)  #s4
   sw    $21, 20($4)  #s5
   sw    $22, 24($4)  #s6
   sw    $23, 28($4)  #s7
   sw    $30, 32($4)  #s8
   sw    $28, 36($4)  #gp
   sw    $29, 40($4)  #sp
   sw    $31, 44($4)  #lr
   jr    $31
   ori   $2,  $0, 0

   .set reorder
   .end setjmp


###################################################
   .global   longjmp
   .ent     longjmp
longjmp:
   .set noreorder
   lw    $16, 0($4)   #s0
   lw    $17, 4($4)   #s1
   lw    $18, 8($4)   #s2
   lw    $19, 12($4)  #s3
   lw    $20, 16($4)  #s4
   lw    $21, 20($4)  #s5
   lw    $22, 24($4)  #s6
   lw    $23, 28($4)  #s7
   lw    $30, 32($4)  #s8
   lw    $28, 36($4)  #gp
   lw    $29, 40($4)  #sp
   lw    $31, 44($4)  #lr
   jr    $31
   ori   $2,  $5, 0

   .set reorder
   .end longjmp
