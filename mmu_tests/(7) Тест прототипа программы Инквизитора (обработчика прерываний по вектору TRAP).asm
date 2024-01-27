
; (7) Тест прототипа программы Инквизитора (обработчика прерываний по вектору TRAP)
;
; Обработчик прерываний по вектору TRAP сначала смотрит, кто был источником
; прерывания. Если таймер, на дисплей печатается '0', а затем осуществляется
; стандартный возврат. Если процесс, то смотрим, из какого он сектора. Если
; из правильного (в идеале должен быть 'F', но для тестов использовался '0',
; так как сама программа теста располагается в этом секторе), то запускается
; алгоритм исполнения системной функции 'Function', которая перебирает цифры
; на экране. Если сектор неправильный, то на экран печатается '1'.
; Если установить правильный сектор как '0', то программа перебирает значения
; на экране. Если установить правильный сектор как 'F', то программа выводит
; '1'. Исходя из этого можно утвердить, что программа опознает источник
; прерывания, а также способна определить сектор процесса, вызвавшего
; перрывание.
; Круто!
; TODO: проверить подставы с таймером
; Upd: Ухх.. Проверено!


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
    lxi     h,$000D     ;смещение 13
    dad     sp          ;(HL)=(SP)+13
    mov     a,m         ;(A)-старший байт адреса процесса пользователя
    ani     $F0
    cpi     $F0         ;проверка на сектор 'F'
    ;cpi     $00         ;проверка на сектор '0'
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


    

Function:
    call    SYS_OS_muutos
    lda     $8010
    ani     $0F
    call    shex1
    call    7-seg
    cma
    out     DISP_PORT
    ret




  
  
  
  
