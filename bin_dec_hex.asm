.386
data segment use16
    buffer db 10 dup('$') ;读取缓存
    xval dd 0  ;乘数
    yval dd 0
    resval dd 0 ;运算结果
    reshex db 8 dup(0), 'H', 0Ah, 0Dh, '$' ;十六进制结果
    resdec db 15 dup('$') ;十进制结果
    resbin db 39 dup(0), 'B', 0Ah, 0Dh, '$' ;二进制结果
    t db "0123456789ABCDEF" ;用于十六进制转换
data ends

code segment use16
assume cs:code, ds:data
read_num: ;读入乘数
    lea dx, buffer ;输入至buffer
    mov ah, 10											
    int 21h
    mov dl, 0Ah ;填充回车及换行
    mov ah, 02h
    int 21h
    mov dl, 0Dh
    mov ah, 02h
    int 21h
    mov bx, 2																																																	
    mov eax, 0
    mov edx, 0
read_next:																																
    mov dl, buffer[bx] ;存数字
    cmp dl, 0Dh ;回车作为结束
    je done
    imul eax, eax, 10 
    sub dl, '0'
    add eax, edx
    inc bx
    jmp read_next
done:
    ret
    
out_dec: ;十进制输出
    mov di, 0
    mov cx, 0
    mov eax, resval
dec_again: ;数位数
    mov dx, 0 
    mov ebx, 10
    div ebx
    add dl, '0'
    push dx ;将每一位的值压入堆栈
    inc cx               
    cmp eax, 0 ;直到被除数为0
    jnz dec_again
dec_next:
    pop dx 
    mov resdec[di], dl ;将堆栈中存储的值存入resdec
    inc di
    dec cx
    jnz dec_next
    mov resdec[di], 0Dh ;在字符串结尾添加回车及换行
    inc di
    mov resdec[di], 0Ah
    mov ah, 9 ;输出结果
    mov dx, offset resdec
    int 21h
    ret


out_hex: ;十六进制输出
    mov di, offset reshex
    mov bx, offset t
    mov cx, 8 ;循环左移次数
    push resval
hex_next:
    push cx 
    mov cl, 4 ;每次循环左移4位
    rol resval, cl
    pop cx
    mov eax, resval 
    and eax, 0Fh
    xlat ;将当前位存入al
    mov ds:[di], al ;将当前位存入reshex
    inc di
    dec cx
    jnz hex_next	  																												
    xor bx, bx    																																		
cal_n: ;计算左侧有几个0，不输出
    inc bx		      																								
    cmp reshex[bx-1], '0'
    jz	cal_n
    dec bx
    mov	ah, 9
    lea dx, reshex[bx] ;输出结果
    int 21h
    pop resval
    ret

out_bin: ;输出二进制结果
    mov cx, 32 ;左移次数
    mov eax, resval
    xor di, di
    xor bx, bx
bin_next:
    cmp bx, 4 ;每4位输出一个空格
    jnz bin_next2
    mov resbin[di], ' '
    inc di
    xor bx, bx
bin_next2:
    shl eax, 1 ;左移1位
    jc is_one
is_zero: ;移出位为0
    mov resbin[di], '0'
    jmp zero_one_done
is_one: ;移出位为1
    mov resbin[di], '1'
zero_one_done: 
    inc di
    inc bx
    dec cx   
    jnz bin_next
    mov ah, 09h ;输出结果
    mov dx, offset resbin
    int 21h
    ret																															

main:
    mov ax, data
    mov ds, ax
    call read_num ;读入乘数
    mov [xval], eax
    call read_num
    mov [yval], eax
    mov ebx, [xval]
    mul ebx ;计算结果
    mov [resval], eax 
    call out_dec ;调用，显示十进制结果
    call out_hex ;调用，显示十六进制结果
    call out_bin ;调用，显示二进制结果
    mov ah, 4Ch 
    int 21h  																																				
code ends
end main

	