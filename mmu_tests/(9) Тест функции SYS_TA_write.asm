
; (9) Тест функции SYS_TA_write (17.11.2023)
;
; Функция SYS_TA_write заносит в таблицу ассоциаций вычислительной платы
; соответственный массив из структуры атрибутов процесса (САП)



;Системный порт
.def SYSPORT_A =            $00
.def SYSPORT_B =            $02
.def SYSPORT_C =            $01
.def SYSPORT_INI =          $03
;Таймер
.def TIMER_COUNTER_0 =      $08
.def TIMER_COUNTER_1 =      $09
.def TIMER_COUNTER_2 =      $0A
.def TIMER_MODEREG =        $0B
;Дисплей
.def DISP_PORT =            $18

;Сигналы управления системного порта (на вывод)
.def SYS_TURBO_BITMASK =    $01     ;1-переход в турборежим тактирования
.def SYS_WB_BITMASK =       $02     ;1-запись ассоциаций в СВА, 0-функция отключена
.def SYS_WB_BITMASK_INV =   $FD
.def SYS_CLKE_BITMASK =     $04     ;1-разрешение работы таймера 2
.def SYS_CLKE_BITMASK_INV = $FB
.def SYS_SY0_BITMASK =      $01
.def SYS_SY1_BITMASK =      $08
.def SYS_SY2_BITMASK =      $02
.def SYS_SY3_BITMASK =      $04
.def SYS_SY4_BITMASK =      $08
.def SYS_SY5_BITMASK =      $10
.def SYS_SY6_BITMASK =      $20
.def SYS_MS0_BITMASK =      $40
.def SYS_MS1_BITMASK =      $80
.def SYS_PT0_BITMASK =      $08
.def SYS_PT1_BITMASK =      $10
.def SYS_PT2_BITMASK =      $20
.def SYS_AU0_BITMASK =      $40
.def SYS_AU1_BITMASK =      $80
.def SYS_PS15_BITMASK =     $01
.def SYS_PS16_BITMASK =     $02
.def SYS_PS17_BITMASK =     $04
;Биты на ввод
.def SYS_REQ_BITMASK =      $10
.def SYS_Priority_BITMASK = $20
.def SYS_CONF_BITMASK =     $40


.def MEMORY_CELL =          $EFFF


Start:
; Устанавливаем указатель стека
    lxi sp,EFF0H
; Инициализируем порт
    mvi a,88H
    out 03H
    jmp m1


; Ссылка на TRAP
    .org 0024H
TRAP-main:
    push    psw
    push    b
    push    d
    push    h
;(1) Определяем, кто был источником прерывания
    rim             ;Чтение маски прерываний
    mov     b,a
;Сбрасываем RST7.5
    mvi     a,$10
    sim
    mov     a,b
    ani     $40     ;Выделяем RST7.5
    jz      trap_source_proc


;(1a) Источник прерывания - таймер
trap_source_timer:
    ;печать значения 0 на экране 
    mvi     a,$30
    call    7-seg
    cma
    out     DISP_PORT
    jmp     trap_source_end     ;переход к стандартному возврату

;(1b) Источник прерывания - процесс    
trap_source_proc:
;Получение значения адреса старшего байта адреса процесса пользователя,
;откуда был выполнен переход в режим ОС
    lxi     h,$000B     ;смещение 11
    dad     sp          ;(HL)=(SP)+11
    mov     a,m         ;(A)-старший байт адреса процесса пользователя
    ani     $F0
    ;cpi     $F0         ;проверка на сектор 'F'
    cpi     $00         ;проверка на сектор '0'
    ;cpi     $20         ;проверка на сектор '2'
    jz      trap_stack_form     ;переход к выполнению системной функции

;(1ba) Убить процесс
    ;печать значения 1 на экране
    mvi     a,$31
    call    7-seg
    cma
    out     DISP_PORT
    jmp     trap_source_end     ;переход к стандартному возврату
    
;(1bb) Переход к исполнению системной функции
trap_stack_form:
;Перестановка:
;
; [HL]          
; [DE]          [USR_MUUTOS]
; [BC]          [HL]
; [PSW]         [DE]
; [SYS_OS] ->   [BC]
; [FUN]         [PSW]
; [USER]   =    [USER]
; [DI]     =    [DI]
;Работаем:
    pop     psw     ;HL
    pop     b       ;DE
    pop     d       ;BC
    pop     h       ;PSW
    xthl            ;(HL)=[SYS_OS], (stack)=PSW
    pop     h       ;PSW
    xthl            ;(HL)=[FUN], (stack)=PSW
    push    d       ;BC
    push    b       ;DE
    push    psw     ;HL
;Загрузка указателя на функцию SYS_User_muutos
    lxi     d,SYS_User_muutos
    push    d
;Переход к системной функции
    ;(HL)-адрес возврата [FUN]
    pchl

;(2) Стандартный возврат
trap_source_end:
    jmp     SYS_User_muutos


.include    /home/victor/Desktop/Laulaja_tests/SYStemFS.asm




m1:
; Включаем запись в банк регистров
;; WB - разряд №1 порта С
;    mvi     a,SYS_WB_BITMASK
;    out     SYSPORT_C
;; Запись в банк
;    mvi     a,0FH
;    sta     0000H
;    mvi     a,0EH
;    sta     1000H
;;    mvi     a,DDH
;    mvi     a,0EH  ;сектор '2' аналогичен '1'
;    sta     2000H
;    mvi     a,0CH
;    sta     3000H
;    mvi     a,0BH
;    sta     4000H
;    mvi     a,0AH
;    sta     5000H
;    mvi     a,09H
;    sta     6000H
;    mvi     a,08H
;    sta     7000H
;    mvi     a,07H
;    sta     8000H
;    mvi     a,06H
;    sta     9000H
;    mvi     a,05H
;    sta     A000H
;    mvi     a,04H
;    sta     B000H
;    mvi     a,03H
;    sta     C000H
;    mvi     a,02H
;    sta     D000H
;    mvi     a,01H
;    sta     E000H
;    mvi     a,00H
;    sta     F000H
;; Выключаем режим записи в банк
;    mvi     a,SYS_CLKE_BITMASK
;    ;ori     SYS_TURBO_BITMASK
;    out     SYSPORT_C
    lxi     h,System_process_attributes
    call    SYS_TA_write

;Загружаем в стек переход к пользовательскому процессу
    ;lxi     h,user_cykle
    lxi     h,$2000
    push    h
;Переход к TRAP
    jmp     TRAP-main


7-seg:
    call    sthex1
    lxi     b,STR-7seg
    add     c
    mov     c,a
    ldax    b
    ret
STR-7seg:
    .db     3FH
    .db     06H
    .db     5BH
    .db     4FH
    .db     66H
    .db     6DH
    .db     7DH
    .db     07H
    .db     7FH
    .db     6FH
    .db     77H
    .db     7CH
    .db     58H
    .db     5EH
    .db     79H
    .db     71H

sthex1:
    sui     30H
    cpi     0AH
    rm
    sui     07H
    ret
shex1:
    adi     30H
    cpi     3AH
    rm
    adi     07H
    ret

data:
    .db     00H


    

Function:
    call    SYS_OS_muutos
    lda     $8010
    ani     $0F
    call    shex1
    call    7-seg
    cma
    out     DISP_PORT
    ret



;Сектор '2'
; Внимание, все переходы следующих 2 функций должны быть заменены с '1' сектора
; на '2'. Это очень важно
.org $1000
user_cykle:
;Программа для пользователя    
    lda     8010H
    inr     a
    sta     8010H
    lxi     h,$0032
    call    Delay_ms_6
    call    Function
    jmp     user_cykle


; (E) Barsotion KY
; Функция Delay_ms_5 - программная задержка
; t = (5009*HL+7)/fтакт мс
; t = HL миллисекунд при fтакт = 5.0 МГц
; Ввод:    HL (время в мс)
; Вывод:   нет
; Используемые регистры: АF,DE,HL
; Используемая память: нет
; Длина: 16 байт
; Время выполнения: ~HL мкс при тактовой частоте 5MHz
Delay_ms_5:
    lxi     d,$00B2
delay_ms_5_1:
    dcx     d
    mov     a,d
    ora     e
    jnz     delay_ms_5_1
    dcx     h
    mov     a,h
    ora     l
    jnz     Delay_ms_5
    ret

; (E) Barsotion KY
; Функция Delay_ms_6_ - программная задержка
; t = (6001*HL)/fтакт мс
; t = HL миллисекунд при fтакт = 6.0 МГц
; Ввод:    HL (время в мс)
; Вывод:   нет
; Используемые регистры: АF,DE,HL
; Используемая память: нет
; Длина: 18 байт
; Время выполнения: ~HL мкс при тактовой частоте 6MHz
Delay_ms_6:
    lxi     d,$00A6
delay_ms_6_1:
    dcx     d
    nop
    nop
    mov     a,d
    ora     e
    jnz     delay_ms_6_1
    dcx     h
    mov     a,h
    ora     l
    jnz     Delay_ms_6
    ret


System_process_attributes:
;--<System Process Attributes>--------------------------------------------------
.db $00     ;SYSPA_ID =         $00
.db $00     ;SYSPA_STATUS =     $01
.db $00     ;SYSPA_STATUS2 =    $02
;Table of Assotiations
.db $01     ;SYSPA_TA_01 =      $03
.db $13     ;SYSPA_TA_23 =      $04
.db $45     ;SYSPA_TA_45 =      $05
.db $67     ;SYSPA_TA_67 =      $06
.db $89     ;SYSPA_TA_89 =      $07
.db $AB     ;SYSPA_TA_AB =      $08
.db $CD     ;SYSPA_TA_CD =      $09
.db $EF     ;SYSPA_TA_EF =      $0A
;Contains of stack
.dw $0000   ;SYSPA_STACK_HL =   $0B
.dw $0000   ;SYSPA_STACK_DE =   $0D
.dw $0000   ;SYSPA_STACK_BC =   $0F
.dw $0000   ;SYSPA_STACK_PSW =  $11
;Return address
.dw $2000   ;SYSPA_RETADDR =    $13
;Name
.db $00     ;SYSPA_NAME =       $15
.db $00     ;SYSPA_NAME_0 =     $15
.db $00     ;SYSPA_NAME_1 =     $16
.db $00     ;SYSPA_NAME_2 =     $17
.db $00     ;SYSPA_NAME_3 =     $18
.db $00     ;SYSPA_NAME_4 =     $19
.db $00     ;SYSPA_NAME_5 =     $1A
.db $00     ;SYSPA_NAME_6 =     $1B
.db $00     ;SYSPA_NAME_7 =     $1C


