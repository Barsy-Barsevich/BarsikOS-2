
; (8) Тест системы виртуальной адресации в режиме пользователя
;
; Для пользовательского процесса код запускается в секторе '2'. Однако на деле
; код располагается в секторе '1'


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


; SYStemFS
; Функция SYS_OS_muutos - переход в режим ОС
; Ввод: нет
; Вывод: нет
; Используемые регистры: A,I
; Оценка: длина - 12 байт, время - ~29 тактов
SYS_OS_muutos:
    mvi     a,40H
    sim
    mvi     a,C0H
    sim
    nop
    nop
    nop
    nop
    nop
    ret

; SYStemFS
; Функция SYS_User_muutos - переход в режим пользователя
; Ввод: нет
; Вывод: нет
; Используемые регистры: все
; Используемые порты: таймер номер 2
; Оценка: длина - 23 байта, время - 123 такта
SYS_User_muutos:
;Настройка таймера
    mvi     a,B0H
    out     TIMER_MODEREG
    mvi     a,60H
    out     TIMER_COUNTER_2
    mvi     a,EAH
    out     TIMER_COUNTER_2
; Включаем режим пользователя
    mvi     a,40H
    sim
    mvi     a,C0H
    sim
    pop     h
    pop     d
    pop     b
    pop     psw
    ret
    
; SYStemFS
; Функция SYS_Read_Time_16 - чтение значения системного времени (в тиках)
; Ввод: нет
; Вывод: (HL) - время в тиках таймера
; Используемые регистры: AF,HL
; Оценка: длина - 21 байт, время - 89-90 тактов
SYS_Read_Time_16:
    in      TIMER_COUNTER_1  ;чтение LSB
    mov     l,a
    in      TIMER_COUNTER_1  ;чтение MSB
    mov     h,a
;Область переполнения (256-(14/tps)), tps = делитель таймера
;    mvi     a,$DF   ;Микрон-2: tps = 1
    mvi     a,$FD   ;Laulaja-4 standart: tps = 5
;    mvi     a,$FF   ;Laulaja-4 turbomode: tps = 10
    sub     l
    jnc     sys_read_time_16_1
    dcr     h
sys_read_time_16_1:
;(HL)-systime*(-1). Необходимо дополнить
    mov     a,l
    cma
    mov     l,a
    mov     a,h
    cma
    mov     h,a
    inx     h
    ret




m1:
; Включаем запись в банк регистров
; WB - разряд №1 порта С
    mvi     a,SYS_WB_BITMASK
    out     SYSPORT_C
; Запись в банк
    mvi     a,FFH
    sta     0000H
    mvi     a,EEH
    sta     1000H
;    mvi     a,DDH
    mvi     a,EEH  ;сектор '2' аналогичен '1'
    sta     2000H
    mvi     a,CCH
    sta     3000H
    mvi     a,BBH
    sta     4000H
    mvi     a,AAH
    sta     5000H
    mvi     a,99H
    sta     6000H
    mvi     a,88H
    sta     7000H
    mvi     a,77H
    sta     8000H
    mvi     a,66H
    sta     9000H
    mvi     a,55H
    sta     A000H
    mvi     a,44H
    sta     B000H
    mvi     a,33H
    sta     C000H
    mvi     a,22H
    sta     D000H
    mvi     a,11H
    sta     E000H
    mvi     a,00H
    sta     F000H
; Выключаем режим записи в банк
    mvi     a,SYS_CLKE_BITMASK
    ori     SYS_TURBO_BITMASK
    out     SYSPORT_C
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
    ;lxi     h,$003E
    lxi     h,$003E
    call    DELAY_MS
    call    Function
    jmp     user_cykle

; (E) Barsotion KY
; Функция DELAY_MS - программная задержка
; t = (5009*HL+7)*1000/fтакт мс
; t = HL миллисекунд при fтакт = 5.0 МГц
; Ввод:    HL (время в мс)
; Вывод:   нет
; Используемые регистры: АF,DE,HL
; Используемая память: нет
; Длина: 16 байт
; Время выполнения: ~HL мкс при тактовой частоте 
DELAY_MS:
    lxi     d,$00B2
delay_1:
    dcx     d
    mov     a,d
    ora     e
    jnz     delay_1
    dcx     h
    mov     a,h
    ora     l
    jnz     DELAY_MS
    ret
    


