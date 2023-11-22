; Levental-Seivill
; Библиотека стандартной арифметики

;.def div16_srem =       $80FF ;(byte)
;.def div16_squot =      $80FE ;(byte)
;.def div16_count =      $80FD ;(byte)

; SUB16 ------- 16р вычитание
; MUL16 ------- Умножение 16р чисел
; SDVI16 ------ 16р деление со знаком
; UDVI16 ------ 16р деление без знака
; CMP16 ------- 16р сравнение
; ABS --------- Модуль 16р числа
; DOPHL ------- Дополнение 16р числа

; Таблица переходов
    jmp     SUB16
    jmp     MUL16
    jmp     SDIV16
    jmp     UDIV16
    jmp     CMP16
    jmp     ABS
    jmp     DOPHL

; Функция SUB16 - 16р вычитание
; Ввод: HL (уменьшаемое)
;       DE (вычитаемое)
; Вывод: HL
; Используемые регистры: AF,HL
; Используемая память: нет
; Длина: 7 байт
; Время выполнения: 52 такта

SUB16:
    mov     a,l
    sub     e
    mov     l,a
    mov     a,h
    sbb     d
    mov     h,a
    ret

; Функция MUL16 - умножение 16р чисел
; Ввод: HL (множимое)
;       DE (множитель)
; Вывод: HL (младшее слово произведения)
; Используемые регистры: все
; Используемая память: нет
; Длина: 26 байт
; Время выполнения: 1001..1065 тактов

MUL16:
    mov     c,l
    mov     b,h
    lxi     h,0000H
    mvi     a,0FH
mul16_1:
    push    psw
    ora     d
    jp      mul16_2
    dad     b
mul16_2:
    dad     h
    xchg
    dad     h
    xchg
    pop     psw
    dcr     a
    jnz     mul16_1
    ora     d
    rp
    dad     b
    ret    

; Функция SDVI16 - 16р деление со знаком
; Функция UDVI16 - 16р деление без знака
; Ввод:  HL (делимое)
;        DE (делитель)
; Вывод: HL (частное)
;        DE (остаток)
; Если делитель равен 0, программа возвращает флаг C=1, частное и остаток при этом равны 0000H.
; Используемые регистры: все
; Используемая память: 3 ячейки в любой обл ОЗУ
;  - div16_srem (byte)
;  - div16_squot (byte)
;  - div16_count (byte)
; Длина: 136 байт
; Время выполнения: 2480..2950 тактов

; деление со знаком
SDIV16:
    mov     a,h         ; определить знак частного с помощью xor
    sta     div16_srem  ; остаток имеет тот же знак, что и делимое
    xra     d
    sta     div16_squot
    mov     a,d         ; получить абсолютное значение делителя
    ora     a
    jp      div16_chkde
    sub     a
    sub     e
    mov     e,a
    sbb     a
    sub     d
    mov     d,a
div16_chkde:            ; получить абсолютное значение делителя
    mov     a,h
    ora     a
    jp  div16_dodiv
    sub     a
    sub     l
    mov     l,a
    sbb     a
    sub     h
    mov     h,a
div16_dodiv:            ; разделить абсолютные значения
    call    UDIV16
    rc                  ; при делении на 0 выйти из подпрограммы
; сделать частное отрицательным, если оно должно быть таковым
    lda     div16_squot
    ora     a
    jp      div16_dorem
    mvi     a,00H
    sub     l
    mov     l,a
    mvi     a,00H
    sbb     h
    mov     h,a
; сделать остаток отрицательным, если он должен быть таковым
div16_dorem:
    lda     div16_srem
    ora     a
    rp
    sub     a
    sub     e
    mov     e,a
    sbb     a
    sub     d
    mov     d,a
    ret
; деление без знака
UDIV16:
; проверить деление на 0
    mov     a,e
    ora     d
    jnz     div16_divide
    lxi     h,0000H
    mov     d,h
    mov     e,l
    stc
    ret
div16_divide:
    mov     c,l
    mov     b,h
    lxi     h,0000H
    mvi     a,10H
    ora     a
div16_dvloop:
    sta     div16_count
; сдвинуть сл разряд частного в разряд 0 делимого
; сдвинуть сл ст разряд делимого в мл разряд остатка
; BC содержит как делимое, так и частное.
; сдвигая разряд из ст байта делимого, мы сдвигаем в регистр из флага переноса сл разряд частного
    mov     a,c         ; HL содержит остаток
    ral
    mov     c,a
    mov     a,b
    ral
    mov     b,a
    mov     a,l
    ral
    mov     l,a
    mov     a,h
    ral
    mov     h,a
    push    h
    mov     a,l
    sub     e
    mov     l,a
    mov     a,h
    sbb     d
    mov     h,a
    cmc
    jc      div16_drop
    xthl
div16_drop:
    inx     sp
    inx     sp
    lda     div16_count
    dcr     a
    jnz     div16_dvloop
; сдвинуть посл перенос в частное
    xchg
    mov     a,c
    ral
    mov     l,a
    mov     a,b
    ral
    mov     h,a
    ora     a
    ret


; Функция CMP16 - 16р сравнение
; Ввод: HL (уменьшаемое)
;       DE (вычитаемое)
; Вывод: Z=1 - HL=DE
;        Z=0 - HL!=DE
;        С=1 - HL<DE   для чисел без знаков
;        C=0 - HL>=DE
;        S=1 - HL<DE   для чисел со знаками
;        S=0 - HL>=DE
; Используемые регистры: AF
; Используемая память: нет
; Длина: 36 байт
; Время выполнения: 51..69 тактов

CMP16:
    mov     a,d
    xra     h
    jm      cmp16_diff
; переполнение невозмжно - выполнить сравнение без знака
    mov     a,l
    sub     e
    jz      cmp16_equal
; мл байты не равны, сравнить старшие биты
; запомним, что флаг С позднее должен быть очищен
    mov     a,h
    sbb     d
    jc      cmp16_cyset
    jnc     cmp16_cyclr
; мл байты равны
cmp16_equal:
    mov     a,h
    sbb     d
    ret
cmp16_diff:
    mov     a,l
    sub     e
    mov     a,h
    sbb     d
    mov     a,h
    jnc     cmp16_cyclr
cmp16_cyset:
    ori     01H
    stc
    ret
cmp16_cyclr:
    ori     01H
    ret


; Функция ABS - модуль 16р числа
; Ввод: HL (int)
; Вывод: HL (int)
; Используемые регистры: AF,HL
; Используемая память: нет
; Длина: 10 байт
; Время выполнения: 20/51 такта

ABS:
    mov     a,h
    ora     a
    rp                  ;выйти, если положительно
    cma                 ;иначе дополнение HL
    mov     h,a
    mov     a,l
    cma
    mov     l,a
    inx     h
    ret


; Функция DOPHL - дополнение 16р числа
; Ввод: HL (int)
; Вывод: HL (int)
; Используемые регистры: AF,HL
; Используемая память: нет
; Длина: 8 байт
; Время выполнения: 41 такт

DOPHL:
    mov     a,h
    cma
    mov     h,a
    mov     a,l
    cma
    mov     l,a
    inx     h
    ret


; Функция DOPBC - дополнение 16р числа
; Ввод: BC (int)
; Вывод: BC (int)
; Используемые регистры: AF,BC
; Используемая память: нет
; Длина: 8 байт
; Время выполнения: 41 такт

DOPBC:
    mov     a,b
    cma
    mov     b,a
    mov     a,c
    cma
    mov     c,a
    inx     b
    ret


; Функция DOPDE - дополнение 16р числа
; Ввод: DE (int)
; Вывод: DE (int)
; Используемые регистры: AF,DE
; Используемая память: нет
; Длина: 8 байт
; Время выполнения: 41 такт

DOPDE:
    mov     a,d
    cma
    mov     d,a
    mov     a,e
    cma
    mov     e,a
    inx     d
    ret
