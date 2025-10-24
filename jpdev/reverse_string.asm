; String Reversal Using Stack Implementation
; Architecture: x86-64 Assembly (NASM syntax)
; Purpose: Reverse strings using stack data structure (LIFO property)

section .data
    ; Test strings to reverse
    test_str1 db "Hello, World!", 0
    test_str2 db "Assembly", 0
    test_str3 db "12345", 0
    test_str4 db "Racecar", 0
    test_str5 db "Data Structures", 0
    
    ; Messages
    original_msg db "Original:  ", 0
    reversed_msg db "Reversed:  ", 0
    newline db 10, 0
    separator db "------------------------", 10, 0
    
    ; Stack constants
    STACK_SIZE equ 256

section .bss
    ; Stack implementation
    stack resb STACK_SIZE    ; Reserve 256 bytes for stack
    stack_top resq 1         ; Pointer to top of stack (8 bytes)
    
    ; Buffer for reversed string
    reversed_buffer resb 256 ; Buffer to store reversed string

section .text
    global _start

; ==================== STACK OPERATIONS ====================

; Initialize stack - sets stack pointer to base
init_stack:
    lea rax, [rel stack]     ; Load address of stack base
    mov [rel stack_top], rax ; Set stack_top to base
    ret

; Push character onto stack
; Input: AL = character to push
; Returns: 1 in AL if success, 0 if stack overflow
push:
    mov rbx, [rel stack_top] ; Get current top pointer
    lea rcx, [rel stack]     ; Get stack base
    add rcx, STACK_SIZE      ; Calculate stack limit
    
    cmp rbx, rcx             ; Check if stack is full
    jge .overflow            ; Jump if greater or equal (full)
    
    mov [rbx], al            ; Store character at top position
    inc rbx                  ; Move top pointer up one byte
    mov [rel stack_top], rbx ; Update stack_top
    mov al, 1                ; Return success
    ret

.overflow:
    mov al, 0                ; Return failure (overflow)
    ret

; Pop character from stack
; Returns: Character in AL, or 0 if stack empty
pop:
    mov rbx, [rel stack_top] ; Get current top pointer
    lea rcx, [rel stack]     ; Get stack base
    
    cmp rbx, rcx             ; Check if stack is empty
    jle .underflow           ; Jump if less or equal (empty)
    
    dec rbx                  ; Move top pointer down one byte
    mov al, [rbx]            ; Get character from top
    mov [rel stack_top], rbx ; Update stack_top
    ret

.underflow:
    mov al, 0                ; Return 0 for empty stack
    ret

; Check if stack is empty
; Returns: 1 in AL if empty, 0 if not empty
is_empty:
    mov rbx, [rel stack_top] ; Get current top pointer
    lea rcx, [rel stack]     ; Get stack base
    
    cmp rbx, rcx             ; Compare top with base
    je .empty                ; Jump if equal (empty)
    mov al, 0                ; Not empty
    ret

.empty:
    mov al, 1                ; Stack is empty
    ret

; ==================== STRING OPERATIONS ====================

; Calculate string length
; Input: RSI = pointer to null-terminated string
; Returns: Length in RAX (excluding null terminator)
string_length:
    xor rax, rax             ; Initialize counter to 0
.loop:
    mov bl, [rsi + rax]      ; Get character at position
    test bl, bl              ; Check if null terminator
    jz .done                 ; If zero, we're done
    inc rax                  ; Increment counter
    jmp .loop                ; Continue
.done:
    ret

; Reverse string using stack
; Input: RSI = pointer to source string
;        RDI = pointer to destination buffer
; Returns: Length of string in RAX
reverse_string:
    push r12                 ; Save registers we'll use
    push r13
    push r14
    
    mov r12, rsi             ; Save source pointer
    mov r13, rdi             ; Save destination pointer
    
    call init_stack          ; Initialize the stack
    
    ; Phase 1: Push all characters onto stack
    mov rsi, r12             ; Restore source pointer
    xor r14, r14             ; Character counter
    
.push_loop:
    mov al, [rsi]            ; Get current character
    test al, al              ; Check for null terminator
    jz .push_done            ; If null, done pushing
    
    call push                ; Push character onto stack
    test al, al              ; Check if push succeeded
    jz .error                ; Handle overflow
    
    inc rsi                  ; Move to next character
    inc r14                  ; Increment counter
    jmp .push_loop           ; Continue
    
.push_done:
    ; Phase 2: Pop all characters from stack to destination
    mov rdi, r13             ; Restore destination pointer
    
.pop_loop:
    call is_empty            ; Check if stack is empty
    test al, al              ; Test result
    jnz .pop_done            ; If empty, we're done
    
    call pop                 ; Pop character from stack
    mov [rdi], al            ; Store in destination
    inc rdi                  ; Move destination pointer
    jmp .pop_loop            ; Continue
    
.pop_done:
    mov byte [rdi], 0        ; Add null terminator
    mov rax, r14             ; Return length
    jmp .done

.error:
    xor rax, rax             ; Return 0 on error
    
.done:
    pop r14                  ; Restore registers
    pop r13
    pop r12
    ret

; ==================== OUTPUT FUNCTIONS ====================

; Print null-terminated string
; Input: RSI = pointer to string
print_string:
    push rsi                 ; Save string pointer
    
    ; Calculate string length
    call string_length       ; Length now in RAX
    mov rdx, rax             ; Move length to RDX for syscall
    
    pop rsi                  ; Restore string pointer
    
    ; System call to write
    mov rax, 1               ; sys_write
    mov rdi, 1               ; stdout
    syscall
    
    ret

; Print a single test case
; Input: RSI = pointer to original string
print_test_case:
    push r12
    mov r12, rsi             ; Save string pointer
    
    ; Print "Original: "
    lea rsi, [rel original_msg]
    call print_string
    
    ; Print original string
    mov rsi, r12
    call print_string
    
    ; Print newline
    lea rsi, [rel newline]
    call print_string
    
    ; Print "Reversed: "
    lea rsi, [rel reversed_msg]
    call print_string
    
    ; Reverse the string
    mov rsi, r12             ; Source string
    lea rdi, [rel reversed_buffer] ; Destination buffer
    call reverse_string
    
    ; Print reversed string
    lea rsi, [rel reversed_buffer]
    call print_string
    
    ; Print newline
    lea rsi, [rel newline]
    call print_string
    
    ; Print separator
    lea rsi, [rel separator]
    call print_string
    
    pop r12
    ret

; ==================== MAIN PROGRAM ====================

_start:
    ; Test case 1: "Hello, World!"
    lea rsi, [rel test_str1]
    call print_test_case
    
    ; Test case 2: "Assembly"
    lea rsi, [rel test_str2]
    call print_test_case
    
    ; Test case 3: "12345"
    lea rsi, [rel test_str3]
    call print_test_case
    
    ; Test case 4: "Racecar" (palindrome)
    lea rsi, [rel test_str4]
    call print_test_case
    
    ; Test case 5: "Data Structures"
    lea rsi, [rel test_str5]
    call print_test_case

    ; Exit program
    mov rax, 60              ; sys_exit
    xor rdi, rdi             ; exit code 0
    syscall
