#PURPOSE: This program converts an input file to an output file with all letters converted
# to uppercase.

.section .data

# CONSTANTS

#sys call num
.equ SYS_OPEN, 5
.equ SYS_WRITE, 4
.equ SYS_READ, 3
.equ SYS_CLOSE,6
.equ SYS_EXIT, 1

.equ O_RDONLY, 0
.equ O_CREAT_WRONGLY_TRUNC, 03101

.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

.equ LINUX_SYSCALL, 0x80

.equ END_OF_FILE, 0

.equ NUMBER_ARGUMENTS, 2

.section .bss
.equ BUFFER_SIZE, 500
.lcomm BUFFER_DATA, BUFFER_SIZE

.section .text

# STACK POS

.equ ST_SIZE_RESERVE, 8
.equ ST_FD_IN, -4
.equ ST_FD_OUT, -8
.equ ST_ARGC, 0
.equ ST_ARGV_0, 4 # Name of program
.equ ST_ARGV_1, 8 # Input file name
.equ ST_ARGV_2, 12 # Output file name

.globl _start

_start:

# Save stack pointer
movl %esp, %ebp

# Alloc space for file desc
subl $ST_SIZE_RESERVE, %esp

open_files:

open_fd_in:

 # OPEN syscall
 movl $SYS_OPEN , %eax

 # File name into %ebx
 movl ST_ARGV_1(%ebp), %ebx

# READ-ONLY Flag
 movl $O_RDONLY, %ecx

# MODE
 movl $0666 , %edx # MAGIC Number

# Call Linux
 int $LINUX_SYSCALL

store_fd_in:
 # Save the given file descriptor
 movl %eax, ST_FD_IN(%ebp)

open_fd_out:
 # OPEN OUTPUT FILE
 movl $SYS_OPEN, %eax
 movl ST_ARGV_2(%ebp), %ebx
 movl $O_CREAT_WRONGLY_TRUNC, %ecx
 # Mode for new file (if its created)
 movl $0666, %edx

 int $LINUX_SYSCALL

store_fd_out:
 # Store the file desc
 movl %eax, ST_FD_OUT(%ebp)
 
# MAIN LOOP
read_loop_begin:

movl $SYS_READ, %eax
# Input file desc
movl ST_FD_IN(%ebp), %ebx
# Location to read into
movl $BUFFER_DATA, %ecx
# SIZE OF Buffer
movl $BUFFER_SIZE, %edx

int $LINUX_SYSCALL
# Number of bytes read returned in %eax, 0 if eof and -ve if error

## IF WE've Reached the end
cmpl $END_OF_FILE, %eax
jle end_loop

continue_read_loop:
 ## CONVERT BLOCK TO UPPER CASE
 pushl $BUFFER_DATA # LOCATION OF BUFFER
 pushl %eax # Number of bytes read
 
 call convert_to_upper
 popl %eax # Get size back

 addl $4, %esp # Restore %esp

 
## Write the block out to the output file

 movl %eax, %edx # Size is stored in %eax, Numbers of bytes to write in file ( from buffer )
 movl $SYS_WRITE, %eax
 # FILE DESC
 movl ST_FD_OUT(%ebp), %ebx
 # Loc of buffer ( buff addr )
 movl $BUFFER_DATA, %ecx
 
 int $LINUX_SYSCALL

## CONTINUE THE LOOP
jmp read_loop_begin

end_loop:
 ## CLOSE THE FILES
 ## * NO ERROR CHECKING

movl $SYS_CLOSE, %eax
movl ST_FD_OUT(%ebp), %ebx
int $LINUX_SYSCALL

movl $SYS_CLOSE, %eax
movl ST_FD_IN(%ebp), %ebx
int $LINUX_SYSCALL

## EXIT
movl $SYS_EXIT, %eax
movl $0 , %ebx
int $LINUX_SYSCALL


## FUNCTION

.equ LOWERCASE_A, 'a' # Lower boundary
.equ LOWERCASE_Z, 'z' # Upper boundary

.equ UPPER_CONVERSION, 'A' - 'a'

## STACK

.equ ST_BUFFER_LEN, 8
.equ ST_BUFFER, 12

# .type convert_to_upper, @function

convert_to_upper:
pushl %ebp
movl %esp, %ebp

movl ST_BUFFER(%ebp), %eax
movl ST_BUFFER_LEN(%ebp), %ebx
movl $0, %edi # Current buffer offset

cmpl $0, %ebx # Zero len buff
je end_convert_loop  # There is nothing to convert then

convert_loop:
 # Get current byte
 movb (%eax, %edi, 1), %cl # %cl is least 16 bit register, using indexed addressing mode
 
# GO to the next byte unless it is between 'a', 'z'
cmpb $LOWERCASE_A, %cl # Compare byte
jl next_byte # Jump if %cl is less then 'a'

cmpb $LOWERCASE_Z, %cl
jg next_byte # Jump if %cl is greater then 'z' , see ASCII/ UTF-8

# Otherwise convert byte to uppercase
addb $UPPER_CONVERSION, %cl

# Replace with existing lowercase
movb %cl, (%eax, %edi, 1) # 
# %eax: stores buffer address
# %edi: Stores current byte index
# 1 : size of element, sizeof( byte ) = 1

next_byte:
 incl %edi # Increament index
 cmpl %edi , %ebx # IF index == size
 jne convert_loop # Not equal, jump to start aka repeat
 
end_convert_loop:

 movl %ebp, %esp
 pop %ebp
 ret







