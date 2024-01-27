
; (3) Тест системы определения сектора программы, инициировавшей переход в режим
; операционной системы (16.11.2023)
;
; Данная программа аналогична предыдущему тесту, однако в начале обработчика
; прерывания по вектору TRAP имеется программа, которая считывает значение
; регистра-указателя стека SP, прибавляет к значению 11. В стеке к этому
; моменту уже лежат: Значение(HL), Значение(DE), Значение(BC), Значение(PSW),
; Значение(ссылка SYS_OS_muutos) + LSB пользовательского процесса, итого 11.
; Значение печатается на дисплей. Если запускать программу просто, на экране
; загорается символ '0'. Если перед началом процесса пользователя поставить
; директиву ассемблерного транслятора '.org $1000', то на экране загорается
; цифра '1', что доказывает, что система правильно опознает сектор программы,
; инициирующей переход в режим ОС. При этом стоит учитывать то, что функция
; 'SYS_OS_muutos' находится в секторе '0'.
; Отдельно хочется отметить, что в работе программы иногда появляется баг.
; Иногда на экране загорается цифра '3', что странно. Вероятной причиной
; следует считать, что иногда прерывание TRAP приходит позже возврата из
; из функции 'SYS_OS_muutos'. Но такое крайне маловероятно, прерывание должно
; приходить сразу же после завершения исполнения последней инструкции. Однако
; при работе с осциллографом было обнаружено, что прерывание TRAP приходит
; не сразу, а в течение исполнения 2 инструкций 'NOP' после инструкции 'SIM'.
; В подпрограмме 'SYS_OS_muutos' используется 5 инструкций 'NOP'. Все же
; признаю, что причина появления цифры '3' на экране остается для меня 
; непонятной.




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

;Получение значения адреса старшего байта адреса процесса пользователя,
;откуда был выполнен переход в режим ОС
    lxi     h,$000B     ;смещение 11
    dad     sp          ;(HL)=(SP)+11
    mov     a,m         ;(A)-старший байт адреса процесса пользователя
    ani     $F0
;    ;cpi     $F0         ;проверка на сектор 'F'
;    cpi     $00         ;проверка на сектор '0'
;;Если сектор F, то ничего не делаем
;    jz      trap_p_sectorf
;    ;зажигаем светодиод точки
;    mvi     a,$80
;    cma
;    out     DISP_PORT
;trap_p_sectorf:
    rrc
    rrc
    rrc
    rrc
    call    shex1
    call    7-seg
    cma
    out     DISP_PORT

; Главное тело контроллёра
    lda     8010H
    ani     0FH
;    inr     a
;    sta     8010H
;    ani     F0H
;    rlc
;    rlc
;    rlc
;    rlc
    call    shex1
    call    7-seg
    cma
    ;out     DISP_PORT
; Инициализация порта
    mvi     a,B0H
    out     TIMER_MODEREG
    mvi     a,60H
    out     TIMER_COUNTER_2
    mvi     a,EAH
    out     TIMER_COUNTER_2
; Включаем режим пользователя
    call    SYS_User_muutos
;    mvi     a,40H
;    sim
;    mvi     a,C0H
;    sim
;    mvi     a,40H
;    sim
    pop     h
    pop     d
    pop     b
    pop     psw
    ret


SYS_OS_muutos:
SYS_User_muutos:
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
    

;Установка сектора
    .org $1000
user_cykle:
;Программа для пользователя    
    lda     8010H
    inr     a
    sta     8010H
    lxi     h,$003E
    call    DELAY_MS
    call    SYS_OS_muutos
    
    jmp     user_cykle


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
    mvi     a,DDH
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
    out     SYSPORT_C
;Загружаем в стек переход к пользовательскому процессу
    lxi     h,user_cykle
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







  
  
  
  
