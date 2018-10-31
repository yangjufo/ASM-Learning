.386																																				
data segment use16
t db '0123456789ABCDEF' ;用于转化成16进制
KeyPageUp dw 4900h ;按键对应的编码
KeyPageDown dw 5100h
KeyHome dw 4700h
KeyEnd dw 4F00h	   																																
KeyEsc dw 011Bh
s db 75 dup(0)  ;存储每行的输出
s_index dw 0 ;s的当前字符位置
buf_index dw 0 ;buf的当前字符位置 
buf db 256 dup(0) ;从文件读入的一个buf
filename db 100 ;文件名
	 db ?
	 db 100 dup(?)		 
file_size dd  0h ;文件大小
offset_in_file dd 0h ;输出的第一个字符在文件中的偏移量
handle dw 0h ;文件句柄
bytes_in_buf dw 0h ;buf中的字符数量
bytes_on_row dw 0h ;一行的字符数量 
offset_on_row dw 0h ;行位移，用于输出行号
row dw 0h ;行号
n dd, 0h
file_open_error db 'Cannot open file!', '$' ;文件打开错误输出信息
data ends 

code segment use16
assume cs:code, ds:data

char2hex: ;char转换成16进制
	push di 
	mov di, s_index ;当前字符
	push ax
	shr ax, 4
	and ax, 0Fh
	mov bx, offset t	
	xlat 
	mov s[di], al ;将转换结果存入s
	inc di
	pop ax
	and ax, 0Fh
	xlat
	mov s[di], al
	mov s_index, di
	pop di
	ret

long2hex:	;输出行号
	push cx
	mov cx, 4
	mov ax, offset_on_row
	
l2h_again:	
	rol eax, 8	
	push eax
	and eax, 0FFh
	call char2hex
	inc s_index
	pop eax
	loop l2h_again
	pop cx
	mov bx, s_index
	mov s[bx], ':' ;输出行号后输出“:”
	inc s_index ;index后移一位
	ret

clear_this_page: ;清空输出页面
	mov ax, 0B800h
	mov es, ax
	xor di, di
	xor cx, cx
	mov ax, 80
	mov cl, 16
	imul cl
	mov cx, ax
	mov ax, 0020h
	cld																																								
	rep stosw
	ret

show_this_row:	;输出一行
	call long2hex ;存入行号
	mov cx, bytes_on_row
	inc s_index
	mov di, buf_index
	xor dx, dx
set_content_hex: ;存入16进制表示
	mov al, buf[di]
	call char2hex ;将字符转换成16机制并存入s
	inc s_index	
	inc dx
	cmp dx, 4	
	je set_ver_line
	inc s_index
	jmp after_set_line
set_ver_line: ;输出竖线
	mov si, s_index
	mov s[si], '|' 
	inc s_index
	xor dx, dx
after_set_line:
	inc di																																																	
	loop set_content_hex
	cmp s_index, 58
	je after_add_zero
	mov cx, 58
	sub cx, s_index
	mov di, s_index
add_zero: ;最后一行输出，不足16字符，将s中剩余维置为空
	cmp s[di], '|'	
	je after_set_zero	
set_zero:
	mov s[di], ' '
after_set_zero:
	inc di
	loop add_zero
after_add_zero:	
	mov cx, bytes_on_row	
	mov si, 59
	mov di, buf_index
set_content_ori:	;存入原始字符
	mov al, buf[di]
	mov s[si], al
	inc si
	inc di
	loop set_content_ori
	mov s_index, si 
	mov ax, row ;根据行号计算输出位置
	mov cl, 160		 																															
	mul cl	   
	mov di, ax
	mov ax, 0B800h
	mov es, ax
	xor si, si
	mov cx, s_index ;获取输出长度
print_row:
	mov al, s[si]		
	cmp s[si], '|'
	je set_bright_color
	mov ah, 07h
	jmp after_set_color
set_bright_color: ;竖线高亮
	mov ah, 0Fh
after_set_color:
	mov word ptr es:[di], ax
	add di, 2
	add si, 1
	loop print_row
	ret

show_this_page: ;输出当前页
	call clear_this_page
	xor ax, ax
	mov ax, bytes_in_buf
	add ax, 15
	mov cl, 16
	div cl		
	xor cx, cx
	mov cl, al	;获取行数
	mov row, 0
	mov buf_index, 0
	mov eax, offset_in_file
	mov offset_on_row, ax ;获取行位移	
show_rows:
	cmp cx, 1
	je assign_i
	mov bytes_on_row, 16
	jmp after_assign_row	
assign_i: ;最后一行输出，不足16字符
	mov ax, row
	mov bx, 0016
	mul bx		
	sub bytes_in_buf, ax
	mov ax, bytes_in_buf
	mov bytes_on_row, ax
after_assign_row:
	push cx
	call show_this_row ;输出一行
	pop cx
	add offset_on_row, 16 ;行位移增加16
	add buf_index, 16	 ;buf的index增加16
	mov s_index, 0 ;s的index置为0
	inc row	;行号加1
	loop show_rows
	ret

file_error: ;打开文件错误
	mov dx, offset file_open_error
	mov ah, 09h
	int 21h
	mov al, 0
	jmp exit


exit:	;退出程序
	mov ah, 4Ch
	int 21h

doPageUp: ;上翻一页
	sub offset_in_file, 256
	jnc after_set_offset
	mov offset_in_file, 0
after_set_offset:																															
	jmp main_loop	

doPageDown: ;下翻一页
	add offset_in_file, 256
	mov eax, offset_in_file
	cmp eax, file_size
	jb main_loop
	sub offset_in_file, 256
	jmp main_loop

doHome: ;跳到第一页
	mov offset_in_file, 0
	jmp main_loop

doEnd: ;跳到最后一页
	mov eax, file_size
	mov bx, 0100h
	div bx
	mov eax, file_size
	sub eax, edx
	mov offset_in_file, eax	
	mov eax, file_size
	cmp eax, offset_in_file
	jne after_minus
	sub offset_in_file, 256
after_minus:	
	jmp main_loop

doEsc: ;退出程序
	mov ah, 3Eh
	mov bx, handle
	int 21h
	jmp exit


main: 
	mov ax, data
	mov ds, ax
	mov ah, 0Ah
	mov dx, offset filename
	int 21h
  					
	mov bl, 2 ;打开文件
	add bl, ds:filename[1]	
	mov bh, 0 
	mov filename[bx], 0
	mov ah, 3Dh
	mov al, 0
	mov dx, offset filename[2]	
	int 21h
	mov handle, ax
	jc file_error

	mov ah, 42h ;获取文件大小
	mov al, 2
	mov bx, handle
	mov cx, 0
	mov dx, 0
	int 21h
	mov word ptr file_size[2], dx
	mov word ptr file_size[0], ax

	mov offset_in_file, 0
main_loop: ;主循环
	mov eax, file_size
	sub eax, offset_in_file
	mov n, eax
	cmp n, 256
	jb assign_n
	mov bytes_in_buf, 256
	jmp after_assign_buf
assign_n: ;最后一页，buf不足256
	mov eax, n
	mov bytes_in_buf, ax
after_assign_buf:
	mov ah, 42h
	mov al, 0
	mov bx, handle
	mov cx, word ptr offset_in_file[2]
	mov dx, word ptr offset_in_file[0]
	int 21h						  																																	
	mov ah, 3Fh
	mov bx, handle
	mov cx, bytes_in_buf
	mov dx, data
	mov ds, dx
	mov dx, offset buf
	int 21h
	call show_this_page ;显示当前页
	mov ah, 0 ;读取键盘输入
	int 16h
	cmp ax, KeyPageUp
	je doPageUp
	cmp ax, KeyPageDown
	je doPageDown
	cmp ax, KeyHome
	je doHome
	cmp ax, KeyEnd
	je doEnd
	cmp ax, KeyEsc
	je doEsc
	jmp main_loop
code ends
end main