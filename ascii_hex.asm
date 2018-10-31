data segment
hex db 4 dup(0), 0Dh, 0Ah, '$' ;存储16进制数
data ends
																																																																									
code segment
assume cs:code, ds:data
main:
  mov ax, 0B800h
  mov es, ax
  mov cx, 80 
  mov ax, 0000h ;黑色填充
  mov di, 0
clear: ;清空第一行
  mov word ptr es:[di], ax
  add di, 2
  sub cx, 1
  jnz clear
  
  xor di, di
  mov al, 0
  mov cx, 11 ;共11列
col_again: ;列循环
  push di ;保存列循环次数
  push cx ;保存每列第0行的地址
  mov cx, 25 ;共25行
row_again: ;行循环
  mov ah, 04h ;红色
  mov word ptr es:[di], ax ;当前字符
  push ax ;保存当前字符序号
  push cx ;保存行循环次数
  push di ;保存当前列输出位置
  push di 
  xor di, di ;di置0，作为数组索引
  mov cx, 4 ;循环左移四次
  
v2h: ;转换成16进制字符
  push cx ;保存移位循环次数
  mov cl, 4 ;左移4位
  rol ax, cl
  push ax ;保存移位后数字
  and ax, 000Fh ;获取最低位
  cmp ax, 10 ;判断是数字还是字母
  jb is_digit
is_alpha:
  sub al, 10
  add al, 'A'
  jmp finish_4bits
is_digit:
  add al, '0'
finish_4bits:
  mov hex[di], al  ;将当前位存入数组
  pop ax ;还原数字
  pop cx ;还原循环次数
  add di, 1 ;索引值加1
  sub cx, 1
  jnz v2h
  
  pop di ;还原当前输出位置(同一个输出)
  mov ah, 02h ;绿色
  add di, 2
  mov al, hex[2]
  mov word ptr es:[di], ax
  add di, 2
  mov al, hex[3]
  mov word ptr es:[di], ax ;输出16进制数

  pop di ;还原当前输出位置(该行)
  pop cx ;还原行循环次数
  pop ax ;还原字符序号
  add al, 1 
  jz exit ;字符序号为0，表示输出结束
  add di, 160 ;下一行
  sub cx, 1 
  jnz row_again
  pop cx ;还原列循环次数
  pop di ;还原输出位置(该列第0行)
  add di, 14 
  sub cx, 1  
  jnz col_again  
exit:
  mov ah, 1
  int 21h
  mov ah, 4Ch
  int 21h
code ends
end main