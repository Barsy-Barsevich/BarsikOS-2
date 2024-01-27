

; SYS_OS_muutos
; SYS_User_muutos
; SYS_Clear_Timer_16
; SYS_Read_Timer_16
; SYS_TA_write


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
; Функция SYS_Clear_Time_16 - сброс системного времени
; Ввод: нет
; Вывод: нет
; Используемые регистры: A
; Используемые порты: таймер номер 1
; Оценка: длина - 9 байт, время - 51 такт
SYS_Clear_Time_16:
    mvi     a,70H
    out     TIMER_MODEREG
    xra     a
    out     TIMER_COUNTER_1
    out     TIMER_COUNTER_1
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
    mvi     a,$DF   ;Микрон-2: tps = 1
;    mvi     a,$FD   ;Laulaja-4 standart: tps = 5
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


; SYStemFS
; Функция SYS_TA_write - запись таблицы ассоциаций из аттрибутов процесса
; Ввод: (HL)-указатель на структуру аттрибутов процесса
; Вывод: нет
; Используемые регистры: все
; Оценка: длина - , время - 
SYS_TA_write:
    in      SYSPORT_C
    ori     SYS_WB_BITMASK
    out     SYSPORT_C
    ldhi    SYSPA_TA_01
    mvi     c,$08
    lxi     h,$0000
sys_ta_write_cycle:
    ldax    d
    cma
    mov     b,a
    ani     $F0
    rrc
    rrc
    rrc
    rrc
    mov     m,a
    mvi     a,$10
    add     h
    mov     h,a
    mov     a,b
    ani     $0F
    mov     m,a
    mvi     a,$10
    add     h
    mov     h,a
    inx     d
    dcr     c
    jnz     sys_ta_write_cycle
    in      SYSPORT_C
    ani     SYS_WB_BITMASK_INV
    ori     SYS_CLKE_BITMASK
    out     SYSPORT_C
    ret

