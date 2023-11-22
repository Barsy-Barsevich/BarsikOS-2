

    .org    $F001
;;StandartArithmetic
;;Важно отметить, что функции SDIV и UDIV не будут пока работать, тк переход
;;в режим ОС не предусматривает сохранения данных регистров
;    jmp     SUB16
;    jmp     MUL16
;    call    SYS_OS_muutos_usr
;    jmp     SDIV16
;    call    SYS_OS_muutos_usr
;    jmp     UDIV16
;    jmp     CMP16
;    jmp     ABS
;    jmp     DOPHL
;    jmp     DOPBC
;    jmp     DOPDE
;;AFS3
;;Важно отметить, что функции STRCMP, CONCAT, POS не будут пока работать, тк
;;переход в режим ОС не предусматривает сохранения данных регистров
;    jmp     BITSET
;    jmp     BITCLR
;    jmp     BITTST
;    jmp     MFILL
;    jmp     COPCOUNT
;    jmp     BN2HEX
;    jmp     HEX2BN
;    jmp     SYM_LOWER
;    jmp     SYM_HIGHER
;    jmp     STRCOP
;    call    SYS_OS_muutos_usr
;    jmp     STRCMP
;    call    SYS_OS_muutos_usr
;    jmp     CONCAT
;    call    SYS_OS_muutos_usr
;    jmp     POS
;;Левые функции
;    jmp     Function
;    jmp     Delay_ms_6

.include /home/victor/Desktop/BarsikOS-2/core/systemdef.def
.include /home/victor/Desktop/BarsikOS-2/lib/StandartArithmetic.asm
.include /home/victor/Desktop/BarsikOS-2/lib/AFS3.asm

Function:
    call    SYS_OS_muutos
    lda     $8010
    ani     $0F
    call    BCDSEG7
    cma
    out     DISP_PORT
    ret
    
; (E) Barsotion KY
; Функция Delay_ms_6_ - программная задержка
; t = (6001*HL)/fтакт мс
; t = HL миллисекунд при fтакт = 6.0 МГц
; Ввод:    HL (время в мс)
; Вывод:   нет
; Используемые регистры: АF,DE,HL
; Используемая память: нет
; Длина: 16 байт
; Время выполнения: ~HL мкс при тактовой частоте 6MHz
Delay_ms_6:
    lxi     d,$00F9
delay_ms_6_1:
    dcx     d
    mov     a,d
    ora     e
    jnz     delay_ms_6_1
    dcx     h
    mov     a,h
    ora     l
    jnz     Delay_ms_6
    ret


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
